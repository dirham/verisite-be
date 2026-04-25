defmodule VerisiteBe.Attendance do
  alias VerisiteBe.Attendance.AttendanceRecord
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Repo

  def clock_in(%Employee{} = employee) do
    create_record(employee, "clockIn")
  end

  def to_record(%AttendanceRecord{} = record) do
    %{
      id: record.id,
      employeeId: record.employee_id,
      type: record.type,
      occurredAt: DateTime.to_iso8601(record.occurred_at),
      suspiciousReason: record.suspicious_reason
    }
  end

  defp create_record(%Employee{} = employee, type) do
    %AttendanceRecord{}
    |> AttendanceRecord.changeset(%{
      employee_id: employee.id,
      type: type,
      occurred_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.insert()
  end
end
