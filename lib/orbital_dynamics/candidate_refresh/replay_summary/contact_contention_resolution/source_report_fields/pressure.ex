defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_contact_contention_resolution_branch_local_contact_contention_resolution_pressure" =>
        Map.get(summary, "branch_local_contact_contention_resolution_pressure"),
      "source_report_contact_contention_resolution_branch_local_deferred_contact_pressure" =>
        Map.get(summary, "branch_local_deferred_contact_pressure"),
      "source_report_contact_contention_resolution_branch_local_capacity_pack_pressure" =>
        Map.get(summary, "branch_local_capacity_pack_pressure"),
      "source_report_contact_contention_resolution_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_contact_contention_resolution_action_pressure")
    }
  end
end
