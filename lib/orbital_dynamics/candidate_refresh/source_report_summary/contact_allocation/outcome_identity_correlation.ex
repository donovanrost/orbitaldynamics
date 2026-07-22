defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  @field_specs [
    {"allocated_contact_count", "allocated_contact_ids",
     "allocated_contact_ids_by_ground_station"},
    {"returned_allocated_contact_count", "returned_allocated_contact_ids",
     "returned_allocated_contact_ids_by_ground_station"},
    {"deferred_contact_count", "deferred_contact_ids", "deferred_contact_ids_by_ground_station"},
    {"blocked_contact_count", "blocked_contact_ids", "blocked_contact_ids_by_ground_station"},
    {"policy_blocked_allocated_contact_count", "policy_blocked_contact_ids",
     "policy_blocked_contact_ids_by_ground_station"}
  ]

  def field_specs, do: @field_specs
  def field_pairs, do: Enum.map(@field_specs, fn {count, ids, _routes} -> {count, ids} end)

  def fields(%{} = summary) do
    Enum.reduce(@field_specs, summary, fn {count_field, ids_field, routes_field}, correlated ->
      routes = station_routes(Map.get(summary, routes_field))

      contact_ids =
        [Map.get(summary, ids_field) | route_contact_ids(routes)]
        |> List.flatten()
        |> contact_ids()

      correlated
      |> put_or_delete(ids_field, contact_ids)
      |> put_or_delete(routes_field, routes)
      |> put_or_delete(
        count_field,
        correlated_count(Map.get(summary, count_field), contact_ids, routes)
      )
    end)
  end

  def contact_ids(contact_ids) when is_list(contact_ids) do
    contact_ids
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> non_empty_list()
  end

  def contact_ids(_contact_ids), do: nil

  def correlated_count(count, contact_ids) when is_list(contact_ids) do
    if is_integer(count) and count > 0 and count >= length(contact_ids), do: count
  end

  def correlated_count(count, _contact_ids), do: count

  def correlated_count(count, contact_ids, routes) do
    required_count =
      max(
        contact_ids |> List.wrap() |> length(),
        routes |> route_contact_ids() |> length()
      )

    if required_count == 0,
      do: count,
      else: correlated_count(count, List.duplicate(:identity, required_count))
  end

  def station_routes(%{} = routes) do
    routes
    |> Enum.reduce(%{}, fn {station, ids}, normalized ->
      station = StableIds.stable_id_or_nil(station)
      ids = contact_ids(ids)

      if station && ids do
        Map.update(normalized, station, ids, fn existing ->
          existing |> Kernel.++(ids) |> Enum.uniq() |> Enum.sort()
        end)
      else
        normalized
      end
    end)
    |> non_empty_map()
  end

  def station_routes(_routes), do: nil

  defp put_or_delete(map, field, nil), do: Map.delete(map, field)
  defp put_or_delete(map, field, value), do: Map.put(map, field, value)

  defp non_empty_list([]), do: nil
  defp non_empty_list(values), do: values

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp route_contact_ids(%{} = routes), do: routes |> Map.values() |> List.flatten()
  defp route_contact_ids(_routes), do: []
end
