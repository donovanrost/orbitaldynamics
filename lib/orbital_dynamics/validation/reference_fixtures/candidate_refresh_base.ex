defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshBase do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.v1" => %{
      "id" => "fixture.artifact.candidate_refresh.v1",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" => "checked-in candidate refresh artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 2,
        "contact_intent_count" => 1,
        "access_window_count" => 1,
        "target_visibility_window_count" => 1,
        "eclipse_interval_count" => 0,
        "warning_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "warning_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks candidate-refresh product counts and source-report provenance counts only"
      ]
    },
    "fixture.artifact.candidate_refresh.resource_provenance_v1" => %{
      "id" => "fixture.artifact.candidate_refresh.resource_provenance_v1",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" => "checked-in candidate refresh resource provenance artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_refresh_resource_provenance_v1.json",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 1,
        "target_visibility_window_count" => 1,
        "eclipse_interval_count" => 0,
        "warning_count" => 3,
        "source_report_family_count" => 2,
        "source_report_row_count" => 7
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "warning_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks branch-local source-report provenance counts, not full refresh viability"
      ]
    }
  }

  def all, do: @fixtures
end
