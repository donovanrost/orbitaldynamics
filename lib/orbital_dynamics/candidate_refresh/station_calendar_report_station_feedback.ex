defmodule OrbitalDynamics.CandidateRefresh.StationCalendarReportStationFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    StationAvailability,
    StationCapacity,
    ValueEncoding
  }

  alias OrbitalDynamics.CandidateRefresh.StationCalendarReportStationFeedback.ProviderContention

  def entries(source_station_calendar_reports) do
    source_station_calendar_reports
    |> Enum.flat_map(fn {path, report} ->
      affected_contact_entries =
        report
        |> Map.get("affected_contacts", [])
        |> Enum.map(&row_ground_network_entry(path, &1, report))

      provider_contention_entries =
        report
        |> Map.get("provider_calendar_contention_groups", [])
        |> Enum.map(&ProviderContention.ground_network_entry(path, &1, report))

      affected_contact_entries ++ provider_contention_entries
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp row_ground_network_entry(path, %{} = row, %{} = report) do
    report = stringify_keys(report)
    row = report_row_with_context(row, report)
    ground_station_id = stable_id_or_nil(row["ground_station_id"] || nested_station_id(row))
    station_state = row_station_state(row)

    with station_id when station_id not in [nil, ""] <- ground_station_id,
         %{} = station_state <- station_state do
      %{
        "id" => row_station_entry_id(path, row),
        "ground_station_id" => station_id,
        "starts_at_s" => numeric_or_nil(row["starts_at_s"] || row["overlap_starts_at_s"]),
        "ends_at_s" => numeric_or_nil(row["ends_at_s"] || row["overlap_ends_at_s"]),
        "direction" => row["direction"],
        "availability" => station_state["availability"],
        "status" => station_state["status"],
        "capacity_fraction" => station_state["capacity_fraction"],
        "station_calendar_entry_id" => stable_id_or_nil(row["station_calendar_entry_id"]),
        "reservation_id" => stable_id_or_nil(row["station_reservation_id"]),
        "reserved_by" => row["station_reserved_by"],
        "reservation_status" => row["station_reservation_status"],
        "reservation_expires_at_s" => numeric_or_nil(row["station_reservation_expires_at_s"]),
        "station_calendar_reservation_expires_at_s" =>
          normalize_number_list(row["station_calendar_reservation_expires_at_s"]),
        "station_contention_status" => row["station_contention_status"],
        "source_station_calendar_review" => row,
        "source_station_calendar_entry" => row_source_entry(row),
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "provenance" =>
          %{
            "source" => "station_calendar_report.affected_contacts",
            "source_path" => path,
            "trust_boundary" => row_trust_boundary(row)
          }
          |> compact_map()
      }
      |> compact_map()
    else
      _value -> nil
    end
  end

  defp row_ground_network_entry(_path, _row, _report), do: nil

  defp report_row_with_context(%{} = row, %{} = report) do
    row = stringify_keys(row)

    row
    |> maybe_put("trust_boundary", row["trust_boundary"] || report["trust_boundary"])
    |> maybe_put("provenance", row["provenance"] || report["provenance"])
  end

  defp row_source_entry(%{} = row) do
    source_entry =
      case row["source_station_calendar_entry"] do
        %{} = entry -> stringify_keys(entry)
        _entry -> %{}
      end

    source_entry
    |> Map.put_new("id", stable_id_or_nil(row["station_calendar_entry_id"]))
    |> Map.put_new(
      "station_calendar_entry_id",
      stable_id_or_nil(row["station_calendar_entry_id"])
    )
    |> Map.put_new("provenance", row["provenance"])
    |> Map.put_new(
      "reservation_expires_at_s",
      numeric_or_nil(row["station_reservation_expires_at_s"])
    )
    |> maybe_put(
      "station_calendar_reservation_expires_at_s",
      normalize_number_list(row["station_calendar_reservation_expires_at_s"])
    )
    |> Map.put("source_station_calendar_review", row)
    |> compact_map()
  end

  defp row_station_state(%{} = row) do
    availability =
      [
        row["station_availability"],
        row["station_calendar_status"],
        row["availability"],
        row["status"]
      ]
      |> Enum.find_value(fn value ->
        normalized =
          value
          |> ValueEncoding.encode_value_preserving_lists()
          |> normalized_availability_token()

        if normalized in ["unavailable", "maintenance", "reserved"], do: normalized
      end)

    capacity_fraction = station_capacity_fraction(row)

    cond do
      availability in ["unavailable", "maintenance"] ->
        %{"availability" => "unavailable", "status" => "unavailable"}

      availability == "reserved" or row["station_contention_status"] == "reserved_overlap" ->
        %{"availability" => "reserved", "status" => "reserved"}

      is_number(capacity_fraction) and capacity_fraction <= 0.0 ->
        %{"availability" => "reduced_capacity", "capacity_fraction" => 0.0}

      true ->
        nil
    end
  end

  defp row_trust_boundary(row) do
    row["trust_boundary"] ||
      row["station_calendar_trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
  end

  defp row_station_entry_id(path, row) do
    base =
      stable_id_or_nil(row["station_calendar_entry_id"]) ||
        stable_id_or_nil(row["station_reservation_id"]) ||
        stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["ground_station_id"]) ||
        "station_calendar_report"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["station_calendar_report", base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

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

  defp station_capacity_fraction(station) do
    StationCapacity.fraction(station, &ValueEncoding.numeric_value/1)
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

  defp numeric_or_nil(value), do: ValueEncoding.numeric_value(value)
end
