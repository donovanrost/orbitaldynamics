defmodule OrbitalDynamics.Schema.BranchEventContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CandidateDiffContracts

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_numeric_map: 3, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_probability_range: 4,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate_event(issues, path, event) do
    issues
    |> require_fields(path, event, ["type"])
    |> expect_type(path, event, "type", :binary)
    |> validate_stable_ids(path, event, [
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
    |> validate_optional_stable_id_list(path, event, "source_branch_ids")
    |> validate_optional_stable_id_list(path, event, "source_activity_ids")
    |> validate_optional_stable_id_list(path, event, "missed_downlink_activity_ids")
    |> validate_optional_stable_id_list(path, event, "source_window_ids")
    |> validate_optional_stable_id_list(path, event, "collection_ids")
    |> validate_optional_stable_id_list(path, event, "product_ids")
    |> validate_optional_stable_id_list(path, event, "payload_ids")
    |> validate_optional_stable_id_list(path, event, "instrument_ids")
    |> validate_optional_stable_id_list(
      path,
      event,
      "station_calendar_overlap_entry_ids"
    )
    |> validate_optional_stable_id_list(
      path,
      event,
      "station_calendar_ambiguous_entry_ids"
    )
    |> validate_optional_stable_id_list(
      path,
      event,
      "station_calendar_reservation_ids"
    )
    |> expect_optional_number(path, event, "starts_at_s")
    |> expect_optional_number(path, event, "ends_at_s")
    |> expect_optional_number(path, event, "actual_starts_at_s")
    |> expect_optional_number(path, event, "actual_ends_at_s")
    |> expect_optional_number(path, event, "priority")
    |> expect_optional_number(path, event, "target_priority")
    |> expect_optional_type(path, event, "target_priority_source", :binary)
    |> expect_optional_type(path, event, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(path, event, "target_priority_objective_ids")
    |> expect_optional_type(path, event, "target_priority_objective_type", :binary)
    |> CandidateDiffContracts.validate_semantic_change_details(path, event)
    |> CandidateDiffContracts.validate_changed_fields(path, event)
    |> expect_optional_type(path, event, "source_target", :map)
    |> expect_optional_number(path, event, "target_latitude_deg")
    |> expect_optional_number(path, event, "target_longitude_deg")
    |> expect_optional_number(path, event, "target_minimum_elevation_deg")
    |> expect_optional_number(path, event, "required_contacts")
    |> expect_optional_number(path, event, "planned_contacts")
    |> expect_optional_number(path, event, "required_downlink_mb")
    |> expect_optional_number(path, event, "planned_downlink_mb")
    |> expect_optional_number(path, event, "max_latency_s")
    |> expect_optional_number(path, event, "planned_latency_s")
    |> expect_optional_number(path, event, "required_observations")
    |> expect_optional_number(path, event, "planned_observations")
    |> expect_optional_number(path, event, "contact_success_factor")
    |> expect_optional_number(path, event, "command_success_factor")
    |> expect_optional_number(path, event, "capacity_fraction")
    |> expect_optional_number(path, event, "capacity_pack_capacity_fraction")
    |> expect_optional_number(path, event, "capacity_pack_used_fraction")
    |> expect_optional_number(path, event, "capacity_pack_unused_fraction")
    |> expect_optional_number(path, event, "required_capacity_fraction")
    |> expect_optional_number(path, event, "observation_success_factor")
    |> expect_optional_number(path, event, "image_quality_score")
    |> expect_optional_number(path, event, "cloud_cover_fraction")
    |> expect_optional_number(path, event, "blur_score")
    |> expect_optional_number(path, event, "maneuver_success_factor")
    |> expect_optional_number(path, event, "station_throughput_factor")
    |> expect_optional_number(path, event, "feedback_weight")
    |> expect_optional_number(path, event, "feedback_sample_weight")
    |> expect_optional_number(path, event, "sample_weight")
    |> expect_optional_number(path, event, "confidence_weight")
    |> expect_optional_number(path, event, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(path, event, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(path, event, "provider_counteroffer_duration_delta_s")
    |> expect_optional_number(path, event, "score_term_value")
    |> expect_optional_number(path, event, "timeline_score")
    |> expect_optional_integer(path, event, "evidence_count")
    |> expect_optional_integer(path, event, "accepted_evidence_count")
    |> expect_optional_integer(path, event, "review_required_evidence_count")
    |> expect_optional_integer(path, event, "blocked_evidence_count")
    |> expect_optional_integer(path, event, "schema_error_count")
    |> expect_optional_integer(path, event, "schema_warning_count")
    |> expect_optional_integer(path, event, "model_blocked_count")
    |> expect_optional_integer(path, event, "quality_gate_review_count")
    |> expect_optional_integer(path, event, "quality_gate_blocked_count")
    |> expect_field_at_least(path, event, "priority", 0.0)
    |> expect_field_at_least(path, event, "target_priority", 0.0)
    |> expect_field_at_least(path, event, "required_contacts", 0.0)
    |> expect_field_at_least(path, event, "planned_contacts", 0.0)
    |> expect_field_at_least(path, event, "required_downlink_mb", 0.0)
    |> expect_field_at_least(path, event, "planned_downlink_mb", 0.0)
    |> expect_field_at_least(path, event, "max_latency_s", 0.0)
    |> expect_field_at_least(path, event, "planned_latency_s", 0.0)
    |> expect_field_at_least(path, event, "required_observations", 0.0)
    |> expect_field_at_least(path, event, "planned_observations", 0.0)
    |> expect_field_at_least(path, event, "feedback_weight", 0.0)
    |> expect_field_at_least(path, event, "feedback_sample_weight", 0.0)
    |> expect_field_at_least(path, event, "sample_weight", 0.0)
    |> expect_field_at_least(path, event, "confidence_weight", 0.0)
    |> expect_field_at_least(path, event, "evidence_count", 0)
    |> expect_field_at_least(path, event, "accepted_evidence_count", 0)
    |> expect_field_at_least(path, event, "review_required_evidence_count", 0)
    |> expect_field_at_least(path, event, "blocked_evidence_count", 0)
    |> expect_field_at_least(path, event, "schema_error_count", 0)
    |> expect_field_at_least(path, event, "schema_warning_count", 0)
    |> expect_field_at_least(path, event, "model_blocked_count", 0)
    |> expect_field_at_least(path, event, "quality_gate_review_count", 0)
    |> expect_field_at_least(path, event, "quality_gate_blocked_count", 0)
    |> expect_probability_range(path, event, "contact_success_factor")
    |> expect_probability_range(path, event, "command_success_factor")
    |> expect_probability_range(path, event, "capacity_fraction")
    |> expect_probability_range(path, event, "capacity_pack_capacity_fraction")
    |> expect_probability_range(path, event, "capacity_pack_used_fraction")
    |> expect_probability_range(path, event, "capacity_pack_unused_fraction")
    |> expect_probability_range(path, event, "required_capacity_fraction")
    |> expect_probability_range(path, event, "observation_success_factor")
    |> expect_probability_range(path, event, "image_quality_score")
    |> expect_probability_range(path, event, "cloud_cover_fraction")
    |> expect_probability_range(path, event, "blur_score")
    |> expect_probability_range(path, event, "maneuver_success_factor")
    |> expect_probability_range(path, event, "station_throughput_factor")
    |> expect_optional_type(path, event, "latency_objective", :boolean)
    |> expect_optional_type(path, event, "station_calendar_entry_ambiguous", :boolean)
    |> expect_optional_type(path, event, "capacity_pack_status", :binary)
    |> expect_optional_type(path, event, "required_capacity_fraction_source", :binary)
    |> expect_optional_type(path, event, "feedback_weight_source", :binary)
    |> expect_optional_type(path, event, "feedback_sample_weight_source", :binary)
    |> expect_optional_type(path, event, "sample_weight_source", :binary)
    |> expect_optional_type(path, event, "confidence_weight_source", :binary)
    |> expect_optional_type(path, event, "feedback_source", :binary)
    |> expect_optional_type(path, event, "feedback_scope", :binary)
    |> expect_optional_type(path, event, "validation_safety_case_status", :binary)
    |> expect_optional_type(path, event, "evidence_status", :binary)
    |> expect_optional_type(path, event, "input_contract", :binary)
    |> expect_optional_type(path, event, "evidence_ref", :binary)
    |> expect_optional_type(path, event, "input_contracts", :list)
    |> expect_optional_type(path, event, "evidence_status_counts", :map)
    |> expect_optional_type(path, event, "evidence_refs_by_status", :map)
    |> expect_optional_type(path, event, "evidence_refs_by_contract", :map)
    |> expect_optional_type(path, event, "trust_boundary", :binary)
    |> expect_optional_type(path, event, "provenance", :map)
    |> expect_optional_integer(path, event, "station_calendar_overlap_count")
    |> expect_optional_integer(path, event, "station_calendar_ambiguous_entry_count")
    |> expect_optional_integer(
      path,
      event,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_field_at_least(path, event, "station_calendar_overlap_count", 0)
    |> expect_field_at_least(
      path,
      event,
      "station_calendar_ambiguous_entry_count",
      0
    )
    |> expect_field_at_least(
      path,
      event,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_one_of(
      path,
      event,
      "station_calendar_trust_boundary_status",
      ["declared", "missing"]
    )
    |> expect_optional_type(path, event, "score_terms", :map)
    |> validate_numeric_map(path <> ".score_terms", Map.get(event, "score_terms"))
    |> validate_string_list_items(path, event, "station_calendar_directions")
    |> validate_string_list_items(
      path,
      event,
      "station_calendar_overlap_availabilities"
    )
    |> validate_string_list_items(path, event, "station_calendar_reserved_by")
    |> validate_string_list_items(path, event, "station_calendar_reservation_statuses")
    |> validate_string_list_items(path, event, "downlink_demand_sources")
    |> validate_string_list_items(path, event, "downlink_completion_sources")
    |> validate_string_list_items(path, event, "derivation_reasons")
    |> validate_string_list_items(path, event, "input_contracts")
    |> validate_string_list_map(path, event, "model_ids_by_status")
    |> validate_string_list_map(path, event, "model_ids_by_validation_level")
    |> validate_string_list_map(path, event, "model_ids_by_intended_use")
    |> validate_non_negative_integer_count_map(
      path <> ".evidence_status_counts",
      event["evidence_status_counts"]
    )
    |> validate_string_list_map(path, event, "evidence_refs_by_status")
    |> validate_string_list_map(path, event, "evidence_refs_by_contract")
    |> validate_validation_safety_case_status(path, event)
    |> validate_validation_safety_case_action(path, event)
  end

  def validate_summary_fields(issues, path, row) do
    issues
    |> expect_optional_non_negative_integer(path, row, "branch_event_count")
    |> expect_optional_type(path, row, "branch_event_types", :list)
    |> validate_string_list_items(path, row, "branch_event_types")
    |> expect_optional_type(
      path,
      row,
      "branch_event_trust_boundary_status_counts",
      :map
    )
    |> validate_trust_boundary_status_counts(path, row)
    |> expect_optional_type(path, row, "combined_source_branch_ids", :list)
    |> validate_optional_stable_id_list(path, row, "combined_source_branch_ids")
    |> expect_optional_type(path, row, "branch_ground_station_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_ground_station_ids")
    |> validate_branch_scoped_downlink_context_fields(path, row)
    |> expect_optional_type(path, row, "branch_directions", :list)
    |> validate_string_list_items(path, row, "branch_directions")
    |> expect_optional_type(path, row, "branch_station_availabilities", :list)
    |> validate_string_list_items(path, row, "branch_station_availabilities")
    |> expect_optional_type(path, row, "branch_station_contention_statuses", :list)
    |> validate_string_list_items(path, row, "branch_station_contention_statuses")
    |> expect_optional_type(path, row, "branch_station_calendar_entry_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_station_calendar_entry_ids")
    |> expect_optional_type(path, row, "branch_station_calendar_provider_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "branch_station_calendar_provider_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "branch_station_calendar_provider_entry_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "branch_station_calendar_provider_entry_ids"
    )
    |> expect_optional_type(path, row, "branch_station_calendar_directions", :list)
    |> validate_string_list_items(path, row, "branch_station_calendar_directions")
    |> expect_optional_type(path, row, "branch_station_calendar_statuses", :list)
    |> validate_string_list_items(path, row, "branch_station_calendar_statuses")
    |> expect_optional_type(
      path,
      row,
      "branch_station_calendar_trust_boundary_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "branch_station_calendar_trust_boundary_statuses"
    )
    |> expect_optional_type(path, row, "branch_station_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_station_reservation_ids")
    |> expect_optional_type(path, row, "branch_station_reserved_by", :list)
    |> validate_string_list_items(path, row, "branch_station_reserved_by")
    |> expect_optional_type(path, row, "branch_station_reservation_statuses", :list)
    |> validate_string_list_items(path, row, "branch_station_reservation_statuses")
    |> expect_optional_type(
      path,
      row,
      "branch_station_reservation_match_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "branch_station_reservation_match_statuses"
    )
    |> expect_optional_type(
      path,
      row,
      "branch_station_reservation_conflict_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "branch_station_reservation_conflict_contact_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "branch_station_reservation_conflict_reservation_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "branch_station_reservation_conflict_reservation_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "branch_station_reservation_conflict_match_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "branch_station_reservation_conflict_match_statuses"
    )
    |> expect_optional_number(path, row, "branch_image_quality_min_score")
    |> expect_optional_type(path, row, "branch_image_quality_statuses", :list)
    |> validate_string_list_items(path, row, "branch_image_quality_statuses")
    |> expect_optional_type(path, row, "branch_image_quality_sources", :list)
    |> validate_string_list_items(path, row, "branch_image_quality_sources")
    |> expect_optional_number(path, row, "branch_cloud_cover_max_fraction")
    |> expect_optional_number(path, row, "branch_blur_max_score")
    |> expect_optional_type(path, row, "capacity_pack_group_ids", :list)
    |> validate_optional_stable_id_list(path, row, "capacity_pack_group_ids")
    |> expect_optional_type(path, row, "capacity_pack_statuses", :list)
    |> validate_string_list_items(path, row, "capacity_pack_statuses")
    |> expect_optional_number(path, row, "capacity_pack_min_capacity_fraction")
    |> expect_optional_number(path, row, "capacity_pack_max_used_fraction")
    |> expect_optional_number(
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_optional_number(
      path,
      row,
      "capacity_pack_total_required_capacity_fraction"
    )
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_required_capacity_sources",
      :list
    )
    |> validate_string_list_items(path, row, "capacity_pack_required_capacity_sources")
    |> expect_probability_range(path, row, "branch_image_quality_min_score")
    |> expect_probability_range(path, row, "branch_cloud_cover_max_fraction")
    |> expect_probability_range(path, row, "branch_blur_max_score")
    |> expect_probability_range(path, row, "capacity_pack_min_capacity_fraction")
    |> expect_probability_range(path, row, "capacity_pack_max_used_fraction")
    |> expect_probability_range(
      path,
      row,
      "capacity_pack_max_required_capacity_fraction"
    )
    |> expect_field_at_least(
      path,
      row,
      "capacity_pack_total_required_capacity_fraction",
      0.0
    )
  end

  def validate_trust_boundary_status_count_map(issues, path, counts) when is_map(counts) do
    Enum.reduce(counts, issues, fn {field, count}, acc ->
      cond do
        field not in ["declared", "missing", "untrusted"] ->
          [
            error(
              "#{path}.#{inspect(field)}",
              "must be declared, missing, or untrusted"
            )
            | acc
          ]

        not is_integer(count) or count < 0 ->
          [error("#{path}.#{field}", "must be a non-negative integer") | acc]

        true ->
          acc
      end
    end)
  end

  def validate_trust_boundary_status_count_map(issues, _path, _counts), do: issues

  def validate_validation_safety_case_status(
        issues,
        path,
        %{"type" => "validation_safety_case_pressure"} = event
      ) do
    issues
    |> require_fields(path, event, ["evidence_status"])
    |> expect_optional_one_of(path, event, "validation_safety_case_status", [
      "review_required",
      "blocked"
    ])
    |> expect_optional_one_of(path, event, "evidence_status", [
      "review_required",
      "blocked"
    ])
  end

  def validate_validation_safety_case_status(issues, _path, _event), do: issues

  def validate_validation_safety_case_action(
        issues,
        path,
        %{"type" => "validation_safety_case_pressure"} = event
      ) do
    expected_action =
      if event["evidence_status"] == "blocked" or
           event["validation_safety_case_status"] == "blocked" do
        "review_blocked_validation_safety_case"
      else
        "review_validation_safety_case"
      end

    expect_equal(issues, path, event, "required_operator_action", expected_action)
  end

  def validate_validation_safety_case_action(issues, _path, _event), do: issues

  defp validate_branch_scoped_downlink_context_fields(issues, path, row) do
    issues
    |> expect_optional_type(path, row, "branch_scenario_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_scenario_ids")
    |> expect_optional_type(path, row, "branch_target_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_target_ids")
    |> expect_optional_type(path, row, "branch_collection_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_collection_ids")
    |> expect_optional_type(path, row, "branch_product_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_product_ids")
    |> expect_optional_type(path, row, "branch_payload_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_payload_ids")
    |> expect_optional_type(path, row, "branch_instrument_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_instrument_ids")
    |> expect_optional_type(path, row, "branch_objective_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_objective_ids")
    |> expect_optional_type(path, row, "branch_objective_types", :list)
    |> validate_string_list_items(path, row, "branch_objective_types")
    |> expect_optional_type(path, row, "branch_objective_statuses", :list)
    |> validate_string_list_items(path, row, "branch_objective_statuses")
    |> expect_optional_type(path, row, "branch_source_objective_statuses", :list)
    |> validate_string_list_items(path, row, "branch_source_objective_statuses")
    |> expect_optional_type(path, row, "branch_feedback_sources", :list)
    |> validate_string_list_items(path, row, "branch_feedback_sources")
    |> expect_optional_type(path, row, "branch_feedback_scopes", :list)
    |> validate_string_list_items(path, row, "branch_feedback_scopes")
    |> expect_optional_type(path, row, "branch_contact_results", :list)
    |> validate_string_list_items(path, row, "branch_contact_results")
    |> expect_optional_type(path, row, "branch_contact_allocation_statuses", :list)
    |> validate_string_list_items(path, row, "branch_contact_allocation_statuses")
    |> expect_optional_type(
      path,
      row,
      "branch_contact_allocation_effective_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "branch_contact_allocation_effective_statuses"
    )
    |> expect_optional_type(path, row, "branch_contact_allocation_reasons", :list)
    |> validate_string_list_items(path, row, "branch_contact_allocation_reasons")
    |> expect_optional_type(
      path,
      row,
      "branch_contact_allocation_review_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "branch_contact_allocation_review_statuses"
    )
    |> expect_optional_type(
      path,
      row,
      "branch_contact_allocation_approval_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "branch_contact_allocation_approval_statuses"
    )
    |> expect_optional_type(
      path,
      row,
      "branch_contact_allocation_policy_classifications",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "branch_contact_allocation_policy_classifications"
    )
    |> expect_optional_type(path, row, "branch_realized_statuses", :list)
    |> validate_string_list_items(path, row, "branch_realized_statuses")
    |> expect_optional_type(path, row, "branch_transition_types", :list)
    |> validate_string_list_items(path, row, "branch_transition_types")
    |> expect_optional_type(path, row, "branch_transition_categories", :list)
    |> validate_string_list_items(path, row, "branch_transition_categories")
    |> expect_optional_type(path, row, "branch_transition_reasons", :list)
    |> validate_string_list_items(path, row, "branch_transition_reasons")
    |> expect_optional_type(path, row, "branch_requires_operator_review", :boolean)
    |> expect_optional_integer(path, row, "branch_requires_operator_review_count")
    |> expect_optional_type(path, row, "branch_missed_downlink_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "branch_missed_downlink_activity_ids"
    )
    |> expect_optional_type(path, row, "branch_source_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_source_activity_ids")
    |> expect_optional_type(path, row, "branch_source_window_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_source_window_ids")
    |> validate_canonical_branch_source_window_ids(path, row)
    |> expect_optional_non_negative_integer(path, row, "branch_source_window_count")
    |> expect_optional_type(path, row, "branch_source_window_bounds", :list)
    |> validate_branch_source_window_bounds(path, row)
    |> expect_optional_non_negative_integer(path, row, "branch_source_window_bound_count")
    |> expect_optional_type(path, row, "branch_untimed_source_window_ids", :list)
    |> validate_optional_stable_id_list(path, row, "branch_untimed_source_window_ids")
    |> validate_canonical_branch_untimed_source_window_ids(path, row)
    |> expect_optional_non_negative_integer(path, row, "branch_untimed_source_window_count")
    |> expect_optional_one_of(path, row, "branch_source_window_timing_coverage_status", [
      "complete",
      "partial",
      "untimed"
    ])
    |> validate_branch_source_window_coverage(path, row)
    |> expect_optional_number(path, row, "branch_earliest_starts_at_s")
    |> expect_optional_number(path, row, "branch_latest_ends_at_s")
    |> validate_branch_window_bounds(path, row)
    |> expect_optional_number(path, row, "branch_max_latency_s")
    |> expect_optional_number(path, row, "branch_planned_latency_s")
    |> expect_optional_number(path, row, "branch_required_contacts")
    |> expect_optional_number(path, row, "branch_planned_contacts")
    |> expect_optional_number(path, row, "branch_required_downlink_mb")
    |> expect_optional_number(path, row, "branch_planned_downlink_mb")
    |> expect_optional_probability(
      path,
      row,
      "branch_actual_downlink_completion_ratio"
    )
  end

  defp validate_canonical_branch_source_window_ids(issues, path, row) do
    case Map.get(row, "branch_source_window_ids") do
      ids when is_list(ids) ->
        if ids == ids |> Enum.uniq() |> Enum.sort() do
          issues
        else
          [
            error(
              "#{path}.branch_source_window_ids",
              "must equal sorted unique stable source-window IDs"
            )
            | issues
          ]
        end

      _ids ->
        issues
    end
  end

  defp validate_canonical_branch_untimed_source_window_ids(issues, path, row) do
    case Map.get(row, "branch_untimed_source_window_ids") do
      ids when is_list(ids) ->
        if ids == ids |> Enum.uniq() |> Enum.sort() do
          issues
        else
          [
            error(
              "#{path}.branch_untimed_source_window_ids",
              "must equal sorted unique untimed source-window IDs"
            )
            | issues
          ]
        end

      _ids ->
        issues
    end
  end

  defp validate_branch_source_window_bounds(issues, path, row) do
    bounds = Map.get(row, "branch_source_window_bounds")
    bounds_path = "#{path}.branch_source_window_bounds"

    issues
    |> validate_rows(bounds_path, bounds, &validate_branch_source_window_bound/3)
    |> validate_canonical_branch_source_window_bounds(bounds_path, bounds)
    |> validate_branch_source_window_bound_ids(path, row, bounds)
  end

  defp validate_branch_source_window_bound(issues, path, bound) do
    issues
    |> require_fields(path, bound, ["source_window_id"])
    |> expect_type(path, bound, "source_window_id", :binary)
    |> validate_stable_ids(path, bound, ["source_window_id"])
    |> expect_optional_number(path, bound, "earliest_starts_at_s")
    |> expect_optional_number(path, bound, "latest_ends_at_s")
    |> validate_branch_source_window_bound_value(path, bound)
    |> validate_branch_source_window_bound_order(path, bound)
  end

  defp validate_branch_source_window_bound_value(issues, path, bound) do
    if Map.has_key?(bound, "earliest_starts_at_s") or
         Map.has_key?(bound, "latest_ends_at_s") do
      issues
    else
      [error(path, "must include earliest_starts_at_s or latest_ends_at_s") | issues]
    end
  end

  defp validate_branch_source_window_bound_order(issues, path, bound) do
    earliest_starts_at_s = Map.get(bound, "earliest_starts_at_s")
    latest_ends_at_s = Map.get(bound, "latest_ends_at_s")

    if is_number(earliest_starts_at_s) and is_number(latest_ends_at_s) and
         latest_ends_at_s < earliest_starts_at_s do
      [
        error(
          "#{path}.latest_ends_at_s",
          "must be greater than or equal to earliest_starts_at_s"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_canonical_branch_source_window_bounds(issues, path, bounds)
       when is_list(bounds) do
    source_window_ids =
      Enum.map(bounds, fn
        %{} = bound -> Map.get(bound, "source_window_id")
        _bound -> nil
      end)

    if Enum.all?(source_window_ids, &is_binary/1) and
         source_window_ids == source_window_ids |> Enum.uniq() |> Enum.sort() do
      issues
    else
      [error(path, "must be sorted by unique source_window_id") | issues]
    end
  end

  defp validate_canonical_branch_source_window_bounds(issues, _path, _bounds), do: issues

  defp validate_branch_source_window_bound_ids(issues, path, row, bounds)
       when is_list(bounds) and bounds != [] do
    source_window_ids = Map.get(row, "branch_source_window_ids")

    bound_source_window_ids =
      Enum.flat_map(bounds, fn
        %{"source_window_id" => source_window_id} when is_binary(source_window_id) ->
          [source_window_id]

        _bound ->
          []
      end)

    if is_list(source_window_ids) and
         Enum.all?(bound_source_window_ids, &(&1 in source_window_ids)) do
      issues
    else
      [
        error(
          "#{path}.branch_source_window_bounds",
          "must reference branch_source_window_ids"
        )
        | issues
      ]
    end
  end

  defp validate_branch_source_window_bound_ids(issues, _path, _row, _bounds), do: issues

  defp validate_branch_source_window_coverage(issues, path, row) do
    source_window_ids = Map.get(row, "branch_source_window_ids")

    if is_list(source_window_ids) and source_window_ids != [] do
      source_window_bounds =
        case Map.get(row, "branch_source_window_bounds") do
          bounds when is_list(bounds) -> bounds
          _bounds -> []
        end

      bounded_source_window_ids =
        Enum.flat_map(source_window_bounds, fn
          %{"source_window_id" => source_window_id} when is_binary(source_window_id) ->
            [source_window_id]

          _bound ->
            []
        end)

      untimed_source_window_ids = source_window_ids -- bounded_source_window_ids

      complete_source_window_bound_count =
        Enum.count(source_window_bounds, fn bound ->
          is_number(bound["earliest_starts_at_s"]) and
            is_number(bound["latest_ends_at_s"])
        end)

      timing_coverage_status =
        cond do
          source_window_bounds == [] -> "untimed"
          complete_source_window_bound_count == length(source_window_ids) -> "complete"
          true -> "partial"
        end

      issues
      |> validate_source_window_coverage_count(
        path,
        row,
        "branch_source_window_count",
        length(source_window_ids)
      )
      |> validate_source_window_coverage_count(
        path,
        row,
        "branch_source_window_bound_count",
        length(source_window_bounds)
      )
      |> validate_source_window_coverage_count(
        path,
        row,
        "branch_untimed_source_window_count",
        length(untimed_source_window_ids)
      )
      |> validate_untimed_source_window_ids(path, row, untimed_source_window_ids)
      |> validate_source_window_timing_coverage_status(path, row, timing_coverage_status)
    else
      validate_source_window_timing_coverage_identity(issues, path, row)
    end
  end

  defp validate_source_window_timing_coverage_identity(issues, path, row) do
    field = "branch_source_window_timing_coverage_status"

    if Map.has_key?(row, field) do
      [error("#{path}.#{field}", "requires non-empty branch_source_window_ids") | issues]
    else
      issues
    end
  end

  defp validate_source_window_coverage_count(issues, path, row, field, expected_count) do
    if Map.has_key?(row, field) and Map.get(row, field) != expected_count do
      [error("#{path}.#{field}", "must equal the row-derived source-window count") | issues]
    else
      issues
    end
  end

  defp validate_untimed_source_window_ids(issues, path, row, expected_ids) do
    case Map.get(row, "branch_untimed_source_window_ids") do
      ids when is_list(ids) and ids != expected_ids ->
        [
          error(
            "#{path}.branch_untimed_source_window_ids",
            "must equal source-window IDs without bound rows"
          )
          | issues
        ]

      _ids ->
        issues
    end
  end

  defp validate_source_window_timing_coverage_status(issues, path, row, expected_status) do
    field = "branch_source_window_timing_coverage_status"

    if Map.has_key?(row, field) and Map.get(row, field) != expected_status do
      [error("#{path}.#{field}", "must equal the row-derived timing coverage status") | issues]
    else
      issues
    end
  end

  defp validate_branch_window_bounds(issues, path, row) do
    earliest_starts_at_s = Map.get(row, "branch_earliest_starts_at_s")
    latest_ends_at_s = Map.get(row, "branch_latest_ends_at_s")

    if is_number(earliest_starts_at_s) and is_number(latest_ends_at_s) and
         latest_ends_at_s < earliest_starts_at_s do
      [
        error(
          "#{path}.branch_latest_ends_at_s",
          "must be greater than or equal to branch_earliest_starts_at_s"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_trust_boundary_status_counts(issues, path, row) do
    counts = Map.get(row, "branch_event_trust_boundary_status_counts")

    issues
    |> validate_trust_boundary_status_count_map(
      path <> ".branch_event_trust_boundary_status_counts",
      counts
    )
    |> validate_trust_boundary_status_count_total(path, row, counts)
  end

  defp validate_trust_boundary_status_count_total(issues, path, row, counts)
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

  defp validate_trust_boundary_status_count_total(issues, _path, _row, _counts),
    do: issues

  defp validate_string_list_map(issues, path, row, field) do
    case Map.get(row, field) do
      %{} = grouped_values ->
        Enum.reduce(grouped_values, issues, fn {key, values}, acc ->
          entry_path = "#{path}.#{field}.#{key}"

          cond do
            not is_list(values) ->
              [error(entry_path, "must be an array") | acc]

            Enum.all?(values, &is_binary/1) ->
              acc

            true ->
              [error(entry_path, "must contain only strings") | acc]
          end
        end)

      _grouped_values ->
        issues
    end
  end
end
