defmodule VerisiteBeWeb.ErrorResponse do
  @moduledoc false

  import Ecto.Changeset
  import Phoenix.Controller
  import Plug.Conn

  def unauthorized(conn, message \\ "Unauthorized") do
    conn
    |> put_status(:unauthorized)
    |> json(%{message: message})
    |> halt()
  end

  def validation_error(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{message: "Invalid request", errors: errors_on(changeset)})
  end

  def conflict(conn, message) do
    conn
    |> put_status(:conflict)
    |> json(%{message: message})
    |> halt()
  end

  def forbidden(conn, message \\ "Forbidden") do
    conn
    |> put_status(:forbidden)
    |> json(%{message: message})
    |> halt()
  end

  def not_found(conn, message \\ "Not found") do
    conn
    |> put_status(:not_found)
    |> json(%{message: message})
    |> halt()
  end

  defp errors_on(changeset) do
    traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
