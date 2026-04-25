defmodule VerisiteBeWeb.AttendanceControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Ecto.Adapters.SQL.Sandbox
  alias VerisiteBe.Auth.Session
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Repo

  @endpoint VerisiteBeWeb.Endpoint

  setup do
    :ok = Sandbox.checkout(Repo)

    employee =
      %Employee{}
      |> Employee.changeset(%{
        email: "clock-in@verisite.local",
        password_hash: "not-used",
        name: "Clock In",
        display_name: "Clock In",
        division: "Operations",
        role: "employee",
        role_label: "Employee",
        about_title: "Field Operations",
        about_description: "Handles site activity.",
        language_code: "en"
      })
      |> Repo.insert!()

    token = "clock-in-token"

    %Session{}
    |> Session.changeset(%{
      employee_id: employee.id,
      token_hash: hash_token(token),
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
    })
    |> Repo.insert!()

    %{employee: employee, token: token}
  end

  test "creates a contract-shaped clock-in record for the authenticated employee", %{
    employee: employee,
    token: token
  } do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/attendance/clock-in")

    assert %{
             "id" => id,
             "employeeId" => employee_id,
             "type" => "clockIn",
             "occurredAt" => occurred_at,
             "suspiciousReason" => nil
           } = json_response(conn, 201)

    assert employee_id == employee.id
    assert {:ok, _uuid} = Ecto.UUID.cast(id)
    assert {:ok, _occurred_at, 0} = DateTime.from_iso8601(occurred_at)
  end

  test "rejects clock-in without a bearer token" do
    conn = post(build_conn(), "/api/attendance/clock-in")

    assert json_response(conn, 401) == %{"message" => "Unauthorized"}
  end

  defp hash_token(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end
end
