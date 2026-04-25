defmodule VerisiteBe.Employees do
  import Ecto.Query

  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Repo

  def get_employee(id), do: Repo.get(Employee, id)

  def get_employee_by_email(email) when is_binary(email) do
    Repo.one(from(employee in Employee, where: employee.email == ^String.downcase(email)))
  end

  def update_profile(%Employee{} = employee, attrs) do
    employee
    |> Employee.profile_changeset(%{
      name: Map.get(attrs, "name"),
      division: Map.get(attrs, "division")
    })
    |> Repo.update()
  end

  def update_language(%Employee{} = employee, attrs) do
    employee
    |> Employee.language_changeset(%{language_code: Map.get(attrs, "languageCode")})
    |> Repo.update()
  end

  def update_photo(%Employee{} = employee, attrs) do
    employee
    |> Employee.photo_changeset(%{
      profile_image_path: Map.get(attrs, "photoPath"),
      profile_image_name: Map.get(attrs, "photoName")
    })
    |> Repo.update()
  end

  def to_profile(%Employee{} = employee) do
    %{
      employeeId: employee.id,
      name: employee.name,
      division: employee.division,
      email: employee.email,
      roleLabel: employee.role_label,
      aboutTitle: employee.about_title,
      aboutDescription: employee.about_description,
      profileImagePath: employee.profile_image_path,
      profileImageName: employee.profile_image_name,
      language: language(employee.language_code)
    }
  end

  defp language("id"), do: %{code: "id", label: "Bahasa Indonesia"}
  defp language(_), do: %{code: "en", label: "English"}
end
