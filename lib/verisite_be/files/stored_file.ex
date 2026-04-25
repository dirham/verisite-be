defmodule VerisiteBe.Files.StoredFile do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Employees.Employee

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "stored_files" do
    field(:name, :string)
    field(:path, :string)
    field(:source, :string)
    field(:content_type, :string)

    belongs_to(:employee, Employee)

    timestamps(type: :utc_datetime)
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, [:employee_id, :name, :path, :source, :content_type])
    |> validate_required([:name, :path, :source])
    |> validate_inclusion(:source, ["gallery", "camera", "profile"])
  end
end
