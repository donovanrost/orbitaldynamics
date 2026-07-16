defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups.ValueCounts.Frequencies do
  @moduledoc false

  def from_values(values) do
    values
    |> Enum.frequencies()
    |> non_empty_counts()
  end

  defp non_empty_counts(counts) when counts == %{}, do: nil
  defp non_empty_counts(counts), do: counts
end
