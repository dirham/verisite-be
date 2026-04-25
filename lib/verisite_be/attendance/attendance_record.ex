defmodule VerisiteBe.Attendance.AttendanceRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias VerisiteBe.Employees.Employee

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "attendance_records" do
    field(:session_id, :binary_id)
    field(:type, :string)
    field(:occurred_at, :utc_datetime)
    field(:timezone, :string)
    field(:location, :map)
    field(:device_signal, :map)
    field(:suspicious_reason, :string)

    belongs_to(:employee, Employee)

    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [
      :employee_id,
      :session_id,
      :type,
      :occurred_at,
      :timezone,
      :location,
      :device_signal,
      :suspicious_reason
    ])
    |> validate_required([:employee_id, :session_id, :type, :occurred_at, :timezone, :location])
    |> validate_inclusion(:type, ["clockIn", "clockOut"])
  end
end
