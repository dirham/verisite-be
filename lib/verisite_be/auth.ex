defmodule VerisiteBe.Auth do
  import Ecto.Query

  alias VerisiteBe.Auth.Password
  alias VerisiteBe.Auth.Session
  alias VerisiteBe.Employees
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Repo

  @session_seconds 30 * 24 * 60 * 60

  def login(%{"email" => email, "password" => password})
      when is_binary(email) and is_binary(password) do
    with %Employee{} = employee <- Employees.get_employee_by_email(email),
         true <- Password.verify(password, employee.password_hash),
         {:ok, token, _session} <- create_session(employee) do
      {:ok,
       %{
         employeeId: employee.id,
         email: employee.email,
         displayName: employee.display_name,
         token: token
       }}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  def login(_attrs), do: {:error, :invalid_credentials}

  def authenticate_token(token) when is_binary(token) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    token_hash = hash_token(token)

    Session
    |> where([session], session.token_hash == ^token_hash)
    |> where([session], is_nil(session.revoked_at))
    |> where([session], session.expires_at > ^now)
    |> preload(:employee)
    |> Repo.one()
    |> case do
      %Session{employee: %Employee{} = employee} = session -> {:ok, employee, session}
      _ -> {:error, :unauthorized}
    end
  end

  def authenticate_token(_token), do: {:error, :unauthorized}

  def logout(%Session{} = session) do
    session
    |> Session.changeset(%{revoked_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  defp create_session(%Employee{} = employee) do
    token = random_token()

    attrs = %{
      employee_id: employee.id,
      token_hash: hash_token(token),
      expires_at:
        DateTime.utc_now()
        |> DateTime.add(@session_seconds, :second)
        |> DateTime.truncate(:second)
    }

    case %Session{} |> Session.changeset(attrs) |> Repo.insert() do
      {:ok, session} -> {:ok, token, session}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp random_token do
    32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end

  defp hash_token(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end
end
