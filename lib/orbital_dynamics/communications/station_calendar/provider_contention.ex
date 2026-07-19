defmodule OrbitalDynamics.Communications.StationCalendar.ProviderContention do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar.Availability

  @command_contact_directions ~w(command uplink)
  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "uplink",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "downlink" => "downlink",
    "down_link" => "downlink",
    "tracking" => "tracking",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "health_check" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check",
    "contact" => "contact"
  }

  def groups(entries) do
    entries
    |> provider_calendar_contention_pairs()
    |> Enum.with_index(1)
    |> Enum.map(fn {{left, right, overlap}, index} ->
      provider_calendar_contention_group(left, right, overlap, index)
    end)
  end

  defp provider_calendar_contention_pairs(entries) do
    entries
    |> Enum.with_index()
    |> Enum.flat_map(fn {left, left_index} ->
      entries
      |> Enum.drop(left_index + 1)
      |> Enum.flat_map(fn right ->
        if provider_calendar_entries_conflict?(left, right) do
          [{left, right, overlap_window(left, right)}]
        else
          []
        end
      end)
    end)
  end

  defp provider_calendar_entries_conflict?(left, right) do
    left["ground_station_id"] == right["ground_station_id"] and
      station_calendar_directions_overlap?(left, right) and
      window_overlaps?(
        left["starts_at_s"],
        left["ends_at_s"],
        right["starts_at_s"],
        right["ends_at_s"]
      )
  end

  defp station_calendar_directions_overlap?(left, right) do
    left_directions = station_calendar_direction_set(left)
    right_directions = station_calendar_direction_set(right)

    cond do
      MapSet.size(left_directions) == 0 ->
        true

      MapSet.size(right_directions) == 0 ->
        true

      not MapSet.disjoint?(left_directions, right_directions) ->
        true

      MapSet.subset?(left_directions, MapSet.new(@command_contact_directions)) and
          MapSet.subset?(right_directions, MapSet.new(@command_contact_directions)) ->
        true

      true ->
        false
    end
  end

  defp station_calendar_direction_set(entry) do
    entry
    |> Map.get("directions", [])
    |> List.wrap()
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  defp provider_calendar_contention_group(left, right, overlap, index) do
    entries = [left, right]
    entry_ids = Enum.map(entries, & &1["id"])
    provider_ids = entries |> Enum.map(&station_calendar_provider_id/1) |> compact_sorted_values()

    provider_entry_ids =
      entries |> Enum.map(&station_calendar_provider_entry_id/1) |> compact_sorted_values()

    %{
      "id" => "station_calendar_provider_contention:#{left["ground_station_id"]}:#{index}",
      "provider_calendar_contention_status" => "provider_calendar_overlap",
      "required_operator_action" => "review_station_provider_contention",
      "approval_status" => "operator_review_required",
      "operator_action_reason" => "overlapping_provider_calendar_entries",
      "ground_station_id" => left["ground_station_id"],
      "starts_at_s" => overlap["starts_at_s"],
      "ends_at_s" => overlap["ends_at_s"],
      "overlap_duration_s" => overlap["duration_s"],
      "entry_count" => length(entries),
      "entry_ids" => Enum.sort(entry_ids),
      "provider_ids" => provider_ids,
      "provider_entry_ids" => provider_entry_ids,
      "availabilities" => entries |> Enum.map(& &1["availability"]) |> compact_sorted_values(),
      "directions" =>
        entries
        |> Enum.flat_map(&(Map.get(&1, "directions", []) || []))
        |> compact_sorted_values(),
      "reservation_ids" => entries |> Enum.map(&reservation_id/1) |> compact_sorted_values(),
      "reserved_by" => entries |> Enum.map(& &1["reserved_by"]) |> compact_sorted_values(),
      "reservation_statuses" =>
        entries |> Enum.map(&reservation_status_or_reserved/1) |> compact_sorted_values(),
      "reservation_expires_at_s" =>
        entries |> Enum.map(& &1["reservation_expires_at_s"]) |> compact_sorted_numbers(),
      "trust_boundary_statuses" =>
        entries |> Enum.map(&station_calendar_trust_boundary_status/1) |> compact_sorted_values(),
      "overlap_pairs" => provider_calendar_contention_overlap_pairs(left, right, overlap),
      "source_station_calendar_entries" => entries
    }
    |> compact_map()
  end

  defp provider_calendar_contention_overlap_pairs(left, right, %{
         "starts_at_s" => starts_at_s,
         "ends_at_s" => ends_at_s,
         "duration_s" => duration_s
       })
       when is_number(starts_at_s) and is_number(ends_at_s) and is_number(duration_s) do
    [
      %{
        "left_entry_id" => left["id"],
        "right_entry_id" => right["id"],
        "overlap_starts_at_s" => starts_at_s,
        "overlap_ends_at_s" => ends_at_s,
        "overlap_duration_s" => duration_s
      }
    ]
  end

  defp provider_calendar_contention_overlap_pairs(_left, _right, _overlap), do: []

  defp compact_sorted_values(values) do
    values
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_sorted_numbers(values) do
    values
    |> List.wrap()
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp reservation_status_or_reserved(%{"availability" => "reserved"} = entry),
    do: entry["reservation_status"] || "reserved"

  defp reservation_status_or_reserved(entry), do: entry["reservation_status"]

  defp window_overlaps?(nil, nil, _starts_at_s, _ends_at_s), do: true

  defp window_overlaps?(nil, entry_end, contact_start, _contact_end),
    do: contact_start < entry_end

  defp window_overlaps?(entry_start, nil, _contact_start, contact_end),
    do: entry_start < contact_end

  defp window_overlaps?(entry_start, entry_end, contact_start, contact_end)
       when is_number(entry_start) and is_number(entry_end) and is_number(contact_start) and
              is_number(contact_end) do
    contact_start < entry_end and entry_start < contact_end
  end

  defp window_overlaps?(_entry_start, _entry_end, _contact_start, _contact_end), do: false

  defp station_calendar_provider_id(entry) do
    entry["provider_id"] || get_in(entry, ["provenance", "provider_id"])
  end

  defp station_calendar_provider_entry_id(entry) do
    entry["provider_entry_id"] || entry["id"]
  end

  defp reservation_id(entry), do: entry["reservation_id"] || entry["id"]

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> then(fn
      "" -> nil
      value -> Map.get(@provider_direction_aliases, value, value)
    end)
  end

  defp station_calendar_trust_boundary_status(entry) do
    case Map.get(entry, "trust_boundary") || get_in(entry, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" -> "declared"
      _value -> "missing"
    end
  end

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

  defp numeric_or_nil(value), do: Availability.numeric_or_nil(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 6)
  defp encode_value(value), do: to_string(value)
end
