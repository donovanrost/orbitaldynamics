defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldImportReadinessSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldImportReadinessSummaryValues,
    as: SummaryValues

  def hold_import_readiness_summary?(summary),
    do: SummaryValues.hold_import_readiness_summary?(summary)

  def report_from_hold_import_readiness_summary(%{} = summary) do
    SummaryValues.report_from_hold_import_readiness_summary(summary)
  end
end
