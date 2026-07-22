defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ResourceBlockingCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.{
    CountMapCorrelation,
    OutcomeIdentityCorrelation
  }

  @fields [
    "resource_blocking_dimension_counts",
    "resource_blocked_contact_ids_by_blocking_dimension",
    "resource_blocked_contact_ids_by_spacecraft",
    "resource_blocked_contact_ids"
  ]

  def fields, do: @fields

  def fields(%{} = summary) do
    dimension_counts =
      summary
      |> Map.get("resource_blocking_dimension_counts")
      |> CountMapCorrelation.positive_counts()
      |> non_empty_map()

    ids_by_dimension =
      correlated_routes(
        dimension_counts,
        Map.get(summary, "resource_blocked_contact_ids_by_blocking_dimension")
      )

    ids_by_spacecraft =
      canonical_routes(Map.get(summary, "resource_blocked_contact_ids_by_spacecraft"))

    contact_ids =
      [
        Map.get(summary, "resource_blocked_contact_ids"),
        route_ids(ids_by_dimension),
        route_ids(ids_by_spacecraft)
      ]
      |> List.flatten()
      |> OutcomeIdentityCorrelation.contact_ids()

    summary
    |> put_or_delete("resource_blocking_dimension_counts", dimension_counts)
    |> put_or_delete("resource_blocked_contact_ids_by_blocking_dimension", ids_by_dimension)
    |> put_or_delete("resource_blocked_contact_ids_by_spacecraft", ids_by_spacecraft)
    |> put_or_delete("resource_blocked_contact_ids", contact_ids)
  end

  def correlated_routes(counts, routes) do
    routes
    |> canonical_routes()
    |> case do
      %{} = routes ->
        routes
        |> Enum.reduce(%{}, fn {key, ids}, correlated ->
          case Map.get(counts || %{}, key) do
            count when is_integer(count) and count > 0 and length(ids) > count -> correlated
            _count -> Map.put(correlated, key, ids)
          end
        end)
        |> non_empty_map()

      _routes ->
        nil
    end
  end

  def canonical_routes(%{} = routes) do
    routes
    |> Enum.reduce(%{}, fn {key, ids}, normalized ->
      key = StableIds.stable_id_or_nil(key)
      ids = OutcomeIdentityCorrelation.contact_ids(ids)

      if key && ids do
        Map.update(normalized, key, ids, fn existing ->
          existing |> Kernel.++(ids) |> Enum.uniq() |> Enum.sort()
        end)
      else
        normalized
      end
    end)
    |> non_empty_map()
  end

  def canonical_routes(_routes), do: nil

  defp route_ids(%{} = routes), do: routes |> Map.values() |> List.flatten()
  defp route_ids(_routes), do: []

  defp put_or_delete(map, field, nil), do: Map.delete(map, field)
  defp put_or_delete(map, field, value), do: Map.put(map, field, value)

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
