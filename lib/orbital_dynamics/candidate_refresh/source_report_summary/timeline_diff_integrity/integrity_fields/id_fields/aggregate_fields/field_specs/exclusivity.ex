defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.AggregateFields.FieldSpecs.Exclusivity do
  @moduledoc false

  def all do
    [
      {"exclusivity_violation_activity_id_counts",
       ["exclusivity_violation_activity_ids", "exclusivity_violation_activity_id"]},
      {"exclusivity_violation_timeline_id_counts",
       ["exclusivity_violation_timeline_ids", "exclusivity_violation_timeline_id"]},
      {"exclusivity_violation_group_counts",
       ["exclusivity_violation_groups", "exclusivity_violation_group"]}
    ]
  end
end
