defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.TransitionProvenance.Counts.CountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.TransitionProvenance.Entries

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      merge_count_maps: 1
    ]

  def total(summaries) do
    summaries
    |> Enum.map(&transition_provenance_count/1)
    |> Enum.sum()
    |> non_zero_count()
  end

  def field_counts(summaries, field) do
    summaries
    |> Enum.map(&field_counts_for_summary(&1, field))
    |> merge_count_maps()
  end

  defp field_counts_for_summary(%{} = summary, field) do
    summary
    |> Entries.transition_application_provenances()
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end

  defp transition_provenance_count(%{} = summary) do
    summary
    |> Entries.transition_application_provenances()
    |> length()
  end

  defp non_zero_count(count) when is_integer(count) and count > 0, do: count
  defp non_zero_count(_count), do: nil
end
