defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFreshnessBudget do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.freshness_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.freshness_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of freshness source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_freshness_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 2,
        "source_freshness_report_count" => 2,
        "source_freshness_row_count" => 2,
        "source_freshness_path_keys" => "source_freshness_report[0]|source_freshness_report[1]",
        "source_freshness_status_counts" => %{
          "stale" => 1,
          "unknown" => 1
        },
        "source_freshness_stale_reason_count" => 2,
        "source_freshness_stale_reason_keys" =>
          "accepted_snapshot_older_than_policy|horizon_start_before_now",
        "source_freshness_stale_reason_counts" => %{
          "accepted_snapshot_older_than_policy" => 1,
          "horizon_start_before_now" => 1
        },
        "source_freshness_unknown_reason_count" => 1,
        "source_freshness_unknown_reason_keys" => "missing_generated_at",
        "source_freshness_unknown_reason_counts" => %{"missing_generated_at" => 1},
        "source_freshness_trust_boundary_status" => "declared",
        "source_freshness_branch_local_stale_pressure" => true,
        "source_freshness_branch_local_unknown_pressure" => true,
        "source_freshness_branch_local_freshness_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_freshness_report_count" => 0,
        "source_freshness_row_count" => 0,
        "source_freshness_stale_reason_count" => 0,
        "source_freshness_unknown_reason_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not freshness policy validation",
        "checks candidate-refresh replay of freshness provenance without refresh mutation, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.refresh_budget_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.refresh_budget_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of refresh-budget source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_refresh_budget_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 2,
        "source_refresh_budget_report_count" => 2,
        "source_refresh_budget_row_count" => 2,
        "source_refresh_budget_path_keys" =>
          "source_refresh_budget_report[0]|source_refresh_budget_report[1]",
        "source_refresh_budget_input_candidate_count" => 5,
        "source_refresh_budget_kept_candidate_count" => 3,
        "source_refresh_budget_dropped_candidate_count" => 2,
        "source_refresh_budget_invalid_candidate_limit_policy_count" => 1,
        "source_refresh_budget_invalid_candidate_limit_policy_reason_counts" => %{
          "max_candidate_activities_must_be_integer" => 1
        },
        "source_refresh_budget_kept_candidate_id_keys" => "candidate_a|candidate_b|candidate_e",
        "source_refresh_budget_dropped_candidate_id_keys" => "candidate_c|candidate_d",
        "source_refresh_budget_trust_boundary_status" => "declared",
        "source_refresh_budget_branch_local_budget_pressure" => true,
        "source_refresh_budget_branch_local_dropped_candidate_pressure" => true,
        "source_refresh_budget_branch_local_invalid_limit_pressure" => true,
        "source_refresh_budget_branch_local_candidate_limit_applied" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_refresh_budget_report_count" => 0,
        "source_refresh_budget_row_count" => 0,
        "source_refresh_budget_input_candidate_count" => 0,
        "source_refresh_budget_kept_candidate_count" => 0,
        "source_refresh_budget_dropped_candidate_count" => 0,
        "source_refresh_budget_invalid_candidate_limit_policy_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not refresh-budget policy validation",
        "checks candidate-refresh replay of refresh-budget provenance without refresh mutation, import approval, or Cadence writes"
      ]
    }
  }

  def all, do: @fixtures
end
