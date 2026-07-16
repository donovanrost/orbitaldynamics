defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.DependencyFields.IdLists.FieldSpecs do
  @moduledoc false

  @id_list_fields [
    "impacted_source_activity_ids",
    "impacted_source_timeline_ids",
    "dependent_activity_ids",
    "dependent_timeline_ids",
    "source_dependent_activity_ids",
    "source_dependent_timeline_ids",
    "replacement_dependent_activity_ids",
    "replacement_dependent_timeline_ids",
    "impacted_dependency_activity_ids",
    "impacted_dependency_timeline_ids",
    "impacted_exclusive_with_activity_ids",
    "impacted_exclusive_with_timeline_ids"
  ]

  def id_list_fields, do: @id_list_fields
end
