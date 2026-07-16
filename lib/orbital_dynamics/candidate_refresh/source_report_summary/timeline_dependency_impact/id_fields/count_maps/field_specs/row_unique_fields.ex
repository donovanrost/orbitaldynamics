defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.IdFields.CountMaps.FieldSpecs.RowUniqueFields do
  @moduledoc false

  def fields do
    [
      {"dependent_activity_id_counts",
       [
         "dependent_activity_ids",
         "source_dependent_activity_ids",
         "replacement_dependent_activity_ids",
         "activity_id"
       ]},
      {"dependent_timeline_id_counts",
       [
         "dependent_timeline_ids",
         "source_dependent_timeline_ids",
         "replacement_dependent_timeline_ids",
         "timeline_id"
       ]}
    ]
  end
end
