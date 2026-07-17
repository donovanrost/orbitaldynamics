defmodule OrbitalDynamics.Validation.ReferenceFixtures.LinkCapacityArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.link_capacity_summary.v1" => %{
      "id" => "fixture.artifact.link_capacity_summary.v1",
      "model_id" => "artifact.link_capacity_summary.v1",
      "reference_case" => "checked-in link capacity summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/link_capacity_summary_v1.json",
        "contract" => "link_capacity_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "link_capacity_summary.v1",
        "model" => "artifact_only_link_capacity_summary",
        "source_artifact_type" => "link_capacity_report.v1",
        "station_count" => 1,
        "contact_count" => 1,
        "effective_contact_count" => 1,
        "ignored_contact_count" => 0,
        "selected_contact_count" => 1,
        "ignored_selected_contact_count" => 0,
        "required_downlink_contact_count" => 0,
        "actual_throughput_contact_count" => 1,
        "actual_completion_contact_count" => 0,
        "invalid_contact_input_count" => 0,
        "invalid_selected_contact_input_count" => 0,
        "invalid_policy_required_downlink_station_count" => 0,
        "downlink_requirement_status" => "satisfied",
        "actual_downlink_requirement_status" => "shortfall",
        "selection_utilization_status" => "fully_selected",
        "selected_downlink_shortfall_mb" => 0,
        "actual_downlink_shortfall_mb" => 10,
        "capacity_adjusted_throughput_mb" => 120,
        "selected_capacity_adjusted_throughput_mb" => 120,
        "unused_capacity_adjusted_throughput_mb" => 0,
        "contact_ids" => "science_downlink",
        "selected_contact_ids" => "science_downlink",
        "actual_throughput_contact_ids" => "science_downlink",
        "actual_completion_contact_ids" => "",
        "ground_station_ids" => "equator_prime",
        "selected_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["science_downlink"]
        },
        "actual_throughput_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["science_downlink"]
        },
        "actual_completion_contact_ids_by_ground_station_id" => %{},
        "capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "equator_prime" => 120
        },
        "selected_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "equator_prime" => 120
        },
        "unused_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "equator_prime" => 0
        },
        "model_limit_count" => 9,
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "assumption_source" => "link_capacity_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_link_budget_model" => true
      },
      "tolerances" => %{
        "station_count" => 0,
        "contact_count" => 0,
        "effective_contact_count" => 0,
        "ignored_contact_count" => 0,
        "selected_contact_count" => 0,
        "ignored_selected_contact_count" => 0,
        "required_downlink_contact_count" => 0,
        "actual_throughput_contact_count" => 0,
        "actual_completion_contact_count" => 0,
        "invalid_contact_input_count" => 0,
        "invalid_selected_contact_input_count" => 0,
        "invalid_policy_required_downlink_station_count" => 0,
        "selected_downlink_shortfall_mb" => 0,
        "actual_downlink_shortfall_mb" => 0,
        "capacity_adjusted_throughput_mb" => 0,
        "selected_capacity_adjusted_throughput_mb" => 0,
        "unused_capacity_adjusted_throughput_mb" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by link_capacity_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external link-budget validation",
        "checks compact contact, station, throughput routing, and no-provider-reservation/no-mutation boundaries only"
      ]
    },
    "fixture.artifact.link_capacity_report.v1" => %{
      "id" => "fixture.artifact.link_capacity_report.v1",
      "model_id" => "artifact.link_capacity_report.v1",
      "reference_case" => "checked-in link capacity artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/link_capacity_report_v1.json",
        "contract" => "link_capacity_report.v1"
      },
      "expected" => %{
        "schema_contract" => "link_capacity_report.v1",
        "model" => "fixed_rate_downlink_capacity_summary",
        "contact_count" => 1,
        "row_derived_contact_count" => 1,
        "effective_contact_count" => 1,
        "row_derived_effective_contact_count" => 1,
        "row_count" => 1,
        "selected_contact_count" => 0,
        "row_derived_selected_contact_count" => 0,
        "ignored_contact_count" => 0,
        "row_derived_ignored_contact_count" => 0,
        "ignored_selected_contact_count" => 0,
        "row_derived_ignored_selected_contact_count" => 0,
        "row_derived_required_downlink_contact_count" => 0,
        "row_derived_actual_throughput_contact_count" => 0,
        "row_derived_actual_completion_contact_count" => 0,
        "unmatched_selected_contact_count" => 0,
        "ambiguous_selected_contact_id_count" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "capacity_adjusted_throughput_mb" => 172.71212086982393,
        "estimated_throughput_mb" => 345.42424173964787,
        "selected_capacity_adjusted_throughput_mb" => 0.0,
        "selected_estimated_throughput_mb" => 0.0,
        "unused_capacity_adjusted_throughput_mb" => 172.71212086982393,
        "selection_utilization_status" => "unselected_capacity",
        "station_count" => 1,
        "stations_by_selection_utilization_status" => %{
          "unselected_capacity" => ["equator_prime"]
        },
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "contact_count" => 0,
        "row_derived_contact_count" => 0,
        "effective_contact_count" => 0,
        "row_derived_effective_contact_count" => 0,
        "row_count" => 0,
        "selected_contact_count" => 0,
        "row_derived_selected_contact_count" => 0,
        "ignored_contact_count" => 0,
        "row_derived_ignored_contact_count" => 0,
        "ignored_selected_contact_count" => 0,
        "row_derived_ignored_selected_contact_count" => 0,
        "row_derived_required_downlink_contact_count" => 0,
        "row_derived_actual_throughput_contact_count" => 0,
        "row_derived_actual_completion_contact_count" => 0,
        "unmatched_selected_contact_count" => 0,
        "ambiguous_selected_contact_id_count" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "capacity_adjusted_throughput_mb" => 0.0,
        "estimated_throughput_mb" => 0.0,
        "selected_capacity_adjusted_throughput_mb" => 0.0,
        "selected_estimated_throughput_mb" => 0.0,
        "unused_capacity_adjusted_throughput_mb" => 0.0,
        "station_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external link-budget validation",
        "checks fixed-rate link-capacity counts, throughput totals, station routing, and model-limit boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
