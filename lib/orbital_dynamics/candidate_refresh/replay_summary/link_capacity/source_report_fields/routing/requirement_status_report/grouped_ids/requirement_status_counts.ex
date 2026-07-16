defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.GroupedIds.RequirementStatusCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows,
    only: [rows_for_summary: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  def requirement_status_counts(report) do
    rows = rows_for_summary(report)

    [
      Counts.normalized_rows(rows, "downlink_requirement_status"),
      Counts.normalized_rows(rows, "actual_downlink_requirement_status")
    ]
    |> merge_count_maps()
  end
end
