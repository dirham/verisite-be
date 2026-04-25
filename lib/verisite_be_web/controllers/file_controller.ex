defmodule VerisiteBeWeb.FileController do
  use VerisiteBeWeb, :controller

  alias VerisiteBe.Files
  alias VerisiteBeWeb.ErrorResponse

  def create(conn, params) do
    case Files.upload(conn.assigns.current_employee, params) do
      {:ok, file} ->
        conn
        |> put_status(:created)
        |> json(Files.to_upload_response(file))

      {:error, :provider_not_implemented} ->
        ErrorResponse.conflict(
          conn,
          "The active storage provider is configured but not yet implemented in this backend"
        )

      {:error, changeset} ->
        ErrorResponse.validation_error(conn, changeset)
    end
  end

  def settings(conn, _params) do
    with :ok <- ensure_admin(conn),
         {:ok, settings} <- Files.current_settings() do
      json(conn, settings)
    end
  end

  def update_settings(conn, params) do
    with :ok <- ensure_admin(conn),
         {:ok, settings} <- Files.update_settings(params) do
      json(conn, settings)
    else
      {:error, changeset} ->
        ErrorResponse.validation_error(conn, changeset)
    end
  end

  defp ensure_admin(conn) do
    if conn.assigns.current_employee.role == "admin" do
      :ok
    else
      ErrorResponse.forbidden(conn, "Admin access required")
    end
  end
end
