defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ReasonIdentityCorrelation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.OutcomeIdentityCorrelation

  def fields(%{} = summary) do
    Map.put(
      summary,
      "contact_ids_by_allocation_reason",
      routes(
        Map.get(summary, "allocation_reason_counts"),
        Map.get(summary, "contact_ids_by_allocation_reason")
      )
    )
  end

  def routes(counts, %{} = routes) do
    routes
    |> Enum.reduce(%{}, fn {reason, ids}, normalized ->
      reason = StableIds.stable_id_or_nil(reason)
      ids = OutcomeIdentityCorrelation.contact_ids(ids)

      if reason && ids do
        Map.update(normalized, reason, ids, fn existing ->
          existing |> Kernel.++(ids) |> Enum.uniq() |> Enum.sort()
        end)
      else
        normalized
      end
    end)
    |> Enum.reduce(%{}, fn {reason, ids}, correlated ->
      case Map.get(counts || %{}, reason) do
        count when is_integer(count) and count > 0 and length(ids) > count -> correlated
        _count -> Map.put(correlated, reason, ids)
      end
    end)
    |> non_empty_map()
  end

  def routes(_counts, _routes), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
