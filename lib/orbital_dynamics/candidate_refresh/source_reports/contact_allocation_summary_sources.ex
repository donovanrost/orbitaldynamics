defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationSummarySources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationSummarySourceTypes
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def report_from_summary_source(%{} = report) do
    case ContactAllocationSummarySourceTypes.builder(report) do
      :summary ->
        SourceReportSummary.ContactAllocation.report_from_summary(report)

      :provider_reservation_request_summary ->
        SourceReportSummary.ContactAllocation.report_from_provider_reservation_request_summary(
          report
        )

      nil ->
        nil
    end
  end

  def report_from_summary_source(_report), do: nil
end
