defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ContactFields.ContactIdFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report,
    as: AllocationReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_lists: 1]

  def fields(reports) do
    %{
      "allocated_contact_ids" => string_lists(reports, &AllocationReport.allocated_contact_ids/1),
      "returned_allocated_contact_ids" =>
        string_lists(reports, &AllocationReport.returned_allocated_contact_ids/1),
      "deferred_contact_ids" => string_lists(reports, &AllocationReport.deferred_contact_ids/1),
      "blocked_contact_ids" => string_lists(reports, &AllocationReport.blocked_contact_ids/1),
      "policy_blocked_contact_ids" =>
        string_lists(reports, &AllocationReport.policy_blocked_contact_ids/1),
      "invalid_contact_input_ids" =>
        string_lists(reports, &AllocationReport.invalid_contact_input_ids/1),
      "status_blocked_contact_ids" =>
        string_lists(reports, &AllocationReport.status_blocked_contact_ids/1),
      "resource_blocked_contact_ids" =>
        string_lists(reports, &AllocationReport.resource_blocked_contact_ids/1),
      "review_contact_ids" => string_lists(reports, &AllocationReport.review_contact_ids/1)
    }
  end

  defp string_lists(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end
end
