defmodule OrbitalDynamics.Validation.ReferenceFixtures.ContactIntentArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.contact_intent.v1" => %{
      "id" => "fixture.artifact.contact_intent.v1",
      "model_id" => "artifact.contact_intent.v1",
      "reference_case" => "checked-in contact intent artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_intent_v1.json",
        "contract" => "contact_intent.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_intent.v1",
        "id" => "refresh_downlink",
        "activity_type" => "downlink",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
        "starts_at_s" => 100,
        "ends_at_s" => 160,
        "duration_s" => 60,
        "estimated_throughput_mb" => 120,
        "station_availability" => "available",
        "schedule_conflict_status" => "not_evaluated",
        "approval_status" => "operator_review_required",
        "approval_requirement_count" => 1,
        "approval_rule_match_count" => 1,
        "policy_decision_classification" => "operator_review_required",
        "policy_bundle_id" => "command_contact_authority_v1",
        "cadence_import_external_id" => "refresh_downlink",
        "cadence_import_activity_type" => "contact",
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "starts_at_s" => 0,
        "ends_at_s" => 0,
        "duration_s" => 0,
        "estimated_throughput_mb" => 0,
        "approval_requirement_count" => 0,
        "approval_rule_match_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external contact validation",
        "checks contact intent timing, approval routing, Cadence import metadata, and no-reservation/no-mutation boundaries only"
      ]
    },
    "fixture.artifact.contact_intent_summary.v1" => %{
      "id" => "fixture.artifact.contact_intent_summary.v1",
      "model_id" => "artifact.contact_intent_summary.v1",
      "reference_case" => "checked-in contact intent summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_intent_summary_v1.json",
        "contract" => "contact_intent_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_intent_summary.v1",
        "model" => "artifact_only_contact_intent_summary",
        "source_artifact_type" => "contact_intent.v1",
        "contact_intent_count" => 3,
        "capacity_pack_required_contact_count" => 3,
        "capacity_pack_required_capacity_fraction" => 0.95,
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "dss_43" => 0.5,
          "equator_prime" => 0.45
        },
        "capacity_pack_required_capacity_fraction_by_direction" => %{
          "command" => 0.5,
          "downlink" => 0.25,
          "tracking" => 0.2
        },
        "direction_counts" => %{"command" => 1, "downlink" => 1, "tracking" => 1},
        "direction_keys" => "command|downlink|tracking",
        "ground_station_keys" => "dss_43|equator_prime",
        "contact_ids_by_ground_station_id" => %{
          "dss_43" => ["throughput_capacity_contact"],
          "equator_prime" => ["capacity_model_contact", "direct_capacity_contact"]
        },
        "contact_ids_by_direction" => %{
          "command" => ["throughput_capacity_contact"],
          "downlink" => ["direct_capacity_contact"],
          "tracking" => ["capacity_model_contact"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "command" => ["throughput_capacity_contact"],
          "downlink" => ["direct_capacity_contact"],
          "tracking" => ["capacity_model_contact"]
        },
        "required_capacity_fraction_source_counts" => %{
          "capacity_model" => 1,
          "contact_required_capacity_fraction" => 1,
          "throughput_model" => 1
        },
        "required_capacity_fraction_source_keys" =>
          "capacity_model|contact_required_capacity_fraction|throughput_model",
        "direction_routing_count" => 3,
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "assumption_source_artifact_type" => "contact_intent.v1",
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_command_execution" => true
      },
      "tolerances" => %{
        "contact_intent_count" => 0,
        "capacity_pack_required_contact_count" => 0,
        "capacity_pack_required_capacity_fraction" => 0.0,
        "direction_routing_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by contact_intent_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external ground-network validation",
        "checks compact contact direction, station, capacity-source routing, and no-provider-reservation/no-mutation boundaries only"
      ]
    }
  }

  def all, do: @fixtures
end
