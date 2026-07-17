defmodule OrbitalDynamics.Validation.CandidateRefreshFreshnessBudgetReplayFixtures do
  alias OrbitalDynamics.{CandidateRefresh, Validation}

  import OrbitalDynamics.Validation.CandidateRefreshContactReplayFixtures,
    only: [result_set: 1]

  def candidate_refresh_freshness_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_freshness_fixture())
  end

  def candidate_refresh_freshness_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_freshness_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_freshness_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-freshness-replay-challenge",
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
      "source_freshness_report" => [
        %{
          "schema_contract" => "freshness_report.v1",
          "status" => "stale",
          "stale_reasons" => [
            "accepted_snapshot_older_than_policy",
            "horizon_start_before_now"
          ],
          "provenance" => %{"trust_boundary" => "ops_freshness"}
        },
        %{
          "schema_contract" => "freshness_report.v1",
          "freshness_status" => "unknown",
          "unknown_reasons" => ["missing_generated_at"],
          "provenance" => %{"trust_boundary" => "ops_freshness"}
        }
      ]
    }
  end

  def candidate_refresh_refresh_budget_fixture_observations do
    "candidate_refresh.v1"
    |> Validation.artifact_observations(candidate_refresh_refresh_budget_fixture())
  end

  def candidate_refresh_refresh_budget_fixture do
    result_set(%{})
    |> CandidateRefresh.build(
      candidate_refresh: candidate_refresh_refresh_budget_request(),
      generated_at: ~U[2026-05-14 00:00:00Z]
    )
  end

  def candidate_refresh_refresh_budget_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-refresh-budget-replay-challenge",
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
      "source_refresh_budget_report" => [
        %{
          "schema_contract" => "refresh_budget_report.v1",
          "input_candidate_count" => 4,
          "kept_candidate_count" => 2,
          "dropped_candidate_count" => 2,
          "kept_candidate_ids" => ["candidate_a", "candidate_b"],
          "dropped_candidate_ids" => ["candidate_c", "candidate_d"],
          "provenance" => %{"trust_boundary" => "ops_refresh_budget"}
        },
        %{
          "schema_contract" => "refresh_budget_report.v1",
          "input_candidate_count" => 1,
          "kept_candidate_count" => 1,
          "dropped_candidate_count" => 0,
          "invalid_candidate_limit_policy" => true,
          "invalid_candidate_limit_policy_reason" => "max_candidate_activities_must_be_integer",
          "kept_candidate_ids" => ["candidate_e"],
          "dropped_candidate_ids" => [],
          "provenance" => %{"trust_boundary" => "ops_refresh_budget"}
        }
      ]
    }
  end
end
