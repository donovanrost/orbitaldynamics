defmodule OrbitalDynamics.RecommendationRiskContext.StationCalendar do
  @moduledoc false

  @fields [
    {"station_calendar_pressure_risk_types", ["type", "risk_type"]},
    {"station_calendar_pressure_ground_station_ids", "ground_station_id"},
    {"station_calendar_pressure_start_values_s", "starts_at_s"},
    {"station_calendar_pressure_end_values_s", "ends_at_s"},
    {"station_calendar_pressure_capacity_fraction_values", "capacity_fraction"},
    {"station_calendar_pressure_station_availabilities", "station_availability"},
    {"station_calendar_pressure_station_contention_statuses", "station_contention_status"},
    {"station_calendar_pressure_station_calendar_entry_ids", "station_calendar_entry_id"},
    {"station_calendar_pressure_station_calendar_provider_ids", "station_calendar_provider_id"},
    {"station_calendar_pressure_station_calendar_provider_entry_ids",
     "station_calendar_provider_entry_id"},
    {"station_calendar_pressure_station_calendar_directions", ["station_calendar_directions"]},
    {"station_calendar_pressure_station_calendar_statuses", "station_calendar_status"},
    {"station_calendar_pressure_station_calendar_overlap_count_values",
     "station_calendar_overlap_count"},
    {"station_calendar_pressure_station_calendar_overlap_entry_ids",
     ["station_calendar_overlap_entry_ids"]},
    {"station_calendar_pressure_station_calendar_overlap_availabilities",
     ["station_calendar_overlap_availabilities"]},
    {"station_calendar_pressure_station_calendar_entry_ambiguous_values",
     "station_calendar_entry_ambiguous"},
    {"station_calendar_pressure_station_calendar_ambiguous_entry_count_values",
     "station_calendar_ambiguous_entry_count"},
    {"station_calendar_pressure_station_calendar_ambiguous_entry_ids",
     ["station_calendar_ambiguous_entry_ids"]},
    {"station_calendar_pressure_station_calendar_reservation_overlap_count_values",
     "station_calendar_reservation_overlap_count"},
    {"station_calendar_pressure_station_calendar_reservation_ids",
     ["station_calendar_reservation_ids"]},
    {"station_calendar_pressure_station_calendar_reserved_by", ["station_calendar_reserved_by"]},
    {"station_calendar_pressure_station_calendar_reservation_statuses",
     ["station_calendar_reservation_statuses"]},
    {"station_calendar_pressure_station_calendar_trust_boundary_statuses",
     "station_calendar_trust_boundary_status"},
    {"station_calendar_pressure_station_reservation_ids",
     ["station_reservation_id", "reservation_id"]},
    {"station_calendar_pressure_station_reserved_by", ["station_reserved_by", "reserved_by"]},
    {"station_calendar_pressure_station_reservation_statuses",
     ["station_reservation_status", "reservation_status"]},
    {"station_calendar_pressure_station_reservation_match_statuses",
     "station_reservation_match_status"},
    {"station_calendar_pressure_station_reservation_expires_at_values_s",
     "station_reservation_expires_at_s"},
    {"station_calendar_pressure_station_reservation_expiration_statuses",
     "station_reservation_expiration_status"},
    {"station_calendar_pressure_provider_calendar_contention_group_ids",
     "provider_calendar_contention_group_id"},
    {"station_calendar_pressure_provider_calendar_contention_statuses",
     "provider_calendar_contention_status"},
    {"station_calendar_pressure_provider_calendar_contention_entry_ids",
     ["provider_calendar_contention_entry_ids"]},
    {"station_calendar_pressure_provider_calendar_contention_provider_ids",
     ["provider_calendar_contention_provider_ids"]},
    {"station_calendar_pressure_provider_calendar_contention_provider_entry_ids",
     ["provider_calendar_contention_provider_entry_ids"]},
    {"station_calendar_pressure_provider_calendar_contention_availabilities",
     ["provider_calendar_contention_availabilities"]},
    {"station_calendar_pressure_provider_calendar_contention_directions",
     ["provider_calendar_contention_directions"]},
    {"station_calendar_pressure_provider_calendar_contention_reservation_ids",
     ["provider_calendar_contention_reservation_ids"]},
    {"station_calendar_pressure_provider_calendar_contention_reserved_by",
     ["provider_calendar_contention_reserved_by"]},
    {"station_calendar_pressure_provider_calendar_contention_reservation_statuses",
     ["provider_calendar_contention_reservation_statuses"]},
    {"station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses",
     ["provider_calendar_contention_trust_boundary_statuses"]},
    {"station_calendar_pressure_provider_calendar_contention_overlap_pairs",
     ["provider_calendar_contention_overlap_pairs"]},
    {"station_calendar_pressure_required_operator_actions", "required_operator_action"},
    {"station_calendar_pressure_feedback_sources", "feedback_source"},
    {"station_calendar_pressure_feedback_scopes", "feedback_scope"},
    {"station_calendar_pressure_trust_boundaries", "trust_boundary"},
    {"station_calendar_pressure_derivation_reasons", ["derivation_reasons"]}
  ]

  def context_keys, do: Enum.map(@fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    station_calendar_risks =
      risks
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&station_calendar_risk?/1)

    @fields
    |> Enum.map(fn {output_key, risk_keys} ->
      {output_key, risk_context_values(station_calendar_risks, risk_keys)}
    end)
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp station_calendar_risk?(%{"feedback_scope" => "station_calendar"}), do: true

  defp station_calendar_risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "ground_station_reserved",
      "ground_station_outage",
      "reduced_downlink_capacity"
    ]
  end

  defp station_calendar_risk?(%{"risk_type" => type}) when is_binary(type) do
    type in [
      "ground_station_reserved",
      "ground_station_outage",
      "reduced_downlink_capacity"
    ]
  end

  defp station_calendar_risk?(_risk), do: false

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(value), do: value
end
