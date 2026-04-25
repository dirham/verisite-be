defmodule VerisiteBe.Files.StoredFile do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Employees.Employee

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @providers ["local", "aws", "google_drive"]
  @usages ["general", "profilePhoto", "reimbursementAttachment"]

  schema "stored_files" do
    field(:name, :string)
    field(:path, :string)
    field(:source, :string)
    field(:content_type, :string)
    field(:provider, :string, default: "local")
    field(:storage_key, :string)
    field(:usage, :string, default: "general")

    belongs_to(:employee, Employee)

    timestamps(type: :utc_datetime)
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, [
      :employee_id,
      :name,
      :path,
      :source,
      :content_type,
      :provider,
      :storage_key,
      :usage
    ])
    |> validate_required([:name, :path, :source])
    |> validate_inclusion(:source, ["gallery", "camera", "profile"])
    |> validate_inclusion(:provider, @providers)
    |> validate_inclusion(:usage, @usages)
  end
end
