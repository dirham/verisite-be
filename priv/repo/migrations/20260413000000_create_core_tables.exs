defmodule VerisiteBe.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION IF EXISTS citext")

    create table(:employees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :password_hash, :string, null: false
      add :name, :string, null: false
      add :display_name, :string, null: false
      add :division, :string, null: false
      add :role, :string, null: false, default: "employee"
      add :role_label, :string, null: false, default: "Employee"
      add :about_title, :string, null: false, default: ""
      add :about_description, :text, null: false, default: ""
      add :profile_image_path, :string
      add :profile_image_name, :string
      add :language_code, :string, null: false, default: "en"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:employees, [:email])

    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :employee_id, references(:employees, type: :binary_id, on_delete: :delete_all), null: false
      add :token_hash, :string, null: false
      add :revoked_at, :utc_datetime
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:sessions, [:token_hash])
    create index(:sessions, [:employee_id])

    create table(:attendance_records, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :employee_id, references(:employees, type: :binary_id, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :occurred_at, :utc_datetime, null: false
      add :suspicious_reason, :text

      timestamps(type: :utc_datetime)
    end

    create index(:attendance_records, [:employee_id, :occurred_at])

    create table(:stored_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :employee_id, references(:employees, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false
      add :path, :string, null: false
      add :source, :string, null: false
      add :content_type, :string

      timestamps(type: :utc_datetime)
    end

    create index(:stored_files, [:employee_id])

    create table(:reimbursement_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :employee_id, references(:employees, type: :binary_id, on_delete: :delete_all), null: false
      add :reviewer_id, references(:employees, type: :binary_id, on_delete: :nilify_all)
      add :title, :string, null: false
      add :amount, :decimal, null: false
      add :submitted_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "pending"
      add :notes, :text, null: false, default: ""
      add :reviewed_at, :utc_datetime
      add :rejection_reason, :text
      add :payment_reference, :string

      timestamps(type: :utc_datetime)
    end

    create index(:reimbursement_requests, [:employee_id, :submitted_at])
    create index(:reimbursement_requests, [:reviewer_id])
    create index(:reimbursement_requests, [:status])

    create table(:reimbursement_attachments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :request_id, references(:reimbursement_requests, type: :binary_id, on_delete: :delete_all), null: false
      add :stored_file_id, references(:stored_files, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false
      add :path, :string, null: false
      add :source, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:reimbursement_attachments, [:request_id])
    create index(:reimbursement_attachments, [:stored_file_id])
  end
end
