defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_contact_filter_branch_local_contact_filter_pressure" =>
        Map.get(summary, "branch_local_contact_filter_pressure"),
      "source_report_contact_filter_branch_local_candidate_suppression_pressure" =>
        Map.get(summary, "branch_local_candidate_suppression_pressure"),
      "source_report_contact_filter_branch_local_invalid_contact_input_pressure" =>
        Map.get(summary, "branch_local_invalid_contact_input_pressure"),
      "source_report_contact_filter_branch_local_station_suppression_pressure" =>
        Map.get(summary, "branch_local_station_suppression_pressure")
    }
  end
end
