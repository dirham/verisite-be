defmodule VerisiteBe.Employees.Employee do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Files.StoredFile

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "employees" do
    field(:email, :string)
    field(:password_hash, :string)
    field(:name, :string)
    field(:display_name, :string)
    field(:division, :string)
    field(:role, :string, default: "employee")
    field(:role_label, :string, default: "Employee")
    field(:about_title, :string, default: "")
    field(:about_description, :string, default: "")
    field(:profile_image_path, :string)
    field(:profile_image_name, :string)
    field(:language_code, :string, default: "en")

    belongs_to(:profile_image_file, StoredFile)

    timestamps(type: :utc_datetime)
  end

  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [
      :email,
      :password_hash,
      :name,
      :display_name,
      :division,
      :role,
      :role_label,
      :about_title,
      :about_description,
      :profile_image_file_id,
      :profile_image_path,
      :profile_image_name,
      :language_code
    ])
    |> validate_required([
      :email,
      :password_hash,
      :name,
      :display_name,
      :division,
      :role,
      :role_label,
      :about_title,
      :about_description,
      :language_code
    ])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_inclusion(:role, ["employee", "admin"])
    |> validate_inclusion(:language_code, ["en", "id"])
    |> unique_constraint(:email)
  end

  def profile_changeset(employee, attrs) do
    employee
    |> cast(attrs, [:name, :division])
    |> validate_required([:name, :division])
  end

  def language_changeset(employee, attrs) do
    employee
    |> cast(attrs, [:language_code])
    |> validate_required([:language_code])
    |> validate_inclusion(:language_code, ["en", "id"])
  end

  def photo_changeset(employee, attrs) do
    employee
    |> cast(attrs, [:profile_image_file_id, :profile_image_path, :profile_image_name])
    |> validate_required([:profile_image_file_id, :profile_image_path, :profile_image_name])
  end
end
