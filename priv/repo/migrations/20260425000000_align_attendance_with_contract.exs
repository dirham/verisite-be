defmodule VerisiteBe.Repo.Migrations.AlignAttendanceWithContract do
  use Ecto.Migration

  def change do
    alter table(:attendance_records) do
      add :session_id, :binary_id
      add :timezone, :string
      add :location, :map
      add :device_signal, :map
    end

    create index(:attendance_records, [:employee_id, :session_id])

    create table(:attendance_location_samples, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :employee_id, references(:employees, type: :binary_id, on_delete: :delete_all), null: false
      add :session_id, :binary_id, null: false
      add :captured_at, :utc_datetime, null: false
      add :timezone, :string, null: false
      add :location, :map, null: false
      add :device_signal, :map

      timestamps(type: :utc_datetime)
    end

    create index(:attendance_location_samples, [:employee_id, :captured_at])
    create index(:attendance_location_samples, [:session_id, :captured_at])
  end
end
