defmodule VerisiteBe.Reimbursements.ReimbursementRequest do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Reimbursements.ReimbursementAttachment

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reimbursement_requests" do
    field(:title, :string)
    field(:amount, :decimal)
    field(:submitted_at, :utc_datetime)
    field(:status, :string, default: "pending")
    field(:notes, :string, default: "")
    field(:reviewed_at, :utc_datetime)
    field(:rejection_reason, :string)
    field(:payment_reference, :string)

    belongs_to(:employee, Employee)
    belongs_to(:reviewer, Employee)
    has_many(:attachments, ReimbursementAttachment, foreign_key: :request_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :employee_id,
      :reviewer_id,
      :title,
      :amount,
      :submitted_at,
      :status,
      :notes,
      :reviewed_at,
      :rejection_reason,
      :payment_reference
    ])
    |> validate_required([:employee_id, :title, :amount, :submitted_at, :status, :notes])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "canceled"])
  end
end
