defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields.FieldSpecs do
  @moduledoc false

  @numeric_count_fields [
    "source_activity_count",
    "replacement_activity_count",
    "changed_source_activity_count",
    "changed_source_timeline_count"
  ]

  def numeric_count_fields, do: @numeric_count_fields
end
