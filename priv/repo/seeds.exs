alias VerisiteBe.Auth.Password
alias VerisiteBe.Employees.Employee
alias VerisiteBe.Repo

employees = [
  %{
    email: "employee@verisite.local",
    password_hash: Password.hash("password123"),
    name: "Rani Saputra",
    display_name: "Rani",
    division: "Operations",
    role: "employee",
    role_label: "Employee",
    about_title: "Field Operations",
    about_description: "Keeps daily site activity moving.",
    language_code: "en"
  },
  %{
    email: "admin@verisite.local",
    password_hash: Password.hash("password123"),
    name: "Bima Pratama",
    display_name: "Bima",
    division: "Finance",
    role: "admin",
    role_label: "Admin",
    about_title: "Finance Reviewer",
    about_description: "Reviews reimbursement requests.",
    language_code: "id"
  }
]

Enum.each(employees, fn attrs ->
  case Repo.get_by(Employee, email: attrs.email) do
    nil -> %Employee{} |> Employee.changeset(attrs) |> Repo.insert!()
    employee -> employee |> Employee.changeset(attrs) |> Repo.update!()
  end
end)
