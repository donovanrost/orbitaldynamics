defmodule OrbitalDynamics.CandidateRefresh.StationCalendarReportStationFeedback.ProviderContention do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    StationAvailability,
    StationCapacity,
    StationState,
    ValueEncoding
  }

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

  def ground_network_entry(path, %{} = group, %{} = report) do
    report = stringify_keys(report)
    group = group_with_context(group, report)
    ground_station_id = stable_id_or_nil(group["ground_station_id"] || nested_station_id(group))
    station_state = station_state(group)

    with station_id when station_id not in [nil, ""] <- ground_station_id,
         %{} = station_state <- station_state do
      %{
        "id" => entry_id(path, group),
        "ground_station_id" => station_id,
        "starts_at_s" => numeric_or_nil(group["starts_at_s"] || group["overlap_starts_at_s"]),
        "ends_at_s" => numeric_or_nil(group["ends_at_s"] || group["overlap_ends_at_s"]),
        "directions" => directions(group),
        "availability" => station_state["availability"],
        "status" => station_state["status"],
        "capacity_fraction" => station_state["capacity_fraction"],
        "station_calendar_entry_id" => stable_id_or_nil(group["id"]),
        "station_calendar_provider_id" => one_or_nil(group["provider_ids"]),
        "station_calendar_provider_entry_id" => one_or_nil(group["provider_entry_ids"]),
        "station_calendar_overlap_entry_ids" => group_ids(group["entry_ids"]),
        "station_calendar_overlap_availabilities" => group_values(group["availabilities"]),
        "station_calendar_reservation_ids" => group_ids(group["reservation_ids"]),
        "station_calendar_reserved_by" => group_values(group["reserved_by"]),
        "station_calendar_reservation_statuses" => group_values(group["reservation_statuses"]),
        "station_calendar_reservation_expires_at_s" =>
          group_numbers(group["reservation_expires_at_s"]),
        "station_calendar_trust_boundary_status" => trust_boundary_status(group),
        "station_contention_status" => "provider_calendar_overlap",
        "source_station_calendar_entry" => source_entry(group),
        "source_station_calendar_overlaps" => source_entries(group),
        "source_station_calendar_provider_contention" => group,
        "provenance" =>
          %{
            "source" => "station_calendar_report.provider_calendar_contention_groups",
            "source_path" => path,
            "trust_boundary" => trust_boundary(group)
          }
          |> compact_map()
      }
      |> compact_map()
    else
      _value -> nil
    end
  end

  def ground_network_entry(_path, _group, _report), do: nil

  defp group_with_context(%{} = group, %{} = report) do
    group = stringify_keys(group)

    group
    |> maybe_put("trust_boundary", group["trust_boundary"] || report["trust_boundary"])
    |> maybe_put("provenance", group["provenance"] || report["provenance"])
  end

  defp station_state(%{} = group) do
    availability_tokens =
      (group_values(group["availabilities"]) ++
         (group
          |> source_entries()
          |> Enum.flat_map(fn entry ->
            [entry["availability"], entry["station_availability"], entry["status"]]
          end)))
      |> Enum.map(&normalized_availability_token(encode_value(&1)))

    capacity_fraction = capacity_fraction(group)
    reservation_ids = group_ids(group["reservation_ids"])

    cond do
      Enum.any?(availability_tokens, &(&1 in ["unavailable", "maintenance"])) ->
        %{"availability" => "unavailable", "status" => "unavailable"}

      "reserved" in availability_tokens or reservation_ids != [] ->
        %{"availability" => "reserved", "status" => "reserved"}

      is_number(capacity_fraction) and capacity_fraction <= 0.0 ->
        %{"availability" => "reduced_capacity", "capacity_fraction" => 0.0}

      true ->
        nil
    end
  end

  defp capacity_fraction(group) do
    candidates =
      [group["capacity_fraction"], group["capacity_pack_capacity_fraction"]] ++
        (group["capacity_fractions"] |> List.wrap()) ++
        (group["capacity_pack_capacity_fractions"] |> List.wrap()) ++
        (group
         |> source_entries()
         |> Enum.map(&station_capacity_fraction/1))

    candidates
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      fractions -> Enum.min(fractions)
    end
  end

  defp directions(group) do
    [
      group["directions"],
      group["provider_calendar_contention_directions"],
      group["direction"],
      group["station_calendar_directions"],
      group
      |> source_entries()
      |> Enum.flat_map(&station_directions/1)
    ]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      directions -> directions
    end
  end

  defp source_entry(%{} = group) do
    %{
      "id" => stable_id_or_nil(group["id"]),
      "station_calendar_entry_id" => stable_id_or_nil(group["id"]),
      "provider_ids" => group_ids(group["provider_ids"]),
      "provider_entry_ids" => group_ids(group["provider_entry_ids"]),
      "directions" => directions(group),
      "station_calendar_reservation_expires_at_s" =>
        group_numbers(group["reservation_expires_at_s"]),
      "source_station_calendar_provider_contention" => group,
      "source_station_calendar_entries" => source_entries(group),
      "provenance" => group["provenance"]
    }
    |> compact_map()
  end

  defp source_entries(%{} = group) do
    [
      group["source_station_calendar_entries"],
      group["source_station_calendar_overlaps"]
    ]
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  defp source_entries(_group), do: []

  defp trust_boundary(group) do
    group["trust_boundary"] ||
      get_in(group, ["provenance", "trust_boundary"]) ||
      group
      |> source_entries()
      |> Enum.find_value(&row_trust_boundary/1)
  end

  defp trust_boundary_status(group) do
    group["station_calendar_trust_boundary_status"] ||
      group
      |> Map.get("trust_boundary_statuses")
      |> group_values()
      |> case do
        [status] -> status
        [] -> nil
        statuses -> Enum.join(statuses, ",")
      end
  end

  defp entry_id(path, group) do
    base =
      stable_id_or_nil(group["id"]) ||
        group["entry_ids"] |> group_ids() |> Enum.join(":") |> stable_id_or_nil() ||
        stable_id_or_nil(group["ground_station_id"]) ||
        "provider_calendar_contention"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, group}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["station_calendar_provider_contention", base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp group_ids(values) do
    values
    |> group_values()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
  end

  defp group_numbers(values) do
    values
    |> List.wrap()
    |> normalize_number_list()
  end

  defp group_values(values) do
    values
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp one_or_nil([value]), do: value
  defp one_or_nil(_values), do: nil

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp row_trust_boundary(row) do
    row["trust_boundary"] ||
      row["station_calendar_trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
  end

  defp station_directions(station) do
    StationState.directions(station, &encode_value/1, &normalize_direction/1)
  end

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      token when is_map_key(@provider_direction_aliases, token) ->
        Map.fetch!(@provider_direction_aliases, token)

      "nil" ->
        nil

      "" ->
        nil

      value ->
        value
    end
  end

  defp station_capacity_fraction(station) do
    StationCapacity.fraction(station, &numeric_value/1)
  end

  defp normalized_availability_token(value), do: StationAvailability.normalized_token(value)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys_preserving_lists(value)

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp numeric_or_nil(value), do: numeric_value(value)

  defp encode_value(value), do: ValueEncoding.encode_value_preserving_lists(value)
end
