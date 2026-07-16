defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.CountMaps do
  @moduledoc false

  alias __MODULE__.CountValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def precondition_status_counts(summaries) do
    precondition_count_map(summaries, &CountValues.status_counts/1)
  end

  def blocked_precondition_type_counts(summaries) do
    precondition_count_map(summaries, &CountValues.blocked_type_counts/1)
  end

  def review_precondition_type_counts(summaries) do
    precondition_count_map(summaries, &CountValues.review_type_counts/1)
  end

  defp precondition_count_map(summaries, values_fun) do
    summaries
    |> Enum.map(values_fun)
    |> merge_count_maps()
  end
end
