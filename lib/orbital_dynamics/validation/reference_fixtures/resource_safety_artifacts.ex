defmodule OrbitalDynamics.Validation.ReferenceFixtures.ResourceSafetyArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" =>
        "checked-in Cadence import resource-projection battery handoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/cadence_import_resource_projection_battery_handoff_v1.json",
        "contract" => "cadence_import_manifest.v1",
        "source_contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "model" => "artifact_only_cadence_import_manifest",
        "source_artifact_type" => "resource_projection_report.v1",
        "row_count" => 1,
        "review_required_count" => 1,
        "source_review_type_counts" => %{"resource_projection_review" => 1},
        "import_action_counts" => %{"review_resource_projection" => 1},
        "resource_projection_battery_handoff_count" => 1,
        "source_review_battery_handoff_count" => 1,
        "total_resource_projection_battery_energy_consumed_wh" => 23.0,
        "total_resource_projection_battery_energy_generated_wh" => 8.0,
        "net_resource_projection_battery_energy_delta_wh" => 15.0,
        "peak_resource_projection_battery_overuse_wh" => 4.0,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "review_required_count" => 0,
        "resource_projection_battery_handoff_count" => 0,
        "source_review_battery_handoff_count" => 0,
        "total_resource_projection_battery_energy_consumed_wh" => 0.0,
        "total_resource_projection_battery_energy_generated_wh" => 0.0,
        "net_resource_projection_battery_energy_delta_wh" => 0.0,
        "peak_resource_projection_battery_overuse_wh" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks resource-projection battery handoff routing and no-write boundary only"
      ]
    },
    "fixture.artifact.resource_projection_report.battery_handoff_v1" => %{
      "id" => "fixture.artifact.resource_projection_report.battery_handoff_v1",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "checked-in resource projection battery handoff source artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_battery_handoff_v1.json",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_battery_handoff_resource_projection_fixture",
        "activity_count" => 2,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 2,
        "storage_overflow_row_count" => 1,
        "downlink_shortfall_row_count" => 1,
        "total_battery_energy_consumed_wh" => 23.0,
        "total_battery_energy_generated_wh" => 8.0,
        "net_battery_energy_delta_wh" => 15.0,
        "peak_battery_overuse_wh" => 4.0,
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "activity_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "total_battery_energy_consumed_wh" => 0.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 0.0,
        "peak_battery_overuse_wh" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks battery flow aggregation source values for review/import handoff fixtures only"
      ]
    },
    "fixture.artifact.resource_projection_report.stale_resource_summary_margins" => %{
      "id" => "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "generated stale derived-margin resource projection challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_resource_projection_stale_derived_margin_fixture",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_stale_derived_margin_resource_projection_fixture",
        "activity_count" => 1,
        "input_resource_summary_count" => 3,
        "valid_resource_summary_count" => 1,
        "invalid_activity_input_count" => 0,
        "invalid_resource_summary_input_count" => 2,
        "invalid_resource_summary_input_ids" => "leo_2|leo_3",
        "invalid_resource_summary_input_reasons" =>
          "stale_battery_state_of_charge|stale_storage_margin",
        "stale_battery_state_of_charge_count" => 1,
        "stale_storage_margin_count" => 1,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 1,
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "activity_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_activity_input_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "stale_battery_state_of_charge_count" => 0,
        "stale_storage_margin_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external resource-model validation",
        "checks stale explicit battery and storage derived-margin evidence is preserved for review"
      ]
    },
    "fixture.artifact.resource_filter_report.stale_resource_summary_margins" => %{
      "id" => "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
      "model_id" => "artifact.resource_filter_report.v1",
      "reference_case" => "generated stale derived-margin resource filter challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_resource_filter_stale_derived_margin_fixture",
        "contract" => "resource_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "input_resource_summary_count" => 2,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 2,
        "invalid_resource_summary_input_ids" => "sat_1|sat_2",
        "invalid_resource_summary_input_reasons" =>
          "stale_battery_state_of_charge|stale_storage_margin",
        "stale_battery_state_of_charge_count" => 1,
        "stale_storage_margin_count" => 1,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "stale_battery_state_of_charge_count" => 0,
        "stale_storage_margin_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not subsystem simulation validation",
        "checks stale explicit battery and storage derived-margin evidence does not suppress candidates"
      ]
    },
    "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1" => %{
      "id" => "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" =>
        "checked-in operator-review resource-projection battery handoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operator_review_resource_projection_battery_handoff_v1.json",
        "contract" => "operator_review_package.v1",
        "source_contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 1,
        "resource_projection_review_count" => 1,
        "resource_projection_battery_handoff_count" => 1,
        "total_resource_projection_battery_energy_consumed_wh" => 23.0,
        "total_resource_projection_battery_energy_generated_wh" => 8.0,
        "net_resource_projection_battery_energy_delta_wh" => 15.0,
        "peak_resource_projection_battery_overuse_wh" => 4.0
      },
      "tolerances" => %{
        "review_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_projection_battery_handoff_count" => 0,
        "total_resource_projection_battery_energy_consumed_wh" => 0.0,
        "total_resource_projection_battery_energy_generated_wh" => 0.0,
        "net_resource_projection_battery_energy_delta_wh" => 0.0,
        "peak_resource_projection_battery_overuse_wh" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-projection battery handoff row aggregation only"
      ]
    }
  }

  def all, do: @fixtures
end
