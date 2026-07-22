defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CountMapCorrelation do
  @moduledoc false

  @count_fields [
    "allocation_status_counts",
    "effective_allocation_status_counts",
    "allocation_reason_counts"
  ]

  def count_fields, do: @count_fields

  def fields(%{} = summary) do
    row_count = Map.get(summary, "row_count")

    Enum.reduce(@count_fields, summary, fn field, correlated ->
      case correlated_counts(Map.get(summary, field), row_count) do
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

  def correlated_counts(counts, row_count) when is_integer(row_count) and row_count > 0 do
    counts = positive_counts(counts)

    if map_size(counts) > 0 and Enum.sum(Map.values(counts)) <= row_count,
      do: counts,
      else: nil
  end

  def correlated_counts(_counts, _row_count), do: nil

  def correlated_counts_or_empty(counts, row_count),
    do: correlated_counts(counts, row_count) || %{}
end
