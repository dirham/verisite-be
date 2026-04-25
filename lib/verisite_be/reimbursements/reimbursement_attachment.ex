defmodule VerisiteBe.Reimbursements.ReimbursementAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Files.StoredFile
  alias VerisiteBe.Reimbursements.ReimbursementRequest

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reimbursement_attachments" do
    field(:name, :string)
    field(:path, :string)
    field(:source, :string)

    belongs_to(:request, ReimbursementRequest)
    belongs_to(:stored_file, StoredFile)

    timestamps(type: :utc_datetime)
  end

  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:request_id, :stored_file_id, :name, :path, :source])
    |> validate_required([:request_id, :stored_file_id, :name, :path, :source])
    |> validate_inclusion(:source, ["gallery", "camera"])
  end
end
