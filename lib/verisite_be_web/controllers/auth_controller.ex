defmodule VerisiteBeWeb.AuthController do
  use VerisiteBeWeb, :controller

  alias VerisiteBe.Auth
  alias VerisiteBeWeb.ErrorResponse

  def login(conn, params) do
    case Auth.login(params) do
      {:ok, session} ->
        json(conn, session)

      {:error, :invalid_credentials} ->
        ErrorResponse.unauthorized(conn, "Invalid employee credentials")
    end
  end
end
