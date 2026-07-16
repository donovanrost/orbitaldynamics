defmodule OrbitalDynamics.Schema.ContactIntentRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "contact_intent.v1" => %{
        "schema_contract" => "contact_intent.v1",
        "artifact_family" => "contact_intent",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "activity_id",
          "scenario_id",
          "ground_station_id",
          "direction",
          "starts_at_s",
          "ends_at_s"
        ],
        "optional_fields" => [
          "activity_type",
          "spacecraft_id",
          "estimated_throughput_mb",
          "station_availability",
          "station_contention_status",
          "station_reservation_id",
          "station_reserved_by",
          "station_reservation_status",
          "schedule_conflict_status",
          "source_window_id",
          "timeline_id",
          "timeline_identity",
          "timeline_integrity_issue_count",
          "timeline_integrity_issue_types",
          "timeline_integrity_issues",
          "cadence_import",
          "approval_status",
          "approval_requirements",
          "approval_rule_matches",
          "policy_decision",
          "model_limits"
        ],
        "nested_contracts" => ["approval_requirement.v1", "policy_decision.v1"]
      },
      "contact_intent_summary.v1" => %{
        "schema_contract" => "contact_intent_summary.v1",
        "artifact_family" => "contact_intent_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "contact_intent_count",
          "capacity_pack_required_contact_count",
          "capacity_pack_required_capacity_fraction",
          "capacity_pack_required_capacity_fraction_by_ground_station_id",
          "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id",
          "required_capacity_fraction_source_counts",
          "required_capacity_fraction_contact_ids_by_source",
          "contact_ids_by_ground_station_id",
          "contact_ids_by_direction_and_ground_station_id",
          "capacity_pack_contact_ids_by_ground_station_id",
          "capacity_pack_contact_ids_by_direction_and_ground_station_id",
          "ground_station_ids",
          "directions",
          "assumptions"
        ],
        "optional_fields" => [
          "capacity_pack_required_capacity_fraction_by_direction",
          "contact_ids_by_direction",
          "capacity_pack_contact_ids_by_direction",
          "direction_counts",
          "direction_routing",
          "model_limits"
        ],
        "nested_contracts" => ["contact_intent.v1"]
      }
    }
  end
end
