defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldImportReadinessSummaryReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationReviewSummaryReports

  def review_summary?(summary),
    do: StationReservationReviewSummaryReports.review_summary?(summary)

  def hold_summary?(summary), do: StationReservationHoldSummaryReports.hold_summary?(summary)

  def hold_import_readiness_summary?(summary),
    do:
      StationReservationHoldImportReadinessSummaryReports.hold_import_readiness_summary?(summary)

  def report_from_review_summary(%{} = summary) do
    StationReservationReviewSummaryReports.report_from_review_summary(summary)
  end

  def report_from_hold_summary(%{} = summary) do
    StationReservationHoldSummaryReports.report_from_hold_summary(summary)
  end

  def report_from_hold_import_readiness_summary(%{} = summary) do
    StationReservationHoldImportReadinessSummaryReports.report_from_hold_import_readiness_summary(
      summary
    )
  end
end
