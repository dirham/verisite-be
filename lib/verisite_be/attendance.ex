defmodule VerisiteBe.Attendance do
  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.Multi
  alias VerisiteBe.Attendance.AttendanceRecord
  alias VerisiteBe.Attendance.LocationSample
  alias VerisiteBe.Employees.Employee
  alias VerisiteBe.Repo

  @platforms ~w(android ios)
  @app_states ~w(foreground background)
  @network_types ~w(wifi cellular offline)

  def clock_in(%Employee{} = employee, attrs) do
    with {:ok, submission} <- validate_event_submission(attrs) do
      create_record(employee, "clockIn", submission, Ecto.UUID.generate())
    end
  end

  def clock_out(%Employee{} = employee, attrs) do
    with {:ok, submission} <- validate_event_submission(attrs),
         {:ok, session_id} <- active_session_id(employee.id) do
      create_record(employee, "clockOut", submission, session_id)
    end
  end

  def submit_location_samples(%Employee{} = employee, attrs) do
    with {:ok, %{session_id: session_id, samples: samples}} <-
           validate_location_sample_batch(attrs),
         true <- session_active?(employee.id, session_id) do
      samples
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {sample, index}, multi ->
        Multi.insert(
          multi,
          {:sample, index},
          LocationSample.changeset(%LocationSample{}, %{
            employee_id: employee.id,
            session_id: session_id,
            captured_at: sample.captured_at,
            timezone: sample.timezone,
            location: sample.location,
            device_signal: sample.device_signal
          })
        )
      end)
      |> Repo.transaction()
      |> case do
        {:ok, _result} -> {:ok, :accepted}
        {:error, _op, changeset, _changes} -> {:error, changeset}
      end
    else
      false -> {:error, :no_active_session}
      {:error, _} = error -> error
    end
  end

  def history(%Employee{} = employee) do
    records =
      AttendanceRecord
      |> where([record], record.employee_id == ^employee.id)
      |> order_by([record], desc: record.occurred_at, desc: record.inserted_at)
      |> Repo.all()

    {:ok, records}
  end

  def to_record(%AttendanceRecord{} = record) do
    %{
      id: record.id,
      employeeId: record.employee_id,
      sessionId: record.session_id,
      type: record.type,
      occurredAt: DateTime.to_iso8601(record.occurred_at),
      suspiciousReason: record.suspicious_reason,
      location: record.location
    }
  end

  def to_history(records) do
    %{records: Enum.map(records, &to_record/1)}
  end

  defp create_record(%Employee{} = employee, type, submission, session_id) do
    %AttendanceRecord{}
    |> AttendanceRecord.changeset(%{
      employee_id: employee.id,
      session_id: session_id,
      type: type,
      occurred_at: submission.occurred_at,
      timezone: submission.timezone,
      location: submission.location,
      device_signal: submission.device_signal,
      suspicious_reason: suspicious_reason(submission)
    })
    |> Repo.insert()
  end

  defp validate_event_submission(attrs) when is_map(attrs) do
    changeset =
      {%{}, %{occurredAt: :string, timezone: :string, location: :map, deviceSignal: :map}}
      |> Changeset.cast(attrs, [:occurredAt, :timezone, :location, :deviceSignal])
      |> Changeset.validate_required([:occurredAt, :timezone, :location])
      |> validate_datetime(:occurredAt)
      |> Changeset.validate_format(:timezone, ~r/^[A-Za-z_]+\/[A-Za-z_]+(?:\/[A-Za-z_]+)?$/)
      |> validate_location(:location)
      |> validate_device_signal(:deviceSignal)

    if changeset.valid? do
      {:ok,
       %{
         occurred_at: parse_datetime(Changeset.get_field(changeset, :occurredAt)),
         timezone: Changeset.get_field(changeset, :timezone),
         location: normalize_location(Changeset.get_field(changeset, :location)),
         device_signal: normalize_device_signal(Changeset.get_field(changeset, :deviceSignal))
       }}
    else
      {:error, changeset}
    end
  end

  defp validate_event_submission(_attrs), do: {:error, invalid_payload_changeset()}

  defp validate_location_sample_batch(attrs) when is_map(attrs) do
    changeset =
      {%{}, %{sessionId: :string, samples: {:array, :map}}}
      |> Changeset.cast(attrs, [:sessionId, :samples])
      |> Changeset.validate_required([:sessionId, :samples])
      |> Changeset.validate_length(:samples, min: 1)
      |> validate_uuid(:sessionId)

    with true <- changeset.valid?,
         {:ok, samples} <- validate_samples(Changeset.get_field(changeset, :samples)) do
      {:ok,
       %{
         session_id: Changeset.get_field(changeset, :sessionId),
         samples: samples
       }}
    else
      false -> {:error, changeset}
      {:error, sample_changeset} -> {:error, sample_changeset}
    end
  end

  defp validate_location_sample_batch(_attrs), do: {:error, invalid_payload_changeset()}

  defp validate_samples(samples) do
    samples
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {sample, _index}, {:ok, acc} ->
      case validate_location_sample(sample) do
        {:ok, validated_sample} -> {:cont, {:ok, [validated_sample | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
    |> case do
      {:ok, validated_samples} -> {:ok, Enum.reverse(validated_samples)}
      error -> error
    end
  end

  defp validate_location_sample(attrs) when is_map(attrs) do
    changeset =
      {%{}, %{capturedAt: :string, timezone: :string, location: :map, deviceSignal: :map}}
      |> Changeset.cast(attrs, [:capturedAt, :timezone, :location, :deviceSignal])
      |> Changeset.validate_required([:capturedAt, :timezone, :location])
      |> validate_datetime(:capturedAt)
      |> Changeset.validate_format(:timezone, ~r/^[A-Za-z_]+\/[A-Za-z_]+(?:\/[A-Za-z_]+)?$/)
      |> validate_location(:location)
      |> validate_device_signal(:deviceSignal)

    if changeset.valid? do
      {:ok,
       %{
         captured_at: parse_datetime(Changeset.get_field(changeset, :capturedAt)),
         timezone: Changeset.get_field(changeset, :timezone),
         location: normalize_location(Changeset.get_field(changeset, :location)),
         device_signal: normalize_device_signal(Changeset.get_field(changeset, :deviceSignal))
       }}
    else
      {:error, changeset}
    end
  end

  defp validate_location_sample(_attrs), do: {:error, invalid_payload_changeset()}

  defp active_session_id(employee_id) do
    closed_sessions =
      from(record in AttendanceRecord,
        where:
          record.employee_id == ^employee_id and record.type == "clockOut" and
            not is_nil(record.session_id),
        select: record.session_id
      )

    AttendanceRecord
    |> where(
      [record],
      record.employee_id == ^employee_id and record.type == "clockIn" and
        not is_nil(record.session_id)
    )
    |> where([record], record.session_id not in subquery(closed_sessions))
    |> order_by([record], desc: record.occurred_at, desc: record.inserted_at)
    |> limit(1)
    |> select([record], record.session_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :no_active_session}
      session_id -> {:ok, session_id}
    end
  end

  defp session_active?(employee_id, session_id) do
    closed_sessions =
      from(record in AttendanceRecord,
        where:
          record.employee_id == ^employee_id and record.type == "clockOut" and
            not is_nil(record.session_id),
        select: record.session_id
      )

    AttendanceRecord
    |> where(
      [record],
      record.employee_id == ^employee_id and record.type == "clockIn" and
        record.session_id == ^session_id
    )
    |> where([record], record.session_id not in subquery(closed_sessions))
    |> Repo.exists?()
  end

  defp suspicious_reason(%{location: %{"isMocked" => true}}), do: "Mocked location detected"
  defp suspicious_reason(_submission), do: nil

  defp validate_datetime(changeset, field) do
    Changeset.validate_change(changeset, field, fn ^field, value ->
      case DateTime.from_iso8601(value) do
        {:ok, _datetime, _offset} -> []
        _ -> [{field, "must be a valid ISO8601 datetime"}]
      end
    end)
  end

  defp validate_uuid(changeset, field) do
    Changeset.validate_change(changeset, field, fn ^field, value ->
      case Ecto.UUID.cast(value) do
        {:ok, _uuid} -> []
        :error -> [{field, "must be a valid UUID"}]
      end
    end)
  end

  defp validate_location(changeset, field) do
    Changeset.validate_change(changeset, field, fn ^field, value ->
      validate_location_map(value)
    end)
  end

  defp validate_device_signal(changeset, field) do
    Changeset.validate_change(changeset, field, fn ^field, value ->
      validate_device_signal_map(value)
    end)
  end

  defp validate_location_map(value) when is_map(value) do
    errors = []
    errors = require_number(errors, value, "latitude", min: -90, max: 90)
    errors = require_number(errors, value, "longitude", min: -180, max: 180)
    errors = optional_number(errors, value, "accuracyMeters", min: 0)
    errors = optional_number(errors, value, "altitudeMeters")
    errors = optional_number(errors, value, "speedMetersPerSecond", min: 0)
    errors = optional_number(errors, value, "headingDegrees", min: 0, max: 360)
    errors = optional_boolean(errors, value, "isMocked")

    Enum.map(errors, fn error -> {:location, error} end)
  end

  defp validate_location_map(_value), do: [location: "must be an object"]

  defp validate_device_signal_map(nil), do: []

  defp validate_device_signal_map(value) when is_map(value) do
    []
    |> optional_enum(value, "platform", @platforms)
    |> optional_enum(value, "appState", @app_states)
    |> optional_integer(value, "batteryLevel", min: 0, max: 100)
    |> optional_enum(value, "networkType", @network_types)
    |> Enum.map(fn error -> {:deviceSignal, error} end)
  end

  defp validate_device_signal_map(_value), do: [deviceSignal: "must be an object"]

  defp require_number(errors, map, key, opts) do
    case Map.fetch(map, key) do
      {:ok, value} -> validate_number(errors, key, value, opts)
      :error -> ["#{key} is required" | errors]
    end
  end

  defp optional_number(errors, map, key, opts \\ []) do
    case Map.fetch(map, key) do
      {:ok, value} -> validate_number(errors, key, value, opts)
      :error -> errors
    end
  end

  defp validate_number(errors, key, value, opts) when is_number(value) do
    min = Keyword.get(opts, :min)
    max = Keyword.get(opts, :max)

    cond do
      not is_nil(min) and value < min ->
        ["#{key} must be greater than or equal to #{min}" | errors]

      not is_nil(max) and value > max ->
        ["#{key} must be less than or equal to #{max}" | errors]

      true ->
        errors
    end
  end

  defp validate_number(errors, key, _value, _opts), do: ["#{key} must be a number" | errors]

  defp optional_integer(errors, map, key, opts) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) ->
        validate_number(errors, key, value, opts)

      {:ok, _value} ->
        ["#{key} must be an integer" | errors]

      :error ->
        errors
    end
  end

  defp optional_boolean(errors, map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_boolean(value) -> errors
      {:ok, _value} -> ["#{key} must be a boolean" | errors]
      :error -> errors
    end
  end

  defp optional_enum(errors, map, key, values) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        if Enum.member?(values, value) do
          errors
        else
          ["#{key} must be one of #{Enum.join(values, ", ")}" | errors]
        end

      :error ->
        errors
    end
  end

  defp normalize_location(location) do
    [
      "latitude",
      "longitude",
      "accuracyMeters",
      "altitudeMeters",
      "speedMetersPerSecond",
      "headingDegrees",
      "isMocked"
    ]
    |> Enum.reduce(%{}, fn key, acc ->
      case Map.fetch(location, key) do
        {:ok, value} -> Map.put(acc, key, value)
        :error -> acc
      end
    end)
  end

  defp normalize_device_signal(nil), do: nil

  defp normalize_device_signal(device_signal) do
    ["platform", "appState", "batteryLevel", "networkType"]
    |> Enum.reduce(%{}, fn key, acc ->
      case Map.fetch(device_signal, key) do
        {:ok, value} -> Map.put(acc, key, value)
        :error -> acc
      end
    end)
  end

  defp parse_datetime(value) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(value)
    DateTime.truncate(datetime, :second)
  end

  defp invalid_payload_changeset do
    {%{}, %{}}
    |> Changeset.cast(%{}, [])
    |> Changeset.add_error(:payload, "must be a JSON object")
  end
end
