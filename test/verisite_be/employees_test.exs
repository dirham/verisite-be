defmodule VerisiteBe.EmployeesTest do
  use ExUnit.Case, async: true

  alias VerisiteBe.Employees
  alias VerisiteBe.Employees.Employee

  test "maps an employee to the profile contract shape" do
    profile =
      Employees.to_profile(%Employee{
        id: "emp-1",
        email: "employee@verisite.local",
        name: "Rani Saputra",
        division: "Operations",
        role_label: "Employee",
        about_title: "Field Operations",
        about_description: "Keeps daily site activity moving.",
        profile_image_file_id: "file-1",
        profile_image_path: "/profiles/rani.png",
        profile_image_name: "rani.png",
        language_code: "id"
      })

    assert profile == %{
             employeeId: "emp-1",
             name: "Rani Saputra",
             division: "Operations",
             email: "employee@verisite.local",
             roleLabel: "Employee",
             aboutTitle: "Field Operations",
             aboutDescription: "Keeps daily site activity moving.",
             profileImageFileId: "file-1",
             profileImagePath: "/profiles/rani.png",
             profileImageName: "rani.png",
             language: %{code: "id", label: "Bahasa Indonesia"}
           }
  end
end
