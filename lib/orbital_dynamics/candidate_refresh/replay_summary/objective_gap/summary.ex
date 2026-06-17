defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.Summary do
  @moduledoc false

  alias __MODULE__.Helpers
  alias __MODULE__.Values

  def summary(satisfaction_summary, tradeoff_summary, score_term_summary) do
    values = Values.values(satisfaction_summary, tradeoff_summary, score_term_summary)

    %{
      "model" => "artifact_only_candidate_refresh_objective_gap_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.objective_gap_reports",
      "contracts" => values.contracts,
      "source_report_count" => values.source_report_count,
      "source_report_row_count" => values.source_report_row_count,
      "source_report_paths" => values.source_report_paths,
      "routed_gap_signal_count" => values.routed_gap_signal_count,
      "downlink_gap_row_count" => values.downlink_gap_count,
      "target_gap_row_count" => values.target_gap_count,
      "collection_latency_gap_row_count" => values.collection_latency_gap_count,
      "objective_satisfaction_gap_row_count" => values.satisfaction_gap_count,
      "objective_satisfaction_status_counts" => values.status_counts,
      "objective_satisfaction_objective_type_counts" => values.objective_type_counts,
      "objective_tradeoff_downlink_gap_row_count" => values.tradeoff_downlink_count,
      "objective_tradeoff_target_gap_row_count" => values.tradeoff_target_count,
      "objective_tradeoff_collection_latency_gap_row_count" => values.tradeoff_collection_count,
      "score_term_downlink_gap_row_count" => values.score_downlink_count,
      "score_term_target_gap_row_count" => values.score_target_count,
      "score_term_collection_latency_gap_row_count" => values.score_collection_count,
      "score_term_key_counts" => values.term_key_counts,
      "ground_station_counts" => values.ground_station_counts,
      "target_counts" => values.target_counts,
      "collection_counts" => values.collection_counts,
      "source_activity_id_counts" => values.source_activity_id_counts,
      "trust_boundary_status_counts" => values.trust_boundary_status_counts,
      "trust_boundaries" => values.trust_boundaries,
      "branch_local_objective_gap_pressure" => values.branch_local_objective_gap_pressure,
      "branch_local_downlink_gap_pressure" => values.branch_local_downlink_gap_pressure,
      "branch_local_target_gap_pressure" => values.branch_local_target_gap_pressure,
      "branch_local_collection_latency_gap_pressure" =>
        values.branch_local_collection_latency_gap_pressure,
      "branch_local_objective_status_pressure" => values.objective_status_pressure,
      "branch_local_score_term_pressure" => values.score_term_pressure,
      "branch_local_routing_pressure" => values.routing_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "objective_gap_source_report_provenance_only",
        "operator_authority" => "not_granted_by_objective_gap_replay_summary",
        "objective_generation" => "not_performed_by_summary",
        "score_recalculation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_objective_gap_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Helpers.compact_map()
  end
end
