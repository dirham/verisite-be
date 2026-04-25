defmodule VerisiteBe.Reimbursements do
  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Reimbursements.ReimbursementAttachment
  alias VerisiteBe.Reimbursements.ReimbursementRequest
  alias VerisiteBe.Repo

  def submit_request(%Employee{} = employee, attrs) do
    with {:ok, submission} <- validate_submission(attrs) do
      Multi.new()
      |> Multi.insert(
        :request,
        ReimbursementRequest.changeset(%ReimbursementRequest{}, %{
          employee_id: employee.id,
          title: submission.title,
          amount: submission.amount,
          notes: submission.notes,
          submitted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          status: "pending"
        })
      )
      |> insert_attachments(submission.attachments)
      |> Repo.transaction()
      |> case do
        {:ok, %{request: request}} ->
          request =
            Repo.preload(request,
              attachments: from(a in ReimbursementAttachment, order_by: a.inserted_at)
            )

          {:ok, request}

        {:error, _operation, changeset, _changes} ->
          {:error, changeset}
      end
    end
  end

  def list_requests(%Employee{} = employee) do
    requests =
      ReimbursementRequest
      |> where([request], request.employee_id == ^employee.id)
      |> order_by([request], desc: request.submitted_at, desc: request.inserted_at)
      |> preload(attachments: ^attachments_query())
      |> Repo.all()

    {:ok, requests}
  end

  def cancel_request(%Employee{} = employee, request_id) when is_binary(request_id) do
    with %ReimbursementRequest{} = request <- get_employee_request(employee.id, request_id),
         :ok <- ensure_status(request, ["pending"], :not_cancelable) do
      request
      |> ReimbursementRequest.changeset(%{status: "canceled"})
      |> Repo.update()
      |> with_preloaded_attachments()
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  def approve_request(%Employee{} = employee, request_id, attrs)
      when is_binary(request_id) and is_map(attrs) do
    with {:ok, reviewer_id} <- validate_reviewer(attrs, employee.id),
         %ReimbursementRequest{} = request <- Repo.get(ReimbursementRequest, request_id),
         :ok <- ensure_status(request, ["pending"], :not_approvable) do
      request
      |> ReimbursementRequest.changeset(%{
        reviewer_id: reviewer_id,
        reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second),
        status: "approved",
        rejection_reason: nil
      })
      |> Repo.update()
      |> with_preloaded_attachments()
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  def approve_request(%Employee{} = _employee, _request_id, _attrs),
    do: {:error, invalid_payload_changeset()}

  def reject_request(%Employee{} = employee, request_id, attrs)
      when is_binary(request_id) and is_map(attrs) do
    with {:ok, review} <- validate_rejection(attrs, employee.id),
         %ReimbursementRequest{} = request <- Repo.get(ReimbursementRequest, request_id),
         :ok <- ensure_status(request, ["pending"], :not_rejectable) do
      request
      |> ReimbursementRequest.changeset(%{
        reviewer_id: review.reviewer_id,
        reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second),
        status: "rejected",
        rejection_reason: review.rejection_reason
      })
      |> Repo.update()
      |> with_preloaded_attachments()
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  def reject_request(%Employee{} = _employee, _request_id, _attrs),
    do: {:error, invalid_payload_changeset()}

  def attach_payment_reference(request_id, attrs) when is_binary(request_id) and is_map(attrs) do
    with {:ok, payment_reference} <- validate_payment_reference(attrs),
         %ReimbursementRequest{} = request <- Repo.get(ReimbursementRequest, request_id),
         :ok <- ensure_status(request, ["approved"], :payment_not_attachable) do
      request
      |> ReimbursementRequest.changeset(%{payment_reference: payment_reference})
      |> Repo.update()
      |> with_preloaded_attachments()
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  def attach_payment_reference(_request_id, _attrs), do: {:error, invalid_payload_changeset()}

  def to_request(%ReimbursementRequest{} = request) do
    %{
      id: request.id,
      employeeId: request.employee_id,
      title: request.title,
      amount: Decimal.to_float(request.amount),
      submittedAt: DateTime.to_iso8601(request.submitted_at),
      status: request.status,
      attachments: Enum.map(request.attachments, &to_attachment/1),
      notes: request.notes,
      reviewedBy: request.reviewer_id,
      reviewedAt: maybe_datetime(request.reviewed_at),
      rejectionReason: request.rejection_reason,
      paymentReference: request.payment_reference
    }
  end

  def to_list(requests) do
    %{requests: Enum.map(requests, &to_request/1)}
  end

  defp insert_attachments(multi, attachments) do
    Enum.with_index(attachments)
    |> Enum.reduce(multi, fn {attachment, index}, acc ->
      Multi.insert(
        acc,
        {:attachment, index},
        fn %{request: request} ->
          ReimbursementAttachment.changeset(%ReimbursementAttachment{}, %{
            request_id: request.id,
            name: attachment.name,
            path: attachment.path,
            source: attachment.source
          })
        end
      )
    end)
  end

  defp validate_submission(attrs) when is_map(attrs) do
    changeset =
      {%{}, %{title: :string, amount: :float, notes: :string, attachments: {:array, :map}}}
      |> Changeset.cast(attrs, [:title, :amount, :notes, :attachments])
      |> Changeset.validate_required([:title, :amount, :attachments])
      |> Changeset.validate_number(:amount, greater_than: 0)
      |> Changeset.validate_length(:attachments, min: 1)

    with true <- changeset.valid?,
         {:ok, attachments} <- validate_attachments(Changeset.get_field(changeset, :attachments)) do
      {:ok,
       %{
         title: Changeset.get_field(changeset, :title),
         amount: Decimal.from_float(Changeset.get_field(changeset, :amount)),
         notes: Changeset.get_field(changeset, :notes) || "",
         attachments: attachments
       }}
    else
      false -> {:error, changeset}
      {:error, attachment_changeset} -> {:error, attachment_changeset}
    end
  end

  defp validate_submission(_attrs), do: {:error, invalid_payload_changeset()}

  defp validate_attachments(attachments) do
    attachments
    |> Enum.reduce_while({:ok, []}, fn attachment, {:ok, acc} ->
      case validate_attachment(attachment) do
        {:ok, validated_attachment} -> {:cont, {:ok, [validated_attachment | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> case do
      {:ok, validated_attachments} -> {:ok, Enum.reverse(validated_attachments)}
      error -> error
    end
  end

  defp validate_attachment(attrs) when is_map(attrs) do
    changeset =
      {%{}, %{id: :string, name: :string, path: :string, source: :string}}
      |> Changeset.cast(attrs, [:id, :name, :path, :source])
      |> Changeset.validate_required([:id, :name, :path, :source])
      |> Changeset.validate_inclusion(:source, ["gallery", "camera"])

    if changeset.valid? do
      {:ok,
       %{
         name: Changeset.get_field(changeset, :name),
         path: Changeset.get_field(changeset, :path),
         source: Changeset.get_field(changeset, :source)
       }}
    else
      {:error, changeset}
    end
  end

  defp validate_attachment(_attrs), do: {:error, invalid_payload_changeset()}

  defp validate_reviewer(attrs, current_employee_id) do
    changeset =
      {%{}, %{reviewerId: :string}}
      |> Changeset.cast(attrs, [:reviewerId])
      |> Changeset.validate_required([:reviewerId])
      |> validate_uuid(:reviewerId)
      |> Changeset.validate_change(:reviewerId, fn :reviewerId, reviewer_id ->
        if reviewer_id == current_employee_id do
          []
        else
          [reviewerId: "must match the authenticated reviewer"]
        end
      end)

    if changeset.valid? do
      {:ok, Changeset.get_field(changeset, :reviewerId)}
    else
      {:error, changeset}
    end
  end

  defp validate_rejection(attrs, current_employee_id) do
    changeset =
      {%{}, %{reviewerId: :string, rejectionReason: :string}}
      |> Changeset.cast(attrs, [:reviewerId, :rejectionReason])
      |> Changeset.validate_required([:reviewerId, :rejectionReason])
      |> validate_uuid(:reviewerId)
      |> Changeset.validate_change(:reviewerId, fn :reviewerId, reviewer_id ->
        if reviewer_id == current_employee_id do
          []
        else
          [reviewerId: "must match the authenticated reviewer"]
        end
      end)

    if changeset.valid? do
      {:ok,
       %{
         reviewer_id: Changeset.get_field(changeset, :reviewerId),
         rejection_reason: Changeset.get_field(changeset, :rejectionReason)
       }}
    else
      {:error, changeset}
    end
  end

  defp validate_payment_reference(attrs) do
    changeset =
      {%{}, %{paymentReference: :string}}
      |> Changeset.cast(attrs, [:paymentReference])
      |> Changeset.validate_required([:paymentReference])

    if changeset.valid? do
      {:ok, Changeset.get_field(changeset, :paymentReference)}
    else
      {:error, changeset}
    end
  end

  defp to_attachment(%ReimbursementAttachment{} = attachment) do
    %{
      id: attachment.id,
      name: attachment.name,
      path: attachment.path,
      source: attachment.source
    }
  end

  defp maybe_datetime(nil), do: nil
  defp maybe_datetime(datetime), do: DateTime.to_iso8601(datetime)

  defp get_employee_request(employee_id, request_id) do
    ReimbursementRequest
    |> where([request], request.id == ^request_id and request.employee_id == ^employee_id)
    |> preload(attachments: ^attachments_query())
    |> Repo.one()
  end

  defp with_preloaded_attachments({:ok, %ReimbursementRequest{} = request}) do
    {:ok, Repo.preload(request, attachments: attachments_query())}
  end

  defp with_preloaded_attachments({:error, _} = error), do: error

  defp ensure_status(%ReimbursementRequest{status: status}, allowed_statuses, error_reason) do
    if status in allowed_statuses do
      :ok
    else
      {:error, error_reason}
    end
  end

  defp attachments_query do
    from(attachment in ReimbursementAttachment, order_by: attachment.inserted_at)
  end

  defp validate_uuid(changeset, field) do
    Changeset.validate_change(changeset, field, fn ^field, value ->
      case Ecto.UUID.cast(value) do
        {:ok, _uuid} -> []
        :error -> [{field, "must be a valid UUID"}]
      end
    end)
  end

  defp invalid_payload_changeset do
    {%{}, %{payload: :map}}
    |> Changeset.cast(%{}, [:payload])
    |> Changeset.add_error(:payload, "must be an object")
  end
end
