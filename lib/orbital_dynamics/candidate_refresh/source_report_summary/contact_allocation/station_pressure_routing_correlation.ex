defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationPressureRoutingCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows.RowValues.Normalization

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation

  @count_field "station_pressure_contact_count"
  @ids_field "station_pressure_contact_ids"
  @station_counts_field "station_pressure_ground_station_counts"
  @station_routes_field "station_pressure_contact_ids_by_ground_station"
  @station_routes_alias_field "station_pressure_contact_ids_by_ground_station_id"
  @direction_counts_field "station_pressure_direction_counts"
  @direction_routes_field "station_pressure_contact_ids_by_direction"
  @nested_routes_field "station_pressure_contact_ids_by_direction_and_ground_station"
  @nested_routes_alias_field "station_pressure_contact_ids_by_direction_and_ground_station_id"

  @dimension_specs [
    {"station_pressure_availability_counts", "station_pressure_contact_ids_by_availability"},
    {"station_pressure_precedence_availability_counts",
     "station_pressure_contact_ids_by_precedence_availability"},
    {"station_pressure_precedence_rank_counts",
     "station_pressure_contact_ids_by_precedence_rank"},
    {"station_pressure_status_counts", "station_pressure_contact_ids_by_status"}
  ]

  @dimension_route_fields Enum.map(@dimension_specs, &elem(&1, 1))

  @routing_fields [
    @station_counts_field,
    @station_routes_field,
    @direction_counts_field,
    @direction_routes_field,
    @nested_routes_field
  ]

  @contact_identity_fields [
                             @ids_field,
                             @station_routes_field,
                             @station_routes_alias_field,
                             @direction_routes_field,
                             @nested_routes_field,
                             @nested_routes_alias_field
                           ] ++ @dimension_route_fields

  @fields [@count_field, @ids_field] ++
            @routing_fields ++ Enum.flat_map(@dimension_specs, &Tuple.to_list/1)

  def fields, do: @fields

  def fields(%{} = summary) do
    nested_routes = canonical_nested_routes(summary)

    station_routes =
      summary
      |> canonical_station_routes()
      |> union_routes(nested_routes_by_station(nested_routes))
      |> non_empty_map()

    direction_routes =
      summary
      |> Map.get(@direction_routes_field)
      |> canonical_direction_routes()
      |> union_routes(nested_routes_by_direction(nested_routes))
      |> non_empty_map()

    station_counts =
      summary
      |> Map.get(@station_counts_field)
      |> canonical_counts(&StableIds.stable_id_or_nil/1)
      |> correlate_counts(station_routes)

    direction_counts =
      summary
      |> Map.get(@direction_counts_field)
      |> canonical_counts(&canonical_direction/1)
      |> correlate_counts(direction_routes)

    correlated =
      summary
      |> put_or_delete(@station_counts_field, station_counts)
      |> put_or_delete(@station_routes_field, station_routes)
      |> put_or_delete(@direction_counts_field, direction_counts)
      |> put_or_delete(@direction_routes_field, direction_routes)
      |> put_or_delete(@nested_routes_field, nested_routes)
      |> correlate_dimension_fields()

    contact_ids =
      [
        Map.get(summary, @ids_field),
        route_ids(station_routes),
        route_ids(direction_routes),
        nested_route_ids(nested_routes)
        | Enum.map(@dimension_route_fields, fn routes_field ->
            correlated |> Map.get(routes_field) |> route_ids()
          end)
      ]
      |> List.flatten()
      |> OutcomeIdentityCorrelation.contact_ids()

    count =
      if contact_identity_supplied?(summary) do
        contact_ids |> List.wrap() |> length()
      else
        non_negative_integer(Map.get(summary, @count_field))
      end

    correlated
    |> put_or_delete(@count_field, count)
    |> put_or_delete(@ids_field, contact_ids)
  end

  defp correlate_dimension_fields(summary) do
    Enum.reduce(@dimension_specs, summary, fn {count_field, routes_field}, correlated ->
      routes =
        correlated
        |> Map.get(routes_field)
        |> canonical_routes(&StableIds.stable_id_or_nil/1)

      counts =
        correlated
        |> Map.get(count_field)
        |> canonical_counts(&StableIds.stable_id_or_nil/1)
        |> correlate_counts(routes)

      correlated
      |> put_or_delete(count_field, counts)
      |> put_or_delete(routes_field, routes)
    end)
  end

  defp contact_identity_supplied?(summary) do
    Enum.any?(@contact_identity_fields, fn field ->
      value = Map.get(summary, field)
      is_list(value) or is_map(value)
    end)
  end

  defp non_negative_integer(count) when is_integer(count) and count >= 0, do: count
  defp non_negative_integer(_count), do: nil

  defp canonical_station_routes(summary) do
    [Map.get(summary, @station_routes_field), Map.get(summary, @station_routes_alias_field)]
    |> Enum.map(fn routes -> canonical_routes(routes, &StableIds.stable_id_or_nil/1) end)
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, &union_routes(&2, &1))
    |> non_empty_map()
  end

  defp canonical_direction_routes(routes), do: canonical_routes(routes, &canonical_direction/1)

  defp canonical_nested_routes(summary) do
    [Map.get(summary, @nested_routes_field), Map.get(summary, @nested_routes_alias_field)]
    |> Enum.map(&canonical_nested_route_map/1)
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn routes, merged ->
      Map.merge(merged, routes, fn _direction, left_routes, right_routes ->
        union_routes(left_routes, right_routes)
      end)
    end)
    |> non_empty_map()
  end

  defp canonical_nested_route_map(%{} = routes) do
    routes
    |> Enum.reduce(%{}, fn {direction, station_routes}, normalized ->
      direction = canonical_direction(direction)
      station_routes = canonical_routes(station_routes, &StableIds.stable_id_or_nil/1)

      if direction && station_routes do
        Map.update(normalized, direction, station_routes, fn existing ->
          union_routes(existing, station_routes)
        end)
      else
        normalized
      end
    end)
    |> non_empty_map()
  end

  defp canonical_nested_route_map(_routes), do: nil

  defp canonical_routes(%{} = routes, key_normalizer) do
    routes
    |> Enum.reduce(%{}, fn {key, ids}, normalized ->
      key = key_normalizer.(key)
      ids = OutcomeIdentityCorrelation.contact_ids(ids)

      if key && ids,
        do: Map.update(normalized, key, ids, &merge_ids(&1, ids)),
        else: normalized
    end)
    |> non_empty_map()
  end

  defp canonical_routes(_routes, _key_normalizer), do: nil

  defp nested_routes_by_direction(%{} = nested_routes) do
    Map.new(nested_routes, fn {direction, station_routes} ->
      {direction, route_ids(station_routes)}
    end)
  end

  defp nested_routes_by_direction(_nested_routes), do: nil

  defp nested_routes_by_station(%{} = nested_routes) do
    nested_routes
    |> Map.values()
    |> Enum.reduce(%{}, &union_routes(&2, &1))
    |> non_empty_map()
  end

  defp nested_routes_by_station(_nested_routes), do: nil

  defp canonical_counts(%{} = counts, key_normalizer) do
    counts
    |> Enum.reduce(%{}, fn {key, count}, normalized ->
      key = key_normalizer.(key)

      if key && is_integer(count) && count > 0,
        do: Map.update(normalized, key, count, &(&1 + count)),
        else: normalized
    end)
    |> non_empty_map()
  end

  defp canonical_counts(_counts, _key_normalizer), do: nil

  defp correlate_counts(%{} = counts, routes) do
    counts
    |> Enum.reduce(%{}, fn {key, count}, correlated ->
      if count >= length(Map.get(routes || %{}, key, [])),
        do: Map.put(correlated, key, count),
        else: correlated
    end)
    |> non_empty_map()
  end

  defp correlate_counts(_counts, _routes), do: nil

  defp canonical_direction(direction) do
    direction
    |> Normalization.normalize_direction()
    |> StableIds.stable_id_or_nil()
  end

  defp union_routes(left, right) do
    Map.merge(left || %{}, right || %{}, fn _key, left_ids, right_ids ->
      merge_ids(left_ids, right_ids)
    end)
  end

  defp merge_ids(left, right), do: left |> Kernel.++(right) |> Enum.uniq() |> Enum.sort()

  defp route_ids(%{} = routes),
    do: routes |> Map.values() |> List.flatten() |> Enum.uniq() |> Enum.sort()

  defp route_ids(_routes), do: []

  defp nested_route_ids(%{} = routes) do
    routes |> Map.values() |> Enum.flat_map(&route_ids/1)
  end

  defp nested_route_ids(_routes), do: []

  defp put_or_delete(map, field, nil), do: Map.delete(map, field)
  defp put_or_delete(map, field, value), do: Map.put(map, field, value)

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
