defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues.CountValues.MapCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues.FieldValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def count_map(summaries, field) do
    summaries
    |> FieldValues.values(field)
    |> merge_count_maps()
  end
end
