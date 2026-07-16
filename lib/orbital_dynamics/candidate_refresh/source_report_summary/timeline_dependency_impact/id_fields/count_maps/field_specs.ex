defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.IdFields.CountMaps.FieldSpecs do
  @moduledoc false

  alias __MODULE__.RowUniqueFields

  def count_fields do
    [
      {"impacted_source_activity_id_counts",
       ["impacted_source_activity_ids", "impacted_source_activity_id"]},
      {"impacted_source_timeline_id_counts",
       ["impacted_source_timeline_ids", "impacted_source_timeline_id"]},
      {"impacted_dependency_activity_id_counts",
       ["impacted_dependency_activity_ids", "impacted_dependency_activity_id"]},
      {"impacted_dependency_timeline_id_counts",
       ["impacted_dependency_timeline_ids", "impacted_dependency_timeline_id"]},
      {"impacted_exclusive_activity_id_counts",
       [
         "impacted_exclusive_with_activity_ids",
         "impacted_exclusive_activity_ids",
         "impacted_exclusive_activity_id"
       ]},
      {"impacted_exclusive_timeline_id_counts",
       [
         "impacted_exclusive_with_timeline_ids",
         "impacted_exclusive_timeline_ids",
         "impacted_exclusive_timeline_id"
       ]}
    ]
  end

  defdelegate row_unique_count_fields, to: RowUniqueFields, as: :fields
end
