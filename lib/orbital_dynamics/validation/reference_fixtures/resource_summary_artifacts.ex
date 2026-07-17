defmodule OrbitalDynamics.Validation.ReferenceFixtures.ResourceSummaryArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.resource_summary.v1" => %{
      "id" => "fixture.artifact.resource_summary.v1",
      "model_id" => "artifact.resource_summary.v1",
      "reference_case" => "checked-in planning resource summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_summary_v1.json",
        "contract" => "resource_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_summary.v1",
        "spacecraft_id" => "leo_1",
        "mode" => "degraded",
        "fuel_margin" => 0.82,
        "power_margin" => 0.74,
        "battery_capacity_wh" => 1200.0,
        "battery_energy_used_wh" => 312.0,
        "battery_state_of_charge" => 0.74,
        "thermal_margin_c" => -2.5,
        "storage_capacity_mb" => 1000.0,
        "storage_used_mb" => 250.0,
        "storage_margin" => 0.75,
        "downlink_capacity_mb" => 600.0,
        "downlink_margin" => 0.65,
        "spacecraft_available" => false,
        "payload_available" => false,
        "antenna_available" => true,
        "degraded" => true,
        "source_quality" => "operator_supplied",
        "trust_boundary" => "operator_declared_resource_summary",
        "suppressed_activity_type_count" => 2,
        "suppressed_activity_type_order" => "observe|command",
        "incompatible_activity_type_count" => 2,
        "incompatible_activity_type_order" => "command|health_check",
        "assumption_source" => "campaign_manifest_demo",
        "provenance_source" => "ops"
      },
      "tolerances" => %{
        "fuel_margin" => 0.0,
        "power_margin" => 0.0,
        "battery_capacity_wh" => 0.0,
        "battery_energy_used_wh" => 0.0,
        "battery_state_of_charge" => 0.0,
        "thermal_margin_c" => 0.0,
        "storage_capacity_mb" => 0.0,
        "storage_used_mb" => 0.0,
        "storage_margin" => 0.0,
        "downlink_capacity_mb" => 0.0,
        "downlink_margin" => 0.0,
        "suppressed_activity_type_count" => 0,
        "incompatible_activity_type_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks resource-summary normalization, derived margins, availability flags, and provenance boundaries only"
      ]
    },
    "fixture.artifact.resource_filter_report.v1" => %{
      "id" => "fixture.artifact.resource_filter_report.v1",
      "model_id" => "artifact.resource_filter_report.v1",
      "reference_case" => "checked-in resource filter artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_filter_report_v1.json",
        "contract" => "resource_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 2,
        "suppressed_candidate_row_count" => 2,
        "invalid_candidate_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "resource_source_quality_counts" => %{"operator_supplied" => 1},
        "resource_trust_boundary_status_counts" => %{"missing" => 1},
        "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
        "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
        "suppressed_reason_counts" => %{
          "downlink_margin_below_policy" => 1,
          "storage_margin_below_observe_policy" => 1
        },
        "suppressed_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
        "suppressed_candidate_ids_by_blocking_dimension" => %{
          "downlink" => ["leo_1_downlink_equator_prime_1"],
          "storage" => ["leo_1_observe_target_a_1"]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "invalid_candidate_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not subsystem simulation validation",
        "checks resource filter counts, suppression routing maps, trust-boundary maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.resource_filter_summary.v1" => %{
      "id" => "fixture.artifact.resource_filter_summary.v1",
      "model_id" => "artifact.resource_filter_summary.v1",
      "reference_case" => "checked-in resource filter summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_filter_summary_v1.json",
        "contract" => "resource_filter_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_summary.v1",
        "model" => "artifact_only_resource_filter_summary",
        "source_artifact_type" => "resource_filter_report.v1",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 2,
        "suppression_review_status" => "review_required",
        "suppressed_candidate_ids" => "leo_1_downlink_equator_prime_1|leo_1_observe_target_a_1",
        "suppressed_reason_counts" => %{
          "downlink_margin_below_policy" => 1,
          "storage_margin_below_observe_policy" => 1
        },
        "suppressed_candidate_ids_by_reason" => %{
          "downlink_margin_below_policy" => ["leo_1_downlink_equator_prime_1"],
          "storage_margin_below_observe_policy" => ["leo_1_observe_target_a_1"]
        },
        "resource_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
        "suppressed_candidate_ids_by_resource_blocking_dimension" => %{
          "downlink" => ["leo_1_downlink_equator_prime_1"],
          "storage" => ["leo_1_observe_target_a_1"]
        },
        "suppressed_candidate_ids_by_scenario_id" => %{
          "leo_1" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
        },
        "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
        "suppressed_candidate_ids_by_resource_source_quality" => %{
          "operator_supplied" => [
            "leo_1_downlink_equator_prime_1",
            "leo_1_observe_target_a_1"
          ]
        },
        "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
        "suppressed_candidate_ids_by_resource_trust_boundary_status" => %{
          "missing" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
        },
        "invalid_candidate_input_count" => 0,
        "invalid_candidate_input_ids" => "",
        "invalid_resource_summary_input_count" => 0,
        "invalid_resource_summary_input_ids" => "",
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "review_row_count" => 2,
        "review_row_ids" => "leo_1_observe_target_a_1|leo_1_downlink_equator_prime_1",
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "assumption_source" => "resource_filter_report.v1",
        "operator_authority" => "not_granted_by_resource_filter_summary",
        "resource_state_propagation" => "not_performed",
        "no_schedule_mutation" => true,
        "no_resource_time_propagation" => true,
        "no_subsystem_simulation" => true
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "invalid_candidate_input_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "review_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by resource_filter_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not subsystem simulation validation",
        "checks compact suppression counts, routing maps, review rows, and no-mutation/no-propagation boundaries only"
      ]
    }
  }

  def all, do: @fixtures
end
