defmodule VerisiteBeWeb.ProfileController do
  use VerisiteBeWeb, :controller

  alias VerisiteBe.Auth
  alias VerisiteBe.Employees
  alias VerisiteBeWeb.ErrorResponse

  def show(conn, _params) do
    json(conn, Employees.to_profile(conn.assigns.current_employee))
  end

  def update(conn, params) do
    conn.assigns.current_employee
    |> Employees.update_profile(params)
    |> render_profile(conn)
  end

  def update_language(conn, params) do
    conn.assigns.current_employee
    |> Employees.update_language(params)
    |> render_profile(conn)
  end

  def update_photo(conn, params) do
    conn.assigns.current_employee
    |> Employees.update_photo(params)
    |> render_profile(conn)
  end

  def logout(conn, _params) do
    with {:ok, _session} <- Auth.logout(conn.assigns.current_session) do
      send_resp(conn, :no_content, "")
    end
  end

  defp render_profile({:ok, employee}, conn), do: json(conn, Employees.to_profile(employee))

  defp render_profile({:error, changeset}, conn),
    do: ErrorResponse.validation_error(conn, changeset)
end
