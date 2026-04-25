defmodule VerisiteBeWeb.ProfileControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Ecto.Adapters.SQL.Sandbox
  alias VerisiteBe.Auth.Session
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Files.StoredFile
  alias VerisiteBe.Repo

  @endpoint VerisiteBeWeb.Endpoint

  setup do
    :ok = Sandbox.checkout(Repo)

    employee =
      %Employee{}
      |> Employee.changeset(%{
        email: "profile@verisite.local",
        password_hash: "not-used",
        name: "Profile Employee",
        display_name: "Profile Employee",
        division: "Operations",
        role: "employee",
        role_label: "Employee",
        about_title: "Profile",
        about_description: "Maintains profile details.",
        language_code: "en"
      })
      |> Repo.insert!()

    token = "profile-token"

    %Session{}
    |> Session.changeset(%{
      employee_id: employee.id,
      token_hash: hash_token(token),
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
    })
    |> Repo.insert!()

    %{employee: employee, token: token}
  end

  test "updates the profile photo from an uploaded file id", %{employee: employee, token: token} do
    file =
      %StoredFile{}
      |> StoredFile.changeset(%{
        employee_id: employee.id,
        name: "avatar.png",
        path: "/uploads/profilePhoto/avatar.png",
        source: "profile",
        content_type: "image/png",
        provider: "local",
        storage_key: "profilePhoto/avatar.png",
        usage: "profilePhoto"
      })
      |> Repo.insert!()

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/profile/photo", %{"fileId" => file.id})

    assert %{
             "employeeId" => employee_id,
             "profileImageFileId" => profile_image_file_id,
             "profileImagePath" => "/uploads/profilePhoto/avatar.png",
             "profileImageName" => "avatar.png"
           } = json_response(conn, 200)

    assert employee_id == employee.id
    assert profile_image_file_id == file.id
  end

  defp hash_token(token) do
    :sha256
    |> :crypto.hash(token)
    |> Base.encode16(case: :lower)
  end
end
