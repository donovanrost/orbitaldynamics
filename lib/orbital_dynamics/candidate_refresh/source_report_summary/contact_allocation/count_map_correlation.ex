defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CountMapCorrelation do
  @moduledoc false

  @count_fields [
    "allocation_status_counts",
    "effective_allocation_status_counts",
    "allocation_reason_counts"
  ]

  def count_fields, do: @count_fields

  def fields(%{} = summary) do
    Enum.reduce(@count_fields, summary, fn field, correlated ->
      case positive_counts_or_nil(Map.get(summary, field)) do
        nil -> Map.delete(correlated, field)
        counts -> Map.put(correlated, field, counts)
      end
    end)
  end

  def positive_counts(%{} = counts) do
    Enum.reduce(counts, %{}, fn {key, count}, positive ->
      if is_integer(count) and count > 0,
        do: Map.update(positive, to_string(key), count, &(&1 + count)),
        else: positive
    end)
  end

  def positive_counts(_counts), do: %{}

  def positive_counts_or_nil(counts) do
    case positive_counts(counts) do
      counts when map_size(counts) == 0 -> nil
      counts -> counts
    end
  end
end
