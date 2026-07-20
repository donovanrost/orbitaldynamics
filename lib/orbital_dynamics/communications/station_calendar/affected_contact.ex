defmodule OrbitalDynamics.Communications.StationCalendar.AffectedContact do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar.{
    Availability,
    ProviderCounterofferHandoffSummary,
    ProviderResult,
    StationMatching
  }

  def build(contact, entry, matches) do
    contact_id = required_contact_id!(contact)
    overlap = overlap_window(contact, entry)
    feedback_factor_issue = contact_feedback_factor_issue(contact)

    row_id =
      ["station_calendar", contact_id, entry["id"]]
      |> Enum.map(&encode_value/1)
      |> Enum.join(":")

    %{
      "id" => row_id,
      "contact_id" => contact_id,
      "scenario_id" => Map.get(contact, "scenario_id"),
      "ground_station_id" => contact["ground_station_id"],
      "starts_at_s" => contact["starts_at_s"] || contact["start_s"],
      "ends_at_s" => contact["ends_at_s"] || contact["end_s"],
      "station_calendar_entry_id" => entry["id"],
      "station_calendar_provider_id" => station_calendar_provider_id(entry),
      "station_calendar_provider_entry_id" => station_calendar_provider_entry_id(entry),
      "station_calendar_directions" => entry["directions"],
      "contact_type" => contact["type"] || contact["activity_type"] || "planned_contact",
      "direction" => StationMatching.contact_direction(contact),
      "contact_success" => contact["contact_success"],
      "contact_result" => ProviderResult.artifact_value(contact["contact_result"]),
      "contact_success_factor" => unit_interval_factor(contact, "contact_success_factor"),
      "contact_success_factor_source" =>
        unit_interval_factor_source(
          contact,
          "contact_success_factor",
          "contact_success_factor_source"
        ),
      "command_success" => contact["command_success"],
      "command_result" => ProviderResult.artifact_value(contact["command_result"]),
      "command_success_factor" => unit_interval_factor(contact, "command_success_factor"),
      "command_success_factor_source" =>
        unit_interval_factor_source(
          contact,
          "command_success_factor",
          "command_success_factor_source"
        ),
      "invalid_feedback_confidence" => if(feedback_factor_issue, do: true),
      "invalid_feedback_confidence_reason" => feedback_factor_issue,
      "source_contact_candidate" => if(feedback_factor_issue, do: contact),
      "status" => entry["status"],
      "station_calendar_status" => entry["status"],
      "station_availability" => entry["availability"],
      "station_calendar_precedence_rank" => StationMatching.priority(entry),
      "station_calendar_precedence_availability" => entry["availability"],
      "overlap_starts_at_s" => overlap["starts_at_s"],
      "overlap_ends_at_s" => overlap["ends_at_s"],
      "overlap_duration_s" => overlap["duration_s"],
      "capacity_fraction" => entry["capacity_fraction"],
      "station_calendar_overlap_count" => length(matches),
      "station_calendar_overlap_entry_ids" => Enum.map(matches, & &1["id"]),
      "station_calendar_overlap_availabilities" =>
        matches |> Enum.map(& &1["availability"]) |> Enum.uniq(),
      "station_calendar_entry_ambiguous" => contact["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        contact["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => contact["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        contact["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => contact["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => contact["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => contact["station_calendar_reservation_statuses"],
      "station_calendar_reservation_expires_at_s" =>
        contact["station_calendar_reservation_expires_at_s"],
      "station_calendar_trust_boundary_status" => trust_boundary_status(entry),
      "provider_counteroffer_id" => contact["provider_counteroffer_id"],
      "provider_counteroffer_status" => contact["provider_counteroffer_status"],
      "provider_counteroffer_negotiation_state" =>
        contact["provider_counteroffer_negotiation_state"],
      "provider_counteroffer_reason_code" => contact["provider_counteroffer_reason_code"],
      "provider_counteroffer_cost_delta" => contact["provider_counteroffer_cost_delta"],
      "provider_counteroffer_lock_deadline_s" => contact["provider_counteroffer_lock_deadline_s"],
      "provider_counteroffer_starts_at_s" => contact["provider_counteroffer_starts_at_s"],
      "provider_counteroffer_ends_at_s" => contact["provider_counteroffer_ends_at_s"],
      "provider_counteroffer_start_delta_s" =>
        ProviderCounterofferHandoffSummary.numeric_delta(
          contact["provider_counteroffer_starts_at_s"],
          contact["starts_at_s"]
        ),
      "provider_counteroffer_end_delta_s" =>
        ProviderCounterofferHandoffSummary.numeric_delta(
          contact["provider_counteroffer_ends_at_s"],
          contact["ends_at_s"]
        ),
      "provider_counteroffer_duration_delta_s" =>
        ProviderCounterofferHandoffSummary.duration_delta(contact),
      "station_contention_status" => contact["station_contention_status"],
      "station_reservation_match_status" => contact["station_reservation_match_status"],
      "station_reservation_id" => contact["station_reservation_id"],
      "station_reservation_expires_at_s" => contact["station_reservation_expires_at_s"],
      "station_reserved_by" => contact["station_reserved_by"],
      "station_reservation_status" => contact["station_reservation_status"],
      "trust_boundary" =>
        Map.get(entry, "trust_boundary") || get_in(entry, ["provenance", "trust_boundary"]),
      "provenance" => entry["provenance"],
      "source_station_calendar_entry" => entry,
      "source_station_calendar_overlaps" => matches,
      "required_operator_action" => action(contact),
      "operator_action_reason" => reason(contact)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def disambiguate_ids(affected) do
    duplicates = duplicate_id_groups(affected)
    duplicate_ids = duplicates |> Enum.map(fn {id, _rows} -> id end) |> MapSet.new()
    duplicate_counts = Map.new(duplicates, fn {id, rows} -> {id, length(rows)} end)

    {rows, _indexes} =
      Enum.map_reduce(affected, %{}, fn row, indexes ->
        row_id = row["id"]
        index = Map.get(indexes, row_id, 0) + 1
        indexes = Map.put(indexes, row_id, index)

        row =
          if MapSet.member?(duplicate_ids, row_id) do
            row
            |> Map.put("id", "#{row_id}:#{index}")
            |> Map.put("base_station_calendar_row_id", row_id)
            |> Map.put("duplicate_station_calendar_row_id_collision", true)
            |> Map.put("duplicate_station_calendar_row_index", index)
            |> Map.put(
              "duplicate_station_calendar_row_count",
              Map.fetch!(duplicate_counts, row_id)
            )
          else
            row
          end

        {row, indexes}
      end)

    rows
  end

  def duplicate_id_groups(affected) do
    affected
    |> Enum.group_by(&Map.get(&1, "base_station_calendar_row_id", Map.get(&1, "id")))
    |> Enum.filter(fn {_row_id, rows} -> length(rows) > 1 end)
    |> Enum.sort_by(fn {row_id, _rows} -> row_id end)
  end

  def duplicate_row_count(duplicate_groups) do
    duplicate_groups
    |> Enum.map(fn {_row_id, rows} -> length(rows) end)
    |> Enum.sum()
  end

  defp action(%{"provider_counteroffer_id" => id}) when is_binary(id),
    do: "review_provider_counteroffer"

  defp action(%{"provider_counteroffer_status" => status}) when is_binary(status),
    do: "review_provider_counteroffer"

  defp action(%{"station_contention_status" => "reserved_overlap"}),
    do: "review_station_reservation_overlap"

  defp action(%{"station_calendar_reservation_overlap_count" => count})
       when is_number(count) and count > 0,
       do: "review_station_reservation_overlap"

  defp action(%{"station_availability" => "reserved"}),
    do: "review_station_reservation_overlap"

  defp action(%{"station_availability" => "reduced_capacity"}),
    do: "review_reduced_station_capacity"

  defp action(_row), do: "review_station_availability"

  defp reason(%{
         "provider_counteroffer_id" => counteroffer_id,
         "ground_station_id" => station
       })
       when is_binary(counteroffer_id) and is_binary(station) do
    "station #{station} provider counteroffer #{counteroffer_id} requires operator review"
  end

  defp reason(%{"provider_counteroffer_id" => counteroffer_id})
       when is_binary(counteroffer_id),
       do: "provider counteroffer #{counteroffer_id} requires operator review"

  defp reason(%{"station_availability" => availability, "ground_station_id" => station})
       when is_binary(availability) and is_binary(station) do
    "station #{station} calendar reports #{availability}"
  end

  defp reason(%{"station_availability" => availability}) when is_binary(availability),
    do: "station calendar reports #{availability}"

  defp reason(_row), do: "station calendar row requires operator review"

  defp overlap_window(contact, entry) do
    contact_start = contact["starts_at_s"] || contact["start_s"]
    contact_end = contact["ends_at_s"] || contact["end_s"]
    entry_start = entry["starts_at_s"]
    entry_end = entry["ends_at_s"]

    starts_at_s = max_present(contact_start, entry_start)
    ends_at_s = min_present(contact_end, entry_end)

    if is_number(starts_at_s) and is_number(ends_at_s) and ends_at_s > starts_at_s do
      %{
        "starts_at_s" => starts_at_s,
        "ends_at_s" => ends_at_s,
        "duration_s" => ends_at_s - starts_at_s
      }
    else
      %{}
    end
  end

  defp max_present(nil, value), do: value
  defp max_present(value, nil), do: value
  defp max_present(left, right) when is_number(left) and is_number(right), do: max(left, right)
  defp max_present(_left, _right), do: nil

  defp min_present(nil, value), do: value
  defp min_present(value, nil), do: value
  defp min_present(left, right) when is_number(left) and is_number(right), do: min(left, right)
  defp min_present(_left, _right), do: nil

  defp required_contact_id!(contact) do
    case Map.get(contact, "id") || Map.get(contact, "contact_id") ||
           Map.get(contact, "activity_id") do
      value when is_binary(value) and value != "" -> value
      value when is_atom(value) -> Atom.to_string(value)
      _value -> raise ArgumentError, "contact id is required"
    end
  end

  defp station_calendar_provider_id(entry) do
    entry["provider_id"] || get_in(entry, ["provenance", "provider_id"])
  end

  defp station_calendar_provider_entry_id(entry), do: entry["provider_entry_id"] || entry["id"]

  defp trust_boundary_status(entry) do
    case Map.get(entry, "trust_boundary") || get_in(entry, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" -> "declared"
      _value -> "missing"
    end
  end

  defp unit_interval_factor(row, field) do
    case Map.get(row, field) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 ->
        value

      value when is_binary(value) ->
        unit_interval_factor(%{field => Availability.numeric_or_nil(value)}, field)

      _value ->
        nil
    end
  end

  defp unit_interval_factor_source(row, factor_field, source_field) do
    if is_nil(feedback_factor_issue(row, factor_field)), do: Map.get(row, source_field)
  end

  defp contact_feedback_factor_issue(contact) do
    Enum.find_value(["contact_success_factor", "command_success_factor"], fn field ->
      feedback_factor_issue(contact, field)
    end)
  end

  defp feedback_factor_issue(row, field) do
    case Map.get(row, field) do
      nil ->
        nil

      value ->
        case Availability.numeric_or_nil(value) do
          number when is_number(number) ->
            if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

          _value ->
            "invalid_#{field}"
        end
    end
  end

  defp encode_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 6)

  defp encode_value(value), do: to_string(value)
end
