defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_contact_contention_branch_local_contact_contention_pressure" =>
        Map.get(summary, "branch_local_contact_contention_pressure"),
      "source_report_contact_contention_branch_local_conflict_pressure" =>
        Map.get(summary, "branch_local_contact_contention_conflict_pressure"),
      "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
        Map.get(summary, "branch_local_invalid_contact_input_pressure"),
      "source_report_contact_contention_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_contact_contention_review_pressure")
    }
  end
end
