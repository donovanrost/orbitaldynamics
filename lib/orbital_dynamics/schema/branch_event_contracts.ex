defmodule OrbitalDynamics.Schema.BranchEventContracts do
  @moduledoc false

  def validate_event(issues, path, event, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, event, ["type"])
    |> expect_type(callbacks, path, event, "type", :binary)
    |> validate_stable_ids(callbacks, path, event, [
      "objective_id",
      "scenario_id",
      "branch_id",
      "source_branch_id",
      "target_id",
      "source_target_id",
      "ground_station_id",
      "spacecraft_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_reservation_id",
      "reservation_id",
      "capacity_pack_group_id",
      "source_activity_id",
      "missed_downlink_activity_id",
      "source_window_id",
      "collection_id",
      "product_id",
      "payload_id",
      "instrument_id"
    ])
    |> validate_optional_stable_id_list(callbacks, path, event, "source_branch_ids")
    |> validate_optional_stable_id_list(callbacks, path, event, "source_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, event, "missed_downlink_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, event, "source_window_ids")
    |> validate_optional_stable_id_list(callbacks, path, event, "collection_ids")
    |> validate_optional_stable_id_list(callbacks, path, event, "product_ids")
    |> validate_optional_stable_id_list(callbacks, path, event, "payload_ids")
    |> validate_optional_stable_id_list(callbacks, path, event, "instrument_ids")
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      event,
      "station_calendar_overlap_entry_ids"
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      event,
      "station_calendar_ambiguous_entry_ids"
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      event,
      "station_calendar_reservation_ids"
    )
    |> expect_optional_number(callbacks, path, event, "starts_at_s")
    |> expect_optional_number(callbacks, path, event, "ends_at_s")
    |> expect_optional_number(callbacks, path, event, "actual_starts_at_s")
    |> expect_optional_number(callbacks, path, event, "actual_ends_at_s")
    |> expect_optional_number(callbacks, path, event, "priority")
    |> expect_optional_number(callbacks, path, event, "target_priority")
    |> expect_optional_type(callbacks, path, event, "target_priority_source", :binary)
    |> expect_optional_type(callbacks, path, event, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, event, "target_priority_objective_ids")
    |> expect_optional_type(callbacks, path, event, "target_priority_objective_type", :binary)
    |> validate_semantic_change_details(callbacks, path, event)
    |> validate_candidate_diff_changed_fields(callbacks, path, event)
    |> expect_optional_type(callbacks, path, event, "source_target", :map)
    |> expect_optional_number(callbacks, path, event, "target_latitude_deg")
    |> expect_optional_number(callbacks, path, event, "target_longitude_deg")
    |> expect_optional_number(callbacks, path, event, "target_minimum_elevation_deg")
    |> expect_optional_number(callbacks, path, event, "required_contacts")
    |> expect_optional_number(callbacks, path, event, "planned_contacts")
    |> expect_optional_number(callbacks, path, event, "required_downlink_mb")
    |> expect_optional_number(callbacks, path, event, "planned_downlink_mb")
    |> expect_optional_number(callbacks, path, event, "max_latency_s")
    |> expect_optional_number(callbacks, path, event, "planned_latency_s")
    |> expect_optional_number(callbacks, path, event, "required_observations")
    |> expect_optional_number(callbacks, path, event, "planned_observations")
    |> expect_optional_number(callbacks, path, event, "contact_success_factor")
    |> expect_optional_number(callbacks, path, event, "command_success_factor")
    |> expect_optional_number(callbacks, path, event, "capacity_fraction")
    |> expect_optional_number(callbacks, path, event, "capacity_pack_capacity_fraction")
    |> expect_optional_number(callbacks, path, event, "capacity_pack_used_fraction")
    |> expect_optional_number(callbacks, path, event, "capacity_pack_unused_fraction")
    |> expect_optional_number(callbacks, path, event, "required_capacity_fraction")
    |> expect_optional_number(callbacks, path, event, "observation_success_factor")
    |> expect_optional_number(callbacks, path, event, "image_quality_score")
    |> expect_optional_number(callbacks, path, event, "cloud_cover_fraction")
    |> expect_optional_number(callbacks, path, event, "blur_score")
    |> expect_optional_number(callbacks, path, event, "maneuver_success_factor")
    |> expect_optional_number(callbacks, path, event, "station_throughput_factor")
    |> expect_optional_number(callbacks, path, event, "feedback_weight")
    |> expect_optional_number(callbacks, path, event, "feedback_sample_weight")
    |> expect_optional_number(callbacks, path, event, "sample_weight")
    |> expect_optional_number(callbacks, path, event, "confidence_weight")
    |> expect_optional_number(callbacks, path, event, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(callbacks, path, event, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(callbacks, path, event, "provider_counteroffer_duration_delta_s")
    |> expect_optional_number(callbacks, path, event, "score_term_value")
    |> expect_optional_number(callbacks, path, event, "timeline_score")
    |> expect_optional_integer(callbacks, path, event, "evidence_count")
    |> expect_optional_integer(callbacks, path, event, "accepted_evidence_count")
    |> expect_optional_integer(callbacks, path, event, "review_required_evidence_count")
    |> expect_optional_integer(callbacks, path, event, "blocked_evidence_count")
    |> expect_optional_integer(callbacks, path, event, "schema_error_count")
    |> expect_optional_integer(callbacks, path, event, "schema_warning_count")
    |> expect_optional_integer(callbacks, path, event, "model_blocked_count")
    |> expect_optional_integer(callbacks, path, event, "quality_gate_review_count")
    |> expect_optional_integer(callbacks, path, event, "quality_gate_blocked_count")
    |> expect_field_at_least(callbacks, path, event, "priority", 0.0)
    |> expect_field_at_least(callbacks, path, event, "target_priority", 0.0)
    |> expect_field_at_least(callbacks, path, event, "required_contacts", 0.0)
    |> expect_field_at_least(callbacks, path, event, "planned_contacts", 0.0)
    |> expect_field_at_least(callbacks, path, event, "required_downlink_mb", 0.0)
    |> expect_field_at_least(callbacks, path, event, "planned_downlink_mb", 0.0)
    |> expect_field_at_least(callbacks, path, event, "max_latency_s", 0.0)
    |> expect_field_at_least(callbacks, path, event, "planned_latency_s", 0.0)
    |> expect_field_at_least(callbacks, path, event, "required_observations", 0.0)
    |> expect_field_at_least(callbacks, path, event, "planned_observations", 0.0)
    |> expect_field_at_least(callbacks, path, event, "feedback_weight", 0.0)
    |> expect_field_at_least(callbacks, path, event, "feedback_sample_weight", 0.0)
    |> expect_field_at_least(callbacks, path, event, "sample_weight", 0.0)
    |> expect_field_at_least(callbacks, path, event, "confidence_weight", 0.0)
    |> expect_field_at_least(callbacks, path, event, "evidence_count", 0)
    |> expect_field_at_least(callbacks, path, event, "accepted_evidence_count", 0)
    |> expect_field_at_least(callbacks, path, event, "review_required_evidence_count", 0)
    |> expect_field_at_least(callbacks, path, event, "blocked_evidence_count", 0)
    |> expect_field_at_least(callbacks, path, event, "schema_error_count", 0)
    |> expect_field_at_least(callbacks, path, event, "schema_warning_count", 0)
    |> expect_field_at_least(callbacks, path, event, "model_blocked_count", 0)
    |> expect_field_at_least(callbacks, path, event, "quality_gate_review_count", 0)
    |> expect_field_at_least(callbacks, path, event, "quality_gate_blocked_count", 0)
    |> expect_probability_range(callbacks, path, event, "contact_success_factor")
    |> expect_probability_range(callbacks, path, event, "command_success_factor")
    |> expect_probability_range(callbacks, path, event, "capacity_fraction")
    |> expect_probability_range(callbacks, path, event, "capacity_pack_capacity_fraction")
    |> expect_probability_range(callbacks, path, event, "capacity_pack_used_fraction")
    |> expect_probability_range(callbacks, path, event, "capacity_pack_unused_fraction")
    |> expect_probability_range(callbacks, path, event, "required_capacity_fraction")
    |> expect_probability_range(callbacks, path, event, "observation_success_factor")
    |> expect_probability_range(callbacks, path, event, "image_quality_score")
    |> expect_probability_range(callbacks, path, event, "cloud_cover_fraction")
    |> expect_probability_range(callbacks, path, event, "blur_score")
    |> expect_probability_range(callbacks, path, event, "maneuver_success_factor")
    |> expect_probability_range(callbacks, path, event, "station_throughput_factor")
    |> expect_optional_type(callbacks, path, event, "latency_objective", :boolean)
    |> expect_optional_type(callbacks, path, event, "station_calendar_entry_ambiguous", :boolean)
    |> expect_optional_type(callbacks, path, event, "capacity_pack_status", :binary)
    |> expect_optional_type(callbacks, path, event, "required_capacity_fraction_source", :binary)
    |> expect_optional_type(callbacks, path, event, "feedback_weight_source", :binary)
    |> expect_optional_type(callbacks, path, event, "feedback_sample_weight_source", :binary)
    |> expect_optional_type(callbacks, path, event, "sample_weight_source", :binary)
    |> expect_optional_type(callbacks, path, event, "confidence_weight_source", :binary)
    |> expect_optional_type(callbacks, path, event, "feedback_source", :binary)
    |> expect_optional_type(callbacks, path, event, "feedback_scope", :binary)
    |> expect_optional_type(callbacks, path, event, "validation_safety_case_status", :binary)
    |> expect_optional_type(callbacks, path, event, "evidence_status", :binary)
    |> expect_optional_type(callbacks, path, event, "input_contract", :binary)
    |> expect_optional_type(callbacks, path, event, "evidence_ref", :binary)
    |> expect_optional_type(callbacks, path, event, "input_contracts", :list)
    |> expect_optional_type(callbacks, path, event, "evidence_status_counts", :map)
    |> expect_optional_type(callbacks, path, event, "evidence_refs_by_status", :map)
    |> expect_optional_type(callbacks, path, event, "evidence_refs_by_contract", :map)
    |> expect_optional_type(callbacks, path, event, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, event, "provenance", :map)
    |> expect_optional_integer(callbacks, path, event, "station_calendar_overlap_count")
    |> expect_optional_integer(callbacks, path, event, "station_calendar_ambiguous_entry_count")
    |> expect_optional_integer(
      callbacks,
      path,
      event,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_field_at_least(callbacks, path, event, "station_calendar_overlap_count", 0)
    |> expect_field_at_least(
      callbacks,
      path,
      event,
      "station_calendar_ambiguous_entry_count",
      0
    )
    |> expect_field_at_least(
      callbacks,
      path,
      event,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      event,
      "station_calendar_trust_boundary_status",
      ["declared", "missing"]
    )
    |> expect_optional_type(callbacks, path, event, "score_terms", :map)
    |> validate_numeric_map(callbacks, path <> ".score_terms", Map.get(event, "score_terms"))
    |> validate_string_list_items(callbacks, path, event, "station_calendar_directions")
    |> validate_string_list_items(
      callbacks,
      path,
      event,
      "station_calendar_overlap_availabilities"
    )
    |> validate_string_list_items(callbacks, path, event, "station_calendar_reserved_by")
    |> validate_string_list_items(callbacks, path, event, "station_calendar_reservation_statuses")
    |> validate_string_list_items(callbacks, path, event, "downlink_demand_sources")
    |> validate_string_list_items(callbacks, path, event, "downlink_completion_sources")
    |> validate_string_list_items(callbacks, path, event, "derivation_reasons")
    |> validate_string_list_items(callbacks, path, event, "input_contracts")
    |> validate_string_list_map(callbacks, path, event, "model_ids_by_status")
    |> validate_string_list_map(callbacks, path, event, "model_ids_by_validation_level")
    |> validate_string_list_map(callbacks, path, event, "model_ids_by_intended_use")
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".evidence_status_counts",
      event["evidence_status_counts"]
    )
    |> validate_string_list_map(callbacks, path, event, "evidence_refs_by_status")
    |> validate_string_list_map(callbacks, path, event, "evidence_refs_by_contract")
    |> validate_validation_safety_case_status(path, event, callbacks)
    |> validate_validation_safety_case_action(path, event, callbacks)
  end

  def validate_summary_fields(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, row, "branch_event_count")
    |> expect_optional_type(callbacks, path, row, "branch_event_types", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_event_types")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_event_trust_boundary_status_counts",
      :map
    )
    |> validate_trust_boundary_status_counts(callbacks, path, row)
    |> expect_optional_type(callbacks, path, row, "combined_source_branch_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "combined_source_branch_ids")
    |> expect_optional_type(callbacks, path, row, "branch_ground_station_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_ground_station_ids")
    |> validate_branch_scoped_downlink_context_fields(callbacks, path, row)
    |> expect_optional_type(callbacks, path, row, "branch_directions", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_directions")
    |> expect_optional_type(callbacks, path, row, "branch_station_availabilities", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_station_availabilities")
    |> expect_optional_type(callbacks, path, row, "branch_station_contention_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_station_contention_statuses")
    |> expect_optional_type(callbacks, path, row, "branch_station_calendar_entry_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_station_calendar_entry_ids")
    |> expect_optional_type(callbacks, path, row, "branch_station_calendar_provider_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "branch_station_calendar_provider_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_station_calendar_provider_entry_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "branch_station_calendar_provider_entry_ids"
    )
    |> expect_optional_type(callbacks, path, row, "branch_station_calendar_directions", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_station_calendar_directions")
    |> expect_optional_type(callbacks, path, row, "branch_station_calendar_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_station_calendar_statuses")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_station_calendar_trust_boundary_statuses",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "branch_station_calendar_trust_boundary_statuses"
    )
    |> expect_optional_type(callbacks, path, row, "branch_station_reservation_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_station_reservation_ids")
    |> expect_optional_type(callbacks, path, row, "branch_station_reserved_by", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_station_reserved_by")
    |> expect_optional_type(callbacks, path, row, "branch_station_reservation_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_station_reservation_statuses")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_station_reservation_match_statuses",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "branch_station_reservation_match_statuses"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_station_reservation_conflict_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "branch_station_reservation_conflict_contact_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_station_reservation_conflict_reservation_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "branch_station_reservation_conflict_reservation_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_station_reservation_conflict_match_statuses",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "branch_station_reservation_conflict_match_statuses"
    )
    |> expect_optional_number(callbacks, path, row, "branch_image_quality_min_score")
    |> expect_optional_type(callbacks, path, row, "branch_image_quality_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_image_quality_statuses")
    |> expect_optional_type(callbacks, path, row, "branch_image_quality_sources", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_image_quality_sources")
    |> expect_optional_number(callbacks, path, row, "branch_cloud_cover_max_fraction")
    |> expect_optional_number(callbacks, path, row, "branch_blur_max_score")
    |> expect_optional_type(callbacks, path, row, "capacity_pack_group_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "capacity_pack_group_ids")
    |> expect_optional_type(callbacks, path, row, "capacity_pack_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "capacity_pack_statuses")
    |> expect_optional_number(callbacks, path, row, "capacity_pack_min_capacity_fraction")
    |> expect_optional_number(callbacks, path, row, "capacity_pack_max_used_fraction")
    |> expect_optional_number(
      callbacks,
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_optional_number(
      callbacks,
      path,
      row,
      "capacity_pack_total_required_capacity_fraction"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "capacity_pack_required_capacity_sources",
      :list
    )
    |> validate_string_list_items(callbacks, path, row, "capacity_pack_required_capacity_sources")
    |> expect_probability_range(callbacks, path, row, "branch_image_quality_min_score")
    |> expect_probability_range(callbacks, path, row, "branch_cloud_cover_max_fraction")
    |> expect_probability_range(callbacks, path, row, "branch_blur_max_score")
    |> expect_probability_range(callbacks, path, row, "capacity_pack_min_capacity_fraction")
    |> expect_probability_range(callbacks, path, row, "capacity_pack_max_used_fraction")
    |> expect_probability_range(
      callbacks,
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_field_at_least(
      callbacks,
      path,
      row,
      "capacity_pack_total_required_capacity_fraction",
      0.0
    )
  end

  def validate_trust_boundary_status_count_map(issues, path, counts, callbacks)
      when is_map(counts) and is_list(callbacks) do
    Enum.reduce(counts, issues, fn {field, count}, acc ->
      cond do
        field not in ["declared", "missing", "untrusted"] ->
          [
            error(
              callbacks,
              "#{path}.#{inspect(field)}",
              "must be declared, missing, or untrusted"
            )
            | acc
          ]

        not is_integer(count) or count < 0 ->
          [error(callbacks, "#{path}.#{field}", "must be a non-negative integer") | acc]

        true ->
          acc
      end
    end)
  end

  def validate_trust_boundary_status_count_map(issues, _path, _counts, _callbacks), do: issues

  def validate_validation_safety_case_status(
        issues,
        path,
        %{"type" => "validation_safety_case_pressure"} = event,
        callbacks
      )
      when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, event, ["evidence_status"])
    |> expect_optional_one_of(callbacks, path, event, "validation_safety_case_status", [
      "review_required",
      "blocked"
    ])
    |> expect_optional_one_of(callbacks, path, event, "evidence_status", [
      "review_required",
      "blocked"
    ])
  end

  def validate_validation_safety_case_status(issues, _path, _event, _callbacks), do: issues

  def validate_validation_safety_case_action(
        issues,
        path,
        %{"type" => "validation_safety_case_pressure"} = event,
        callbacks
      )
      when is_list(callbacks) do
    expected_action =
      if event["evidence_status"] == "blocked" or
           event["validation_safety_case_status"] == "blocked" do
        "review_blocked_validation_safety_case"
      else
        "review_validation_safety_case"
      end

    expect_equal(callbacks, issues, path, event, "required_operator_action", expected_action)
  end

  def validate_validation_safety_case_action(issues, _path, _event, _callbacks), do: issues

  defp validate_branch_scoped_downlink_context_fields(issues, callbacks, path, row) do
    issues
    |> expect_optional_type(callbacks, path, row, "branch_scenario_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_scenario_ids")
    |> expect_optional_type(callbacks, path, row, "branch_target_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_target_ids")
    |> expect_optional_type(callbacks, path, row, "branch_collection_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_collection_ids")
    |> expect_optional_type(callbacks, path, row, "branch_product_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_product_ids")
    |> expect_optional_type(callbacks, path, row, "branch_payload_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_payload_ids")
    |> expect_optional_type(callbacks, path, row, "branch_instrument_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_instrument_ids")
    |> expect_optional_type(callbacks, path, row, "branch_objective_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_objective_ids")
    |> expect_optional_type(callbacks, path, row, "branch_objective_types", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_objective_types")
    |> expect_optional_type(callbacks, path, row, "branch_objective_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_objective_statuses")
    |> expect_optional_type(callbacks, path, row, "branch_source_objective_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_source_objective_statuses")
    |> expect_optional_type(callbacks, path, row, "branch_feedback_sources", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_feedback_sources")
    |> expect_optional_type(callbacks, path, row, "branch_feedback_scopes", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_feedback_scopes")
    |> expect_optional_type(callbacks, path, row, "branch_contact_results", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_contact_results")
    |> expect_optional_type(callbacks, path, row, "branch_contact_allocation_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_contact_allocation_statuses")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_contact_allocation_effective_statuses",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "branch_contact_allocation_effective_statuses"
    )
    |> expect_optional_type(callbacks, path, row, "branch_contact_allocation_reasons", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_contact_allocation_reasons")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_contact_allocation_review_statuses",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "branch_contact_allocation_review_statuses"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_contact_allocation_approval_statuses",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "branch_contact_allocation_approval_statuses"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "branch_contact_allocation_policy_classifications",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "branch_contact_allocation_policy_classifications"
    )
    |> expect_optional_type(callbacks, path, row, "branch_realized_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_realized_statuses")
    |> expect_optional_type(callbacks, path, row, "branch_transition_types", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_transition_types")
    |> expect_optional_type(callbacks, path, row, "branch_transition_categories", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_transition_categories")
    |> expect_optional_type(callbacks, path, row, "branch_transition_reasons", :list)
    |> validate_string_list_items(callbacks, path, row, "branch_transition_reasons")
    |> expect_optional_type(callbacks, path, row, "branch_requires_operator_review", :boolean)
    |> expect_optional_integer(callbacks, path, row, "branch_requires_operator_review_count")
    |> expect_optional_type(callbacks, path, row, "branch_missed_downlink_activity_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "branch_missed_downlink_activity_ids"
    )
    |> expect_optional_type(callbacks, path, row, "branch_source_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "branch_source_activity_ids")
    |> expect_optional_number(callbacks, path, row, "branch_max_latency_s")
    |> expect_optional_number(callbacks, path, row, "branch_planned_latency_s")
    |> expect_optional_number(callbacks, path, row, "branch_required_contacts")
    |> expect_optional_number(callbacks, path, row, "branch_planned_contacts")
    |> expect_optional_number(callbacks, path, row, "branch_required_downlink_mb")
    |> expect_optional_number(callbacks, path, row, "branch_planned_downlink_mb")
    |> expect_optional_probability(
      callbacks,
      path,
      row,
      "branch_actual_downlink_completion_ratio"
    )
  end

  defp validate_trust_boundary_status_counts(issues, callbacks, path, row) do
    counts = Map.get(row, "branch_event_trust_boundary_status_counts")

    issues
    |> validate_trust_boundary_status_count_map(
      path <> ".branch_event_trust_boundary_status_counts",
      counts,
      callbacks
    )
    |> validate_trust_boundary_status_count_total(callbacks, path, row, counts)
  end

  defp validate_trust_boundary_status_count_total(issues, callbacks, path, row, counts)
       when is_map(counts) do
    case Map.get(row, "branch_event_count") do
      event_count when is_integer(event_count) ->
        count_total =
          counts
          |> Map.values()
          |> Enum.filter(&is_integer/1)
          |> Enum.sum()

        if count_total == event_count do
          issues
        else
          [
            error(
              callbacks,
              path <> ".branch_event_trust_boundary_status_counts",
              "must add up to branch_event_count"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_trust_boundary_status_count_total(issues, _callbacks, _path, _row, _counts),
    do: issues

  defp expect_field_at_least(issues, callbacks, path, row, field, min) do
    callback!(callbacks, :expect_field_at_least).(issues, path, row, field, min)
  end

  defp expect_equal(callbacks, issues, path, row, field, expected) do
    callback!(callbacks, :expect_equal).(issues, path, row, field, expected)
  end

  defp expect_optional_integer(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_integer).(issues, path, row, field)
  end

  defp expect_optional_one_of(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :expect_optional_one_of).(issues, path, row, field, values)
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, row, field)
  end

  defp expect_optional_number(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_number).(issues, path, row, field)
  end

  defp expect_optional_probability(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_probability).(issues, path, row, field)
  end

  defp expect_optional_type(issues, callbacks, path, row, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, row, field, type)
  end

  defp expect_type(issues, callbacks, path, row, field, type) do
    callback!(callbacks, :expect_type).(issues, path, row, field, type)
  end

  defp expect_probability_range(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_probability_range).(issues, path, row, field)
  end

  defp validate_candidate_diff_changed_fields(issues, callbacks, path, row) do
    callback!(callbacks, :validate_candidate_diff_changed_fields).(issues, path, row)
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    callback!(callbacks, :validate_non_negative_integer_count_map).(issues, path, counts)
  end

  defp validate_numeric_map(issues, callbacks, path, values) do
    callback!(callbacks, :validate_numeric_map).(issues, path, values)
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_stable_id_list).(issues, path, row, field)
  end

  defp validate_semantic_change_details(issues, callbacks, path, row) do
    callback!(callbacks, :validate_semantic_change_details).(issues, path, row)
  end

  defp validate_stable_ids(issues, callbacks, path, row, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, row, fields)
  end

  defp validate_string_list_map(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_string_list_map).(issues, path, row, field)
  end

  defp validate_string_list_items(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_string_list_items).(issues, path, row, field)
  end

  defp require_fields(issues, callbacks, path, row, fields) do
    callback!(callbacks, :require_fields).(issues, path, row, fields)
  end

  defp error(callbacks, path, message) do
    callback!(callbacks, :error).(path, message)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
