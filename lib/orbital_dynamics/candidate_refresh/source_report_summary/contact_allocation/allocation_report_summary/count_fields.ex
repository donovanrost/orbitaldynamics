defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report,
    as: AllocationReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &AllocationReport.row_count/1),
      "blocked_row_count" => sum_report_count(reports, &AllocationReport.blocked_row_count/1),
      "deferred_row_count" => sum_report_count(reports, &AllocationReport.deferred_row_count/1),
      "allocated_contact_count" =>
        sum_report_count(reports, &AllocationReport.allocated_contact_count/1),
      "returned_allocated_contact_count" =>
        sum_report_count(reports, &AllocationReport.returned_allocated_contact_count/1),
      "deferred_contact_count" =>
        sum_report_count(reports, &AllocationReport.deferred_contact_count/1),
      "blocked_contact_count" =>
        sum_report_count(reports, &AllocationReport.blocked_contact_count/1),
      "policy_blocked_allocated_contact_count" =>
        sum_report_count(reports, &AllocationReport.policy_blocked_allocated_contact_count/1),
      "invalid_contact_input_count" =>
        sum_report_count(reports, &AllocationReport.invalid_contact_input_count/1),
      "duplicate_contact_id_count" =>
        sum_report_count(reports, &AllocationReport.duplicate_contact_id_count/1),
      "status_blocked_contact_count" =>
        sum_report_count(reports, &AllocationReport.status_blocked_contact_count/1),
      "resource_blocked_contact_count" =>
        sum_report_count(reports, &AllocationReport.resource_blocked_contact_count/1)
    }
  end
end
