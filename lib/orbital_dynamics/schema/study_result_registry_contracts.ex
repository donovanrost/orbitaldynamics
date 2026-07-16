defmodule OrbitalDynamics.Schema.StudyResultRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "study_benchmark.v1" => %{
        "schema_contract" => "study_benchmark.v1",
        "artifact_family" => "study_benchmark",
        "schema_version" => 1,
        "required_fields" => [
          "schema_version",
          "generated_at",
          "manifest",
          "benchmark_options",
          "results"
        ],
        "optional_fields" => ["schema_contract", "model_limits"],
        "nested_contracts" => []
      },
      "manifest_field_reference.v1" => %{
        "schema_contract" => "manifest_field_reference.v1",
        "artifact_family" => "manifest_field_reference",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "reference_mode",
          "schema_version",
          "field_count",
          "fields",
          "top_level_required",
          "activation_sections",
          "supported",
          "lint_command",
          "schema_export_command"
        ],
        "optional_fields" => [
          "compatibility_policy_version",
          "identity_policy_version",
          "identity_policy"
        ],
        "nested_contracts" => []
      },
      "result_artifact.v1" => %{
        "schema_contract" => "result_artifact.v1",
        "artifact_family" => "result_artifact",
        "schema_version" => 1,
        "required_fields" => [
          "schema_version",
          "generated_at",
          "study_id",
          "run",
          "assumptions",
          "metadata",
          "trajectories",
          "access_windows",
          "eclipse_intervals",
          "target_visibility_windows",
          "ground_track_crossings",
          "errors",
          "execution_report",
          "payload_metrics"
        ],
        "optional_fields" => [
          "maneuver_recommendations",
          "campaign_plan",
          "candidate_refresh",
          "monte_carlo_reproducibility_report",
          "constraint_report",
          "maneuver_review_report"
        ],
        "nested_contracts" => [
          "execution_report.v1",
          "maneuver_recommendation.v1",
          "maneuver_review_report.v1",
          "monte_carlo_reproducibility_report.v1",
          "constraint_report.v1"
        ]
      }
    }
  end
end
