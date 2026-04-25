defmodule VerisiteBeWeb.Plugs.AuthenticateBearer do
  @moduledoc false

  import Plug.Conn

  alias VerisiteBe.Auth
  alias VerisiteBeWeb.ErrorResponse

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, employee, session} <- Auth.authenticate_token(token) do
      conn
      |> assign(:current_employee, employee)
      |> assign(:current_session, session)
    else
      _ -> ErrorResponse.unauthorized(conn)
    end
  end
end
