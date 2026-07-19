defmodule OrbitalDynamics.TimelineFeedback.StationCalendarContext do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{
    ArtifactValue,
    ExecutionUncertainty,
    RealizedIdentity
  }

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

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

  def build(activity) when is_map(activity) do
    capacity_context = station_capacity_context(activity)

    %{
      "station_availability" => Map.get(activity, "station_availability"),
      "station_contention_status" => Map.get(activity, "station_contention_status"),
      "capacity_fraction" => capacity_context["capacity_fraction"],
      "capacity_fraction_min" => capacity_context["capacity_fraction_min"],
      "capacity_fraction_max" => capacity_context["capacity_fraction_max"],
      "station_calendar_entry_id" => Map.get(activity, "station_calendar_entry_id"),
      "station_calendar_provider_id" =>
        first_identifier(activity, ["station_calendar_provider_id"]),
      "station_calendar_provider_entry_id" =>
        first_identifier(activity, ["station_calendar_provider_entry_id"]),
      "station_calendar_directions" =>
        normalize_string_list(Map.get(activity, "station_calendar_directions")),
      "station_calendar_status" => Map.get(activity, "station_calendar_status"),
      "station_calendar_overlap_count" => Map.get(activity, "station_calendar_overlap_count"),
      "station_calendar_overlap_entry_ids" =>
        Map.get(activity, "station_calendar_overlap_entry_ids"),
      "station_calendar_overlap_availabilities" =>
        normalize_string_list(Map.get(activity, "station_calendar_overlap_availabilities")),
      "station_calendar_entry_ambiguous" => Map.get(activity, "station_calendar_entry_ambiguous"),
      "station_calendar_ambiguous_entry_count" =>
        Map.get(activity, "station_calendar_ambiguous_entry_count"),
      "station_calendar_ambiguous_entry_ids" =>
        Map.get(activity, "station_calendar_ambiguous_entry_ids"),
      "station_calendar_reservation_overlap_count" =>
        Map.get(activity, "station_calendar_reservation_overlap_count"),
      "station_calendar_reservation_ids" => Map.get(activity, "station_calendar_reservation_ids"),
      "station_calendar_reservation_expires_at_s" =>
        station_calendar_reservation_expires_at_s(activity),
      "station_calendar_reserved_by" =>
        normalize_string_list(Map.get(activity, "station_calendar_reserved_by")),
      "station_calendar_reservation_statuses" =>
        normalize_string_list(Map.get(activity, "station_calendar_reservation_statuses")),
      "station_calendar_trust_boundary_status" =>
        Map.get(activity, "station_calendar_trust_boundary_status"),
      "source_station_calendar_entry" => Map.get(activity, "source_station_calendar_entry"),
      "source_station_calendar_overlaps" => Map.get(activity, "source_station_calendar_overlaps"),
      "station_reservation_id" => Map.get(activity, "station_reservation_id"),
      "station_reservation_expires_at_s" => station_reservation_expires_at_s(activity),
      "station_reserved_by" => Map.get(activity, "station_reserved_by"),
      "station_reservation_status" => Map.get(activity, "station_reservation_status"),
      "station_reservation_match_status" => Map.get(activity, "station_reservation_match_status")
    }
    |> ArtifactValue.compact_map()
  end

  defp station_capacity_context(activity) do
    case station_capacity_fractions(activity) do
      [] ->
        %{}

      fractions ->
        %{
          "capacity_fraction" => Enum.min(fractions),
          "capacity_fraction_min" => Enum.min(fractions),
          "capacity_fraction_max" => Enum.max(fractions)
        }
    end
  end

  defp station_capacity_fractions(activity) do
    activity
    |> station_capacity_fraction_candidates()
    |> Enum.map(&unit_interval_number/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_capacity_fraction_candidates(activity) do
    capacity_value_candidates(activity, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_overlaps"])
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
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp unit_interval_number(value) do
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp normalize_string_list(nil), do: nil

  defp normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&ArtifactValue.stringify_scalar/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp normalize_string_list(value), do: normalize_string_list([value])

  defp station_reservation_expires_at_s(activity) do
    first_numeric_value([
      Map.get(activity, "station_reservation_expires_at_s"),
      Map.get(activity, "reservation_expires_at_s"),
      get_in(activity, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"])
    ])
  end

  defp station_calendar_reservation_expires_at_s(activity) do
    [
      Map.get(activity, "station_calendar_reservation_expires_at_s"),
      station_reservation_expires_at_s(activity),
      get_in(activity, [
        "source_station_calendar_entry",
        "station_calendar_reservation_expires_at_s"
      ]),
      get_in(activity, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      source_station_calendar_overlap_values(
        activity,
        "station_calendar_reservation_expires_at_s"
      ),
      source_station_calendar_overlap_values(activity, "station_reservation_expires_at_s"),
      source_station_calendar_overlap_values(activity, "reservation_expires_at_s")
    ]
    |> normalize_number_list()
  end

  defp first_numeric_value(values), do: Enum.find_value(values, &numeric_value/1)

  defp source_station_calendar_overlap_values(activity, field) do
    activity
    |> Map.get("source_station_calendar_overlaps")
    |> List.wrap()
    |> Enum.flat_map(fn
      %{} = overlap -> [Map.get(overlap, field)]
      _overlap -> []
    end)
  end

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&number_values/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

  defp number_values(%{} = value) do
    [
      Map.get(value, "station_calendar_reservation_expires_at_s"),
      Map.get(value, "station_reservation_expires_at_s"),
      Map.get(value, "reservation_expires_at_s")
    ]
    |> normalize_number_list()
    |> List.wrap()
  end

  defp number_values(values) when is_list(values), do: Enum.flat_map(values, &number_values/1)

  defp number_values(value) do
    case numeric_value(value) do
      nil -> []
      number -> [number]
    end
  end

  defp first_identifier(map, keys),
    do: RealizedIdentity.first_identifier(map, keys, @stable_id_pattern)

  defp numeric_value(value), do: ExecutionUncertainty.numeric_value(value)
end
