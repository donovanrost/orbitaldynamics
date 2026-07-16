defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.GroupedIds.RouteSpecs do
  @moduledoc false

  alias __MODULE__.PairValues

  def specs do
    [
      {"candidate_ids_by_suppressed_reason", &PairValues.suppressed_reason_pairs/1,
       [
         "candidate_ids_by_suppressed_reason",
         "suppressed_candidate_ids_by_reason"
       ]},
      {"candidate_ids_by_spacecraft", &PairValues.spacecraft_pairs/1,
       [
         "candidate_ids_by_spacecraft",
         "suppressed_candidate_ids_by_spacecraft_id"
       ]},
      {"candidate_ids_by_resource", &PairValues.resource_pairs/1,
       [
         "candidate_ids_by_resource"
       ]},
      {"candidate_ids_by_blocking_dimension", &PairValues.blocking_dimension_pairs/1,
       [
         "candidate_ids_by_blocking_dimension",
         "suppressed_candidate_ids_by_resource_blocking_dimension"
       ]}
    ]
  end
end
