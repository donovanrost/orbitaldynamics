defmodule OrbitalDynamics.CampaignPlanner.TimelinePressureBranchIds do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  @families %{
    integrity: %{
      prefix: "derived_timeline_integrity_pressure_",
      base_key: "timeline_integrity_branch_base_id",
      identity_key: "timeline_integrity_branch_identity",
      event_fields: [
        "activity_id",
        "timeline_id",
        "feedback_source",
        "timeline_integrity_issue_types",
        "missing_dependency_activity_ids",
        "missing_dependency_timeline_ids",
        "dependency_cycle_activity_ids",
        "dependency_cycle_timeline_ids",
        "dependency_order_violation_activity_ids",
        "dependency_order_violation_timeline_ids",
        "exclusivity_violation_activity_ids",
        "exclusivity_violation_timeline_ids"
      ]
    },
    dependency_impact: %{
      prefix: "derived_timeline_dependency_impact_pressure_",
      base_key: "timeline_dependency_impact_branch_base_id",
      identity_key: "timeline_dependency_impact_branch_identity",
      event_fields: [
        "activity_id",
        "timeline_id",
        "feedback_source",
        "dependency_impact_scope",
        "impacted_dependency_activity_ids",
        "impacted_dependency_timeline_ids",
        "impacted_exclusive_with_activity_ids",
        "impacted_exclusive_with_timeline_ids"
      ]
    },
    publication: %{
      prefix: "derived_timeline_publication_pressure_",
      base_key: "timeline_publication_branch_base_id",
      identity_key: "timeline_publication_branch_identity",
      event_fields: [
        "publication_id",
        "source_artifact_id",
        "feedback_source",
        "publication_status",
        "downstream_invalidation_status",
        "dependency_impact_status",
        "invalidated_downstream_product_ids",
        "changed_timeline_ids",
        "review_timeline_ids"
      ]
    },
    lifecycle_state: %{
      prefix: "derived_timeline_lifecycle_state_pressure_",
      base_key: "timeline_lifecycle_state_branch_base_id",
      identity_key: "timeline_lifecycle_state_branch_identity",
      event_fields: [
        "feedback_source",
        "timeline_lifecycle_state_status",
        "review_timeline_ids",
        "review_activity_ids",
        "invalid_activity_input_ids",
        "required_operator_action_counts",
        "import_action_counts"
      ]
    },
    activity_lifecycle_state: %{
      prefix: "derived_timeline_activity_lifecycle_state_pressure_",
      base_key: "timeline_activity_lifecycle_state_branch_base_id",
      identity_key: "timeline_activity_lifecycle_state_branch_identity",
      event_fields: [
        "activity_id",
        "timeline_id",
        "feedback_source",
        "transition_decision",
        "status_transition_decision",
        "approval_transition_decision",
        "required_operator_action",
        "required_operator_actions",
        "operator_action_reasons",
        "import_action",
        "invalid_activity_input_reasons"
      ]
    },
    activity_precondition: %{
      prefix: "derived_timeline_activity_precondition_pressure_",
      base_key: "timeline_activity_precondition_branch_base_id",
      identity_key: "timeline_activity_precondition_branch_identity",
      event_fields: [
        "activity_id",
        "timeline_id",
        "feedback_source",
        "precondition_status",
        "blocked_precondition_types",
        "review_precondition_types",
        "dependency_activity_ids",
        "dependency_timeline_ids",
        "exclusive_with_activity_ids",
        "exclusive_with_timeline_ids",
        "duplicate_dependency_activity_ids",
        "duplicate_dependency_timeline_ids",
        "duplicate_exclusivity_activity_ids",
        "duplicate_exclusivity_timeline_ids",
        "invalid_activity_input_reason"
      ]
    },
    preservation: %{
      prefix: "derived_timeline_preservation_pressure_",
      base_key: "timeline_preservation_branch_base_id",
      identity_key: "timeline_preservation_branch_identity",
      event_fields: [
        "activity_id",
        "timeline_id",
        "feedback_source",
        "timeline_preservation_status",
        "protection_decision",
        "protection_category",
        "protection_reason",
        "preserve_activity_ids",
        "preserve_timeline_ids",
        "review_change_activity_ids",
        "review_change_timeline_ids",
        "invalid_activity_input_reason"
      ]
    },
    timeline_diff: %{
      prefix: "derived_timeline_diff_",
      base_key: "timeline_diff_branch_base_id",
      identity_key: "timeline_diff_branch_identity",
      event_fields: [
        "type",
        "feedback_source",
        "timeline_id",
        "diff_status",
        "changed_fields",
        "transition_type",
        "transition_category",
        "transition_reason",
        "requires_operator_review",
        "source_activity_id",
        "replacement_activity_id",
        "source_activity_ids",
        "spacecraft_id",
        "resource_field",
        "available",
        "fuel_margin",
        "fuel_margin_threshold",
        "power_margin",
        "power_margin_threshold",
        "storage_margin",
        "storage_margin_threshold",
        "downlink_margin",
        "downlink_margin_threshold",
        "thermal_margin_c",
        "thermal_margin_c_threshold",
        "temperature_c",
        "actual_temperature_c",
        "measured_temperature_c",
        "planned_temperature_c",
        "min_operating_temperature_c",
        "max_operating_temperature_c",
        "thermal_status",
        "thermal_model",
        "thermal_source",
        "thermal_confidence",
        "spacecraft_available",
        "payload_available",
        "antenna_available",
        "ground_station_id",
        "planned_ground_station_id",
        "realized_ground_station_id",
        "ground_station_match_status",
        "direction",
        "planned_direction",
        "realized_direction",
        "direction_match_status",
        "source_window_id",
        "planned_source_window_id",
        "realized_source_window_id",
        "source_window_match_status",
        "contact_identity_mismatch_fields",
        "contact_success_factor",
        "station_throughput_factor",
        "observation_success_factor",
        "link_margin_db",
        "snr_db",
        "eb_no_db",
        "bit_error_rate",
        "packet_loss_rate",
        "frame_loss_rate",
        "carrier_lock",
        "symbol_lock",
        "link_quality_status",
        "link_profile_mismatch_fields",
        "link_protocol",
        "planned_link_protocol",
        "realized_link_protocol",
        "link_protocol_match_status",
        "frequency_band",
        "planned_frequency_band",
        "realized_frequency_band",
        "frequency_band_match_status",
        "modulation",
        "planned_modulation",
        "realized_modulation",
        "modulation_match_status",
        "coding_scheme",
        "planned_coding_scheme",
        "realized_coding_scheme",
        "coding_scheme_match_status",
        "polarization",
        "planned_polarization",
        "realized_polarization",
        "polarization_match_status",
        "data_rate_mbps",
        "planned_data_rate_mbps",
        "realized_data_rate_mbps",
        "data_rate_delta_mbps",
        "data_rate_match_status",
        "actual_throughput_mb",
        "estimated_throughput_mb",
        "expected_throughput_mb",
        "target_id",
        "planned_target_id",
        "realized_target_id",
        "target_match_status",
        "priority",
        "target_priority_source",
        "target_priority_objective_ids",
        "target_priority_objective_type",
        "latitude_deg",
        "longitude_deg",
        "minimum_elevation_deg",
        "required_downlink_mb",
        "downlink_shortfall_mb",
        "required_contacts",
        "required_observations",
        "max_latency_s",
        "planned_latency_s",
        "latency_gap_s",
        "collection_id",
        "planned_collection_id",
        "realized_collection_id",
        "collection_match_status",
        "collection_ids",
        "product_id",
        "planned_product_id",
        "realized_product_id",
        "product_match_status",
        "product_ids",
        "planned_product_ids",
        "realized_product_ids",
        "product_ids_match_status",
        "payload_id",
        "planned_payload_id",
        "realized_payload_id",
        "payload_match_status",
        "payload_ids",
        "instrument_id",
        "planned_instrument_id",
        "realized_instrument_id",
        "instrument_match_status",
        "instrument_ids",
        "observation_identity_mismatch_fields",
        "image_quality_score",
        "image_quality_status",
        "image_quality_source",
        "cloud_cover_fraction",
        "blur_score",
        "pointing_target_match_status",
        "pointing_mode_match_status",
        "planned_pointing_target_id",
        "realized_pointing_target_id",
        "planned_pointing_mode",
        "realized_pointing_mode",
        "pointing_status",
        "pointing_error_deg",
        "pointing_model",
        "pointing_source",
        "attitude_target_match_status",
        "attitude_mode_match_status",
        "planned_attitude_target_id",
        "realized_attitude_target_id",
        "planned_attitude_mode",
        "realized_attitude_mode",
        "attitude_status",
        "attitude_error_deg",
        "attitude_model",
        "attitude_source",
        "lighting_condition_match_status",
        "planned_lighting_condition",
        "realized_lighting_condition",
        "lighting_condition_detail",
        "lighting_condition_model",
        "lighting_detail_model",
        "lighting_confidence",
        "eclipse_overlap_fraction",
        "eclipse_overlap_s",
        "maneuver_id",
        "execution_uncertainty_status",
        "execution_uncertainty_source",
        "timing_3sigma_s",
        "delta_v_3sigma_magnitude_km_s",
        "starts_at_s",
        "ends_at_s",
        "application_status",
        "selected_activity_source",
        "trust_boundary"
      ]
    },
    review_replay: %{
      prefixes: [
        "derived_operational_timeline_feedback_",
        "derived_candidate_diff_replacement_",
        "derived_candidate_rejection_pressure_",
        "derived_provider_counteroffer_pressure_",
        "derived_schema_validation_pressure_",
        "derived_operational_readiness_pressure_",
        "derived_quality_gate_pressure_",
        "derived_model_acceptance_pressure_",
        "derived_validation_safety_case_pressure_",
        "derived_refresh_budget_pressure_",
        "derived_refresh_freshness_pressure_",
        "derived_command_window_feedback_",
        "derived_maneuver_review_feedback_",
        "derived_realized_feedback_",
        "derived_contact_intent_pressure_",
        "derived_station_calendar_pressure_",
        "derived_station_calendar_provider_contention_"
      ],
      base_key: "review_replay_branch_base_id",
      identity_key: "review_replay_branch_identity",
      metadata_fields: [
        "derived_source"
      ],
      event_fields: [
        "feedback_source",
        "feedback_scope",
        "feedback_key",
        "derivation_reasons",
        "trust_boundary",
        "activity_id",
        "maneuver_id",
        "timeline_id",
        "replacement_candidate_id",
        "invalidated_candidate_id",
        "freshness_status",
        "relaxed_max_candidate_activities",
        "station_calendar_entry_id",
        "station_calendar_provider_id",
        "station_calendar_provider_entry_id",
        "station_calendar_status",
        "station_availability",
        "station_reservation_id",
        "station_reserved_by",
        "station_reservation_status",
        "station_reservation_match_status",
        "provider_calendar_contention_group_id",
        "provider_calendar_contention_status",
        "ground_station_id",
        "target_id",
        "direction",
        "starts_at_s",
        "ends_at_s",
        "contact_success_factor",
        "station_throughput_factor",
        "observation_success_factor",
        "command_success_factor",
        "maneuver_success_factor",
        "cadence_import_status",
        "required_operator_action"
      ]
    }
  }

  def disambiguate_timeline_integrity_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :integrity))

  def disambiguate_timeline_dependency_impact_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :dependency_impact))

  def disambiguate_timeline_publication_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :publication))

  def disambiguate_timeline_lifecycle_state_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :lifecycle_state))

  def disambiguate_timeline_activity_lifecycle_state_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :activity_lifecycle_state))

  def disambiguate_timeline_activity_precondition_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :activity_precondition))

  def disambiguate_timeline_preservation_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :preservation))

  def disambiguate_timeline_diff_pressure_branch_ids(branches),
    do:
      disambiguate_timeline_diff(
        branches,
        Map.fetch!(@families, :timeline_diff)
      )

  def disambiguate_review_replay_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :review_replay))

  defp disambiguate_timeline_diff(branches, family) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    keep_first_branch_ids =
      branches
      |> Enum.group_by(& &1["id"])
      |> Enum.filter(fn {branch_id, duplicate_branches} ->
        branch_id?(branch_id, family) and length(duplicate_branches) > 1 and
          Enum.any?(duplicate_branches, &transition_application_branch?/1)
      end)
      |> Enum.map(fn {branch_id, _branches} -> branch_id end)
      |> MapSet.new()

    branches
    |> Enum.with_index(1)
    |> Enum.map_reduce(%{}, fn {branch, index}, seen_ids ->
      branch_id = branch["id"]

      duplicate_timeline_diff? =
        branch_id?(branch_id, family) and Map.get(id_counts, branch_id, 0) > 1

      should_disambiguate? =
        duplicate_timeline_diff? and
          (not MapSet.member?(keep_first_branch_ids, branch_id) or
             Map.has_key?(seen_ids, branch_id))

      if should_disambiguate? do
        seen_ids = Map.update(seen_ids, branch_id, 1, &(&1 + 1))

        {
          disambiguate_branch(branch, branch_id, index, family),
          seen_ids
        }
      else
        {branch, Map.put_new(seen_ids, branch_id, 1)}
      end
    end)
    |> elem(0)
    |> disambiguate_duplicate_suffixes(family)
  end

  defp disambiguate(branches, family) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if branch_id?(branch_id, family) and Map.get(id_counts, branch_id, 0) > 1 do
        disambiguate_branch(branch, branch_id, index, family)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes(family)
  end

  defp branch_id?(id, %{prefix: prefix}) when is_binary(id),
    do: String.starts_with?(id, prefix)

  defp branch_id?(id, %{prefixes: prefixes}) when is_binary(id),
    do: Enum.any?(prefixes, &String.starts_with?(id, &1))

  defp branch_id?(_id, _family), do: false

  defp transition_application_branch?(branch) do
    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.any?(&(&1["type"] == "timeline_transition_application_pressure"))
  end

  defp disambiguate_branch(branch, branch_id, index, family) do
    suffix =
      branch
      |> branch_identity(index, family)
      |> ValueEncoding.branch_id_fragment()

    branch
    |> Map.put("id", "#{branch_id}_#{suffix}")
    |> Map.update("metadata", %{}, fn metadata ->
      metadata
      |> Map.put(family.base_key, branch_id)
      |> Map.put(family.identity_key, suffix)
    end)
  end

  defp disambiguate_duplicate_suffixes(branches, family) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, family.base_key) and Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata[family.identity_key]}_#{index}"

        branch
        |> Map.put("id", "#{metadata[family.base_key]}_#{suffix}")
        |> Map.update("metadata", %{}, &Map.put(&1, family.identity_key, suffix))
      else
        branch
      end
    end)
  end

  defp branch_identity(branch, index, family) do
    metadata = Map.get(branch, "metadata", %{})
    metadata_fields = Map.get(family, :metadata_fields, [])

    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      Enum.map(metadata_fields, &metadata[&1]) ++ Enum.map(family.event_fields, &event[&1])
    end)
    |> List.flatten()
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end
end
