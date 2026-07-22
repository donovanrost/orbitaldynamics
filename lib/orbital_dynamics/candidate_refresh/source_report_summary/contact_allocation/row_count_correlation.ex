defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.RowCountCorrelation do
  @moduledoc false

  @count_fields ["blocked_row_count", "deferred_row_count"]

  def count_fields, do: @count_fields

  def fields(%{} = summary) do
    Map.merge(
      summary,
      correlated_counts(
        Map.get(summary, "row_count"),
        Map.get(summary, "blocked_row_count"),
        Map.get(summary, "deferred_row_count")
      )
    )
  end

  def correlated_counts(row_count, blocked_row_count, deferred_row_count)
      when is_integer(blocked_row_count) and blocked_row_count >= 0 and
             is_integer(deferred_row_count) and deferred_row_count >= 0 do
    total = blocked_row_count + deferred_row_count

    if total == 0 or (is_integer(row_count) and row_count > 0 and total <= row_count) do
      %{
        "blocked_row_count" => blocked_row_count,
        "deferred_row_count" => deferred_row_count
      }
    else
      zero_counts()
    end
  end

  def correlated_counts(_row_count, _blocked_row_count, _deferred_row_count),
    do: zero_counts()

  def correlated_counts_or_nil(nil, nil, nil), do: nil

  def correlated_counts_or_nil(row_count, blocked_row_count, deferred_row_count),
    do: correlated_counts(row_count, blocked_row_count, deferred_row_count)

  defp zero_counts, do: %{"blocked_row_count" => 0, "deferred_row_count" => 0}
end
