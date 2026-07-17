defmodule OrbitalDynamics.Validation.CandidateRefreshPlanningFeedbackReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [result_set: 1]

  def candidate_refresh_objective_gap_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_objective_gap_fixture())
  end

  def candidate_refresh_objective_gap_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_objective_gap_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_objective_gap_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-objective-gap-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_objective_satisfaction_report" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => [
          %{
            "gap_id" => "gap_downlink",
            "objective_type" => "downlink_completion",
            "status" => "unmet",
            "ground_station_id" => "equator_prime",
            "missing_downlink_mb" => 20.0,
            "source_activity_id" => "dl_gap_activity",
            "trust_boundary" => "objective_gap_rows"
          },
          %{
            "gap_id" => "gap_target",
            "objective_type" => "target_coverage",
            "status" => "partial",
            "target_id" => "target_a",
            "missing_revisits" => 1,
            "source_activity_id" => "target_gap_activity",
            "trust_boundary" => "objective_gap_rows"
          },
          %{
            "gap_id" => "gap_latency",
            "objective_type" => "collection_latency",
            "status" => "partial",
            "collection_id" => "collection_alpha",
            "max_latency_s" => 600.0,
            "missed_downlink_activity_ids" => ["collection_latency_activity"],
            "trust_boundary" => "objective_gap_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_objective_activity" => 99},
        "provenance" => %{"trust_boundary" => "objective_gap_report"}
      },
      "source_objective_tradeoff_report" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => [
          %{
            "tradeoff_id" => "tradeoff_downlink",
            "required_downlink_mb" => 20.0,
            "ground_station_id" => "equator_prime",
            "activity_ids" => ["tradeoff_downlink_activity"],
            "trust_boundary" => "objective_gap_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "tradeoff_target",
            "target_id" => "target_a",
            "required_revisits" => 1.0,
            "source_activity_ids" => ["tradeoff_target_activity"],
            "trust_boundary" => "objective_gap_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "tradeoff_latency",
            "collection_id" => "collection_alpha",
            "collection_latency_gap_s" => 300.0,
            "source_activity_id" => "tradeoff_latency_activity",
            "trust_boundary" => "objective_gap_tradeoff_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_tradeoff_activity" => 99},
        "provenance" => %{"trust_boundary" => "objective_gap_tradeoff_report"}
      },
      "source_score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "rows" => [
          %{
            "term_key" => "downlink_shortfall_mb",
            "value" => 20.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "score_downlink_activity",
            "trust_boundary" => "objective_gap_score_rows"
          },
          %{
            "term_key" => "target_gap_count",
            "value" => 1.0,
            "target_id" => "target_a",
            "source_activity_id" => "score_target_activity",
            "trust_boundary" => "objective_gap_score_rows"
          },
          %{
            "term_key" => "collection_latency_gap_s",
            "value" => 300.0,
            "collection_id" => "collection_alpha",
            "selected_contact" => %{"contact_id" => "score_collection_activity"},
            "trust_boundary" => "objective_gap_score_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_score_activity" => 99},
        "provenance" => %{"trust_boundary" => "objective_gap_score_report"}
      }
    }
  end

  def candidate_refresh_constraint_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_constraint_fixture())
  end

  def candidate_refresh_constraint_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_constraint_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_constraint_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-constraint-replay-challenge",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [],
        "source" => %{"system" => "validation_challenge"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "validation_fixture"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [],
      "constraints" => %{},
      "scoring_policy" => %{},
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "source_constraint_report" => %{
        "schema_contract" => "constraint_report.v1",
        "rows" => [
          %{
            "constraint_id" => "downlink_shortfall",
            "metric" => "selected_downlink_shortfall_mb",
            "status" => "warning",
            "value" => 40.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "constraint_downlink_activity",
            "trust_boundary" => "constraint_replay_rows"
          },
          %{
            "constraint_id" => "battery_margin",
            "metric" => "battery_margin",
            "status" => "fail",
            "value" => -0.2,
            "resource_id" => "battery_1",
            "spacecraft_id" => "sat_1",
            "activity_ids" => ["constraint_battery_activity"],
            "trust_boundary" => "constraint_replay_rows"
          },
          %{
            "constraint_id" => "storage_margin",
            "metric" => "storage_margin",
            "status" => "warning",
            "value" => -0.1,
            "resource_id" => "storage_1",
            "spacecraft_id" => "sat_1",
            "activity_id" => "constraint_storage_activity",
            "trust_boundary" => "constraint_replay_rows"
          }
        ],
        "provenance" => %{"trust_boundary" => "constraint_replay_report"}
      }
    }
  end
end
