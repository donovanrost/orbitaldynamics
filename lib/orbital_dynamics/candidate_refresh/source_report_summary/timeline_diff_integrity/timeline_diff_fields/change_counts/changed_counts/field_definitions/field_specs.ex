defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.ChangedCounts.FieldDefinitions.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.FeedbackCounts.RowCountValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.ObjectiveCounts

  def all do
    [
      {"changed_downlink_shortfall_count", "source_changed_downlink_shortfall_count",
       &RowCountValues.changed_downlink_shortfall_count/1},
      {"changed_contact_feedback_count", "source_changed_contact_feedback_count",
       &RowCountValues.changed_contact_feedback_count/1},
      {"changed_observation_count", "source_changed_observation_count",
       &ObjectiveCounts.changed_observation_count/1},
      {"changed_observation_quality_feedback_count",
       "source_changed_observation_quality_feedback_count",
       &RowCountValues.changed_observation_quality_feedback_count/1},
      {"changed_command_feedback_count", "source_changed_command_feedback_count",
       &RowCountValues.changed_command_feedback_count/1},
      {"changed_maneuver_feedback_count", "source_changed_maneuver_feedback_count",
       &RowCountValues.changed_maneuver_feedback_count/1}
    ]
  end
end
