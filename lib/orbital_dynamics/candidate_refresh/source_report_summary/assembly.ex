defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ContactNetworkFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.PlanningReviewFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ReadinessValidationFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def build(refresh_or_artifact, source_reports) do
    SourceReportSummary.base_fields(source_reports)
    |> Map.merge(PlanningReviewFields.fields(source_reports))
    |> Map.merge(ReadinessValidationFields.fields(refresh_or_artifact, source_reports))
    |> Map.merge(ContactNetworkFields.source_report_fields(refresh_or_artifact, source_reports))
    |> Map.merge(
      TimelineFields.source_report_fields(
        refresh_or_artifact,
        source_reports
      )
    )
    |> compact_map()
  end
end
