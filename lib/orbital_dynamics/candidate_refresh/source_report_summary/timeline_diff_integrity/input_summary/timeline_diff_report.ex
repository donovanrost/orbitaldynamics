defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.InputSummary.TimelineDiffReport do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.{
    SourceFields,
    TimelineDiffFields
  }

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.InputSummary.SourceReports

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def input_summary(sources) do
    reports = SourceReports.values(sources)

    sources
    |> SourceFields.timeline_diff_fields(reports)
    |> Map.merge(TimelineDiffFields.fields(reports))
    |> compact_map()
  end
end
