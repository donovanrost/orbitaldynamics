defmodule OrbitalDynamics.Communications.ContactFilter.StationState do
  @moduledoc false

  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @capacity_value_paths [
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["capacity_percent"]},
    {:percent, ["station_capacity_percent"]}
  ]

  alias OrbitalDynamics.Communications.ContactFilter.ContactNormalization
  alias OrbitalDynamics.Communications.ContactFilter.ProviderCounterofferContext

  def resolve(ground_network, ground_station_id, starts_at_s, ends_at_s, direction) do
    ground_network
    |> Enum.filter(fn station ->
      station_id = ground_network_station_id(station)

      station_id == encode_value(ground_station_id) and
        station_direction_matches?(station, direction) and
        station_window_matches?(station, starts_at_s, ends_at_s)
    end)
    |> unambiguous_highest_severity_state()
  end

  defp ground_network_station_id(station) do
    Map.get(station, "ground_station_id") || Map.get(station, "station_id") ||
      Map.get(station, "id")
  end

  defp unambiguous_highest_severity_state([]), do: %{}

  defp unambiguous_highest_severity_state(stations) do
    highest_severity_stations =
      stations
      |> Enum.group_by(&severity/1)
      |> Enum.max_by(fn {severity, _stations} -> severity end)
      |> elem(1)

    case highest_severity_stations do
      [station] ->
        station
        |> put_station_overlap_context(stations)
        |> put_station_reservation_context(stations)
        |> put_station_trust_context(stations)

      ambiguous_stations ->
        ambiguous_stations
        |> ambiguous_state(stations)
        |> put_station_trust_context(stations)
    end
  end

  defp ambiguous_state([station | _rest] = ambiguous_stations, stations) do
    ambiguous_entry_ids = station_entry_ids(ambiguous_stations)
    overlap_entry_ids = station_entry_ids(stations)

    %{
      "id" => ambiguous_station_entry_id(ambiguous_entry_ids),
      "station_calendar_entry_id" => ambiguous_station_entry_id(ambiguous_entry_ids),
      "ground_station_id" => ground_network_station_id(station),
      "status" => "ambiguous",
      "availability" => availability(station),
      "station_calendar_entry_ambiguous" => true,
      "station_calendar_ambiguous_entry_count" => length(ambiguous_stations),
      "station_calendar_ambiguous_entry_ids" => ambiguous_entry_ids,
      "station_calendar_overlap_count" => length(stations),
      "station_calendar_overlap_entry_ids" => overlap_entry_ids,
      "station_calendar_overlap_availabilities" =>
        stations |> Enum.map(&availability/1) |> Enum.uniq()
    }
    |> maybe_put("capacity_fraction", unambiguous_capacity_fraction(ambiguous_stations))
    |> put_ambiguous_station_reservation_context(stations)
  end

  defp station_entry_ids(stations) do
    stations
    |> Enum.with_index(1)
    |> Enum.map(fn {station, index} -> station_entry_id(station, index) end)
    |> Enum.sort()
  end

  defp station_entry_id(station, index) do
    Map.get(station, "id") || Map.get(station, "station_calendar_entry_id") ||
      source_station_calendar_entry_id(station) || Map.get(station, "reservation_id") ||
      derived_station_entry_id(station, index)
  end

  defp derived_station_entry_id(station, index) do
    [
      "ground_network",
      ground_network_station_id(station) || "unknown_station",
      availability(station),
      Map.get(station, "starts_at_s", "open"),
      Map.get(station, "ends_at_s", "open"),
      index
    ]
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp ambiguous_station_entry_id(entry_ids) do
    entry_ids
    |> then(&["ambiguous_station_calendar" | &1])
    |> Enum.join(":")
  end

  defp put_station_overlap_context(station, [_single_station]), do: station

  defp put_station_overlap_context(station, stations) do
    station
    |> Map.put("station_calendar_overlap_count", length(stations))
    |> Map.put("station_calendar_overlap_entry_ids", station_entry_ids(stations))
    |> Map.put(
      "station_calendar_overlap_availabilities",
      stations
      |> Enum.map(&availability/1)
      |> Enum.uniq()
      |> Enum.sort_by(&station_availability_severity/1, :desc)
    )
  end

  defp unambiguous_capacity_fraction(stations) do
    stations
    |> Enum.map(&capacity_fraction/1)
    |> Enum.uniq()
    |> case do
      [capacity_fraction] -> capacity_fraction
      _ambiguous_capacity -> nil
    end
  end

  defp station_direction_matches?(station, direction) do
    case station_directions(station) do
      [] -> true
      directions -> normalize_direction(direction) in directions
    end
  end

  defp station_directions(station) do
    [
      Map.get(station, "directions"),
      Map.get(station, "station_calendar_directions"),
      Map.get(station, "direction"),
      get_in(station, ["source_station_calendar_entry", "directions"]),
      get_in(station, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(station, ["source_station_calendar_entry", "direction"])
    ]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def nonempty_directions(station) do
    case station_directions(station) do
      [] -> nil
      directions -> directions
    end
  end

  defp normalize_direction(direction), do: ContactNormalization.normalize_direction(direction)

  defp station_window_matches?(station, starts_at_s, ends_at_s) do
    window_overlaps?(
      Map.get(station, "starts_at_s"),
      Map.get(station, "ends_at_s"),
      starts_at_s,
      ends_at_s
    )
  end

  defp window_overlaps?(nil, nil, _contact_start, _contact_end), do: true

  defp window_overlaps?(entry_start, entry_end, contact_start, contact_end)
       when is_number(entry_start) and is_number(entry_end) and is_number(contact_start) and
              is_number(contact_end) do
    contact_end > entry_start and contact_start < entry_end
  end

  defp window_overlaps?(_entry_start, _entry_end, _contact_start, _contact_end), do: true

  def severity(station) do
    cond do
      unavailable?(station) -> 4
      reserved?(station) -> 3
      counteroffer_review?(station) -> 2
      station_reduced_capacity?(station) -> 2
      true -> 1
    end
  end

  def unavailable?(station) do
    availability(station) == "unavailable" or Map.get(station, "available") == false
  end

  def reserved?(station) do
    availability(station) == "reserved" or
      Map.get(station, "station_contention_status") == "reserved_overlap"
  end

  def counteroffer_review?(station) do
    station["required_operator_action"] == "review_provider_counteroffer" or
      present_station_evidence?(
        ProviderCounterofferContext.source_value(station, "provider_counteroffer_id")
      ) or
      present_station_evidence?(
        ProviderCounterofferContext.source_value(station, "provider_counteroffer_status")
      )
  end

  def reservation_matched?(
        %{"station_reservation_match_status" => match_status},
        _station_state
      )
      when match_status in ["matched", "owner_matched"],
      do: true

  def reservation_matched?(
        %{"station_reservation_match_status" => _match_status},
        _station_state
      ),
      do: false

  def reservation_matched?(
        %{"station_contention_status" => "reserved_overlap"},
        _station_state
      ),
      do: false

  def reservation_matched?(candidate, station_state) do
    not Map.get(station_state, "station_calendar_entry_ambiguous", false) and
      (station_reservation_identity_matched?(candidate, station_state) or
         station_reservation_owner_matched?(candidate, station_state))
  end

  defp station_reservation_identity_matched?(candidate, station_state) do
    candidate_reservation_id = contact_reservation_id(candidate)

    station_reservation_ids =
      [
        Map.get(station_state, "reservation_id"),
        Map.get(station_state, "station_reservation_id")
      ] ++ List.wrap(Map.get(station_state, "station_calendar_reservation_ids"))

    not is_nil(candidate_reservation_id) and candidate_reservation_id in station_reservation_ids
  end

  defp station_reservation_owner_matched?(candidate, station_state) do
    candidate_reserved_by = contact_reserved_by(candidate)

    station_reserved_bys =
      [
        Map.get(station_state, "reserved_by"),
        Map.get(station_state, "station_reserved_by")
      ] ++ List.wrap(Map.get(station_state, "station_calendar_reserved_by"))

    candidate_reserved_by not in [nil, ""] and
      to_string(candidate_reserved_by) in (station_reserved_bys
                                           |> Enum.reject(&(&1 in [nil, ""]))
                                           |> Enum.map(&to_string/1))
  end

  defp contact_reservation_id(contact) do
    Map.get(contact, "station_reservation_id") || Map.get(contact, "reservation_id")
  end

  defp contact_reserved_by(contact) do
    Map.get(contact, "station_reserved_by") || Map.get(contact, "reserved_by")
  end

  defp station_reduced_capacity?(station) do
    availability(station) == "reduced_capacity" or
      capacity_fraction(station) < 1.0
  end

  def capacity_fraction(station) do
    case capacity_value(station) || Map.get(station, "availability") do
      value when is_number(value) -> value |> max(0.0) |> min(1.0)
      value when is_binary(value) -> numeric_or_nil(value) |> capacity_fraction_or_full()
      _value -> 1.0
    end
  end

  def availability(station) do
    availability =
      station
      |> station_availability_candidates()
      |> Enum.filter(&station_availability_value?/1)
      |> highest_availability()

    cond do
      availability in ["unavailable", "maintenance" | @unavailable_aliases] -> "unavailable"
      availability == "reserved" -> "reserved"
      availability == "reduced_capacity" -> "reduced_capacity"
      capacity_fraction(station) < 1.0 -> "reduced_capacity"
      true -> "available"
    end
  end

  defp station_availability_candidates(station) do
    [
      station["station_availability"],
      station["availability"],
      station["station_calendar_status"],
      station["status"]
    ] ++
      source_station_calendar_availability_candidates(station["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(station["source_station_calendar_overlaps"])
  end

  defp highest_availability([]), do: nil

  defp highest_availability(values),
    do: Enum.max_by(values, &station_availability_severity/1)

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(value) when value in @unavailable_aliases, do: true
  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value) when value in @unavailable_aliases,
    do: @station_availability_severity["unavailable"]

  defp station_availability_severity(value), do: Map.get(@station_availability_severity, value, 0)

  defp source_station_calendar_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_availability_candidates/1)

  defp source_station_calendar_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_station_calendar_availability_candidates(_source), do: []

  defp put_station_reservation_context(station, stations) do
    reservations = Enum.filter(stations, &reserved?/1)

    case reservations do
      [] ->
        station

      [first | _rest] ->
        station
        |> Map.put_new("station_contention_status", "reserved_overlap")
        |> Map.put("reservation_id", Map.get(station, "reservation_id") || reservation_id(first))
        |> maybe_put("reserved_by", Map.get(station, "reserved_by") || first["reserved_by"])
        |> maybe_put(
          "reservation_status",
          Map.get(station, "reservation_status") || first["reservation_status"] || "reserved"
        )
        |> Map.put("station_calendar_reservation_overlap_count", length(reservations))
        |> maybe_put_list("station_calendar_reservation_ids", reservation_ids(reservations))
        |> maybe_put_list(
          "station_calendar_reserved_by",
          reservation_owners(reservations)
        )
        |> maybe_put_list(
          "station_calendar_reservation_statuses",
          reservation_statuses(reservations)
        )
        |> maybe_put("reservation_expires_at_s", reservation_expires_at_s(first))
        |> maybe_put_list(
          "station_calendar_reservation_expires_at_s",
          reservation_expires_at_s_values(reservations)
        )
    end
  end

  defp put_ambiguous_station_reservation_context(station, stations) do
    reservations = Enum.filter(stations, &reserved?/1)

    case reservations do
      [] ->
        station

      reservations ->
        station
        |> Map.put_new("station_contention_status", "reserved_overlap")
        |> Map.put("station_calendar_reservation_overlap_count", length(reservations))
        |> maybe_put_list("station_calendar_reservation_ids", reservation_ids(reservations))
        |> maybe_put_list(
          "station_calendar_reserved_by",
          reservation_owners(reservations)
        )
        |> maybe_put_list(
          "station_calendar_reservation_statuses",
          reservation_statuses(reservations)
        )
        |> maybe_put_list(
          "station_calendar_reservation_expires_at_s",
          reservation_expires_at_s_values(reservations)
        )
    end
  end

  defp put_station_trust_context(station, stations) do
    trust_status = station_calendar_trust_boundary_status(stations)
    trust_boundary = station_calendar_trust_boundary(station)
    provenance = station_calendar_provenance(station)
    normalized_station = normalize_station_evidence_numbers(station)
    normalized_stations = Enum.map(stations, &normalize_station_evidence_numbers/1)

    normalized_station
    |> Map.put("station_calendar_trust_boundary_status", trust_status)
    |> maybe_put("trust_boundary", trust_boundary)
    |> maybe_put("provenance", provenance)
    |> Map.put("source_station_calendar_entry", normalized_station)
    |> Map.put("source_station_calendar_overlaps", normalized_stations)
  end

  defp normalize_station_evidence_numbers(station) do
    station
    |> normalize_numeric_evidence_field("starts_at_s")
    |> normalize_numeric_evidence_field("ends_at_s")
    |> normalize_numeric_evidence_field("capacity_pack_capacity_fraction")
    |> normalize_numeric_evidence_field("capacity_fraction")
    |> normalize_numeric_evidence_field("station_capacity_fraction")
    |> normalize_capacity_percent_evidence()
  end

  defp normalize_capacity_percent_evidence(row) do
    case capacity_percent_fraction(row) do
      value when is_number(value) -> Map.put_new(row, "capacity_fraction", value)
      _value -> row
    end
  end

  defp normalize_numeric_evidence_field(row, field) do
    if Map.has_key?(row, field) do
      case numeric_or_nil(Map.get(row, field)) do
        value when is_number(value) -> Map.put(row, field, value)
        _value -> Map.delete(row, field)
      end
    else
      row
    end
  end

  defp station_calendar_trust_boundary_status(stations) do
    if Enum.all?(stations, &(station_calendar_trust_boundary(&1) not in [nil, ""])),
      do: "declared",
      else: "missing"
  end

  defp station_calendar_trust_boundary(station) do
    Map.get(station, "trust_boundary") || get_in(station, ["provenance", "trust_boundary"])
  end

  defp station_calendar_provenance(%{"provenance" => provenance}) when is_map(provenance),
    do: provenance

  defp station_calendar_provenance(_station), do: nil

  defp reservation_ids(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [reservation_id(reservation)] ++ List.wrap(reservation["station_calendar_reservation_ids"])
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp reservation_id(station), do: station["reservation_id"] || station["id"]

  defp reservation_owners(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [reservation["reserved_by"]] ++ List.wrap(reservation["station_calendar_reserved_by"])
    end)
  end

  defp reservation_statuses(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [reservation["reservation_status"]] ++
        List.wrap(reservation["station_calendar_reservation_statuses"])
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> ["reserved"]
      statuses -> statuses
    end
  end

  defp reservation_expires_at_s_values(reservations) do
    reservations
    |> Enum.flat_map(fn reservation ->
      [
        reservation_expires_at_s(reservation),
        reservation["station_calendar_reservation_expires_at_s"]
      ]
    end)
    |> normalize_number_list()
    |> case do
      nil -> []
      values -> values
    end
  end

  def reservation_expires_at_s(station) do
    [
      station["station_reservation_expires_at_s"],
      station["reservation_expires_at_s"],
      station["reservation_hold_expires_at_s"],
      station["hold_expires_at_s"],
      station["expires_at_s"],
      station["expires_at"],
      get_in(station, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "expires_at_s"])
    ]
    |> Enum.find_value(&numeric_or_nil/1)
  end

  def contention_status(station) do
    if reserved?(station), do: "reserved_overlap", else: nil
  end

  def reservation_match_status(candidate, station_state) do
    unambiguous_station_entry =
      not Map.get(station_state, "station_calendar_entry_ambiguous", false)

    cond do
      unambiguous_station_entry and
          station_reservation_identity_matched?(candidate, station_state) ->
        "matched"

      unambiguous_station_entry and station_reservation_owner_matched?(candidate, station_state) ->
        "owner_matched"

      reserved?(station_state) ->
        "overlap"

      true ->
        nil
    end
  end

  defp source_station_calendar_entry_id(row) do
    stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "station_calendar_entry_id"])) ||
      stable_id_or_nil(get_in(row, ["source_station_calendar_entry", "id"])) ||
      stable_id_or_nil(
        get_in(row, [
          "source_station_calendar_entry",
          "source_station_calendar_entry",
          "station_calendar_entry_id"
        ])
      ) ||
      stable_id_or_nil(
        get_in(row, ["source_station_calendar_entry", "source_station_calendar_entry", "id"])
      )
  end

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values =
      values
      |> Enum.map(&ContactNormalization.numeric_or_nil/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    if values == [], do: nil, else: values
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

  defp capacity_fraction_or_full(value) when is_number(value), do: clamp_unit_interval(value)
  defp capacity_fraction_or_full(_value), do: 1.0

  defp capacity_value(row) do
    @capacity_value_paths
    |> Enum.find_value(fn
      {:fraction, path} -> path_value(row, path)
      {:percent, path} -> capacity_percent_fraction(path_value(row, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp clamp_unit_interval(value) when is_number(value), do: value |> max(0.0) |> min(1.0)

  defp present_station_evidence?(value), do: value not in [nil, "", [], %{}]
  defp stable_id_or_nil(value), do: ContactNormalization.stable_id_or_nil(value)
  defp numeric_or_nil(value), do: ContactNormalization.numeric_or_nil(value)
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_list(map, key, values) do
    values =
      values
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()

    case values do
      [] -> map
      values -> Map.put(map, key, values)
    end
  end

  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
