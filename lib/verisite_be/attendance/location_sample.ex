defmodule VerisiteBe.Attendance.LocationSample do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Employees.Employee

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "attendance_location_samples" do
    field(:session_id, :binary_id)
    field(:captured_at, :utc_datetime)
    field(:timezone, :string)
    field(:location, :map)
    field(:device_signal, :map)

    belongs_to(:employee, Employee)

    timestamps(type: :utc_datetime)
  end

  def changeset(sample, attrs) do
    sample
    |> cast(attrs, [:employee_id, :session_id, :captured_at, :timezone, :location, :device_signal])
    |> validate_required([:employee_id, :session_id, :captured_at, :timezone, :location])
  end
end
