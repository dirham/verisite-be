defmodule VerisiteBe.Storage.HttpClientMock do
  def put(url, headers, body, content_type) do
    send(self(), {:http_put, url, headers, body, content_type})
    {:ok, 200, [], ""}
  end
end

defmodule VerisiteBeWeb.FileControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Ecto.Adapters.SQL.Sandbox
  alias VerisiteBe.Auth.Session
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Files.StoredFile
  alias VerisiteBe.Repo
  alias VerisiteBe.Storage.StorageSetting

  @endpoint VerisiteBeWeb.Endpoint

  setup do
    :ok = Sandbox.checkout(Repo)
    previous_http_client = Application.get_env(:verisite_be, :storage_http_client)
    previous_credentials = Application.get_env(:verisite_be, :storage_aws_credentials)

    on_exit(fn ->
      restore_env(:storage_http_client, previous_http_client)
      restore_env(:storage_aws_credentials, previous_credentials)
    end)

    employee =
      insert_employee(%{
        email: "file-employee@verisite.local",
        name: "File Employee",
        display_name: "File Employee",
        division: "Operations",
        role: "employee",
        role_label: "Employee",
        about_title: "Operations",
        about_description: "Uploads operational files."
      })

    admin =
      insert_employee(%{
        email: "file-admin@verisite.local",
        name: "File Admin",
        display_name: "File Admin",
        division: "IT",
        role: "admin",
        role_label: "Admin",
        about_title: "Admin",
        about_description: "Configures storage."
      })

    employee_token = "file-employee-token"
    admin_token = "file-admin-token"

    insert_session(employee.id, employee_token)
    insert_session(admin.id, admin_token)

    %{employee: employee, admin: admin, employee_token: employee_token, admin_token: admin_token}
  end

  test "uploads a file to the active local storage backend", %{
    employee: employee,
    employee_token: token
  } do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/files/upload", valid_upload_payload())

    assert %{
             "fileId" => file_id,
             "name" => "receipt.jpg",
             "source" => "gallery",
             "contentType" => "image/jpeg",
             "provider" => "local",
             "usage" => "reimbursementAttachment",
             "path" => path
           } = json_response(conn, 201)

    assert path =~ "/uploads/reimbursementAttachment/"

    stored_file = Repo.get!(StoredFile, file_id)
    assert stored_file.employee_id == employee.id
    assert stored_file.provider == "local"
  end

  test "uploads a file to an s3-compatible backend when aws storage is active", %{
    employee: employee,
    employee_token: token
  } do
    Application.put_env(:verisite_be, :storage_http_client, VerisiteBe.Storage.HttpClientMock)
    Application.put_env(:verisite_be, :storage_aws_credentials, {"minioadmin", "minioadmin"})

    %StorageSetting{}
    |> StorageSetting.changeset(%{
      active_provider: "aws",
      aws_bucket: "verisite-files",
      aws_region: "ap-southeast-1",
      aws_base_url: "http://minio:9000",
      aws_prefix: "dev"
    })
    |> Repo.insert!()

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/files/upload", valid_upload_payload())

    assert %{
             "fileId" => file_id,
             "provider" => "aws",
             "path" => path
           } = json_response(conn, 201)

    assert path =~ "http://minio:9000/verisite-files/dev/reimbursementAttachment/"

    assert_received {:http_put, put_url, headers, body, "image/jpeg"}
    assert put_url == path
    assert body == "fake-jpeg-content"
    assert header_value(headers, "authorization") =~ "AWS4-HMAC-SHA256"
    assert header_value(headers, "x-amz-content-sha256")

    stored_file = Repo.get!(StoredFile, file_id)
    assert stored_file.employee_id == employee.id
    assert stored_file.provider == "aws"
    assert stored_file.path == path
  end

  test "returns the persisted storage settings for admins", %{admin_token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/admin/settings/storage")

    assert %{
             "activeProvider" => "local",
             "local" => %{"basePath" => "priv/uploads"}
           } = json_response(conn, 200)
  end

  test "updates storage settings for admins", %{admin_token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> put("/api/admin/settings/storage", %{
        "activeProvider" => "aws",
        "aws" => %{
          "bucket" => "verisite-files",
          "region" => "ap-southeast-1",
          "baseUrl" => "https://verisite-files.s3.amazonaws.com",
          "prefix" => "prod"
        }
      })

    assert %{
             "activeProvider" => "aws",
             "aws" => %{
               "bucket" => "verisite-files",
               "region" => "ap-southeast-1",
               "baseUrl" => "https://verisite-files.s3.amazonaws.com",
               "prefix" => "prod"
             }
           } = json_response(conn, 200)

    assert %StorageSetting{active_provider: "aws", aws_bucket: "verisite-files"} =
             Repo.one(StorageSetting)
  end

  test "forbids storage settings access for non-admins", %{employee_token: token} do
    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get("/api/admin/settings/storage")

    assert json_response(conn, 403) == %{"message" => "Admin access required"}
  end

  defp valid_upload_payload do
    %{
      "name" => "receipt.jpg",
      "source" => "gallery",
      "contentType" => "image/jpeg",
      "usage" => "reimbursementAttachment",
      "contentBase64" => Base.encode64("fake-jpeg-content")
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

  defp hash_token(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end

  defp header_value(headers, name) do
    headers
    |> Enum.find_value(fn {header_name, value} ->
      if String.downcase(to_string(header_name)) == name do
        to_string(value)
      end
    end)
  end

  defp restore_env(key, nil), do: Application.delete_env(:verisite_be, key)
  defp restore_env(key, value), do: Application.put_env(:verisite_be, key, value)
end
