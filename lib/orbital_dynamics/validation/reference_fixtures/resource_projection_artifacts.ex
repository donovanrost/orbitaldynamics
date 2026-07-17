defmodule OrbitalDynamics.Validation.ReferenceFixtures.ResourceProjectionArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.resource_projection_report.v1" => %{
      "id" => "fixture.artifact.resource_projection_report.v1",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "checked-in selected-activity resource projection artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_report_v1.json",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_campaign_selected_activity_resource_projection",
        "activity_count" => 1,
        "input_resource_summary_count" => 1,
        "valid_activity_count" => 1,
        "invalid_activity_input_count" => 0,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 1,
        "resource_pressure_row_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "projected_storage_overflow_mb_total" => 0.0,
        "projected_downlink_shortfall_mb_total" => 0.0,
        "warning_count" => 0,
        "model_limit_count" => 9,
        "resource_source_quality_counts" => %{"operator_supplied" => 1},
        "resource_trust_boundary_status_counts" => %{"missing" => 1}
      },
      "tolerances" => %{
        "activity_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "resource_pressure_row_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "projected_storage_overflow_mb_total" => 0.0,
        "projected_downlink_shortfall_mb_total" => 0.0,
        "warning_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks resource projection counts, pressure routing counts, and summary maps only"
      ]
    },
    "fixture.artifact.resource_projection_flow_summary.v1" => %{
      "id" => "fixture.artifact.resource_projection_flow_summary.v1",
      "model_id" => "artifact.resource_projection_flow_summary.v1",
      "reference_case" => "checked-in compact selected-activity resource-flow summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_flow_summary_v1.json",
        "contract" => "resource_projection_flow_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_flow_summary.v1",
        "model" => "artifact_only_selected_activity_resource_flow_summary",
        "source" => "campaign.resource_summaries",
        "activity_count" => 1,
        "valid_activity_count" => 1,
        "invalid_activity_input_count" => 0,
        "input_resource_summary_count" => 1,
        "valid_resource_summary_count" => 1,
        "invalid_resource_summary_input_count" => 0,
        "projected_resource_count" => 1,
        "flow_row_count" => 1,
        "resource_flow_status" => "clear",
        "resource_pressure_status" => "clear",
        "resource_pressure_count" => 0,
        "total_storage_produced_mb" => 0.0,
        "total_storage_limited_downlinked_mb" => 0.0,
        "total_downlink_shortfall_mb" => 0.0,
        "total_unused_downlink_capacity_mb" => 0.0,
        "total_battery_energy_consumed_wh" => 120.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 120.0,
        "peak_battery_overuse_wh" => 0.0,
        "total_projected_storage_remaining_mb" => 750.0,
        "minimum_projected_storage_remaining_mb" => 750.0,
        "total_projected_downlink_remaining_mb" => 600.0,
        "minimum_projected_downlink_remaining_mb" => 600.0,
        "ignored_activity_count" => 0,
        "ignored_activity_reason_counts" => %{},
        "resource_pressure_types" => [],
        "model_limit_count" => 9,
        "execution_boundary" => "artifact_only_no_schedule_mutation"
      },
      "tolerances" => %{
        "activity_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "projected_resource_count" => 0,
        "flow_row_count" => 0,
        "resource_pressure_count" => 0,
        "total_storage_produced_mb" => 0.0,
        "total_storage_limited_downlinked_mb" => 0.0,
        "total_downlink_shortfall_mb" => 0.0,
        "total_unused_downlink_capacity_mb" => 0.0,
        "total_battery_energy_consumed_wh" => 0.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 0.0,
        "peak_battery_overuse_wh" => 0.0,
        "total_projected_storage_remaining_mb" => 0.0,
        "minimum_projected_storage_remaining_mb" => 0.0,
        "total_projected_downlink_remaining_mb" => 0.0,
        "minimum_projected_downlink_remaining_mb" => 0.0,
        "ignored_activity_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks compact resource-flow row-derived storage, downlink, battery, and pressure evidence only"
      ]
    }
  }

  def all, do: @fixtures
end
