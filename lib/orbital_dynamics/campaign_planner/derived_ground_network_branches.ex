defmodule OrbitalDynamics.CampaignPlanner.DerivedGroundNetworkBranches do
  @moduledoc false

  def build(mission_state, prior_plan, callbacks) do
    unavailable_station_tokens = Keyword.fetch!(callbacks, :unavailable_station_tokens)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    station_id = Keyword.fetch!(callbacks, :station_id)
    normalize_availability_token = Keyword.fetch!(callbacks, :normalize_availability_token)
    capacity_fraction = Keyword.fetch!(callbacks, :capacity_fraction)
    time = Keyword.fetch!(callbacks, :time)
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    horizon = Map.get(prior_plan, "planning_horizon", %{})
    ends_at_s = time.(horizon, "duration_s", 0.0)

    mission_state
    |> Map.get("ground_network", [])
    |> Enum.map(fn station -> stringify_keys.(station) end)
    |> Enum.flat_map(fn station ->
      station_id = station_id.(station)
      availability = normalize_availability_token.(Map.get(station, "availability"))

      status =
        normalize_availability_token.(Map.get(station, "status") || availability) ||
          "available"

      capacity_fraction = capacity_fraction.(station, nil)

      cond do
        station_id in [nil, ""] ->
          []

        status == "reserved" ->
          [
            %{
              "id" => "derived_station_reserved_#{station_id}",
              "label" => "Derived #{station_id} reservation",
              "events" => [
                station
                |> Map.merge(%{
                  "type" => "ground_station_reserved",
                  "ground_station_id" => station_id,
                  "starts_at_s" => time.(station, "starts_at_s", 0.0),
                  "ends_at_s" => time.(station, "ends_at_s", ends_at_s),
                  "reservation_id" =>
                    Map.get(station, "reservation_id") || Map.get(station, "id"),
                  "reserved_by" => Map.get(station, "reserved_by"),
                  "reservation_status" => Map.get(station, "reservation_status", "reserved")
                })
                |> ground_network_branch_event(
                  compact_map,
                  encode_value,
                  normalize_availability_token
                )
              ],
              "metadata" => %{"derived_source" => ground_network_derived_source(station)}
            }
          ]

        status in unavailable_station_tokens ->
          [
            %{
              "id" => "derived_station_outage_#{station_id}",
              "label" => "Derived #{station_id} outage",
              "events" => [
                station
                |> Map.merge(%{
                  "type" => "ground_station_outage",
                  "ground_station_id" => station_id,
                  "starts_at_s" => time.(station, "starts_at_s", 0.0),
                  "ends_at_s" => time.(station, "ends_at_s", ends_at_s)
                })
                |> ground_network_branch_event(
                  compact_map,
                  encode_value,
                  normalize_availability_token
                )
              ],
              "metadata" => %{"derived_source" => ground_network_derived_source(station)}
            }
          ]

        is_number(capacity_fraction) and capacity_fraction < 1.0 ->
          [
            %{
              "id" => "derived_station_capacity_#{station_id}",
              "label" => "Derived #{station_id} reduced capacity",
              "events" => [
                station
                |> Map.merge(%{
                  "type" => "reduced_downlink_capacity",
                  "ground_station_id" => station_id,
                  "capacity_fraction" => capacity_fraction,
                  "starts_at_s" => time.(station, "starts_at_s", 0.0),
                  "ends_at_s" => time.(station, "ends_at_s", ends_at_s)
                })
                |> ground_network_branch_event(
                  compact_map,
                  encode_value,
                  normalize_availability_token
                )
              ],
              "metadata" => %{"derived_source" => ground_network_derived_source(station)}
            }
          ]

        true ->
          []
      end
    end)
  end

  def disambiguate(branches, callbacks) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if ground_network_branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> ground_network_branch_identity(index, encode_value)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("ground_network_branch_base_id", branch_id)
          |> Map.put("ground_network_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_ground_network_suffixes()
  end

  defp ground_network_branch_id?(id) when is_binary(id) do
    Enum.any?(
      [
        "derived_station_reserved_",
        "derived_station_outage_",
        "derived_station_capacity_"
      ],
      &String.starts_with?(id, &1)
    )
  end

  defp ground_network_branch_id?(_id), do: false

  defp disambiguate_duplicate_ground_network_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "ground_network_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["ground_network_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["ground_network_branch_base_id"]}_#{suffix}")
        |> Map.update("metadata", %{}, &Map.put(&1, "ground_network_branch_identity", suffix))
      else
        branch
      end
    end)
  end

  defp ground_network_branch_identity(branch, index, encode_value) do
    metadata = Map.get(branch, "metadata", %{})

    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      [
        metadata["derived_source"],
        event["type"],
        event["ground_station_id"],
        event["starts_at_s"],
        event["ends_at_s"],
        event["capacity_fraction"],
        event["reservation_id"],
        event["reserved_by"],
        event["reservation_status"],
        event["station_calendar_entry_id"],
        event["trust_boundary"]
      ]
    end)
    |> List.flatten()
    |> Enum.map(fn value -> encode_value.(value) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end

  defp ground_network_derived_source(station) do
    case Map.get(station, "mission_state_source_path") ||
           get_in(station, ["provenance", "source"]) do
      "mission_state.station_calendar" -> "mission_state.station_calendar"
      "mission_state.station_calendar_provider" -> "mission_state.station_calendar_provider"
      "station_calendar_provider" -> "mission_state.station_calendar_provider"
      _source -> "mission_state.ground_network"
    end
  end

  defp ground_network_branch_event(
         station,
         compact_map,
         encode_value,
         normalize_availability_token
       ) do
    station_calendar_entry_id =
      Map.get(station, "station_calendar_entry_id") || Map.get(station, "id")

    station
    |> Map.take([
      "type",
      "ground_station_id",
      "starts_at_s",
      "ends_at_s",
      "capacity_fraction",
      "reservation_id",
      "reserved_by",
      "reservation_status"
    ])
    |> Map.put("station_calendar_entry_id", station_calendar_entry_id)
    |> put_if_present(
      "station_calendar_provider_id",
      Map.get(station, "station_calendar_provider_id") || Map.get(station, "provider_id") ||
        get_in(station, ["provenance", "provider_id"])
    )
    |> put_if_present(
      "station_calendar_provider_entry_id",
      Map.get(station, "station_calendar_provider_entry_id") ||
        Map.get(station, "provider_entry_id")
    )
    |> put_if_present(
      "station_calendar_directions",
      normalized_station_calendar_directions(
        Map.get(station, "station_calendar_directions") || Map.get(station, "directions"),
        encode_value
      )
    )
    |> put_if_present(
      "station_calendar_status",
      normalize_availability_token.(
        Map.get(station, "station_calendar_status") || Map.get(station, "status") ||
          Map.get(station, "availability")
      )
    )
    |> put_if_present(
      "station_calendar_trust_boundary_status",
      Map.get(station, "station_calendar_trust_boundary_status")
    )
    |> put_if_present(
      "station_reservation_match_status",
      Map.get(station, "station_reservation_match_status")
    )
    |> maybe_put_ground_network_event_trust_boundary(station)
    |> compact_map.()
  end

  defp maybe_put_ground_network_event_trust_boundary(event, station) do
    trust_boundary =
      Map.get(station, "trust_boundary") || get_in(station, ["provenance", "trust_boundary"])

    provenance = Map.get(station, "provenance")

    event
    |> put_if_present("trust_boundary", trust_boundary)
    |> put_if_present("provenance", provenance)
  end

  defp normalized_station_calendar_directions(nil, _encode_value), do: []

  defp normalized_station_calendar_directions(directions, encode_value) do
    directions
    |> List.wrap()
    |> Enum.map(fn direction -> encode_value.(direction) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp put_if_present(map, _key, value) when value in [nil, "", [], %{}], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
