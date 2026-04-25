defmodule VerisiteBe.Employees do
  import Ecto.Query

  alias Ecto.Changeset
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Files
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
    with {:ok, file_id} <- validate_photo_file_id(attrs),
         {:ok, file} <- Files.get_owned_file(employee, file_id) do
      employee
      |> Employee.photo_changeset(%{
        profile_image_file_id: file.id,
        profile_image_path: file.path,
        profile_image_name: file.name
      })
      |> Repo.update()
    end
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
      profileImageFileId: employee.profile_image_file_id,
      profileImagePath: employee.profile_image_path,
      profileImageName: employee.profile_image_name,
      language: language(employee.language_code)
    }
  end

  defp language("id"), do: %{code: "id", label: "Bahasa Indonesia"}
  defp language(_), do: %{code: "en", label: "English"}

  defp validate_photo_file_id(attrs) when is_map(attrs) do
    case Map.get(attrs, "fileId") do
      nil ->
        {:error, missing_photo_file_changeset()}

      file_id ->
        {:ok, file_id}
    end
  end

  defp validate_photo_file_id(_attrs) do
    {:error, missing_photo_file_changeset()}
  end

  defp missing_photo_file_changeset do
    {%{}, %{fileId: :string}}
    |> Changeset.cast(%{}, [:fileId])
    |> Changeset.validate_required([:fileId])
  end
end
