defmodule VerisiteBe.Storage.StorageSetting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @providers ["local", "aws", "google_drive"]

  schema "storage_settings" do
    field(:active_provider, :string, default: "local")
    field(:local_base_path, :string, default: "priv/uploads")
    field(:aws_bucket, :string)
    field(:aws_region, :string)
    field(:aws_base_url, :string)
    field(:aws_prefix, :string)
    field(:google_drive_folder_id, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [
      :active_provider,
      :local_base_path,
      :aws_bucket,
      :aws_region,
      :aws_base_url,
      :aws_prefix,
      :google_drive_folder_id
    ])
    |> validate_required([:active_provider, :local_base_path])
    |> validate_inclusion(:active_provider, @providers)
    |> validate_provider_requirements()
  end

  defp validate_provider_requirements(%Ecto.Changeset{} = changeset) do
    case get_field(changeset, :active_provider) do
      "aws" ->
        changeset
        |> validate_required([:aws_bucket, :aws_region, :aws_base_url])

      "google_drive" ->
        validate_required(changeset, [:google_drive_folder_id])

      _ ->
        changeset
    end
  end
end
