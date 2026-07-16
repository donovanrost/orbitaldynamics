defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ContactFields.RouteFields.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report,
    as: AllocationReport

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ContactFields.RouteFields.StringListMaps

  def fields(reports) do
    %{
      "contact_ids_by_direction" =>
        route_map(reports, &AllocationReport.contact_ids_by_direction/1),
      "allocated_contact_ids_by_ground_station" =>
        route_map(reports, &AllocationReport.allocated_contact_ids_by_station/1),
      "returned_allocated_contact_ids_by_ground_station" =>
        route_map(reports, &AllocationReport.returned_allocated_contact_ids_by_station/1),
      "deferred_contact_ids_by_ground_station" =>
        route_map(reports, &AllocationReport.deferred_contact_ids_by_station/1),
      "blocked_contact_ids_by_ground_station" =>
        route_map(reports, &AllocationReport.blocked_contact_ids_by_station/1),
      "policy_blocked_contact_ids_by_ground_station" =>
        route_map(reports, &AllocationReport.policy_blocked_contact_ids_by_station/1),
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        route_map(reports, &AllocationReport.resource_blocked_contact_ids_by_dimension/1),
      "resource_blocked_contact_ids_by_spacecraft" =>
        route_map(reports, &AllocationReport.resource_blocked_contact_ids_by_spacecraft/1),
      "contact_ids_by_allocation_reason" =>
        route_map(reports, &AllocationReport.contact_ids_by_allocation_reason/1)
    }
  end

  defp route_map(reports, extractor) do
    StringListMaps.from_reports(reports, extractor)
  end
end
