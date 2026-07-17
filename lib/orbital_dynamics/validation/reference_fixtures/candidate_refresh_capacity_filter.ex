defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshCapacityFilter do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.link_capacity_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.link_capacity_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of link-capacity source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_link_capacity_fixture",
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
        "source_link_capacity_report_count" => 1,
        "source_link_capacity_row_count" => 2,
        "source_link_capacity_selected_shortfall_row_count" => 1,
        "source_link_capacity_actual_shortfall_row_count" => 1,
        "source_link_capacity_actual_throughput_row_count" => 2,
        "source_link_capacity_capacity_adjusted_throughput_row_count" => 2,
        "source_link_capacity_capacity_adjusted_throughput_mb_total" => 85.0,
        "source_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 40.0,
        "source_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 45.0,
        "source_link_capacity_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 1
        },
        "source_link_capacity_spacecraft_counts" => %{"leo_1" => 1, "leo_2" => 1},
        "source_link_capacity_direction_counts" => %{
          "command" => 1,
          "downlink" => 1,
          "tracking" => 1
        },
        "source_link_capacity_downlink_requirement_status_counts" => %{
          "actual_met" => 1,
          "actual_shortfall" => 1,
          "selected_met" => 1,
          "selected_shortfall" => 1
        },
        "source_link_capacity_contact_ids_by_requirement_status" => %{
          "actual_met" => ["contact_alpha"],
          "actual_shortfall" => ["contact_gamma"],
          "selected_met" => ["contact_gamma"],
          "selected_shortfall" => ["contact_alpha", "contact_beta"]
        },
        "source_link_capacity_trust_boundary_status" => "declared",
        "source_link_capacity_branch_local_link_capacity_pressure" => true,
        "source_link_capacity_branch_local_capacity_adjusted_throughput_pressure" => true,
        "source_link_capacity_branch_local_downlink_shortfall_pressure" => true,
        "source_link_capacity_branch_local_actual_throughput_pressure" => true
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
        "source_link_capacity_report_count" => 0,
        "source_link_capacity_row_count" => 0,
        "source_link_capacity_selected_shortfall_row_count" => 0,
        "source_link_capacity_actual_shortfall_row_count" => 0,
        "source_link_capacity_actual_throughput_row_count" => 0,
        "source_link_capacity_capacity_adjusted_throughput_row_count" => 0,
        "source_link_capacity_capacity_adjusted_throughput_mb_total" => 0.0,
        "source_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 0.0,
        "source_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not link-budget or provider-capacity validation",
        "checks candidate-refresh replay of link-capacity provenance without contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.resource_filter_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.resource_filter_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of resource-filter source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_resource_filter_fixture",
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
        "source_report_row_count" => 4,
        "source_resource_filter_report_count" => 1,
        "source_resource_filter_row_count" => 4,
        "source_resource_filter_suppressed_candidate_count" => 3,
        "source_resource_filter_invalid_resource_summary_input_count" => 1,
        "source_resource_filter_suppressed_reason_counts" => %{
          "downlink_margin_low" => 1,
          "payload_unavailable" => 1,
          "power_margin_low" => 1
        },
        "source_resource_filter_candidate_ids_by_suppressed_reason" => %{
          "downlink_margin_low" => ["downlink_margin_block"],
          "payload_unavailable" => ["obs_payload_block"],
          "power_margin_low" => ["power_block"]
        },
        "source_resource_filter_spacecraft_counts" => %{"leo_1" => 2, "leo_2" => 1},
        "source_resource_filter_candidate_ids_by_spacecraft" => %{
          "leo_1" => ["downlink_margin_block", "obs_payload_block"],
          "leo_2" => ["power_block"]
        },
        "source_resource_filter_resource_counts" => %{
          "battery_main" => 1,
          "downlink_budget" => 1,
          "payload_1" => 1
        },
        "source_resource_filter_blocking_dimension_counts" => %{
          "communications" => 1,
          "payload" => 1,
          "power" => 1
        },
        "source_resource_filter_direction_counts" => %{
          "command" => 1,
          "downlink" => 1
        },
        "source_resource_filter_direction_routing" => %{
          "command" => %{
            "candidate_count" => 1,
            "candidate_ids" => ["power_block"]
          },
          "downlink" => %{
            "candidate_count" => 1,
            "candidate_ids" => ["downlink_margin_block"]
          }
        },
        "source_resource_filter_trust_boundary_status" => "declared",
        "source_resource_filter_branch_local_resource_filter_pressure" => true,
        "source_resource_filter_branch_local_candidate_suppression_pressure" => true,
        "source_resource_filter_branch_local_invalid_resource_summary_pressure" => true,
        "source_resource_filter_branch_local_resource_blocking_pressure" => true
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
        "source_resource_filter_report_count" => 0,
        "source_resource_filter_row_count" => 0,
        "source_resource_filter_suppressed_candidate_count" => 0,
        "source_resource_filter_invalid_resource_summary_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not resource filtering validation",
        "checks candidate-refresh replay of resource-filter provenance without resource filtering, candidate selection, import approval, or Cadence writes"
      ]
    }
  }

  def all, do: @fixtures
end
