defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.PlanningReviewFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Diff.SourceReportFields,
    as: CandidateDiffFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Rejection.SourceReportFields,
    as: CandidateRejectionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields,
    as: ResourceFilterFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields,
    as: ResourceProjectionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.SourceReportFields,
    as: StorageDownlinkPressureFields

  alias __MODULE__.FeedbackFields

  def fields(source_reports) do
    StorageDownlinkPressureFields.source_report_summary_fields(source_reports)
    |> Map.merge(CandidateDiffFields.source_report_summary_fields(source_reports))
    |> Map.merge(CandidateRejectionFields.source_report_summary_fields(source_reports))
    |> Map.merge(ResourceFilterFields.source_report_summary_fields(source_reports))
    |> Map.merge(ResourceProjectionFields.source_report_summary_fields(source_reports))
    |> Map.merge(FeedbackFields.fields(source_reports))
  end
end
