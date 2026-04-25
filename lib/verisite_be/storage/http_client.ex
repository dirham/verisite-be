defmodule VerisiteBe.Storage.HttpClient do
  @moduledoc false

  @callback put(String.t(), [{charlist(), charlist()}], binary(), String.t()) ::
              {:ok, pos_integer(), [{charlist(), charlist()}], binary()} | {:error, term()}

  def put(url, headers, body, content_type) do
    request = {String.to_charlist(url), headers, String.to_charlist(content_type), body}

    case :httpc.request(:put, request, [ssl: [verify: :verify_none]], body_format: :binary) do
      {:ok, {{_http_version, status, _reason_phrase}, response_headers, response_body}} ->
        {:ok, status, response_headers, response_body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
