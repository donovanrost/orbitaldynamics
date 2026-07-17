defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateStateArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_rejection_report.v1" => %{
      "id" => "fixture.artifact.candidate_rejection_report.v1",
      "model_id" => "artifact.candidate_rejection_report.v1",
      "reference_case" => "checked-in candidate rejection explanation report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_rejection_report_v1.json",
        "contract" => "candidate_rejection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "model" => "artifact_only_candidate_rejection_explanation",
        "source" => "candidate_refresh",
        "candidate_count" => 4,
        "row_count" => 4,
        "rejected_count" => 3,
        "not_rejected_count" => 1,
        "invalid_candidate_input_count" => 1,
        "reviewable_count" => 3,
        "rejection_reason_family_count" => 8,
        "required_operator_review_count" => 3,
        "rejected_candidate_id_order" => "dl_reserved|missing_activity_id:4|obs_clouded",
        "reviewable_candidate_id_order" => "dl_reserved|missing_activity_id:4|obs_clouded",
        "invalid_candidate_input_id_order" => "missing_activity_id:4",
        "station_reserved_candidate_ids" => "dl_reserved",
        "declared_rejection_candidate_ids" => "obs_clouded",
        "no_target_visibility_candidate_ids" => "obs_clouded",
        "contact_too_short_count" => 1,
        "station_reserved_count" => 1,
        "quality_gate_failed_count" => 1,
        "invalid_candidate_input_reason_count" => 1,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "candidate_count" => 0,
        "row_count" => 0,
        "rejected_count" => 0,
        "not_rejected_count" => 0,
        "invalid_candidate_input_count" => 0,
        "reviewable_count" => 0,
        "rejection_reason_family_count" => 0,
        "required_operator_review_count" => 0,
        "contact_too_short_count" => 0,
        "station_reserved_count" => 0,
        "quality_gate_failed_count" => 0,
        "invalid_candidate_input_reason_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks candidate-rejection counts, reason routing, review action counts, and no-execution model limits only"
      ]
    },
    "fixture.artifact.candidate_diff_row.v1" => %{
      "id" => "fixture.artifact.candidate_diff_row.v1",
      "model_id" => "artifact.candidate_diff_row.v1",
      "reference_case" => "checked-in semantic candidate diff row artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_diff_row_v1.json",
        "contract" => "candidate_diff_row.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_diff_row.v1",
        "id" => "leo_1_observe_target_a_1",
        "type" => "observe",
        "scenario_id" => "leo_1",
        "diff_reason" => "semantically_similar_prior_candidate_changed",
        "matched_prior_candidate_id" => "old_candidate",
        "source_window_id" => "window:leo_1:target_visibility:target_a:1",
        "changed_field_count" => 3,
        "changed_field_order" => "ends_at_s|source_window_id|starts_at_s",
        "candidate_diff_changed_field_count" => 3,
        "candidate_diff_changed_field_order" => "ends_at_s|source_window_id|starts_at_s",
        "semantic_change_reason_count" => 3,
        "semantic_change_reason_order" =>
          "starts_at_s_changed|ends_at_s_changed|source_window_id_changed",
        "semantic_change_detail_count" => 3,
        "target_id" => "target_a",
        "source_target_id" => "target_a",
        "target_priority" => 12,
        "target_priority_source" => "candidate_refresh.objectives.observation_priority",
        "target_priority_objective_type" => "urgent_target",
        "target_priority_objective_count" => 1
      },
      "tolerances" => %{
        "changed_field_count" => 0,
        "candidate_diff_changed_field_count" => 0,
        "semantic_change_reason_count" => 0,
        "semantic_change_detail_count" => 0,
        "target_priority" => 0,
        "target_priority_objective_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external candidate scoring validation",
        "checks one semantic candidate-diff row and target-priority metadata only"
      ]
    }
  }

  def all, do: @fixtures
end
