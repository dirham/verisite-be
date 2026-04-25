defmodule VerisiteBeWeb.ReimbursementController do
  use VerisiteBeWeb, :controller

  alias VerisiteBe.Reimbursements
  alias VerisiteBeWeb.ErrorResponse

  def index(conn, _params) do
    with {:ok, requests} <- Reimbursements.list_requests(conn.assigns.current_employee) do
      json(conn, Reimbursements.to_list(requests))
    end
  end

  def create(conn, params) do
    case Reimbursements.submit_request(conn.assigns.current_employee, params) do
      {:ok, request} ->
        conn
        |> put_status(:created)
        |> json(Reimbursements.to_request(request))

      {:error, changeset} ->
        ErrorResponse.validation_error(conn, changeset)
    end
  end

  def cancel(conn, %{"requestId" => request_id}) do
    conn.assigns.current_employee
    |> Reimbursements.cancel_request(request_id)
    |> render_reimbursement(conn, :ok)
  end

  def approve(conn, %{"requestId" => request_id} = params) do
    with :ok <- ensure_admin(conn),
         result <-
           Reimbursements.approve_request(conn.assigns.current_employee, request_id, params) do
      render_reimbursement(result, conn, :ok)
    end
  end

  def reject(conn, %{"requestId" => request_id} = params) do
    with :ok <- ensure_admin(conn),
         result <-
           Reimbursements.reject_request(conn.assigns.current_employee, request_id, params) do
      render_reimbursement(result, conn, :ok)
    end
  end

  def payment(conn, %{"requestId" => request_id} = params) do
    with :ok <- ensure_admin(conn),
         result <- Reimbursements.attach_payment_reference(request_id, params) do
      render_reimbursement(result, conn, :ok)
    end
  end

  defp ensure_admin(conn) do
    if conn.assigns.current_employee.role == "admin" do
      :ok
    else
      ErrorResponse.forbidden(conn, "Admin access required")
    end
  end

  defp render_reimbursement({:ok, request}, conn, status) do
    conn
    |> put_status(status)
    |> json(Reimbursements.to_request(request))
  end

  defp render_reimbursement({:error, :not_found}, conn, _status),
    do: ErrorResponse.not_found(conn, "Reimbursement request not found")

  defp render_reimbursement({:error, :not_cancelable}, conn, _status),
    do: ErrorResponse.conflict(conn, "Reimbursement request cannot be canceled")

  defp render_reimbursement({:error, :not_approvable}, conn, _status),
    do: ErrorResponse.conflict(conn, "Reimbursement request cannot be approved")

  defp render_reimbursement({:error, :not_rejectable}, conn, _status),
    do: ErrorResponse.conflict(conn, "Reimbursement request cannot be rejected")

  defp render_reimbursement({:error, :payment_not_attachable}, conn, _status),
    do:
      ErrorResponse.conflict(
        conn,
        "Payment reference can only be attached to approved reimbursements"
      )

  defp render_reimbursement({:error, changeset}, conn, _status),
    do: ErrorResponse.validation_error(conn, changeset)
end
