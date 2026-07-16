defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_contact_allocation_branch_local_contact_allocation_pressure" =>
        Map.get(summary, "branch_local_contact_allocation_pressure"),
      "source_report_contact_allocation_branch_local_blocked_allocation_pressure" =>
        Map.get(summary, "branch_local_blocked_allocation_pressure"),
      "source_report_contact_allocation_branch_local_deferred_allocation_pressure" =>
        Map.get(summary, "branch_local_deferred_allocation_pressure"),
      "source_report_contact_allocation_branch_local_station_pressure" =>
        Map.get(summary, "branch_local_station_pressure"),
      "source_report_contact_allocation_branch_local_capacity_pack_pressure" =>
        Map.get(summary, "branch_local_capacity_pack_pressure"),
      "source_report_contact_allocation_branch_local_reservation_conflict_pressure" =>
        Map.get(summary, "branch_local_reservation_conflict_pressure"),
      "source_report_contact_allocation_branch_local_station_reservation_pressure" =>
        Map.get(summary, "branch_local_station_reservation_pressure"),
      "source_report_contact_allocation_branch_local_provider_reservation_request_pressure" =>
        Map.get(summary, "branch_local_provider_reservation_request_pressure")
    }
  end
end
