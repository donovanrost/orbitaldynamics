defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.CountMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def from_reports(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
