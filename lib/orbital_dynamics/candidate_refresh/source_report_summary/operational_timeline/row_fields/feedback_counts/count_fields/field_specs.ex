defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.FeedbackCounts.CountFields.FieldSpecs do
  @moduledoc false

  @count_fields [
    {"contact_feedback_count", :contact_count},
    {"command_feedback_count", :command_count},
    {"maneuver_feedback_count", :maneuver_count},
    {"observation_feedback_count", :observation_count},
    {"station_throughput_feedback_count", :station_throughput_count}
  ]

  def count_fields, do: @count_fields
end
