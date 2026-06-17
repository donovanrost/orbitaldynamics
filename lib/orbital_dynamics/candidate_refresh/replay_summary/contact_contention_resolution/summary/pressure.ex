defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary.Pressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary.CapacityPack

  def fields(
        resolution_fields,
        capacity_pack_fields,
        recommendation_count,
        deferred_contact_count,
        conflict_group_count,
        review_recommendation_count
      ) do
    resolution_status_counts = Map.get(resolution_fields, "resolution_status_counts", %{})
    selection_reason_counts = Map.get(resolution_fields, "selection_reason_counts", %{})
    recommendation_group_ids = Map.get(resolution_fields, "recommendation_group_ids", [])
    review_group_ids = Map.get(resolution_fields, "review_group_ids", [])
    ambiguous_group_ids = Map.get(resolution_fields, "ambiguous_group_ids", [])

    ambiguous_duplicate_contact_ids =
      Map.get(resolution_fields, "ambiguous_duplicate_contact_ids", [])

    ambiguous_duplicate_contact_ids_by_group =
      Map.get(resolution_fields, "ambiguous_duplicate_contact_ids_by_group_id", %{})

    selected_contact_ids = Map.get(resolution_fields, "selected_contact_ids", [])
    deferred_contact_ids = Map.get(resolution_fields, "deferred_contact_ids", [])
    review_contact_ids = Map.get(resolution_fields, "review_contact_ids", [])

    selected_contact_ids_by_group =
      Map.get(resolution_fields, "selected_contact_ids_by_group_id", %{})

    deferred_contact_ids_by_group =
      Map.get(resolution_fields, "deferred_contact_ids_by_group_id", %{})

    review_contact_ids_by_group =
      Map.get(resolution_fields, "review_contact_ids_by_group_id", %{})

    selected_contact_ids_by_selection_reason =
      Map.get(resolution_fields, "selected_contact_ids_by_selection_reason", %{})

    selected_contact_ids_by_station =
      Map.get(resolution_fields, "selected_contact_ids_by_ground_station", %{})

    deferred_contact_ids_by_station =
      Map.get(resolution_fields, "deferred_contact_ids_by_ground_station", %{})

    resource_scope_counts = Map.get(resolution_fields, "resource_scope_counts", %{})

    selected_contact_ids_by_resource_scope =
      Map.get(resolution_fields, "selected_contact_ids_by_resource_scope", %{})

    deferred_contact_ids_by_resource_scope =
      Map.get(resolution_fields, "deferred_contact_ids_by_resource_scope", %{})

    review_contact_ids_by_resource_scope =
      Map.get(resolution_fields, "review_contact_ids_by_resource_scope", %{})

    direction_counts = Map.get(resolution_fields, "direction_counts", %{})
    contact_ids_by_direction = Map.get(resolution_fields, "contact_ids_by_direction", %{})
    direction_routing = Map.get(resolution_fields, "direction_routing", %{})
    required_action_counts = Map.get(resolution_fields, "required_operator_action_counts", %{})

    review_contact_ids_by_action =
      Map.get(resolution_fields, "review_contact_ids_by_action", %{})

    capacity_pack_pressure = CapacityPack.pressure?(capacity_pack_fields)

    deferred_contact_pressure =
      deferred_contact_count > 0 or deferred_contact_ids != [] or
        map_size(deferred_contact_ids_by_station) > 0 or
        CapacityPack.deferred_pressure?(capacity_pack_fields) or
        map_size(deferred_contact_ids_by_group) > 0 or
        map_size(deferred_contact_ids_by_resource_scope) > 0

    compact_resolution_pressure =
      conflict_group_count > 0 or review_recommendation_count > 0 or
        recommendation_group_ids != [] or review_group_ids != [] or review_contact_ids != [] or
        ambiguous_group_ids != [] or ambiguous_duplicate_contact_ids != [] or
        map_size(ambiguous_duplicate_contact_ids_by_group) > 0 or
        map_size(selected_contact_ids_by_group) > 0 or
        map_size(deferred_contact_ids_by_group) > 0 or
        map_size(review_contact_ids_by_group) > 0 or map_size(resource_scope_counts) > 0 or
        map_size(selected_contact_ids_by_selection_reason) > 0 or
        map_size(selected_contact_ids_by_resource_scope) > 0 or
        map_size(deferred_contact_ids_by_resource_scope) > 0 or
        map_size(review_contact_ids_by_resource_scope) > 0 or
        map_size(review_contact_ids_by_action) > 0

    %{
      "branch_local_contact_contention_resolution_pressure" =>
        recommendation_count + deferred_contact_count > 0 or
          map_size(resolution_status_counts) > 0 or map_size(selection_reason_counts) > 0 or
          compact_resolution_pressure or
          selected_contact_ids != [] or deferred_contact_ids != [] or
          map_size(selected_contact_ids_by_station) > 0 or
          map_size(deferred_contact_ids_by_station) > 0 or capacity_pack_pressure or
          map_size(direction_counts) > 0 or map_size(contact_ids_by_direction) > 0 or
          map_size(direction_routing) > 0 or
          map_size(required_action_counts) > 0,
      "branch_local_deferred_contact_pressure" => deferred_contact_pressure,
      "branch_local_capacity_pack_pressure" => capacity_pack_pressure,
      "branch_local_contact_contention_resolution_action_pressure" =>
        map_size(required_action_counts) > 0
    }
  end
end
