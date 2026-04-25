defmodule VerisiteBe.Storage.Providers.Local do
  @moduledoc false

  @behaviour VerisiteBe.Storage.Provider

  alias VerisiteBe.Storage.StorageSetting

  @impl true
  def store(upload, %StorageSetting{} = settings) do
    with {:ok, binary} <- Base.decode64(upload.content_base64),
         relative_key <- build_storage_key(upload),
         full_path <- Path.join(root_path(settings.local_base_path), relative_key),
         :ok <- File.mkdir_p(Path.dirname(full_path)),
         :ok <- File.write(full_path, binary) do
      {:ok,
       %{
         provider: "local",
         storage_key: relative_key,
         path: "/" <> Path.join("uploads", relative_key),
         content_type: upload.content_type
       }}
    else
      :error -> {:error, :invalid_base64}
      {:error, reason} -> {:error, reason}
    end
  end

  defp root_path(base_path) do
    if Path.type(base_path) == :absolute do
      base_path
    else
      Path.expand(base_path, File.cwd!())
    end
  end

  defp build_storage_key(upload) do
    extension = upload.name |> Path.extname() |> String.downcase()
    stem = upload.name |> Path.rootname() |> slugify()
    filename = "#{Ecto.UUID.generate()}-#{stem}#{extension}"
    Path.join(upload.usage, filename)
  end

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
end
