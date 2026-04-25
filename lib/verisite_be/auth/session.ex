defmodule VerisiteBe.Auth.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Employees.Employee

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sessions" do
    field(:token_hash, :string)
    field(:revoked_at, :utc_datetime)
    field(:expires_at, :utc_datetime)

    belongs_to(:employee, Employee)

    timestamps(type: :utc_datetime)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:employee_id, :token_hash, :revoked_at, :expires_at])
    |> validate_required([:employee_id, :token_hash, :expires_at])
    |> unique_constraint(:token_hash)
  end
end
