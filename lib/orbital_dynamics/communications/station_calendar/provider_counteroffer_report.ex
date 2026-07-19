defmodule OrbitalDynamics.Communications.StationCalendar.ProviderCounterofferReport do
  @moduledoc false

  @schema_contract "provider_counteroffer_report.v1"
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounteroffer

  def build(rows, source, source_artifact_id, source_artifact_type) do
    counteroffer_rows =
      rows
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&ProviderCounteroffer.entry?/1)
      |> Enum.with_index(1)
      |> Enum.map(&report_row/1)

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_provider_counteroffer_review",
      "source" => source,
      "source_artifact_type" => source_artifact_type,
      "source_artifact_id" => source_artifact_id,
      "counteroffer_count" => length(counteroffer_rows),
      "reviewable_count" => Enum.count(counteroffer_rows, & &1["reviewable"]),
      "counteroffer_cost_delta_count" =>
        numeric_value_count(counteroffer_rows, "provider_counteroffer_cost_delta"),
      "counteroffer_cost_delta_total" =>
        numeric_value_sum(counteroffer_rows, "provider_counteroffer_cost_delta"),
      "counteroffer_lock_deadline_count" =>
        numeric_value_count(counteroffer_rows, "provider_counteroffer_lock_deadline_s"),
      "earliest_counteroffer_lock_deadline_s" =>
        numeric_value_min(counteroffer_rows, "provider_counteroffer_lock_deadline_s"),
      "counteroffer_status_counts" => count_by(counteroffer_rows, "provider_counteroffer_status"),
      "counteroffer_negotiation_state_counts" =>
        count_by(counteroffer_rows, "provider_counteroffer_negotiation_state"),
      "required_operator_action_counts" =>
        count_by(counteroffer_rows, "required_operator_action"),
      "rows" => counteroffer_rows,
      "model_limits" => [
        "artifact_only",
        "does_not_accept_counteroffers",
        "does_not_reserve_station_time",
        "does_not_mutate_schedules"
      ],
      "assumptions" => %{
        "scope" =>
          "provider counteroffer reports preserve declared station-calendar counteroffer evidence only",
        "reviewability" =>
          "counteroffer rows are reviewable unless source evidence explicitly sets provider_counteroffer_reviewable false",
        "execution_boundary" => "artifact_only_no_provider_writes"
      }
    }
    |> compact_map()
  end

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&is_map/1)
    |> Enum.filter(&ProviderCounteroffer.entry?/1)
    |> Enum.with_index(1)
    |> Enum.map(&report_row/1)
  end

  defp report_row({row, sequence}) do
    counteroffer_id = report_id(row, sequence)
    status = ProviderCounteroffer.status(row) || "unknown"
    reviewable = reviewable?(row)
    action = if reviewable, do: "review_provider_counteroffer", else: "none"

    %{
      "id" => "provider_counteroffer:#{sequence}:#{counteroffer_id}",
      "provider_counteroffer_id" => counteroffer_id,
      "provider_counteroffer_status" => status,
      "provider_counteroffer_negotiation_state" => ProviderCounteroffer.negotiation_state(row),
      "provider_counteroffer_reason_code" => ProviderCounteroffer.reason_code(row),
      "provider_counteroffer_cost_delta" => ProviderCounteroffer.cost_delta(row),
      "provider_counteroffer_lock_deadline_s" => ProviderCounteroffer.lock_deadline_s(row),
      "provider_counteroffer_starts_at_s" => ProviderCounteroffer.starts_at_s(row),
      "provider_counteroffer_ends_at_s" => ProviderCounteroffer.ends_at_s(row),
      "provider_counteroffer_start_delta_s" =>
        numeric_delta(ProviderCounteroffer.starts_at_s(row), row["starts_at_s"]),
      "provider_counteroffer_end_delta_s" =>
        numeric_delta(ProviderCounteroffer.ends_at_s(row), row["ends_at_s"]),
      "provider_counteroffer_duration_delta_s" => duration_delta(row),
      "reviewable" => reviewable,
      "required_operator_action" => action,
      "ground_station_id" => row["ground_station_id"],
      "starts_at_s" => numeric_or_nil(row["starts_at_s"]),
      "ends_at_s" => numeric_or_nil(row["ends_at_s"]),
      "station_calendar_entry_id" => row["station_calendar_entry_id"] || row["id"],
      "station_calendar_provider_id" => row["station_calendar_provider_id"] || row["provider_id"],
      "station_calendar_provider_entry_id" =>
        row["station_calendar_provider_entry_id"] || row["provider_entry_id"],
      "station_availability" => row["station_availability"] || row["availability"],
      "source_station_calendar_entry" => source_entry(row)
    }
    |> compact_map()
  end

  defp report_id(row, sequence) do
    existing = ProviderCounteroffer.id(row)

    cond do
      value_present?(existing) ->
        existing

      stable_id?(row["station_calendar_provider_entry_id"]) ->
        "provider_counteroffer:#{row["station_calendar_provider_entry_id"]}"

      stable_id?(row["provider_entry_id"]) ->
        "provider_counteroffer:#{row["provider_entry_id"]}"

      stable_id?(row["id"]) ->
        "provider_counteroffer:#{row["id"]}"

      true ->
        "provider_counteroffer:#{sequence}"
    end
  end

  defp source_entry(%{"source_station_calendar_entry" => %{} = entry}), do: entry
  defp source_entry(row), do: row

  defp reviewable?(row) do
    case first_present_value(row, ["provider_counteroffer_reviewable", "reviewable"]) do
      false -> false
      value when is_binary(value) -> String.downcase(String.trim(value)) not in ["false", "0"]
      _value -> true
    end
  end

  defp duration_delta(row) do
    with start when is_number(start) <- numeric_or_nil(row["starts_at_s"]),
         finish when is_number(finish) <- numeric_or_nil(row["ends_at_s"]),
         counter_start when is_number(counter_start) <- ProviderCounteroffer.starts_at_s(row),
         counter_finish when is_number(counter_finish) <- ProviderCounteroffer.ends_at_s(row) do
      counter_finish - counter_start - (finish - start)
    else
      _value -> nil
    end
  end

  defp numeric_delta(left, right) do
    with left when is_number(left) <- numeric_or_nil(left),
         right when is_number(right) <- numeric_or_nil(right) do
      left - right
    else
      _value -> nil
    end
  end

  defp numeric_value_count(rows, field), do: rows |> numeric_values(field) |> length()
  defp numeric_value_sum(rows, field), do: rows |> numeric_values(field) |> Enum.sum()

  defp numeric_value_min(rows, field),
    do: rows |> numeric_values(field) |> Enum.min(fn -> nil end)

  defp numeric_values(rows, field) do
    rows
    |> Enum.map(&numeric_or_nil(&1[field]))
    |> Enum.filter(&is_number/1)
  end

  defp count_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field))
    |> Map.new(fn {value, matching_rows} -> {value, length(matching_rows)} end)
    |> Map.delete(nil)
  end

  defp first_present_value(map, keys) do
    keys
    |> Enum.map(&Map.get(map, &1))
    |> Enum.find(fn value -> value not in [nil, ""] end)
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)

  defp value_present?(value), do: value not in [nil, ""]

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
