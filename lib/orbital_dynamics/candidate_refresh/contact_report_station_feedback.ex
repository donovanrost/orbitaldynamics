defmodule OrbitalDynamics.CandidateRefresh.ContactReportStationFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    StationAvailability,
    ValueEncoding
  }

  def contact_filter_entries(source_contact_filter_reports) do
    source_contact_filter_reports
    |> Enum.flat_map(fn {path, report} ->
      report
      |> Map.get("suppressed_candidates", [])
      |> Enum.map(&contact_filter_row_ground_network_entry(path, &1))
      |> Enum.reject(&is_nil/1)
    end)
  end

  def contact_allocation_entries(source_contact_allocation_reports) do
    source_contact_allocation_reports
    |> Enum.flat_map(fn {path, report} ->
      trust_boundary = result_artifact_trust_boundary(report)

      report
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        row =
          Map.put_new(
            row,
            "_source_report_trust_boundary",
            trust_boundary
          )

        contact_allocation_row_ground_network_entry(path, row, index)
      end)
      |> Enum.reject(&is_nil/1)
    end)
  end

  defp contact_filter_row_ground_network_entry(path, %{} = row) do
    row = stringify_keys(row)
    reason = normalized_contact_token(row["suppressed_reason"])
    ground_station_id = stable_id_or_nil(row["ground_station_id"] || nested_station_id(row))

    with station_state when not is_nil(station_state) <-
           contact_filter_station_state_for_reason(reason),
         station_id when station_id not in [nil, ""] <- ground_station_id do
      %{
        "id" => contact_filter_station_entry_id(path, row),
        "ground_station_id" => station_id,
        "starts_at_s" => numeric_or_nil(row["starts_at_s"]),
        "ends_at_s" => numeric_or_nil(row["ends_at_s"]),
        "direction" => row["direction"] || contact_filter_row_direction(row),
        "availability" => station_state["availability"],
        "status" => station_state["status"],
        "capacity_fraction" => station_state["capacity_fraction"],
        "station_calendar_entry_id" => stable_id_or_nil(row["station_calendar_entry_id"]),
        "reservation_id" => stable_id_or_nil(row["station_reservation_id"]),
        "reserved_by" => row["station_reserved_by"],
        "reservation_status" => row["station_reservation_status"],
        "station_contention_status" => row["station_contention_status"],
        "source_contact_suppression" => row,
        "provenance" =>
          %{
            "source" => "contact_filter_report.suppressed_candidates",
            "source_path" => path,
            "trust_boundary" => contact_filter_row_trust_boundary(row)
          }
          |> compact_map()
      }
      |> compact_map()
    else
      _value -> nil
    end
  end

  defp contact_filter_row_ground_network_entry(_path, _row), do: nil

  defp contact_filter_station_state_for_reason("ground_station_unavailable"),
    do: %{"availability" => "unavailable", "status" => "unavailable"}

  defp contact_filter_station_state_for_reason("ground_station_reserved"),
    do: %{"availability" => "reserved", "status" => "reserved"}

  defp contact_filter_station_state_for_reason("ground_station_capacity_zero"),
    do: %{"availability" => "reduced_capacity", "capacity_fraction" => 0.0}

  defp contact_filter_station_state_for_reason(_reason), do: nil

  defp contact_filter_row_direction(row) do
    case row["type"] do
      type when type in ["downlink", "uplink", "command", "tracking", "health_check"] -> type
      _type -> nil
    end
  end

  defp contact_filter_row_trust_boundary(row) do
    row["trust_boundary"] ||
      row["station_calendar_trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
  end

  defp contact_filter_station_entry_id(path, row) do
    base =
      stable_id_or_nil(row["station_calendar_entry_id"]) ||
        stable_id_or_nil(row["station_reservation_id"]) ||
        stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["ground_station_id"]) ||
        "contact_filter_suppression"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["contact_filter", base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp contact_allocation_row_ground_network_entry(path, %{} = row, index) do
    row = stringify_keys(row)
    source_contact = contact_allocation_source_contact(row)
    station_state = contact_allocation_row_station_state(row, source_contact)
    ground_station_id = contact_allocation_station_id(row, source_contact)

    with station_id when station_id not in [nil, ""] <- ground_station_id,
         %{} = station_state <- station_state do
      %{
        "id" => contact_allocation_station_entry_id(path, row, index),
        "ground_station_id" => station_id,
        "starts_at_s" => numeric_or_nil(row["starts_at_s"] || source_contact["starts_at_s"]),
        "ends_at_s" => numeric_or_nil(row["ends_at_s"] || source_contact["ends_at_s"]),
        "direction" => contact_allocation_row_direction(row, source_contact),
        "availability" => station_state["availability"],
        "status" => station_state["status"],
        "capacity_fraction" => station_state["capacity_fraction"],
        "station_calendar_entry_id" =>
          stable_id_or_nil(row["station_calendar_entry_id"]) ||
            stable_id_or_nil(source_contact["station_calendar_entry_id"]),
        "reservation_id" =>
          stable_id_or_nil(row["station_reservation_id"] || row["reservation_id"]) ||
            stable_id_or_nil(
              source_contact["station_reservation_id"] || source_contact["reservation_id"]
            ),
        "reserved_by" =>
          row["station_reserved_by"] || row["reserved_by"] ||
            source_contact["station_reserved_by"] || source_contact["reserved_by"],
        "reservation_status" =>
          row["station_reservation_status"] || row["reservation_status"] ||
            source_contact["station_reservation_status"] || source_contact["reservation_status"],
        "station_contention_status" => row["station_contention_status"],
        "source_contact_allocation" => row,
        "provenance" =>
          %{
            "source" => "contact_allocation_report.rows",
            "source_path" => path,
            "trust_boundary" => contact_allocation_trust_boundary(row)
          }
          |> compact_map()
      }
      |> compact_map()
    else
      _value -> nil
    end
  end

  defp contact_allocation_source_contact(row) do
    contact_id = contact_allocation_contact_id(row, %{})

    cond do
      is_map(row["source_contact_candidate"]) ->
        stringify_keys(row["source_contact_candidate"])

      source_contact = contact_allocation_direct_source_contact(row, contact_id) ->
        source_contact

      is_list(get_in(row, ["source_contention_recommendation", "source_contact_candidates"])) ->
        row
        |> get_in(["source_contention_recommendation", "source_contact_candidates"])
        |> Enum.map(&stringify_keys/1)
        |> Enum.find(%{}, &contact_allocation_contact_match?(&1, contact_id))

      true ->
        %{}
    end
  end

  defp contact_allocation_direct_source_contact(row, contact_id) do
    [
      row["source_contact"],
      row["contact_candidate"],
      row["contact"],
      row["source_contacts"],
      row["contact_candidates"],
      row["contacts"]
    ]
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.find(&contact_allocation_contact_match?(&1, contact_id))
  end

  defp contact_allocation_contact_match?(contact, contact_id) do
    contact_id in [nil, ""] or contact_allocation_contact_id(contact, %{}) == contact_id
  end

  defp contact_allocation_contact_id(row, source_contact) do
    [
      row["contact_id"],
      row["activity_id"],
      row["source_activity_id"],
      row["downlink_activity_id"],
      row["id"],
      source_contact["contact_id"],
      source_contact["activity_id"],
      source_contact["source_activity_id"],
      source_contact["downlink_activity_id"],
      source_contact["id"]
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp contact_allocation_station_id(row, source_contact) do
    [
      row["ground_station_id"],
      row["station_id"],
      nested_station_id(row),
      source_contact["ground_station_id"],
      source_contact["station_id"],
      nested_station_id(source_contact)
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp contact_allocation_trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_contact_allocation", "trust_boundary"]) ||
      get_in(row, ["source_contact_allocation", "provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp contact_allocation_row_station_state(row, source_contact) do
    reason = normalized_contact_token(row["allocation_reason"] || row["suppressed_reason"])

    precedence_availability =
      row["station_calendar_precedence_availability"]
      |> ValueEncoding.encode_value_preserving_lists()
      |> StationAvailability.normalized_token()

    availability =
      StationAvailability.normalized_token(
        ValueEncoding.encode_value_preserving_lists(
          row["station_availability"] ||
            row["availability"] ||
            row["station_calendar_status"] ||
            row["status"] ||
            source_contact["station_availability"] ||
            source_contact["availability"]
        )
      )

    cond do
      reason == "ground_station_unavailable" or availability in ["unavailable", "maintenance"] or
          precedence_availability in ["unavailable", "maintenance"] ->
        %{"availability" => "unavailable", "status" => "unavailable"}

      reason == "ground_station_reserved" or availability == "reserved" or
        row["station_contention_status"] == "reserved_overlap" or
          precedence_availability == "reserved" ->
        %{"availability" => "reserved", "status" => "reserved"}

      reason == "ground_station_capacity_zero" ->
        %{"availability" => "reduced_capacity", "capacity_fraction" => 0.0}

      reason == "ground_station_reduced_capacity_insufficient" or
        availability == "reduced_capacity" or precedence_availability == "reduced_capacity" ->
        %{
          "availability" => "reduced_capacity",
          "capacity_fraction" => contact_allocation_row_capacity_fraction(row, source_contact)
        }
        |> compact_map()

      true ->
        nil
    end
  end

  defp contact_allocation_row_capacity_fraction(row, source_contact) do
    [
      row["capacity_fraction"],
      row["station_capacity_fraction"],
      row["capacity_pack_capacity_fraction"],
      get_in(row, ["source_station_calendar_entry", "capacity_fraction"]),
      source_contact["capacity_fraction"],
      source_contact["station_capacity_fraction"],
      source_contact["capacity_pack_capacity_fraction"],
      get_in(source_contact, ["source_station_calendar_entry", "capacity_fraction"])
    ]
    |> Enum.find_value(&station_capacity_fraction_or_nil/1)
  end

  defp station_capacity_fraction_or_nil(value) when value in [nil, ""], do: nil

  defp station_capacity_fraction_or_nil(value) do
    case ValueEncoding.numeric_value(value) do
      number when is_number(number) -> number |> max(0.0) |> min(1.0)
      _value -> nil
    end
  end

  defp contact_allocation_row_direction(row, source_contact) do
    direction =
      row["direction"] ||
        get_in(row, ["activity_context", "direction"]) ||
        source_contact["direction"] ||
        get_in(source_contact, ["activity_context", "direction"]) ||
        row["type"] ||
        source_contact["type"]

    normalized_contact_token(direction)
  end

  defp contact_allocation_station_entry_id(path, row, index) do
    base =
      stable_id_or_nil(row["station_calendar_entry_id"]) ||
        stable_id_or_nil(row["station_reservation_id"]) ||
        stable_id_or_nil(row["contact_id"]) ||
        stable_id_or_nil(row["id"]) ||
        stable_id_or_nil(row["ground_station_id"]) ||
        "contact_allocation_row"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, index, row}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["contact_allocation", base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
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

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys_preserving_lists(value)

  defp numeric_or_nil(value), do: ValueEncoding.numeric_value(value)

  defp normalized_contact_token(value) do
    value
    |> ValueEncoding.encode_value_preserving_lists()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end
end
