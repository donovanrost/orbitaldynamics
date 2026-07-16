defmodule OrbitalDynamics.Schema.ContactContentionRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "contact_contention_report.v1" => %{
        "schema_contract" => "contact_contention_report.v1",
        "artifact_family" => "contact_contention_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "input_contact_count",
          "conflicted_contact_count",
          "conflict_group_count",
          "conflict_groups"
        ],
        "optional_fields" => [
          "assumptions",
          "provenance",
          "model_limits",
          "duplicate_contact_candidate_count",
          "duplicate_contact_id_count",
          "invalid_contact_input_count",
          "invalid_contact_input_ids",
          "invalid_contact_inputs"
        ],
        "nested_contracts" => []
      },
      "contact_contention_resolution_report.v1" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "artifact_family" => "contact_contention_resolution_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "policy",
          "conflict_group_count",
          "recommendation_count",
          "recommendations"
        ],
        "optional_fields" => ["assumptions", "model_limits"],
        "nested_contracts" => []
      },
      "contact_contention_resolution_summary.v1" => %{
        "schema_contract" => "contact_contention_resolution_summary.v1",
        "artifact_family" => "contact_contention_resolution_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "conflict_group_count",
          "recommendation_count",
          "policy",
          "recommendation_group_ids",
          "review_group_ids",
          "selected_contact_ids",
          "selected_contact_ids_by_group_id",
          "deferred_contact_ids",
          "deferred_contact_ids_by_group_id",
          "ambiguous_group_ids",
          "ambiguous_duplicate_contact_ids",
          "ambiguous_duplicate_contact_ids_by_group_id",
          "review_contact_ids",
          "review_contact_ids_by_group_id",
          "review_recommendation_count",
          "resource_scope_counts",
          "selected_contact_ids_by_resource_scope",
          "deferred_contact_ids_by_resource_scope",
          "review_contact_ids_by_resource_scope",
          "selection_reason_counts",
          "selected_contact_ids_by_selection_reason",
          "action_counts",
          "review_contact_ids_by_action",
          "capacity_pack_required_capacity_fraction_by_status",
          "required_capacity_fraction_source_counts",
          "required_capacity_fraction_contact_ids_by_source",
          "assumptions"
        ],
        "optional_fields" => [
          "model_limits",
          "capacity_pack_required_capacity_fraction",
          "capacity_pack_selected_required_capacity_fraction",
          "capacity_pack_deferred_required_capacity_fraction",
          "capacity_pack_required_capacity_fraction_by_ground_station_id",
          "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
        ],
        "nested_contracts" => ["contact_contention_resolution_report.v1"]
      }
    }
  end
end
