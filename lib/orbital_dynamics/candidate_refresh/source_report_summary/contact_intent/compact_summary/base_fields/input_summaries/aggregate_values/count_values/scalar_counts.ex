defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues.CountValues.ScalarCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      report_count: 1
    ]

  def count(summaries, field) do
    summaries
    |> Enum.map(&numeric_report_count(&1, field))
    |> Enum.sum()
    |> report_count()
  end
end
