defmodule VerisiteBeWeb.ReportControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Ecto.Adapters.SQL.Sandbox
  alias VerisiteBe.Attendance.AttendanceRecord
  alias VerisiteBe.Auth.Session
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Reimbursements.ReimbursementRequest
  alias VerisiteBe.Repo

  @endpoint VerisiteBeWeb.Endpoint

  setup do
    :ok = Sandbox.checkout(Repo)

    employee =
      %Employee{}
      |> Employee.changeset(%{
        email: "reports@verisite.local",
        password_hash: "not-used",
        name: "Report Employee",
        display_name: "Report Employee",
        division: "Operations",
        role: "employee",
        role_label: "Employee",
        about_title: "Field Operations",
        about_description: "Handles site activity.",
        language_code: "en"
      })
      |> Repo.insert!()

    token = "reports-token"

    %Session{}
    |> Session.changeset(%{
      employee_id: employee.id,
      token_hash: hash_token(token),
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
    })
    |> Repo.insert!()

    %{employee: employee, token: token}
  end

  test "exports attendance records as inline CSV metadata for the signed-in employee", %{
    employee: employee,
    token: token
  } do
    session_id = Ecto.UUID.generate()

    Repo.insert!(
      attendance_record(employee.id, session_id, "clockIn", ~U[2026-04-24 01:00:00Z], nil)
    )

    Repo.insert!(
      attendance_record(
        employee.id,
        session_id,
        "clockOut",
        ~U[2026-04-24 10:00:00Z],
        "Mocked location detected"
      )
    )

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/reports/attendance/export")

    assert %{
             "id" => id,
             "type" => "attendance",
             "scope" => "singleEmployee",
             "fileName" => file_name,
             "formatLabel" => "CSV",
             "generatedAt" => generated_at,
             "rowCount" => 2,
             "content" => content,
             "employee" => %{
               "id" => employee_id,
               "name" => "Report Employee",
               "division" => "Operations"
             }
           } = json_response(conn, 200)

    assert employee_id == employee.id
    assert {:ok, _uuid} = Ecto.UUID.cast(id)
    assert file_name =~ "attendance-report-employee-"
    assert file_name =~ ".csv"
    assert {:ok, _datetime, 0} = DateTime.from_iso8601(generated_at)

    assert content ==
             Enum.join(
               [
                 "occurredAt,type,sessionId,timezone,latitude,longitude,accuracyMeters,suspiciousReason",
                 "2026-04-24T01:00:00Z,clockIn,#{session_id},Asia/Makassar,-5.1477,119.4327,8.5,",
                 "2026-04-24T10:00:00Z,clockOut,#{session_id},Asia/Makassar,-5.1477,119.4327,8.5,Mocked location detected"
               ],
               "\n"
             )
  end

  test "exports a header-only CSV when the employee has no attendance rows", %{token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/reports/attendance/export")

    assert %{
             "rowCount" => 0,
             "content" =>
               "occurredAt,type,sessionId,timezone,latitude,longitude,accuracyMeters,suspiciousReason"
           } = json_response(conn, 200)
  end

  test "returns attendance insights for the requested week period", %{
    employee: employee,
    token: token
  } do
    today = Date.utc_today()
    workday = Date.add(today, -1)
    old_day = Date.add(today, -10)
    session_id = Ecto.UUID.generate()
    old_session_id = Ecto.UUID.generate()

    Repo.insert!(
      attendance_record(
        employee.id,
        session_id,
        "clockIn",
        datetime_for(workday, ~T[01:00:00]),
        nil
      )
    )

    Repo.insert!(
      attendance_record(
        employee.id,
        session_id,
        "clockOut",
        datetime_for(workday, ~T[09:30:00]),
        "Mocked location detected"
      )
    )

    Repo.insert!(
      attendance_record(
        employee.id,
        old_session_id,
        "clockIn",
        datetime_for(old_day, ~T[02:00:00]),
        nil
      )
    )

    Repo.insert!(
      attendance_record(
        employee.id,
        old_session_id,
        "clockOut",
        datetime_for(old_day, ~T[08:00:00]),
        nil
      )
    )

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/reports/attendance/insights?period=week")

    assert %{
             "period" => "week",
             "generatedAt" => generated_at,
             "summary" => %{
               "totalWorkedHours" => 8.5,
               "daysPresent" => 1,
               "averageWorkedHours" => 8.5
             },
             "days" => [
               %{
                 "date" => date,
                 "workedHours" => 8.5,
                 "suspicious" => true,
                 "suspiciousReason" => "Mocked location detected"
               }
             ]
           } = json_response(conn, 200)

    assert date == Date.to_iso8601(workday)
    assert {:ok, _datetime, 0} = DateTime.from_iso8601(generated_at)
  end

  test "returns reimbursement summary totals for the requested week period", %{
    employee: employee,
    token: token
  } do
    today = Date.utc_today()

    insert_request(employee.id, %{
      title: "Pending request",
      amount: Decimal.new("50000"),
      submitted_at: datetime_for(Date.add(today, -1), ~T[01:00:00]),
      status: "pending"
    })

    insert_request(employee.id, %{
      title: "Approved request",
      amount: Decimal.new("70000"),
      submitted_at: datetime_for(Date.add(today, -2), ~T[01:00:00]),
      status: "approved"
    })

    insert_request(employee.id, %{
      title: "Rejected request",
      amount: Decimal.new("20000"),
      submitted_at: datetime_for(Date.add(today, -3), ~T[01:00:00]),
      status: "rejected"
    })

    insert_request(employee.id, %{
      title: "Old request",
      amount: Decimal.new("99999"),
      submitted_at: datetime_for(Date.add(today, -12), ~T[01:00:00]),
      status: "canceled"
    })

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/reports/reimbursements/summary?period=week")

    assert %{
             "period" => "week",
             "generatedAt" => generated_at,
             "totals" => totals,
             "statuses" => statuses
           } = json_response(conn, 200)

    assert totals["submittedAmount"] == 140_000.0
    assert totals["pendingAmount"] == 50_000.0
    assert totals["approvedAmount"] == 70_000.0
    assert totals["rejectedAmount"] == 20_000.0
    assert totals["canceledAmount"] == 0.0

    assert statuses == [
             %{"status" => "pending", "requestCount" => 1, "totalAmount" => 50_000.0},
             %{"status" => "approved", "requestCount" => 1, "totalAmount" => 70_000.0},
             %{"status" => "rejected", "requestCount" => 1, "totalAmount" => 20_000.0},
             %{"status" => "canceled", "requestCount" => 0, "totalAmount" => 0.0}
           ]

    assert {:ok, _datetime, 0} = DateTime.from_iso8601(generated_at)
  end

  test "exports reimbursements as inline CSV metadata for the signed-in employee", %{
    employee: employee,
    token: token
  } do
    insert_request(employee.id, %{
      title: "Taxi, airport",
      amount: Decimal.new("150000"),
      submitted_at: ~U[2026-04-24 01:00:00Z],
      status: "approved",
      reviewed_at: ~U[2026-04-24 04:00:00Z],
      payment_reference: "PAY-2026-0001",
      notes: "Airport to client office"
    })

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/reports/reimbursements/export")

    assert %{
             "id" => id,
             "type" => "reimbursement",
             "scope" => "singleEmployee",
             "fileName" => file_name,
             "formatLabel" => "CSV",
             "generatedAt" => generated_at,
             "rowCount" => 1,
             "content" => content,
             "employee" => %{
               "id" => employee_id,
               "name" => "Report Employee",
               "division" => "Operations"
             }
           } = json_response(conn, 200)

    assert employee_id == employee.id
    assert {:ok, _uuid} = Ecto.UUID.cast(id)
    assert file_name =~ "reimbursement-report-employee-"
    assert file_name =~ ".csv"
    assert {:ok, _datetime, 0} = DateTime.from_iso8601(generated_at)

    assert content ==
             Enum.join(
               [
                 "submittedAt,title,amount,status,reviewedAt,rejectionReason,paymentReference,notes",
                 "2026-04-24T01:00:00Z,\"Taxi, airport\",150000,approved,2026-04-24T04:00:00Z,,PAY-2026-0001,Airport to client office"
               ],
               "\n"
             )
  end

  test "rejects invalid report period values", %{token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/reports/attendance/insights?period=year")

    assert %{"message" => "Invalid request", "errors" => errors} = json_response(conn, 422)
    assert "is invalid" in List.wrap(errors["period"])
  end

  defp attendance_record(employee_id, session_id, type, occurred_at, suspicious_reason) do
    %AttendanceRecord{}
    |> AttendanceRecord.changeset(%{
      employee_id: employee_id,
      session_id: session_id,
      type: type,
      occurred_at: occurred_at,
      timezone: "Asia/Makassar",
      location: %{
        "latitude" => -5.1477,
        "longitude" => 119.4327,
        "accuracyMeters" => 8.5
      },
      suspicious_reason: suspicious_reason
    })
  end

  defp insert_request(employee_id, attrs) do
    defaults = %{
      title: "Meal reimbursement",
      amount: Decimal.new("50000"),
      submitted_at: ~U[2026-04-25 01:00:00Z],
      status: "pending",
      notes: "",
      employee_id: employee_id
    }

    %ReimbursementRequest{}
    |> ReimbursementRequest.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end

  defp datetime_for(date, time) do
    {:ok, datetime} = DateTime.new(date, time, "Etc/UTC")
    datetime
  end

  defp hash_token(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end
end
