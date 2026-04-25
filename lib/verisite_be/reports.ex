defmodule VerisiteBe.Reports do
  import Ecto.Query

  alias Ecto.Changeset
  alias VerisiteBe.Attendance.AttendanceRecord
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Reimbursements.ReimbursementRequest
  alias VerisiteBe.Repo

  @periods ~w(week month)
  @reimbursement_statuses ~w(pending approved rejected canceled)

  def attendance_insights(%Employee{} = employee, params) do
    with {:ok, period} <- validate_period(params) do
      range = period_range(period)

      records =
        AttendanceRecord
        |> where([record], record.employee_id == ^employee.id)
        |> where(
          [record],
          record.occurred_at >= ^range.start_at and record.occurred_at <= ^range.end_at
        )
        |> order_by([record], asc: record.occurred_at, asc: record.inserted_at)
        |> Repo.all()

      daily_rows = attendance_daily_rows(records)
      total_worked_hours = Enum.reduce(daily_rows, 0.0, &(&1.worked_hours + &2))
      days_present = length(daily_rows)

      {:ok,
       %{
         period: period,
         generatedAt: DateTime.to_iso8601(range.generated_at),
         summary: %{
           totalWorkedHours: round_hours(total_worked_hours),
           daysPresent: days_present,
           averageWorkedHours: average_hours(total_worked_hours, days_present)
         },
         days:
           Enum.map(daily_rows, fn row ->
             %{
               date: row.date,
               workedHours: round_hours(row.worked_hours),
               suspicious: row.suspicious,
               suspiciousReason: row.suspicious_reason
             }
           end)
       }}
    end
  end

  def reimbursement_summary(%Employee{} = employee, params) do
    with {:ok, period} <- validate_period(params) do
      range = period_range(period)

      requests =
        ReimbursementRequest
        |> where([request], request.employee_id == ^employee.id)
        |> where(
          [request],
          request.submitted_at >= ^range.start_at and request.submitted_at <= ^range.end_at
        )
        |> order_by([request], asc: request.submitted_at, asc: request.inserted_at)
        |> Repo.all()

      totals_by_status =
        Enum.reduce(@reimbursement_statuses, %{}, fn status, acc ->
          Map.put(acc, status, reimbursement_status_total(requests, status))
        end)

      submitted_amount =
        Enum.reduce(requests, Decimal.new("0"), fn request, acc ->
          Decimal.add(acc, request.amount)
        end)

      {:ok,
       %{
         period: period,
         generatedAt: DateTime.to_iso8601(range.generated_at),
         totals: %{
           submittedAmount: decimal_to_float(submitted_amount),
           pendingAmount: decimal_to_float(totals_by_status["pending"].amount),
           approvedAmount: decimal_to_float(totals_by_status["approved"].amount),
           rejectedAmount: decimal_to_float(totals_by_status["rejected"].amount),
           canceledAmount: decimal_to_float(totals_by_status["canceled"].amount)
         },
         statuses:
           Enum.map(@reimbursement_statuses, fn status ->
             total = totals_by_status[status]

             %{
               status: status,
               requestCount: total.count,
               totalAmount: decimal_to_float(total.amount)
             }
           end)
       }}
    end
  end

  def export_attendance(%Employee{} = employee) do
    records =
      AttendanceRecord
      |> where([record], record.employee_id == ^employee.id)
      |> order_by([record], asc: record.occurred_at, asc: record.inserted_at)
      |> Repo.all()

    generated_at = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok,
     %{
       id: Ecto.UUID.generate(),
       type: "attendance",
       scope: "singleEmployee",
       fileName: report_file_name("attendance", employee, generated_at),
       formatLabel: "CSV",
       generatedAt: DateTime.to_iso8601(generated_at),
       rowCount: length(records),
       content: attendance_csv(records),
       employee: report_employee(employee)
     }}
  end

  def export_reimbursements(%Employee{} = employee) do
    requests =
      ReimbursementRequest
      |> where([request], request.employee_id == ^employee.id)
      |> order_by([request], asc: request.submitted_at, asc: request.inserted_at)
      |> Repo.all()

    generated_at = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok,
     %{
       id: Ecto.UUID.generate(),
       type: "reimbursement",
       scope: "singleEmployee",
       fileName: report_file_name("reimbursement", employee, generated_at),
       formatLabel: "CSV",
       generatedAt: DateTime.to_iso8601(generated_at),
       rowCount: length(requests),
       content: reimbursement_csv(requests),
       employee: report_employee(employee)
     }}
  end

  defp validate_period(params) when is_map(params) do
    changeset =
      {%{}, %{period: :string}}
      |> Changeset.cast(params, [:period])
      |> Changeset.validate_required([:period])
      |> Changeset.validate_inclusion(:period, @periods)

    if changeset.valid? do
      {:ok, Changeset.get_field(changeset, :period)}
    else
      {:error, changeset}
    end
  end

  defp validate_period(_params), do: {:error, invalid_payload_changeset()}

  defp period_range("week"), do: build_period_range(6)
  defp period_range("month"), do: build_period_range(29)

  defp build_period_range(days_back) do
    generated_at = DateTime.utc_now() |> DateTime.truncate(:second)
    today = DateTime.to_date(generated_at)
    start_date = Date.add(today, -days_back)

    {:ok, start_at} = DateTime.new(start_date, ~T[00:00:00], "Etc/UTC")
    {:ok, end_at} = DateTime.new(today, ~T[23:59:59], "Etc/UTC")

    %{generated_at: generated_at, start_at: start_at, end_at: end_at}
  end

  defp attendance_daily_rows(records) do
    records
    |> Enum.group_by(&Date.to_iso8601(DateTime.to_date(&1.occurred_at)))
    |> Enum.map(fn {date, day_records} ->
      sessions =
        day_records
        |> Enum.filter(&(&1.type == "clockIn"))
        |> Enum.map(fn clock_in ->
          clock_out =
            Enum.find(day_records, fn record ->
              record.type == "clockOut" and record.session_id == clock_in.session_id
            end)

          worked_hours =
            case clock_out do
              nil ->
                0.0

              %AttendanceRecord{} ->
                max(DateTime.diff(clock_out.occurred_at, clock_in.occurred_at, :second), 0) / 3600
            end

          suspicious_reasons =
            day_records
            |> Enum.filter(
              &(&1.session_id == clock_in.session_id and not is_nil(&1.suspicious_reason))
            )
            |> Enum.map(& &1.suspicious_reason)

          %{worked_hours: worked_hours, suspicious_reasons: suspicious_reasons}
        end)

      suspicious_reasons =
        sessions
        |> Enum.flat_map(& &1.suspicious_reasons)
        |> Enum.uniq()

      %{
        date: date,
        worked_hours: Enum.reduce(sessions, 0.0, &(&1.worked_hours + &2)),
        suspicious: suspicious_reasons != [],
        suspicious_reason: join_reasons(suspicious_reasons)
      }
    end)
    |> Enum.sort_by(& &1.date)
  end

  defp reimbursement_status_total(requests, status) do
    Enum.reduce(requests, %{count: 0, amount: Decimal.new("0")}, fn request, acc ->
      if request.status == status do
        %{
          count: acc.count + 1,
          amount: Decimal.add(acc.amount, request.amount)
        }
      else
        acc
      end
    end)
  end

  defp report_employee(%Employee{} = employee) do
    %{
      id: employee.id,
      name: employee.name,
      division: employee.division
    }
  end

  defp report_file_name(type, employee, generated_at) do
    safe_name =
      employee.name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, "-")
      |> String.trim("-")

    "#{type}-#{safe_name}-#{Date.to_iso8601(DateTime.to_date(generated_at))}.csv"
  end

  defp attendance_csv(records) do
    header =
      "occurredAt,type,sessionId,timezone,latitude,longitude,accuracyMeters,suspiciousReason"

    rows =
      Enum.map(records, fn record ->
        [
          DateTime.to_iso8601(record.occurred_at),
          record.type,
          record.session_id,
          record.timezone,
          csv_location_value(record.location, "latitude"),
          csv_location_value(record.location, "longitude"),
          csv_location_value(record.location, "accuracyMeters"),
          record.suspicious_reason
        ]
        |> Enum.map_join(",", &csv_escape/1)
      end)

    Enum.join([header | rows], "\n")
  end

  defp reimbursement_csv(requests) do
    header =
      "submittedAt,title,amount,status,reviewedAt,rejectionReason,paymentReference,notes"

    rows =
      Enum.map(requests, fn request ->
        [
          DateTime.to_iso8601(request.submitted_at),
          request.title,
          Decimal.to_string(request.amount, :normal),
          request.status,
          maybe_datetime(request.reviewed_at),
          request.rejection_reason,
          request.payment_reference,
          request.notes
        ]
        |> Enum.map_join(",", &csv_escape/1)
      end)

    Enum.join([header | rows], "\n")
  end

  defp csv_location_value(location, key) when is_map(location), do: Map.get(location, key)
  defp csv_location_value(_location, _key), do: nil

  defp csv_escape(nil), do: ""

  defp csv_escape(value) when is_binary(value) do
    escaped = String.replace(value, "\"", "\"\"")

    if String.contains?(escaped, [",", "\"", "\n", "\r"]) do
      ~s("#{escaped}")
    else
      escaped
    end
  end

  defp csv_escape(value), do: value |> to_string() |> csv_escape()

  defp round_hours(hours), do: Float.round(hours, 2)

  defp average_hours(_total_worked_hours, 0), do: 0.0

  defp average_hours(total_worked_hours, days_present),
    do: round_hours(total_worked_hours / days_present)

  defp join_reasons([]), do: nil
  defp join_reasons(reasons), do: Enum.join(reasons, "; ")

  defp decimal_to_float(decimal), do: Decimal.to_float(decimal)

  defp maybe_datetime(nil), do: nil
  defp maybe_datetime(datetime), do: DateTime.to_iso8601(datetime)

  defp invalid_payload_changeset do
    {%{}, %{}}
    |> Changeset.cast(%{}, [])
    |> Changeset.add_error(:payload, "must be a JSON object")
  end
end
