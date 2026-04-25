defmodule VerisiteBe.Repo.Migrations.AddStorageSettingsAndFileReferences do
  use Ecto.Migration

  def change do
    create table(:storage_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :active_provider, :string, null: false, default: "local"
      add :local_base_path, :string, null: false, default: "priv/uploads"
      add :aws_bucket, :string
      add :aws_region, :string
      add :aws_base_url, :string
      add :aws_prefix, :string
      add :google_drive_folder_id, :string

      timestamps(type: :utc_datetime)
    end

    alter table(:employees) do
      add :profile_image_file_id, references(:stored_files, type: :binary_id, on_delete: :nilify_all)
    end

    alter table(:stored_files) do
      add :provider, :string, null: false, default: "local"
      add :storage_key, :string, null: false, default: ""
      add :usage, :string, null: false, default: "general"
    end

    create index(:employees, [:profile_image_file_id])
    create index(:stored_files, [:provider])
    create index(:stored_files, [:usage])
  end
end
