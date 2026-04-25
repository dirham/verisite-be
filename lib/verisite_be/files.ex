defmodule VerisiteBe.Files do
  import Ecto.Query

  alias Ecto.Changeset
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Files.StoredFile
  alias VerisiteBe.Repo
  alias VerisiteBe.Storage.Providers.Aws
  alias VerisiteBe.Storage.Providers.GoogleDrive
  alias VerisiteBe.Storage.Providers.Local
  alias VerisiteBe.Storage.StorageSetting

  @usages ~w(general profilePhoto reimbursementAttachment)
  @sources ~w(gallery camera profile)

  def upload(%Employee{} = employee, attrs) do
    with {:ok, upload} <- validate_upload(attrs),
         {:ok, settings} <- get_or_create_settings(),
         {:ok, stored} <- provider_module(settings.active_provider).store(upload, settings) do
      %StoredFile{}
      |> StoredFile.changeset(%{
        employee_id: employee.id,
        name: upload.name,
        path: stored.path,
        source: upload.source,
        content_type: stored.content_type,
        provider: stored.provider,
        storage_key: stored.storage_key,
        usage: upload.usage
      })
      |> Repo.insert()
    else
      {:error, :provider_not_implemented} ->
        {:error, :provider_not_implemented}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}

      {:error, :invalid_base64} ->
        {:error, invalid_base64_changeset()}

      {:error, reason} ->
        {:error, storage_changeset(reason)}
    end
  end

  def get_owned_file(%Employee{} = employee, file_id) when is_binary(file_id) do
    StoredFile
    |> where([file], file.id == ^file_id and file.employee_id == ^employee.id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      file -> {:ok, file}
    end
  end

  def fetch_owned_files(%Employee{} = employee, file_ids) when is_list(file_ids) do
    files =
      StoredFile
      |> where([file], file.employee_id == ^employee.id and file.id in ^file_ids)
      |> Repo.all()

    if length(files) == length(Enum.uniq(file_ids)) do
      {:ok, files}
    else
      {:error, attachments_not_found_changeset()}
    end
  end

  def current_settings do
    with {:ok, settings} <- get_or_create_settings() do
      {:ok, to_settings(settings)}
    end
  end

  def update_settings(attrs) do
    with {:ok, settings} <- get_or_create_settings() do
      settings
      |> StorageSetting.changeset(normalize_settings_attrs(attrs))
      |> Repo.update()
      |> case do
        {:ok, updated} -> {:ok, to_settings(updated)}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  def to_upload_response(%StoredFile{} = file) do
    %{
      fileId: file.id,
      name: file.name,
      path: file.path,
      source: file.source,
      contentType: file.content_type,
      provider: file.provider,
      usage: file.usage
    }
  end

  def to_settings(%StorageSetting{} = settings) do
    %{
      activeProvider: settings.active_provider,
      local: %{
        basePath: settings.local_base_path
      },
      aws: %{
        bucket: settings.aws_bucket,
        region: settings.aws_region,
        baseUrl: settings.aws_base_url,
        prefix: settings.aws_prefix
      },
      googleDrive: %{
        folderId: settings.google_drive_folder_id
      }
    }
  end

  defp get_or_create_settings do
    case Repo.one(StorageSetting) do
      nil ->
        %StorageSetting{}
        |> StorageSetting.changeset(%{})
        |> Repo.insert()
        |> case do
          {:ok, settings} -> {:ok, settings}
          {:error, changeset} -> {:error, changeset}
        end

      settings ->
        {:ok, settings}
    end
  end

  defp validate_upload(attrs) when is_map(attrs) do
    changeset =
      {%{},
       %{
         name: :string,
         source: :string,
         contentType: :string,
         contentBase64: :string,
         usage: :string
       }}
      |> Changeset.cast(attrs, [:name, :source, :contentType, :contentBase64, :usage])
      |> Changeset.validate_required([:name, :source, :contentType, :contentBase64])
      |> Changeset.put_change(:usage, Map.get(attrs, "usage", "general"))
      |> Changeset.validate_inclusion(:source, @sources)
      |> Changeset.validate_inclusion(:usage, @usages)

    if changeset.valid? do
      {:ok,
       %{
         name: Changeset.get_field(changeset, :name),
         source: Changeset.get_field(changeset, :source),
         content_type: Changeset.get_field(changeset, :contentType),
         content_base64: Changeset.get_field(changeset, :contentBase64),
         usage: Changeset.get_field(changeset, :usage) || "general"
       }}
    else
      {:error, changeset}
    end
  end

  defp validate_upload(_attrs), do: {:error, invalid_payload_changeset()}

  defp normalize_settings_attrs(attrs) when is_map(attrs) do
    %{
      active_provider: Map.get(attrs, "activeProvider"),
      local_base_path: get_in(attrs, ["local", "basePath"]),
      aws_bucket: get_in(attrs, ["aws", "bucket"]),
      aws_region: get_in(attrs, ["aws", "region"]),
      aws_base_url: get_in(attrs, ["aws", "baseUrl"]),
      aws_prefix: get_in(attrs, ["aws", "prefix"]),
      google_drive_folder_id: get_in(attrs, ["googleDrive", "folderId"])
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp provider_module("aws"), do: Aws
  defp provider_module("google_drive"), do: GoogleDrive
  defp provider_module(_provider), do: Local

  defp invalid_payload_changeset do
    {%{}, %{payload: :string}}
    |> Changeset.cast(%{}, [:payload])
    |> Changeset.add_error(:payload, "must be an object")
  end

  defp invalid_base64_changeset do
    {%{}, %{contentBase64: :string}}
    |> Changeset.cast(%{}, [:contentBase64])
    |> Changeset.add_error(:contentBase64, "must be valid base64 content")
  end

  defp attachments_not_found_changeset do
    {%{}, %{attachments: {:array, :string}}}
    |> Changeset.cast(%{}, [:attachments])
    |> Changeset.add_error(:attachments, "must reference uploaded files owned by the employee")
  end

  defp storage_changeset(reason) do
    {%{}, %{storage: :string}}
    |> Changeset.cast(%{}, [:storage])
    |> Changeset.add_error(:storage, "upload failed: #{inspect(reason)}")
  end
end
