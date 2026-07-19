defmodule OrbitalDynamics.Communications.ContactContention.StationCalendarContext do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention.{
    ContactIdentity,
    ContactNormalization
  }

  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @station_capacity_fraction_paths [
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @station_capacity_value_paths [
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]}
  ]

  def unavailable_aliases, do: @unavailable_aliases
  def availability_precedence, do: @station_availability_severity
  def capacity_fraction_paths, do: @station_capacity_fraction_paths
  def capacity_percent_paths, do: @station_capacity_percent_paths

  def capacity_value_path_metadata do
    Enum.map(@station_capacity_value_paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  def build(contacts) do
    %{
      "station_availability" => station_availability(contacts),
      "station_calendar_status" => station_calendar_status(contacts),
      "capacity_fraction" => station_capacity_fraction(contacts),
      "capacity_fraction_min" => station_capacity_fraction_min(contacts),
      "capacity_fraction_max" => station_capacity_fraction_max(contacts),
      "station_calendar_entry_ids" =>
        stable_context_values(contacts, ["station_calendar_entry_id"]),
      "station_calendar_provider_ids" =>
        stable_context_values(contacts, ["station_calendar_provider_id"]),
      "station_calendar_provider_entry_ids" =>
        stable_context_values(contacts, ["station_calendar_provider_entry_id"]),
      "station_calendar_overlap_entry_ids" =>
        stable_context_values(contacts, ["station_calendar_overlap_entry_ids"]),
      "station_calendar_directions" =>
        string_context_values(contacts, ["station_calendar_directions"]),
      "station_calendar_reservation_ids" =>
        stable_context_values(contacts, ["station_calendar_reservation_ids"]),
      "station_calendar_reserved_by" =>
        string_context_values(contacts, ["station_calendar_reserved_by"]),
      "station_calendar_reservation_statuses" =>
        string_context_values(contacts, ["station_calendar_reservation_statuses"]),
      "station_calendar_reservation_expires_at_s" =>
        numeric_context_values(contacts, [
          "station_calendar_reservation_expires_at_s",
          "station_reservation_expires_at_s",
          "reservation_expires_at_s"
        ]),
      "station_calendar_trust_boundary_statuses" =>
        string_context_values(contacts, ["station_calendar_trust_boundary_status"]),
      "station_reservation_ids" =>
        stable_context_values(contacts, ["station_reservation_id", "reservation_id"]),
      "station_reserved_bys" =>
        string_context_values(contacts, ["station_reserved_by", "reserved_by"]),
      "station_reservation_statuses" =>
        string_context_values(contacts, ["station_reservation_status", "reservation_status"]),
      "station_reservation_match_statuses" =>
        string_context_values(contacts, [
          "station_reservation_match_status",
          "reservation_match_status"
        ])
    }
    |> Enum.reject(fn {_key, value} -> value == [] end)
    |> Map.new()
  end

  def fields do
    [
      "station_availability",
      "station_calendar_status",
      "capacity_fraction",
      "capacity_fraction_min",
      "capacity_fraction_max",
      "station_calendar_entry_ids",
      "station_calendar_provider_ids",
      "station_calendar_provider_entry_ids",
      "station_calendar_overlap_entry_ids",
      "station_calendar_directions",
      "station_calendar_reservation_ids",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_trust_boundary_statuses",
      "station_reservation_ids",
      "station_reserved_bys",
      "station_reservation_statuses",
      "station_reservation_match_statuses"
    ]
  end

  defp station_availability(contacts) do
    contacts
    |> Enum.flat_map(&station_availability_candidates/1)
    |> Enum.filter(&station_availability_value?/1)
    |> highest_station_availability()
    |> canonical_station_availability()
  end

  defp station_calendar_status(contacts) do
    contacts
    |> Enum.flat_map(&station_calendar_status_candidates/1)
    |> Enum.filter(&station_availability_value?/1)
    |> highest_station_availability()
    |> canonical_station_availability()
  end

  defp station_capacity_fraction(contacts) do
    contacts
    |> station_capacity_fractions()
    |> case do
      [] -> nil
      fractions -> Enum.min(fractions)
    end
  end

  defp station_capacity_fraction_min(contacts), do: station_capacity_fraction(contacts)

  defp station_capacity_fraction_max(contacts) do
    contacts
    |> station_capacity_fractions()
    |> case do
      [] -> nil
      fractions -> Enum.max(fractions)
    end
  end

  defp station_capacity_fractions(contacts) do
    contacts
    |> Enum.flat_map(&station_capacity_fraction_candidates/1)
    |> Enum.map(&unit_interval_number/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_capacity_fraction_candidates(contact) do
    capacity_value_candidates(contact, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_overlaps"])
  end

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp unit_interval_number(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp station_availability_candidates(contact) do
    [
      contact["station_availability"],
      contact["availability"],
      contact["station_calendar_status"],
      contact["status"]
    ] ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_overlaps"])
  end

  defp station_calendar_status_candidates(contact) do
    [
      contact["station_calendar_status"],
      contact["status"]
    ] ++
      source_station_calendar_status_candidates(contact["source_station_calendar_entry"]) ++
      source_station_calendar_status_candidates(contact["source_station_calendar_overlaps"])
  end

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

  defp source_station_calendar_status_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_status_candidates/1)

  defp source_station_calendar_status_candidates(%{} = source) do
    [
      source["station_calendar_status"],
      source["status"],
      source["availability"]
    ]
  end

  defp source_station_calendar_status_candidates(_source), do: []

  defp highest_station_availability([]), do: nil

  defp highest_station_availability(values),
    do: Enum.max_by(values, &station_availability_severity/1)

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(value) when value in @unavailable_aliases, do: true
  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value) when value in @unavailable_aliases,
    do: @station_availability_severity["unavailable"]

  defp station_availability_severity(value), do: Map.get(@station_availability_severity, value, 0)

  defp canonical_station_availability(value)
       when value in ["unavailable", "maintenance" | @unavailable_aliases],
       do: "unavailable"

  defp canonical_station_availability(value), do: value

  defp stable_context_values(contacts, fields) do
    contacts
    |> context_values(fields)
    |> Enum.map(&ContactIdentity.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp string_context_values(contacts, fields) do
    contacts
    |> context_values(fields)
    |> Enum.map(&ContactNormalization.encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp numeric_context_values(contacts, fields) do
    contacts
    |> context_values(fields)
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp context_values(contacts, fields) do
    Enum.flat_map(contacts, fn contact ->
      Enum.flat_map(fields, fn field ->
        contact
        |> Map.get(field)
        |> List.wrap()
      end)
    end)
  end

  defp numeric_or_nil(value), do: ContactNormalization.numeric_or_nil(value)
end
