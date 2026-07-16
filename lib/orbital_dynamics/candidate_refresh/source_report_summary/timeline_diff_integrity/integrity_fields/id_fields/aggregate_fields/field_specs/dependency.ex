defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.AggregateFields.FieldSpecs.Dependency do
  @moduledoc false

  def all do
    [
      {"missing_dependency_activity_id_counts",
       ["missing_dependency_activity_ids", "missing_dependency_activity_id"]},
      {"missing_dependency_timeline_id_counts",
       ["missing_dependency_timeline_ids", "missing_dependency_timeline_id"]},
      {"self_dependency_activity_id_counts",
       ["self_dependency_activity_ids", "self_dependency_activity_id"]},
      {"self_dependency_timeline_id_counts",
       ["self_dependency_timeline_ids", "self_dependency_timeline_id"]},
      {"dependency_cycle_activity_id_counts",
       ["dependency_cycle_activity_ids", "dependency_cycle_activity_id"]},
      {"dependency_cycle_timeline_id_counts",
       ["dependency_cycle_timeline_ids", "dependency_cycle_timeline_id"]},
      {"dependency_order_violation_activity_id_counts",
       ["dependency_order_violation_activity_ids", "dependency_order_violation_activity_id"]},
      {"dependency_order_violation_timeline_id_counts",
       ["dependency_order_violation_timeline_ids", "dependency_order_violation_timeline_id"]}
    ]
  end
end
