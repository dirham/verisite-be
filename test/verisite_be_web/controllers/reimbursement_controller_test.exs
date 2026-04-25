defmodule VerisiteBeWeb.ReimbursementControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Ecto.Adapters.SQL.Sandbox
  alias VerisiteBe.Auth.Session
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Reimbursements.ReimbursementAttachment
  alias VerisiteBe.Reimbursements.ReimbursementRequest
  alias VerisiteBe.Repo

  @endpoint VerisiteBeWeb.Endpoint

  setup do
    :ok = Sandbox.checkout(Repo)

    employee =
      insert_employee(%{
        email: "reimbursement@verisite.local",
        name: "Reimbursement Employee",
        display_name: "Reimbursement Employee",
        division: "Finance",
        role: "employee",
        role_label: "Employee",
        about_title: "Expense Claims",
        about_description: "Submits reimbursement requests."
      })

    admin =
      insert_employee(%{
        email: "admin-reviewer@verisite.local",
        name: "Admin Reviewer",
        display_name: "Admin Reviewer",
        division: "Finance",
        role: "admin",
        role_label: "Admin",
        about_title: "Finance Reviewer",
        about_description: "Reviews reimbursement requests."
      })

    other_employee =
      insert_employee(%{
        email: "other-employee@verisite.local",
        name: "Other Employee",
        display_name: "Other Employee",
        division: "Operations",
        role: "employee",
        role_label: "Employee",
        about_title: "Field Operations",
        about_description: "Owns unrelated reimbursements."
      })

    employee_token = "reimbursement-token"
    admin_token = "admin-token"

    insert_session(employee.id, employee_token)
    insert_session(admin.id, admin_token)

    %{
      employee: employee,
      admin: admin,
      other_employee: other_employee,
      employee_token: employee_token,
      admin_token: admin_token
    }
  end

  test "creates a reimbursement request with attachments for the authenticated employee", %{
    employee: employee,
    employee_token: token
  } do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/reimbursements", valid_submission_payload())

    assert %{
             "id" => request_id,
             "employeeId" => employee_id,
             "title" => "Taxi receipt",
             "amount" => 150_000.0,
             "status" => "pending",
             "notes" => "Airport to client office",
             "attachments" => [
               %{
                 "id" => attachment_id,
                 "name" => "receipt.jpg",
                 "path" => "/tmp/receipt.jpg",
                 "source" => "gallery"
               }
             ],
             "reviewedBy" => nil,
             "reviewedAt" => nil,
             "rejectionReason" => nil,
             "paymentReference" => nil
           } = json_response(conn, 201)

    assert employee_id == employee.id
    assert {:ok, _uuid} = Ecto.UUID.cast(request_id)
    assert {:ok, _uuid} = Ecto.UUID.cast(attachment_id)
    assert Repo.aggregate(ReimbursementRequest, :count, :id) == 1
    assert Repo.aggregate(ReimbursementAttachment, :count, :id) == 1
  end

  test "lists reimbursement requests newest first for the authenticated employee", %{
    employee: employee,
    other_employee: other_employee,
    employee_token: token
  } do
    older = insert_request(employee.id, %{title: "Older", submitted_at: ~U[2026-04-20 01:00:00Z]})
    newer = insert_request(employee.id, %{title: "Newer", submitted_at: ~U[2026-04-21 01:00:00Z]})

    _other =
      insert_request(other_employee.id, %{
        title: "Other",
        submitted_at: ~U[2026-04-22 01:00:00Z]
      })

    insert_attachment(older.id, "older.jpg")
    insert_attachment(newer.id, "newer.jpg")

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/reimbursements")

    assert %{"requests" => [first, second]} = json_response(conn, 200)
    assert first["title"] == "Newer"
    assert second["title"] == "Older"
    assert hd(first["attachments"])["name"] == "newer.jpg"
  end

  test "cancels a pending reimbursement owned by the employee", %{
    employee: employee,
    employee_token: token
  } do
    request = insert_request(employee.id, %{status: "pending"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/reimbursements/#{request.id}/cancel")

    assert %{"status" => "canceled"} = json_response(conn, 200)
  end

  test "rejects cancel when the reimbursement is no longer pending", %{
    employee: employee,
    employee_token: token
  } do
    request = insert_request(employee.id, %{status: "approved"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/reimbursements/#{request.id}/cancel")

    assert json_response(conn, 409) == %{"message" => "Reimbursement request cannot be canceled"}
  end

  test "approves a reimbursement as admin reviewer", %{
    employee: employee,
    admin: admin,
    admin_token: token
  } do
    request = insert_request(employee.id, %{status: "pending"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/admin/reimbursements/#{request.id}/approve", %{"reviewerId" => admin.id})

    assert %{
             "status" => "approved",
             "reviewedBy" => reviewed_by,
             "reviewedAt" => reviewed_at,
             "rejectionReason" => nil
           } = json_response(conn, 200)

    assert reviewed_by == admin.id
    assert is_binary(reviewed_at)
  end

  test "rejects a reimbursement as admin reviewer", %{
    employee: employee,
    admin: admin,
    admin_token: token
  } do
    request = insert_request(employee.id, %{status: "pending"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/admin/reimbursements/#{request.id}/reject", %{
        "reviewerId" => admin.id,
        "rejectionReason" => "Receipt is incomplete"
      })

    assert %{
             "status" => "rejected",
             "reviewedBy" => reviewed_by,
             "rejectionReason" => "Receipt is incomplete"
           } = json_response(conn, 200)

    assert reviewed_by == admin.id
  end

  test "attaches a payment reference to an approved reimbursement", %{
    employee: employee,
    admin_token: token
  } do
    request = insert_request(employee.id, %{status: "approved"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/admin/reimbursements/#{request.id}/payment", %{
        "paymentReference" => "PAY-2026-0001"
      })

    assert %{"status" => "approved", "paymentReference" => "PAY-2026-0001"} =
             json_response(conn, 200)
  end

  test "forbids non-admin review actions", %{employee: employee, employee_token: token} do
    request = insert_request(employee.id, %{status: "pending"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/admin/reimbursements/#{request.id}/approve", %{"reviewerId" => employee.id})

    assert json_response(conn, 403) == %{"message" => "Admin access required"}
  end

  test "returns not found when employee cancels someone else's reimbursement", %{
    other_employee: other_employee,
    employee_token: token
  } do
    request = insert_request(other_employee.id, %{status: "pending"})

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/reimbursements/#{request.id}/cancel")

    assert json_response(conn, 404) == %{"message" => "Reimbursement request not found"}
  end

  test "defaults notes to an empty string when omitted", %{employee_token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/reimbursements", Map.delete(valid_submission_payload(), "notes"))

    assert %{"notes" => ""} = json_response(conn, 201)
  end

  test "rejects invalid reimbursement payload", %{employee_token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/reimbursements", %{
        "title" => "Taxi receipt",
        "amount" => 150_000,
        "attachments" => [%{"name" => "receipt.jpg"}]
      })

    assert %{"message" => "Invalid request", "errors" => errors} = json_response(conn, 422)
    assert "can't be blank" in List.wrap(errors["id"])
    assert "can't be blank" in List.wrap(errors["path"])
    assert "can't be blank" in List.wrap(errors["source"])
  end

  test "rejects submission without a bearer token" do
    conn = post(build_conn(), "/api/reimbursements", valid_submission_payload())

    assert json_response(conn, 401) == %{"message" => "Unauthorized"}
  end

  defp valid_submission_payload do
    %{
      "title" => "Taxi receipt",
      "amount" => 150_000,
      "notes" => "Airport to client office",
      "attachments" => [
        %{
          "id" => Ecto.UUID.generate(),
          "name" => "receipt.jpg",
          "path" => "/tmp/receipt.jpg",
          "source" => "gallery"
        }
      ]
    }
  end

  defp insert_employee(attrs) do
    defaults = %{
      password_hash: "not-used",
      language_code: "en"
    }

    %Employee{}
    |> Employee.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end

  defp insert_session(employee_id, token) do
    %Session{}
    |> Session.changeset(%{
      employee_id: employee_id,
      token_hash: hash_token(token),
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
    })
    |> Repo.insert!()
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

  defp insert_attachment(request_id, name) do
    %ReimbursementAttachment{}
    |> ReimbursementAttachment.changeset(%{
      request_id: request_id,
      name: name,
      path: "/tmp/#{name}",
      source: "gallery"
    })
    |> Repo.insert!()
  end

  defp hash_token(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end
end
