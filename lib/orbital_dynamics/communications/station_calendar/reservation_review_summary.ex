defmodule OrbitalDynamics.Communications.StationCalendar.ReservationReviewSummary do
  @moduledoc false

  @reservation_schema_contract "station_reservation_report.v1"
  @schema_contract "station_reservation_review_summary.v1"

  alias OrbitalDynamics.Communications.StationCalendar.Availability
  alias OrbitalDynamics.Communications.StationCalendar.ReservationSummaryValues

  def build(report, opts, model_limits) do
    report = stringify_keys(report)
    now_s = opts |> Keyword.get(:now_s) |> Availability.numeric_or_nil()

    affected_rows =
      report
      |> Map.get("affected_contacts", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&review_row(&1, "affected_contact", now_s))

    provider_rows =
      report
      |> Map.get("provider_calendar_contention_groups", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&review_row(&1, "provider_calendar_contention_group", now_s))

    rows = affected_rows ++ provider_rows

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_station_reservation_review_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @reservation_schema_contract),
      "source" => report["source"],
      "model_limits" => model_limits,
      "reservation_count" => length(rows),
      "affected_contact_reservation_count" => length(affected_rows),
      "provider_calendar_contention_group_count" => length(provider_rows),
      "reservation_review_status" => if(rows == [], do: "clear", else: "review_required"),
      "reservation_expiration_count" => ReservationSummaryValues.expiration_count(rows),
      "earliest_reservation_expires_at_s" => ReservationSummaryValues.earliest_expiration(rows),
      "reservation_expiration_status_counts" =>
        count_by(rows, "station_reservation_expiration_status"),
      "reservation_ids_by_expiration_status" =>
        ReservationSummaryValues.ids_by(rows, "station_reservation_expiration_status"),
      "expired_reservation_count" =>
        Enum.count(rows, &(&1["station_reservation_expiration_status"] == "expired")),
      "active_reservation_count" =>
        Enum.count(rows, &(&1["station_reservation_expiration_status"] == "active")),
      "missing_reservation_expiration_count" =>
        Enum.count(rows, &(&1["station_reservation_expiration_status"] == "missing")),
      "review_reservation_ids" => ReservationSummaryValues.row_ids(rows),
      "review_rows" => rows,
      "assumptions" =>
        %{
          "execution_boundary" => "artifact_only_no_provider_reservation",
          "source" => "station_reservation_report.v1",
          "operator_authority" => "not_granted_by_summary",
          "deadline_evaluation" =>
            if(is_number(now_s), do: "relative_to_now_s", else: "not_evaluated")
        }
        |> maybe_put("now_s", now_s)
    }
    |> compact_map()
  end

  defp review_row(row, row_type, now_s) do
    row = stringify_keys(row)
    expiration_values = ReservationSummaryValues.expiration_values(row)

    %{
      "reservation_review_row_type" => row_type,
      "contact_id" => row["contact_id"],
      "direction" => row["direction"],
      "directions" => row["directions"],
      "station_calendar_directions" => row["station_calendar_directions"],
      "ground_station_id" => row["ground_station_id"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_provider_id" => row["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
      "station_contention_status" => row["station_contention_status"],
      "provider_calendar_contention_status" => row["provider_calendar_contention_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "reservation_ids" => ReservationSummaryValues.ids_for_row(row),
      "reservation_statuses" => ReservationSummaryValues.statuses_for_row(row),
      "reserved_by" => ReservationSummaryValues.reserved_by_for_row(row),
      "reservation_expires_at_s" => expiration_values,
      "station_reservation_expiration_status" => expiration_status(expiration_values, now_s),
      "required_operator_action" => row["required_operator_action"]
    }
    |> compact_map()
  end

  defp expiration_status([], _now_s), do: "missing"

  defp expiration_status(expiration_values, now_s) when is_number(now_s) do
    if Enum.any?(expiration_values, &(&1 < now_s)), do: "expired", else: "active"
  end

  defp expiration_status(_expiration_values, _now_s), do: "declared"

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
