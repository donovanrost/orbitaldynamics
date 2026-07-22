defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReservationConflictCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows.RowValues.Normalization

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation

  @count_field "reservation_conflict_contact_count"
  @ids_field "reservation_conflict_contact_ids"
  @match_counts_field "reservation_conflict_match_status_counts"
  @match_routes_field "reservation_conflict_contact_ids_by_match_status"
  @reservation_routes_field "reservation_conflict_reservation_ids_by_match_status"
  @direction_counts_field "reservation_conflict_direction_counts"
  @direction_routes_field "reservation_conflict_contact_ids_by_direction"
  @nested_routes_field "reservation_conflict_contact_ids_by_direction_and_ground_station"

  @contact_identity_fields [
    @ids_field,
    @match_routes_field,
    @direction_routes_field,
    @nested_routes_field
  ]

  @fields [
    @count_field,
    @ids_field,
    @match_counts_field,
    @match_routes_field,
    @reservation_routes_field,
    @direction_counts_field,
    @direction_routes_field,
    @nested_routes_field
  ]

  def fields, do: @fields

  def fields(%{} = summary) do
    match_routes = canonical_routes(Map.get(summary, @match_routes_field))
    reservation_routes = canonical_routes(Map.get(summary, @reservation_routes_field))
    direction_routes = canonical_direction_routes(Map.get(summary, @direction_routes_field))
    nested_routes = canonical_nested_direction_routes(Map.get(summary, @nested_routes_field))

    match_counts =
      summary
      |> Map.get(@match_counts_field)
      |> canonical_counts(&StableIds.stable_id_or_nil/1)
      |> correlate_counts(match_route_cardinalities(match_routes, reservation_routes))

    direction_counts =
      summary
      |> Map.get(@direction_counts_field)
      |> canonical_counts(&canonical_direction/1)
      |> correlate_counts(direction_route_cardinalities(direction_routes, nested_routes))

    contact_ids =
      [
        Map.get(summary, @ids_field),
        route_ids(match_routes),
        route_ids(direction_routes),
        nested_route_ids(nested_routes)
      ]
      |> List.flatten()
      |> OutcomeIdentityCorrelation.contact_ids()

    count =
      if contact_identity_supplied?(summary) do
        contact_ids |> List.wrap() |> length()
      else
        non_negative_integer(Map.get(summary, @count_field))
      end

    summary
    |> put_or_delete(@count_field, count)
    |> put_or_delete(@ids_field, contact_ids)
    |> put_or_delete(@match_counts_field, match_counts)
    |> put_or_delete(@match_routes_field, match_routes)
    |> put_or_delete(@reservation_routes_field, reservation_routes)
    |> put_or_delete(@direction_counts_field, direction_counts)
    |> put_or_delete(@direction_routes_field, direction_routes)
    |> put_or_delete(@nested_routes_field, nested_routes)
  end

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

  defp correlate_counts(%{} = counts, required_counts) do
    counts
    |> Enum.reduce(%{}, fn {key, count}, correlated ->
      if count >= Map.get(required_counts, key, 0),
        do: Map.put(correlated, key, count),
        else: correlated
    end)
    |> non_empty_map()
  end

  defp correlate_counts(_counts, _required_counts), do: nil

  defp canonical_routes(routes), do: OutcomeIdentityCorrelation.station_routes(routes)

  defp canonical_direction_routes(%{} = routes) do
    routes
    |> Enum.reduce(%{}, fn {direction, ids}, normalized ->
      direction = canonical_direction(direction)
      ids = OutcomeIdentityCorrelation.contact_ids(ids)

      if direction && ids do
        Map.update(normalized, direction, ids, &merge_ids(&1, ids))
      else
        normalized
      end
    end)
    |> non_empty_map()
  end

  defp canonical_direction_routes(_routes), do: nil

  defp canonical_nested_direction_routes(%{} = routes) do
    routes
    |> Enum.reduce(%{}, fn {direction, station_routes}, normalized ->
      direction = canonical_direction(direction)
      station_routes = canonical_routes(station_routes)

      if direction && station_routes do
        Map.update(normalized, direction, station_routes, &merge_routes(&1, station_routes))
      else
        normalized
      end
    end)
    |> non_empty_map()
  end

  defp canonical_nested_direction_routes(_routes), do: nil

  defp canonical_direction(direction) do
    direction
    |> Normalization.normalize_direction()
    |> StableIds.stable_id_or_nil()
  end

  defp contact_identity_supplied?(summary) do
    Enum.any?(@contact_identity_fields, fn field ->
      value = Map.get(summary, field)
      is_list(value) or is_map(value)
    end)
  end

  defp match_route_cardinalities(match_routes, reservation_routes) do
    merge_cardinalities(
      route_cardinalities(match_routes),
      route_cardinalities(reservation_routes)
    )
  end

  defp direction_route_cardinalities(direction_routes, nested_routes) do
    keys =
      [direction_routes, nested_routes]
      |> Enum.filter(&is_map/1)
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()

    Map.new(keys, fn direction ->
      nested_direction_routes = Map.get(nested_routes || %{}, direction)

      ids =
        [
          Map.get(direction_routes || %{}, direction, []),
          route_ids(nested_direction_routes)
        ]
        |> List.flatten()
        |> Enum.uniq()

      {direction, length(ids)}
    end)
  end

  defp route_cardinalities(%{} = routes) do
    Map.new(routes, fn {key, ids} -> {key, length(ids)} end)
  end

  defp route_cardinalities(_routes), do: %{}

  defp merge_cardinalities(left, right) do
    Map.merge(left, right, fn _key, left_count, right_count -> max(left_count, right_count) end)
  end

  defp merge_routes(left, right) do
    Map.merge(left, right, fn _station, left_ids, right_ids -> merge_ids(left_ids, right_ids) end)
  end

  defp merge_ids(left, right), do: left |> Kernel.++(right) |> Enum.uniq() |> Enum.sort()

  defp route_ids(%{} = routes), do: routes |> Map.values() |> List.flatten()
  defp route_ids(_routes), do: []

  defp nested_route_ids(%{} = routes) do
    routes |> Map.values() |> Enum.flat_map(&route_ids/1)
  end

  defp nested_route_ids(_routes), do: []

  defp non_negative_integer(count) when is_integer(count) and count >= 0, do: count
  defp non_negative_integer(_count), do: nil

  defp put_or_delete(map, field, nil), do: Map.delete(map, field)
  defp put_or_delete(map, field, value), do: Map.put(map, field, value)

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
