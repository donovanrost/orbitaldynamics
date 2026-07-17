defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshFilterRejection do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.candidate_rejection_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.candidate_rejection_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of candidate-rejection source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_candidate_rejection_fixture",
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
        "source_candidate_rejection_report_count" => 1,
        "source_candidate_rejection_row_count" => 2,
        "source_candidate_rejection_rejected_count" => 2,
        "source_candidate_rejection_reviewable_count" => 1,
        "source_candidate_rejection_invalid_candidate_input_count" => 1,
        "source_candidate_rejection_rejection_reason_counts" => %{
          "invalid_candidate_input" => 1,
          "station_reserved" => 1
        },
        "source_candidate_rejection_required_operator_action_counts" => %{
          "none" => 1,
          "review_candidate_rejection" => 1
        },
        "source_candidate_rejection_candidate_id_counts" => %{
          "bad_candidate" => 1,
          "dl_reserved" => 1
        },
        "source_candidate_rejection_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 1
        },
        "source_candidate_rejection_trust_boundary_status" => "declared",
        "source_candidate_rejection_branch_local_rejection_pressure" => true,
        "source_candidate_rejection_branch_local_review_pressure" => true,
        "source_candidate_rejection_branch_local_invalid_input_pressure" => true
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
        "source_candidate_rejection_report_count" => 0,
        "source_candidate_rejection_row_count" => 0,
        "source_candidate_rejection_rejected_count" => 0,
        "source_candidate_rejection_reviewable_count" => 0,
        "source_candidate_rejection_invalid_candidate_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not candidate selection validation",
        "checks candidate-refresh replay of candidate-rejection provenance without candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.contact_filter_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.contact_filter_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of contact-filter source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_contact_filter_fixture",
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
        "source_contact_filter_report_count" => 1,
        "source_contact_filter_row_count" => 4,
        "source_contact_filter_suppressed_candidate_count" => 4,
        "source_contact_filter_invalid_contact_input_count" => 1,
        "source_contact_filter_suppressed_reason_counts" => %{
          "ground_station_capacity_zero" => 1,
          "ground_station_reserved" => 1,
          "ground_station_unavailable" => 1,
          "invalid_contact_input" => 1
        },
        "source_contact_filter_contact_ids_by_suppressed_reason" => %{
          "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
          "ground_station_reserved" => ["dl_station_reserved"],
          "ground_station_unavailable" => ["dl_station_unavailable"],
          "invalid_contact_input" => ["invalid_contact"]
        },
        "source_contact_filter_direction_counts" => %{
          "command" => 1,
          "downlink" => 1,
          "health_check" => 1,
          "tracking" => 1
        },
        "source_contact_filter_station_suppression_count" => 3,
        "source_contact_filter_station_suppression_ground_station_counts" => %{
          "dss_43" => 2,
          "equator_prime" => 1
        },
        "source_contact_filter_station_suppression_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1,
          "unavailable" => 1
        },
        "source_contact_filter_station_suppression_status_counts" => %{
          "reserved" => 1,
          "unavailable" => 1
        },
        "source_contact_filter_trust_boundary_status" => "declared",
        "source_contact_filter_branch_local_contact_filter_pressure" => true,
        "source_contact_filter_branch_local_candidate_suppression_pressure" => true,
        "source_contact_filter_branch_local_invalid_contact_input_pressure" => true,
        "source_contact_filter_branch_local_station_suppression_pressure" => true
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
        "source_contact_filter_report_count" => 0,
        "source_contact_filter_row_count" => 0,
        "source_contact_filter_suppressed_candidate_count" => 0,
        "source_contact_filter_invalid_contact_input_count" => 0,
        "source_contact_filter_station_suppression_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not contact filtering validation",
        "checks candidate-refresh replay of contact-filter provenance without contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    }
  }

  def all, do: @fixtures
end
