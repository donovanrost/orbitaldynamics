defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.CountFields.CountMapSpecs do
  @moduledoc false

  def all do
    [
      {"timeline_integrity_status_counts", "timeline_integrity_status_counts",
       "timeline_integrity_status"},
      {"required_operator_action_counts", "required_operator_action_counts",
       "required_operator_action"},
      {"operator_action_reason_counts", "operator_action_reason_counts", "operator_action_reason"}
    ]
  end
end
