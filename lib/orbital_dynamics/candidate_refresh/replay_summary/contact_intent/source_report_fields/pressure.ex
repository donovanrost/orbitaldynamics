defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_contact_intent_branch_local_contact_intent_pressure" =>
        Map.get(summary, "branch_local_contact_intent_pressure"),
      "source_report_contact_intent_branch_local_station_feedback_pressure" =>
        Map.get(summary, "branch_local_station_feedback_pressure"),
      "source_report_contact_intent_branch_local_capacity_pack_pressure" =>
        Map.get(summary, "branch_local_capacity_pack_pressure")
    }
  end
end
