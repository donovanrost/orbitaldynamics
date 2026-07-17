defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshContact do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of cross-station same-spacecraft contention challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_contact_contention_challenge_fixture",
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
        "warning_count" => 2,
        "source_report_family_count" => 1,
        "source_report_row_count" => 1,
        "source_contact_contention_report_count" => 1,
        "source_contact_contention_row_count" => 1,
        "source_contact_contention_conflict_group_count" => 1,
        "source_contact_contention_invalid_contact_input_count" => 0,
        "source_contact_contention_resource_scope_counts" => %{"spacecraft" => 1},
        "source_contact_contention_direction_counts" => %{"downlink" => 2},
        "source_contact_contention_contact_ids_by_direction" => %{
          "downlink" => ["dl_dsn", "dl_equator"]
        },
        "source_contact_contention_required_operator_action_counts" => %{
          "review_contact_contention" => 1
        },
        "source_contact_contention_trust_boundary_status" => "declared"
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
        "source_report_row_count" => 0,
        "source_contact_contention_report_count" => 0,
        "source_contact_contention_row_count" => 0,
        "source_contact_contention_conflict_group_count" => 0,
        "source_contact_contention_invalid_contact_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not provider schedule validation",
        "checks candidate-refresh replay of contact-contention provenance without contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.contact_intent_direction_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.contact_intent_direction_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of direction-scoped contact-intent capacity demand",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_contact_intent_direction_fixture",
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
        "source_report_row_count" => 3,
        "source_contact_intent_report_count" => 3,
        "source_contact_intent_row_count" => 3,
        "source_contact_intent_station_feedback_count" => 2,
        "source_contact_intent_capacity_pack_required_contact_count" => 2,
        "source_contact_intent_capacity_pack_required_capacity_fraction" => 0.65,
        "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction" => %{
          "downlink" => 0.25,
          "tracking" => 0.4
        },
        "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
          %{
            "downlink" => %{"equator_prime" => 0.25},
            "tracking" => %{"dss_43" => 0.4}
          },
        "source_contact_intent_capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["intent_direct_capacity"],
          "tracking" => ["intent_nested_capacity"]
        },
        "source_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" => %{
          "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
          "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
        },
        "source_contact_intent_direction_keys" => "command|downlink|tracking",
        "source_contact_intent_direction_counts" => %{
          "command" => 1,
          "downlink" => 1,
          "tracking" => 1
        },
        "source_contact_intent_contact_ids_by_direction" => %{
          "command" => ["intent_station_only"],
          "downlink" => ["intent_direct_capacity"],
          "tracking" => ["intent_nested_capacity"]
        },
        "source_contact_intent_contact_ids_by_direction_and_ground_station" => %{
          "command" => %{"dss_43" => ["intent_station_only"]},
          "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
          "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
        },
        "source_contact_intent_direction_routing" => %{
          "command" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_station_only"],
            "capacity_pack_contact_ids" => [],
            "ground_station_ids" => ["dss_43"],
            "contact_ids_by_ground_station" => %{"dss_43" => ["intent_station_only"]}
          },
          "downlink" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_direct_capacity"],
            "capacity_pack_required_capacity_fraction" => 0.25,
            "capacity_pack_contact_ids" => ["intent_direct_capacity"],
            "ground_station_ids" => ["equator_prime"],
            "contact_ids_by_ground_station" => %{
              "equator_prime" => ["intent_direct_capacity"]
            },
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.25
            },
            "capacity_pack_contact_ids_by_ground_station" => %{
              "equator_prime" => ["intent_direct_capacity"]
            }
          },
          "tracking" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_nested_capacity"],
            "capacity_pack_required_capacity_fraction" => 0.4,
            "capacity_pack_contact_ids" => ["intent_nested_capacity"],
            "ground_station_ids" => ["dss_43"],
            "contact_ids_by_ground_station" => %{"dss_43" => ["intent_nested_capacity"]},
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{
              "dss_43" => 0.4
            },
            "capacity_pack_contact_ids_by_ground_station" => %{
              "dss_43" => ["intent_nested_capacity"]
            }
          }
        },
        "source_contact_intent_trust_boundary_status" => "declared"
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
        "source_contact_intent_report_count" => 0,
        "source_contact_intent_row_count" => 0,
        "source_contact_intent_station_feedback_count" => 0,
        "source_contact_intent_capacity_pack_required_contact_count" => 0,
        "source_contact_intent_capacity_pack_required_capacity_fraction" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not provider schedule validation",
        "checks candidate-refresh replay of contact-intent direction and capacity-pack provenance without contact generation, contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    }
  }

  def all, do: @fixtures
end
