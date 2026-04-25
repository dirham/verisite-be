defmodule VerisiteBe.Storage.Providers.Aws do
  @moduledoc false

  @behaviour VerisiteBe.Storage.Provider

  alias VerisiteBe.Storage.StorageSetting

  @service "s3"

  @impl true
  def store(upload, %StorageSetting{} = settings) do
    with {:ok, binary} <- Base.decode64(upload.content_base64),
         {:ok, credentials} <- credentials(),
         {:ok, base_url} <- normalize_base_url(settings.aws_base_url),
         uri <-
           build_uri(
             base_url,
             settings.aws_bucket,
             build_storage_key(upload, settings.aws_prefix)
           ),
         timestamp = DateTime.utc_now() |> DateTime.truncate(:second),
         content_sha256 <- sha256_hex(binary),
         headers <-
           signed_headers(
             uri,
             upload.content_type,
             content_sha256,
             timestamp,
             settings,
             credentials
           ),
         {:ok, status, _response_headers, _response_body} <-
           http_client().put(URI.to_string(uri), headers, binary, upload.content_type),
         :ok <- ensure_success(status) do
      {:ok,
       %{
         provider: "aws",
         storage_key:
           uri.path
           |> URI.decode()
           |> String.trim_leading("/")
           |> bucket_relative_key(settings.aws_bucket),
         path: URI.to_string(uri),
         content_type: upload.content_type
       }}
    else
      :error -> {:error, :invalid_base64}
      {:error, _reason} = error -> error
    end
  end

  defp credentials do
    case Application.get_env(:verisite_be, :storage_aws_credentials) do
      nil ->
        access_key =
          System.get_env("AWS_ACCESS_KEY_ID") || System.get_env("STORAGE_ACCESS_KEY")

        secret_key =
          System.get_env("AWS_SECRET_ACCESS_KEY") || System.get_env("STORAGE_SECRET_KEY")

        session_token = System.get_env("AWS_SESSION_TOKEN")

        build_credentials(access_key, secret_key, session_token)

      {access_key, secret_key} ->
        build_credentials(access_key, secret_key, nil)

      {access_key, secret_key, session_token} ->
        build_credentials(access_key, secret_key, session_token)
    end
  end

  defp build_credentials(nil, _secret_key, _session_token), do: {:error, :missing_aws_access_key}
  defp build_credentials(_access_key, nil, _session_token), do: {:error, :missing_aws_secret_key}

  defp build_credentials(access_key, secret_key, session_token) do
    {:ok,
     %{
       access_key: access_key,
       secret_key: secret_key,
       session_token: session_token
     }}
  end

  defp normalize_base_url(nil), do: {:error, :missing_aws_base_url}
  defp normalize_base_url(""), do: {:error, :missing_aws_base_url}

  defp normalize_base_url(base_url) do
    {:ok, String.trim_trailing(base_url, "/")}
  end

  defp build_storage_key(upload, prefix) do
    extension = upload.name |> Path.extname() |> String.downcase()
    stem = upload.name |> Path.rootname() |> slugify()
    filename = "#{Ecto.UUID.generate()}-#{stem}#{extension}"

    [blank_to_nil(prefix), upload.usage, filename]
    |> Enum.reject(&is_nil/1)
    |> Path.join()
  end

  defp build_uri(base_url, bucket, storage_key) do
    encoded_key =
      storage_key
      |> String.split("/")
      |> Enum.map(&URI.encode/1)
      |> Enum.join("/")

    URI.parse("#{base_url}/#{bucket}/#{encoded_key}")
  end

  defp signed_headers(uri, content_type, content_sha256, timestamp, settings, credentials) do
    host = uri.authority || uri.host
    amz_date = amz_date(timestamp)
    short_date = short_date(timestamp)
    region = settings.aws_region
    canonical_uri = uri.path || "/"

    headers =
      [
        {"content-type", content_type},
        {"host", host},
        {"x-amz-content-sha256", content_sha256},
        {"x-amz-date", amz_date}
      ]
      |> maybe_add_session_token(credentials.session_token)
      |> Enum.sort()

    signed_header_names =
      headers
      |> Enum.map(fn {name, _value} -> name end)
      |> Enum.join(";")

    canonical_headers =
      headers
      |> Enum.map_join("", fn {name, value} -> "#{name}:#{String.trim(value)}\n" end)

    canonical_request =
      [
        "PUT",
        canonical_uri,
        "",
        canonical_headers,
        signed_header_names,
        content_sha256
      ]
      |> Enum.join("\n")

    credential_scope = "#{short_date}/#{region}/#{@service}/aws4_request"

    string_to_sign =
      [
        "AWS4-HMAC-SHA256",
        amz_date,
        credential_scope,
        sha256_hex(canonical_request)
      ]
      |> Enum.join("\n")

    signature =
      credentials.secret_key
      |> signing_key(short_date, region)
      |> hmac_hex(string_to_sign)

    authorization =
      "AWS4-HMAC-SHA256 Credential=#{credentials.access_key}/#{credential_scope}, SignedHeaders=#{signed_header_names}, Signature=#{signature}"

    [{"authorization", authorization} | headers]
    |> Enum.map(fn {name, value} -> {String.to_charlist(name), String.to_charlist(value)} end)
  end

  defp maybe_add_session_token(headers, nil), do: headers
  defp maybe_add_session_token(headers, ""), do: headers
  defp maybe_add_session_token(headers, token), do: [{"x-amz-security-token", token} | headers]

  defp signing_key(secret_key, short_date, region) do
    ("AWS4" <> secret_key)
    |> hmac(short_date)
    |> hmac(region)
    |> hmac(@service)
    |> hmac("aws4_request")
  end

  defp hmac(key, data), do: :crypto.mac(:hmac, :sha256, key, data)
  defp hmac_hex(key, data), do: key |> hmac(data) |> Base.encode16(case: :lower)
  defp sha256_hex(data), do: :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)

  defp amz_date(datetime), do: Calendar.strftime(datetime, "%Y%m%dT%H%M%SZ")
  defp short_date(datetime), do: Calendar.strftime(datetime, "%Y%m%d")

  defp ensure_success(status) when status in 200..299, do: :ok
  defp ensure_success(status), do: {:error, {:upload_failed, status}}

  defp bucket_relative_key(path, bucket) do
    String.replace_prefix(path, "#{bucket}/", "")
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: String.trim(value, "/")

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "file"
      slug -> slug
    end
  end

  defp http_client do
    Application.get_env(:verisite_be, :storage_http_client, VerisiteBe.Storage.HttpClient)
  end
end
