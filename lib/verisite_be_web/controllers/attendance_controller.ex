defmodule VerisiteBeWeb.AttendanceController do
  use VerisiteBeWeb, :controller

  alias VerisiteBe.Attendance
  alias VerisiteBeWeb.ErrorResponse

  def clock_in(conn, params) do
    conn.assigns.current_employee
    |> Attendance.clock_in(params)
    |> render_attendance_record(conn)
  end

  def clock_out(conn, params) do
    conn.assigns.current_employee
    |> Attendance.clock_out(params)
    |> render_attendance_record(conn)
  end

  def location_samples(conn, params) do
    case Attendance.submit_location_samples(conn.assigns.current_employee, params) do
      {:ok, :accepted} ->
        send_resp(conn, :accepted, "")

      {:error, :no_active_session} ->
        ErrorResponse.conflict(conn, "No active attendance session")

      {:error, changeset} ->
        ErrorResponse.validation_error(conn, changeset)
    end
  end

  def history(conn, _params) do
    with {:ok, records} <- Attendance.history(conn.assigns.current_employee) do
      json(conn, Attendance.to_history(records))
    end
  end

  defp render_attendance_record({:ok, record}, conn) do
    conn
    |> put_status(:created)
    |> json(Attendance.to_record(record))
  end

  defp render_attendance_record({:error, :no_active_session}, conn),
    do: ErrorResponse.conflict(conn, "No active attendance session")

  defp render_attendance_record({:error, changeset}, conn),
    do: ErrorResponse.validation_error(conn, changeset)
end
