defmodule VerisiteBeWeb.AttendanceControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Ecto.Adapters.SQL.Sandbox
  alias VerisiteBe.Attendance.AttendanceRecord
  alias VerisiteBe.Attendance.LocationSample
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
      |> post("/api/attendance/clock-in", valid_event_payload())

    assert %{
             "id" => id,
             "employeeId" => employee_id,
             "sessionId" => session_id,
             "type" => "clockIn",
             "occurredAt" => "2026-04-25T01:02:03Z",
             "suspiciousReason" => nil,
             "location" => %{
               "latitude" => -5.1477,
               "longitude" => 119.4327,
               "accuracyMeters" => 8.5
             }
           } = json_response(conn, 201)

    assert employee_id == employee.id
    assert {:ok, _uuid} = Ecto.UUID.cast(id)
    assert {:ok, _uuid} = Ecto.UUID.cast(session_id)
  end

  test "creates a clock-out record tied to the active session", %{token: token} do
    clock_in_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/attendance/clock-in", valid_event_payload())

    %{"sessionId" => session_id} = json_response(clock_in_conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/attendance/clock-out", %{
        "occurredAt" => "2026-04-25T10:12:00Z",
        "timezone" => "Asia/Makassar",
        "location" => %{"latitude" => -5.1478, "longitude" => 119.4329}
      })

    assert %{
             "sessionId" => ^session_id,
             "type" => "clockOut",
             "occurredAt" => "2026-04-25T10:12:00Z"
           } = json_response(conn, 201)
  end

  test "returns attendance history newest first", %{employee: employee, token: token} do
    session_id = Ecto.UUID.generate()

    Repo.insert!(attendance_record(employee.id, session_id, "clockIn", ~U[2026-04-24 01:00:00Z]))
    Repo.insert!(attendance_record(employee.id, session_id, "clockOut", ~U[2026-04-24 10:00:00Z]))

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/attendance/history")

    assert %{"records" => [first, second | _rest]} = json_response(conn, 200)
    assert first["type"] == "clockOut"
    assert second["type"] == "clockIn"
  end

  test "accepts location samples for the active attendance session", %{token: token} do
    clock_in_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/attendance/clock-in", valid_event_payload())

    %{"sessionId" => session_id} = json_response(clock_in_conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/attendance/location-samples", %{
        "sessionId" => session_id,
        "samples" => [
          %{
            "capturedAt" => "2026-04-25T01:12:03Z",
            "timezone" => "Asia/Makassar",
            "location" => %{
              "latitude" => -5.1477,
              "longitude" => 119.4327,
              "isMocked" => false
            },
            "deviceSignal" => %{"platform" => "android", "batteryLevel" => 89}
          }
        ]
      })

    assert response(conn, 202) == ""
    assert Repo.aggregate(LocationSample, :count, :id) == 1
  end

  test "rejects invalid clock-in payload", %{token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/attendance/clock-in", %{
        "timezone" => "Asia/Makassar",
        "location" => %{"latitude" => -5.1477}
      })

    assert %{"message" => "Invalid request", "errors" => errors} = json_response(conn, 422)
    assert errors["occurredAt"] == ["can't be blank"]
    assert "longitude is required" in List.wrap(errors["location"])
  end

  test "rejects clock-in without a bearer token" do
    conn = post(build_conn(), "/api/attendance/clock-in", valid_event_payload())

    assert json_response(conn, 401) == %{"message" => "Unauthorized"}
  end

  defp valid_event_payload do
    %{
      "occurredAt" => "2026-04-25T01:02:03Z",
      "timezone" => "Asia/Makassar",
      "location" => %{
        "latitude" => -5.1477,
        "longitude" => 119.4327,
        "accuracyMeters" => 8.5
      }
    }
  end

  defp attendance_record(employee_id, session_id, type, occurred_at) do
    %AttendanceRecord{}
    |> AttendanceRecord.changeset(%{
      employee_id: employee_id,
      session_id: session_id,
      type: type,
      occurred_at: occurred_at,
      timezone: "Asia/Makassar",
      location: %{"latitude" => -5.1477, "longitude" => 119.4327}
    })
  end

  defp hash_token(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end
end
