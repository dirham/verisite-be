defmodule VerisiteBeWeb.ReportController do
  use VerisiteBeWeb, :controller

  alias VerisiteBe.Reports
  alias VerisiteBeWeb.ErrorResponse

  def attendance_insights(conn, params) do
    conn.assigns.current_employee
    |> Reports.attendance_insights(params)
    |> render_report_response(conn)
  end

  def reimbursement_summary(conn, params) do
    conn.assigns.current_employee
    |> Reports.reimbursement_summary(params)
    |> render_report_response(conn)
  end

  def export_attendance(conn, _params) do
    conn.assigns.current_employee
    |> Reports.export_attendance()
    |> render_report_response(conn)
  end

  def export_reimbursements(conn, _params) do
    conn.assigns.current_employee
    |> Reports.export_reimbursements()
    |> render_report_response(conn)
  end

  defp render_report_response({:ok, payload}, conn), do: json(conn, payload)

  defp render_report_response({:error, changeset}, conn),
    do: ErrorResponse.validation_error(conn, changeset)
end
