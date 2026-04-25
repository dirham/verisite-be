defmodule VerisiteBeWeb.AttendanceController do
  use VerisiteBeWeb, :controller

  alias VerisiteBe.Attendance
  alias VerisiteBeWeb.ErrorResponse

  def clock_in(conn, _params) do
    conn.assigns.current_employee
    |> Attendance.clock_in()
    |> render_attendance_record(conn)
  end

  defp render_attendance_record({:ok, record}, conn) do
    conn
    |> put_status(:created)
    |> json(Attendance.to_record(record))
  end

  defp render_attendance_record({:error, changeset}, conn),
    do: ErrorResponse.validation_error(conn, changeset)
end
