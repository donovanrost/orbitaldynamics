defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.BranchComparisonReport

  alias OrbitalDynamics.Schema.{
    CadenceImportValidation,
    DecisionSupportValidation,
    StableIdValidation
  }

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_type: 5,
      require_fields: 4
    ]

  @provenance_path "$.operational_feedback_provenance"
  @provenance_model "deterministic_merge_explicit_overrides_mission_state_overrides_prior_plan"
  @provenance_fields ~w(
    model
    merge_order
    input_keys
    effective_sources
    overridden_sources
    source_count
    sources
    explicit_request_override
  )
  @operational_feedback_fields ~w(
    contact_success_rate
    observation_success_rate
    image_quality_score
    image_quality_status
    image_quality_source
    cloud_cover_fraction
    blur_score
    maneuver_success_rate
    maneuver_execution_uncertainty
    command_success_rate
    station_throughput_factor
    downlink_demand_mb
    downlink_demand_sources
    downlink_demand_context
    target_priority_overrides
    resource_margin_overrides
    resource_availability_overrides
  )
  @source_provenance_fields ~w(
    source_plan_id
    source_planner
    source_plan_generated_at
    source_provenance
  )
  @recommendation_reasons %{
    "auto_approvable" => "best_expected_score_within_auto_approval_policy",
    "operator_review_required" => "best_expected_score_requiring_operator_review",
    "blocked_by_policy" => "all_branches_blocked_highest_score_reported_for_review"
  }
  @branch_comparison_assumptions %{
    "branch_order" => "score_descending_then_branch_id",
    "score_delta_from_recommended" => "row_score_minus_recommended_branch_score",
    "score" => "probability_weighted_expected_score",
    "raw_score" => "score_before_branch_probability_multiplier",
    "branch_probability" => "independent branch likelihood or confidence multiplier in [0,1]",
    "expected_score" => "raw_score_times_branch_probability_times_probability_weight",
    "blocked_branches_remain_visible" => true
  }
  @strategy_ranking_comparison_fields %{
    "source" => "campaign_strategy.branch_comparison_report",
    "objective" => "strategy_branch_score",
    "objective_direction" => "maximize",
    "left_label" => "normalized_branch_order",
    "right_label" => "score_ranked_branches"
  }
  @strategy_ranking_comparison_assumptions %{
    "comparison_scope" => "ranked_scenario_rows",
    "rank_source" => "input_order",
    "external_solver" => false
  }
  @strategy_pareto_frontier_fields ~w(
    source
    alternative_count
    objective_count
    frontier_count
    dominated_count
    frontier_ids
    dominated_ids
    objective_directions
    assumptions
  )
  @strategy_pareto_frontier_row_fields ~w(
    id
    scenario_id
    objective_values
    objective_keys
    frontier
    dominated_by_ids
    dominates_ids
  )
  @branch_comparison_feedback_fields [
    {"feedback_score_adjustment", "score_adjustment"},
    {"contact_success_factor", "contact_success_factor"},
    {"contact_success_factor_source", "contact_success_factor_source"},
    {"contact_success_factor_activity_source", "contact_success_factor_activity_source"},
    {"observation_success_factor", "observation_success_factor"},
    {"observation_success_factor_source", "observation_success_factor_source"},
    {"observation_success_factor_activity_source", "observation_success_factor_activity_source"},
    {"image_quality_score", "image_quality_score"},
    {"image_quality_score_source", "image_quality_score_source"},
    {"image_quality_statuses", "image_quality_statuses"},
    {"image_quality_sources", "image_quality_sources"},
    {"cloud_cover_fraction", "cloud_cover_fraction"},
    {"cloud_cover_fraction_source", "cloud_cover_fraction_source"},
    {"blur_score", "blur_score"},
    {"blur_score_source", "blur_score_source"},
    {"maneuver_success_factor", "maneuver_success_factor"},
    {"maneuver_success_factor_source", "maneuver_success_factor_source"},
    {"command_success_factor", "command_success_factor"},
    {"command_success_factor_source", "command_success_factor_source"},
    {"station_throughput_factor", "station_throughput_factor"},
    {"station_throughput_factor_source", "station_throughput_factor_source"},
    {"station_throughput_factor_activity_source", "station_throughput_factor_activity_source"},
    {"feedback_weight_sources", "feedback_weight_sources"}
  ]
  @branch_comparison_mission_identity_fields [
    {"branch_scenario_ids", ["scenario_id"]},
    {"branch_target_ids", ["target_id"]},
    {"branch_collection_ids", ["collection_id", "collection_ids"]},
    {"branch_product_ids", ["product_id", "product_ids"]},
    {"branch_payload_ids", ["payload_id", "payload_ids"]},
    {"branch_instrument_ids", ["instrument_id", "instrument_ids"]},
    {"branch_objective_ids", ["objective_id", "objective_ids"]},
    {"branch_objective_types", ["objective_type"]},
    {"branch_objective_statuses", ["objective_status"]},
    {"branch_source_objective_statuses", ["source_objective_status"]}
  ]
  @branch_comparison_source_window_fields ~w(
    branch_source_window_ids
    branch_source_window_count
    branch_source_window_bounds
    branch_source_window_bound_count
    branch_untimed_source_window_ids
    branch_untimed_source_window_count
    branch_partially_timed_source_window_ids
    branch_partially_timed_source_window_count
    branch_source_window_timing_coverage_status
  )
  @branch_comparison_operational_event_fields [
    {"branch_feedback_sources", ["feedback_source"]},
    {"branch_feedback_scopes", ["feedback_scope"]},
    {"branch_contact_results", ["contact_result"]},
    {"branch_contact_allocation_statuses", ["allocation_status"]},
    {"branch_contact_allocation_effective_statuses", ["effective_allocation_status"]},
    {"branch_contact_allocation_reasons", ["allocation_reason"]},
    {"branch_contact_allocation_review_statuses", ["review_status"]},
    {"branch_contact_allocation_approval_statuses", ["approval_status"]},
    {"branch_contact_allocation_policy_classifications", ["policy_classification"]},
    {"branch_realized_statuses", ["realized_status"]},
    {"branch_source_activity_ids", ["source_activity_id", "source_activity_ids"]}
  ]
  @branch_comparison_transition_fields [
    {"branch_transition_types", "transition_type"},
    {"branch_transition_categories", "transition_category"},
    {"branch_transition_reasons", "transition_reason"}
  ]
  @branch_comparison_execution_uncertainty_fields [
    {"branch_maneuver_execution_uncertainty_activity_ids", "activity_id"},
    {"branch_maneuver_execution_uncertainty_timeline_ids", "timeline_id"},
    {"branch_maneuver_execution_uncertainty_maneuver_ids", "maneuver_id"},
    {"branch_maneuver_execution_uncertainty_statuses", "execution_uncertainty_status"},
    {"branch_maneuver_execution_uncertainty_sources", "execution_uncertainty_source"}
  ]
  @branch_comparison_execution_uncertainty_maximum_fields [
    {"branch_maneuver_execution_uncertainty_max_timing_3sigma_s", "timing_3sigma_s"},
    {"branch_maneuver_execution_uncertainty_max_delta_v_3sigma_magnitude_km_s",
     "delta_v_3sigma_magnitude_km_s"}
  ]
  @branch_comparison_operational_readiness_fields [
    {"branch_operational_readiness_levels", ["readiness_level"],
     ["readiness_level", "readiness_levels"]},
    {"branch_operational_readiness_import_classifications", ["import_classification"],
     ["import_classification", "import_classifications"]},
    {"branch_operational_readiness_statuses", ["operational_readiness_status"],
     ["operational_readiness_status", "operational_readiness_statuses"]},
    {"branch_operational_readiness_gate_statuses", ["readiness_gate_status"],
     ["readiness_gate_status", "gate_statuses"]},
    {"branch_operational_readiness_gate_classifications", ["readiness_gate_classification"],
     ["readiness_gate_classification", "gate_classifications"]},
    {"branch_operational_readiness_review_required_gate_ids", ["review_required_gate_ids"],
     ["review_required_gate_ids"]},
    {"branch_operational_readiness_analysis_only_gate_ids", ["analysis_only_gate_ids"],
     ["analysis_only_gate_ids"]},
    {"branch_operational_readiness_blocked_gate_ids", ["blocked_gate_ids"], ["blocked_gate_ids"]},
    {"branch_operational_readiness_non_passed_gate_ids", ["non_passed_gate_ids"],
     ["non_passed_gate_ids"]}
  ]
  @branch_comparison_priority_target_fields [
    {"required", "required_target_ids"},
    {"satisfied", "satisfied_target_ids"},
    {"missed", "missed_target_ids"}
  ]
  @branch_comparison_priority_scalar_fields [
    {"priority_commitment_required_observation_count", "required_observation_count"},
    {"priority_commitment_planned_observation_count", "planned_observation_count"},
    {"priority_commitment_missing_observation_count", "missing_observation_count"},
    {"priority_commitment_ratio", "ratio"}
  ]
  @branch_comparison_downlink_fields [
    {"downlink_completion_required_contacts", "required_contacts"},
    {"downlink_completion_planned_contacts", "planned_contacts"},
    {"downlink_completion_required_downlink_mb", "required_downlink_mb"},
    {"downlink_completion_planned_downlink_mb", "planned_downlink_mb"},
    {"downlink_completion_ratio", "ratio"}
  ]
  @branch_comparison_coverage_revisit_fields [
    {"coverage_observed_target_count", "coverage", "observed_target_count"},
    {"revisit_count", "revisit", "revisit_count"}
  ]
  @branch_comparison_collection_latency_fields [
    {"collection_latency_ratio", "ratio"},
    {"collection_latency_objective_count", "objective_count"},
    {"collection_latency_observation_count", "observation_count"},
    {"collection_latency_satisfied_observation_count", "satisfied_observation_count"},
    {"collection_latency_unsatisfied_observation_count", "unsatisfied_observation_count"}
  ]
  @branch_comparison_resource_impact_fields [
    {"fuel_margin", "fuel_margin"},
    {"power_margin", "power_margin"},
    {"storage_margin", "storage_margin"},
    {"downlink_capacity_margin", "downlink_capacity_margin"},
    {"thermal_margin_c", "thermal_margin_c"},
    {"spacecraft_availability", "spacecraft_availability"},
    {"payload_availability", "payload_availability"},
    {"antenna_availability", "antenna_availability"},
    {"resource_score_adjustment", "score_adjustment"},
    {"fuel_preservation_mode", "fuel_preservation_mode"}
  ]
  @branch_comparison_resource_projection_minimum_fields [
    {"projected_storage_margin", "projected_storage_margin"},
    {"projected_downlink_margin", "projected_downlink_margin"},
    {"projected_power_margin", "projected_power_margin"}
  ]
  @branch_comparison_resource_projection_maximum_fields [
    {"projected_storage_overflow_mb", "projected_storage_overflow_mb"},
    {"projected_downlink_shortfall_mb", "projected_downlink_shortfall_mb"},
    {"projected_battery_overuse_wh", "projected_battery_overuse_wh"},
    {"storage_limited_downlinked_mb", "storage_limited_downlinked_mb"},
    {"unused_downlink_capacity_mb", "unused_downlink_capacity_mb"}
  ]
  @branch_comparison_resource_projection_peak_fields [
    {"resource_projection_peak_storage_overflow_mb", "storage_overflow_mb"},
    {"resource_projection_peak_downlink_shortfall_mb", "downlink_shortfall_mb"},
    {"resource_projection_peak_battery_overuse_wh", "battery_overuse_wh"},
    {"resource_projection_peak_unused_downlink_capacity_mb", "unused_downlink_capacity_mb"}
  ]
  @branch_comparison_first_resource_pressure_fields [
    {"first_resource_pressure_activity_id", "activity_id"},
    {"first_resource_pressure_activity_type", "activity_type"},
    {"first_resource_pressure_starts_at_s", "starts_at_s"},
    {"first_resource_pressure_direction", "direction"},
    {"first_resource_pressure_ground_station_id", "ground_station_id"},
    {"first_resource_pressure_station_calendar_entry_id", "station_calendar_entry_id"},
    {"first_resource_pressure_station_calendar_provider_id", "station_calendar_provider_id"},
    {"first_resource_pressure_station_calendar_provider_entry_id",
     "station_calendar_provider_entry_id"},
    {"first_resource_pressure_station_calendar_directions", "station_calendar_directions"}
  ]
  @branch_comparison_target_identity_fields ~w(
    target_branch_base_id
    target_branch_identity
  )
  @branch_comparison_station_calendar_fields [
    {"branch_station_calendar_entry_ids",
     ["station_calendar_entry_id", "station_calendar_entry_ids"]},
    {"branch_station_calendar_provider_ids",
     ["station_calendar_provider_id", "station_calendar_provider_ids"]},
    {"branch_station_calendar_provider_entry_ids",
     ["station_calendar_provider_entry_id", "station_calendar_provider_entry_ids"]},
    {"branch_station_calendar_directions",
     ["station_calendar_direction", "station_calendar_directions"]},
    {"branch_station_calendar_statuses", ["station_calendar_status", "calendar_status"]},
    {"branch_station_calendar_trust_boundary_statuses",
     ["station_calendar_trust_boundary_status"]}
  ]
  @branch_comparison_station_reservation_fields [
    {"branch_station_reservation_ids",
     ["station_reservation_id", "reservation_id", "station_calendar_reservation_ids"]},
    {"branch_station_reserved_by",
     ["station_reserved_by", "reserved_by", "station_calendar_reserved_by"]},
    {"branch_station_reservation_statuses",
     ["station_reservation_status", "reservation_status", "station_calendar_reservation_statuses"]},
    {"branch_station_reservation_match_statuses",
     ["station_reservation_match_status", "reservation_match_status"]}
  ]
  @branch_comparison_station_reservation_conflict_fields [
    {"branch_station_reservation_conflict_contact_ids",
     ["contact_id", "source_activity_id", "source_activity_ids"], false},
    {"branch_station_reservation_conflict_reservation_ids",
     ["station_reservation_id", "reservation_id"], false},
    {"branch_station_reservation_conflict_match_statuses",
     ["station_reservation_match_status", "reservation_match_status"], true}
  ]
  @branch_comparison_capacity_pack_contact_map_fields ~w(
    capacity_pack_contact_ids_by_direction
    capacity_pack_selected_contact_ids_by_direction
    capacity_pack_deferred_contact_ids_by_direction
  )
  @branch_comparison_capacity_pack_numeric_map_fields ~w(
    capacity_pack_required_capacity_fraction_by_direction
    capacity_pack_selected_required_capacity_fraction_by_direction
    capacity_pack_deferred_required_capacity_fraction_by_direction
  )
  @branch_comparison_timeline_integrity_fields [
    {"branch_timeline_integrity_activity_ids", "activity_id"},
    {"branch_timeline_integrity_timeline_ids", "timeline_id"},
    {"branch_missing_dependency_activity_ids", "missing_dependency_activity_ids"},
    {"branch_missing_dependency_timeline_ids", "missing_dependency_timeline_ids"},
    {"branch_dependency_cycle_activity_ids", "dependency_cycle_activity_ids"},
    {"branch_dependency_cycle_timeline_ids", "dependency_cycle_timeline_ids"},
    {"branch_dependency_order_violation_activity_ids", "dependency_order_violation_activity_ids"},
    {"branch_dependency_order_violation_timeline_ids", "dependency_order_violation_timeline_ids"},
    {"branch_exclusivity_violation_activity_ids", "exclusivity_violation_activity_ids"},
    {"branch_exclusivity_violation_timeline_ids", "exclusivity_violation_timeline_ids"},
    {"branch_exclusivity_violation_groups", "exclusivity_violation_group"}
  ]
  @branch_comparison_timeline_dependency_impact_fields [
    {"branch_timeline_dependency_impact_activity_ids", "activity_id"},
    {"branch_timeline_dependency_impact_timeline_ids", "timeline_id"},
    {"branch_timeline_dependency_impact_scopes", "dependency_impact_scope"},
    {"branch_impacted_dependency_activity_ids", "impacted_dependency_activity_ids"},
    {"branch_impacted_dependency_timeline_ids", "impacted_dependency_timeline_ids"},
    {"branch_impacted_exclusive_with_activity_ids", "impacted_exclusive_with_activity_ids"},
    {"branch_impacted_exclusive_with_timeline_ids", "impacted_exclusive_with_timeline_ids"}
  ]
  @branch_comparison_timeline_publication_fields [
    {"branch_timeline_publication_ids", "publication_id", "publication_ids"},
    {"branch_timeline_publication_statuses", "publication_status", nil},
    {"branch_timeline_publication_source_artifact_ids", "source_artifact_id",
     "source_artifact_ids"},
    {"branch_timeline_publication_source_artifact_types", "source_artifact_type", nil},
    {"branch_timeline_publication_downstream_invalidation_statuses",
     "downstream_invalidation_status", nil},
    {"branch_timeline_publication_invalidated_downstream_product_ids",
     "invalidated_downstream_product_ids", "invalidated_downstream_product_ids"},
    {"branch_timeline_publication_downstream_invalidation_reasons",
     "downstream_invalidation_reasons", "downstream_invalidation_reasons"},
    {"branch_timeline_publication_dependency_impact_statuses", "dependency_impact_status", nil},
    {"branch_timeline_publication_impacted_source_activity_ids", "impacted_source_activity_ids",
     "impacted_source_activity_ids"},
    {"branch_timeline_publication_impacted_source_timeline_ids", "impacted_source_timeline_ids",
     "impacted_source_timeline_ids"},
    {"branch_timeline_publication_dependent_activity_ids", "dependent_activity_ids",
     "dependent_activity_ids"},
    {"branch_timeline_publication_dependent_timeline_ids", "dependent_timeline_ids",
     "dependent_timeline_ids"},
    {"branch_timeline_publication_changed_fields", "changed_fields", "changed_fields"},
    {"branch_timeline_publication_changed_timeline_ids", "changed_timeline_ids",
     "changed_timeline_ids"},
    {"branch_timeline_publication_review_timeline_ids", "review_timeline_ids",
     "review_timeline_ids"}
  ]
  @branch_comparison_timeline_lifecycle_state_value_fields [
    {"branch_timeline_lifecycle_state_statuses", "timeline_lifecycle_state_status", nil},
    {"branch_timeline_lifecycle_state_review_timeline_ids", "review_timeline_ids",
     "review_timeline_ids"},
    {"branch_timeline_lifecycle_state_review_activity_ids", "review_activity_ids",
     "review_activity_ids"},
    {"branch_timeline_lifecycle_state_invalid_activity_input_ids", "invalid_activity_input_ids",
     "invalid_activity_input_ids"}
  ]
  @branch_comparison_timeline_lifecycle_state_action_fields [
    {"branch_timeline_lifecycle_state_required_operator_actions",
     "required_operator_action_counts", ["none"]},
    {"branch_timeline_lifecycle_state_import_actions", "import_action_counts", []}
  ]
  @branch_comparison_timeline_activity_lifecycle_state_fields [
    {"branch_timeline_activity_lifecycle_state_activity_ids", ["activity_id"],
     ["activity_id", "activity_ids", "action_routing_activity_ids", "review_activity_ids"]},
    {"branch_timeline_activity_lifecycle_state_timeline_ids", ["timeline_id"],
     ["timeline_id", "timeline_ids", "action_routing_timeline_ids"]},
    {"branch_timeline_activity_lifecycle_state_transition_decisions", ["transition_decision"],
     ["transition_decision", "transition_decisions"]},
    {"branch_timeline_activity_lifecycle_state_required_operator_actions",
     ["required_operator_action", "required_operator_actions"],
     ["required_operator_action", "required_operator_actions", "required_operator_action_counts"]},
    {"branch_timeline_activity_lifecycle_state_import_actions", ["import_action"],
     ["import_action", "import_actions", "import_action_counts"]},
    {"branch_timeline_activity_lifecycle_state_invalid_activity_input_reasons",
     ["invalid_activity_input_reasons"], []},
    {"branch_timeline_activity_lifecycle_state_status_transition_categories", [],
     ["status_transition_categories"]},
    {"branch_timeline_activity_lifecycle_state_approval_transition_categories", [],
     ["approval_transition_categories"]}
  ]
  @branch_comparison_timeline_activity_precondition_fields [
    {"branch_timeline_activity_precondition_activity_ids", "activity_id"},
    {"branch_timeline_activity_precondition_timeline_ids", "timeline_id"},
    {"branch_timeline_activity_precondition_statuses", "precondition_status"},
    {"branch_timeline_activity_precondition_blocked_types", "blocked_precondition_types"},
    {"branch_timeline_activity_precondition_review_types", "review_precondition_types"},
    {"branch_timeline_activity_precondition_dependency_activity_ids", "dependency_activity_ids"},
    {"branch_timeline_activity_precondition_dependency_timeline_ids", "dependency_timeline_ids"},
    {"branch_timeline_activity_precondition_exclusive_with_activity_ids",
     "exclusive_with_activity_ids"},
    {"branch_timeline_activity_precondition_exclusive_with_timeline_ids",
     "exclusive_with_timeline_ids"},
    {"branch_timeline_activity_precondition_duplicate_dependency_activity_ids",
     "duplicate_dependency_activity_ids"},
    {"branch_timeline_activity_precondition_duplicate_dependency_timeline_ids",
     "duplicate_dependency_timeline_ids"},
    {"branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids",
     "duplicate_exclusivity_activity_ids"},
    {"branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids",
     "duplicate_exclusivity_timeline_ids"},
    {"branch_timeline_activity_precondition_invalid_activity_input_reasons",
     "invalid_activity_input_reason"}
  ]
  @branch_comparison_timeline_preservation_fields [
    {"branch_timeline_preservation_activity_ids", "activity_id"},
    {"branch_timeline_preservation_timeline_ids", "timeline_id"},
    {"branch_timeline_preservation_statuses", "timeline_preservation_status"},
    {"branch_timeline_preservation_protection_decisions", "protection_decision"},
    {"branch_timeline_preservation_protection_categories", "protection_category"},
    {"branch_timeline_preservation_protection_reasons", "protection_reason"},
    {"branch_timeline_preservation_preserve_activity_ids", "preserve_activity_ids"},
    {"branch_timeline_preservation_preserve_timeline_ids", "preserve_timeline_ids"},
    {"branch_timeline_preservation_review_change_activity_ids", "review_change_activity_ids"},
    {"branch_timeline_preservation_review_change_timeline_ids", "review_change_timeline_ids"},
    {"branch_timeline_preservation_invalid_activity_input_reasons",
     "invalid_activity_input_reason"}
  ]
  @branch_comparison_resource_projection_availability_pairs [
    {"resource_projection_payload_unavailable_count",
     "resource_projection_payload_unavailable_spacecraft_ids", "payload_unavailable"},
    {"resource_projection_degraded_payload_unavailable_count",
     "resource_projection_degraded_payload_unavailable_spacecraft_ids",
     "spacecraft_degraded_payload_unavailable"},
    {"resource_projection_antenna_unavailable_count",
     "resource_projection_antenna_unavailable_spacecraft_ids", "antenna_unavailable"},
    {"resource_projection_activity_type_suppressed_count",
     "resource_projection_activity_type_suppressed_spacecraft_ids",
     "activity_type_suppressed_by_resource_summary"},
    {"resource_projection_activity_type_incompatible_count",
     "resource_projection_activity_type_incompatible_spacecraft_ids",
     "activity_type_incompatible_with_resource_summary"}
  ]
  @resource_projection_availability_pressure_types ~w(
    spacecraft_unavailable
    payload_unavailable
    spacecraft_degraded_payload_unavailable
    antenna_unavailable
    activity_type_suppressed_by_resource_summary
    activity_type_incompatible_with_resource_summary
  )
  @stable_id_regex ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def validate(issues, artifact) do
    issues
    |> StableIdValidation.validate_optional_stable_ids("$", artifact, ["source_repair_id"])
    |> validate_branch_metadata(artifact)
    |> validate_ranked_branch_eligibility(artifact)
    |> validate_recommended_branch_evidence(artifact)
    |> validate_branch_comparison_identity(artifact)
    |> validate_branch_comparison_assumptions(artifact)
    |> validate_strategy_ranking_comparison_identity(artifact)
    |> validate_strategy_ranking_comparison_score_ranked_evidence(artifact)
    |> validate_strategy_pareto_frontier_evidence(artifact)
    |> validate_branch_comparison_target_identity(artifact)
    |> validate_branch_comparison_event_summary(artifact)
    |> validate_branch_comparison_score_evidence(artifact)
    |> validate_branch_comparison_operational_evidence(artifact)
    |> validate_branch_comparison_risk_classifications(artifact)
    |> validate_branch_comparison_resource_impacts(artifact)
    |> validate_branch_comparison_resource_projection_summary(artifact)
    |> validate_branch_comparison_resource_projection_aggregates(artifact)
    |> validate_branch_comparison_resource_projection_availability(artifact)
    |> validate_branch_comparison_resource_projection_peaks(artifact)
    |> validate_branch_comparison_first_resource_pressure_context(artifact)
    |> validate_branch_comparison_feedback_evidence(artifact)
    |> validate_branch_comparison_priority_commitments(artifact)
    |> validate_branch_comparison_downlink_completion(artifact)
    |> validate_branch_comparison_coverage_and_revisit(artifact)
    |> validate_branch_comparison_collection_latency(artifact)
    |> validate_branch_comparison_repair_score_evidence(artifact)
    |> validate_branch_comparison_repair_link_selection_evidence(artifact)
    |> validate_branch_comparison_repair_constraint_evidence(artifact)
    |> validate_source_provenance(artifact)
    |> OrbitalDynamics.Schema.CampaignStrategyScoreTermContracts.validate(artifact)
    |> validate_optional_score_term_report(Map.get(artifact, "score_term_report"))
    |> OrbitalDynamics.Schema.CampaignStrategyObjectiveTradeoffContracts.validate(artifact)
    |> validate_optional_objective_tradeoff_report(Map.get(artifact, "objective_tradeoff_report"))
    |> validate_optional_pareto_frontier_report(Map.get(artifact, "pareto_frontier_report"))
    |> OrbitalDynamics.Schema.CampaignStrategyOperatorReviewContracts.validate(artifact)
    |> validate_optional_cadence_import_manifest(Map.get(artifact, "cadence_import_manifest"))
    |> validate_optional_operational_feedback_provenance(artifact)
  end

  defp validate_branch_metadata(
         issues,
         %{"branches" => branches, "strategy_metadata" => %{} = metadata}
       )
       when is_list(branches) do
    issues =
      expect_equal(
        issues,
        "$.strategy_metadata",
        metadata,
        "branch_count",
        length(branches)
      )

    case Enum.filter(branches, &(is_map(&1) and Map.get(&1, "branch_id") == "baseline")) do
      [_baseline] ->
        expect_equal(
          issues,
          "$.strategy_metadata",
          metadata,
          "baseline_branch_id",
          "baseline"
        )

      _missing_or_ambiguous_baseline ->
        issues
    end
  end

  defp validate_branch_metadata(issues, _artifact), do: issues

  defp validate_ranked_branch_eligibility(
         issues,
         %{
           "branches" => branches,
           "recommendation" => %{"ranked_branch_ids" => ranked_branch_ids}
         }
       )
       when is_list(branches) and is_list(ranked_branch_ids) do
    if Enum.all?(branches, &valid_branch_rank_input?/1) and
         Enum.all?(ranked_branch_ids, &is_binary/1) do
      branch_ids = Enum.map(branches, &Map.fetch!(&1, "branch_id"))

      selectable_branch_ids =
        branches
        |> Enum.reject(&(&1["approval_status"] == "blocked_by_policy"))
        |> Enum.map(&Map.fetch!(&1, "branch_id"))

      expected_branch_ids =
        if selectable_branch_ids == [], do: branch_ids, else: selectable_branch_ids

      if ranked_branch_ids == expected_branch_ids do
        issues
      else
        [
          error(
            "$.recommendation.ranked_branch_ids",
            "must equal selectable branch IDs in enclosing branch order, falling back to all branch IDs when every branch is blocked"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_ranked_branch_eligibility(issues, _artifact), do: issues

  defp valid_branch_rank_input?(%{"branch_id" => id, "approval_status" => status}),
    do: is_binary(id) and is_binary(status)

  defp valid_branch_rank_input?(_branch), do: false

  defp validate_recommended_branch_evidence(
         issues,
         %{
           "branches" => branches,
           "recommendation" =>
             %{"recommended_branch_id" => recommended_branch_id} =
               recommendation
         }
       )
       when is_list(branches) and is_binary(recommended_branch_id) do
    case Enum.filter(
           branches,
           &(is_map(&1) and Map.get(&1, "branch_id") == recommended_branch_id)
         ) do
      [recommended_branch] ->
        issues
        |> validate_optional_copy(
          "$.recommendation.approval_status",
          recommendation,
          "approval_status",
          Map.get(recommended_branch, "approval_status"),
          "must match the recommended branch approval_status"
        )
        |> validate_optional_copy(
          "$.recommendation.risks_remaining",
          recommendation,
          "risks_remaining",
          Map.get(recommended_branch, "risk_indicators"),
          "must match the recommended branch risk_indicators"
        )
        |> validate_optional_copy(
          "$.recommendation.requires_approval",
          recommendation,
          "requires_approval",
          Map.get(recommended_branch, "approval_requirements"),
          "must match the recommended branch approval_requirements"
        )
        |> validate_recommendation_reason(recommendation, recommended_branch)

      _missing_or_ambiguous_branch ->
        issues
    end
  end

  defp validate_recommended_branch_evidence(issues, _artifact), do: issues

  defp validate_recommendation_reason(issues, recommendation, recommended_branch) do
    case Map.fetch(@recommendation_reasons, Map.get(recommended_branch, "approval_status")) do
      {:ok, expected_reason} ->
        validate_optional_copy(
          issues,
          "$.recommendation.reason",
          recommendation,
          "reason",
          expected_reason,
          "must match the recommended branch approval_status reason"
        )

      :error ->
        issues
    end
  end

  defp validate_branch_comparison_identity(
         issues,
         %{
           "branches" => branches,
           "recommendation" => %{} = recommendation,
           "branch_comparison_report" => %{"rows" => rows} = report
         }
       )
       when is_list(branches) and is_list(rows) do
    issues =
      validate_optional_copy(
        issues,
        "$.branch_comparison_report.recommended_branch_id",
        report,
        "recommended_branch_id",
        Map.get(recommendation, "recommended_branch_id"),
        "must match the enclosing CampaignStrategy recommendation"
      )

    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) do
      branch_ids = Enum.map(branches, &Map.fetch!(&1, "branch_id"))
      report_branch_ids = Enum.map(rows, &Map.fetch!(&1, "branch_id"))

      if report_branch_ids == branch_ids do
        rows
        |> Enum.with_index(1)
        |> Enum.reduce(issues, fn {row, rank}, acc ->
          branch_id = Map.fetch!(row, "branch_id")
          path = "$.branch_comparison_report.rows[#{rank - 1}]"

          acc
          |> validate_optional_copy(
            path <> ".id",
            row,
            "id",
            "branch_comparison:#{branch_id}",
            "must match the deterministic branch comparison row ID"
          )
          |> validate_optional_copy(
            path <> ".rank",
            row,
            "rank",
            rank,
            "must match the one-based branch comparison row position"
          )
        end)
      else
        [
          error(
            "$.branch_comparison_report.rows",
            "branch_id values must match enclosing CampaignStrategy branches in order"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_branch_comparison_identity(issues, _artifact), do: issues

  defp validate_branch_comparison_assumptions(
         issues,
         %{"branch_comparison_report" => %{"assumptions" => assumptions}}
       )
       when is_map(assumptions) do
    Enum.reduce(@branch_comparison_assumptions, issues, fn {field, expected}, acc ->
      validate_optional_copy(
        acc,
        "$.branch_comparison_report.assumptions.#{field}",
        assumptions,
        field,
        expected,
        "must match the deterministic branch comparison assumption"
      )
    end)
  end

  defp validate_branch_comparison_assumptions(issues, _artifact), do: issues

  defp validate_strategy_ranking_comparison_identity(
         issues,
         %{"ranking_comparison_report" => %{} = report}
       ) do
    issues =
      Enum.reduce(@strategy_ranking_comparison_fields, issues, fn {field, expected}, acc ->
        validate_optional_copy(
          acc,
          "$.ranking_comparison_report.#{field}",
          report,
          field,
          expected,
          "must match the CampaignStrategy ranking-report producer identity"
        )
      end)

    case Map.get(report, "assumptions") do
      %{} = assumptions ->
        Enum.reduce(
          @strategy_ranking_comparison_assumptions,
          issues,
          fn {field, expected}, acc ->
            validate_optional_copy(
              acc,
              "$.ranking_comparison_report.assumptions.#{field}",
              assumptions,
              field,
              expected,
              "must match the deterministic ranking-comparison assumption"
            )
          end
        )

      _assumptions ->
        issues
    end
  end

  defp validate_strategy_ranking_comparison_identity(issues, _artifact), do: issues

  defp validate_strategy_ranking_comparison_score_ranked_evidence(
         issues,
         %{
           "branches" => branches,
           "ranking_comparison_report" => %{"rows" => rows} = report
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_score_input?/1) and Enum.all?(rows, &is_map/1) do
      branch_count = length(branches)

      issues =
        Enum.reduce(
          [
            {"left_count", branch_count},
            {"right_count", branch_count},
            {"matched_count", branch_count},
            {"left_only_count", 0},
            {"right_only_count", 0},
            {"row_count", branch_count}
          ],
          issues,
          fn {field, expected}, acc ->
            validate_optional_copy(
              acc,
              "$.ranking_comparison_report.#{field}",
              report,
              field,
              expected,
              "must match the deterministic all-branch ranking comparison count"
            )
          end
        )

      issues =
        case {Map.get(report, "winner"), List.first(branches)} do
          {%{} = winner, %{"branch_id" => branch_id}} ->
            validate_optional_copy(
              issues,
              "$.ranking_comparison_report.winner.right_scenario_id",
              winner,
              "right_scenario_id",
              branch_id,
              "must match the first score-ranked CampaignStrategy branch"
            )

          _winner ->
            issues
        end

      if length(rows) == branch_count do
        branches
        |> Enum.zip(rows)
        |> Enum.with_index(1)
        |> Enum.reduce(issues, fn {{branch, row}, rank}, acc ->
          validate_strategy_ranking_comparison_score_ranked_row(acc, branch, row, rank)
        end)
      else
        [
          error(
            "$.ranking_comparison_report.rows",
            "row count must match enclosing CampaignStrategy branches"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_strategy_ranking_comparison_score_ranked_evidence(issues, _artifact),
    do: issues

  defp validate_strategy_ranking_comparison_score_ranked_row(issues, branch, row, rank) do
    path = "$.ranking_comparison_report.rows[#{rank - 1}]"
    branch_id = Map.fetch!(branch, "branch_id")
    branch_score = Map.fetch!(branch, "score")

    issues
    |> validate_optional_copy(
      path <> ".scenario_id",
      row,
      "scenario_id",
      branch_id,
      "must match the score-ranked CampaignStrategy branch"
    )
    |> validate_optional_copy(
      path <> ".status",
      row,
      "status",
      "matched",
      "must remain matched across input-order and score-ranked branches"
    )
    |> validate_optional_copy(
      path <> ".right_rank",
      row,
      "right_rank",
      rank,
      "must match the one-based score-ranked CampaignStrategy branch position"
    )
    |> validate_optional_copy(
      path <> ".left_value",
      row,
      "left_value",
      branch_score,
      "must match the CampaignStrategy branch score"
    )
    |> validate_optional_copy(
      path <> ".right_value",
      row,
      "right_value",
      branch_score,
      "must match the CampaignStrategy branch score"
    )
  end

  defp branch_score_input?(%{"branch_id" => branch_id, "score" => score}),
    do: is_binary(branch_id) and is_number(score)

  defp branch_score_input?(_branch), do: false

  defp validate_strategy_pareto_frontier_evidence(
         issues,
         %{
           "branch_comparison_report" => %{"rows" => branch_rows} = branch_report,
           "pareto_frontier_report" => %{"rows" => rows} = report
         }
       )
       when is_list(branch_rows) and is_list(rows) do
    if Enum.all?(branch_rows, &is_map/1) and Enum.all?(rows, &is_map/1) do
      expected = BranchComparisonReport.pareto_frontier_report(branch_report)

      issues =
        Enum.reduce(@strategy_pareto_frontier_fields, issues, fn field, acc ->
          validate_optional_copy(
            acc,
            "$.pareto_frontier_report.#{field}",
            report,
            field,
            Map.get(expected, field),
            "must match the Pareto report replayed from branch_comparison_report"
          )
        end)

      expected_rows = Map.fetch!(expected, "rows")

      if length(rows) == length(expected_rows) do
        expected_rows
        |> Enum.zip(rows)
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {{expected_row, row}, index}, acc ->
          validate_strategy_pareto_frontier_row(acc, expected_row, row, index)
        end)
      else
        [
          error(
            "$.pareto_frontier_report.rows",
            "rows must match the Pareto report replayed from branch_comparison_report"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_strategy_pareto_frontier_evidence(issues, _artifact), do: issues

  defp validate_strategy_pareto_frontier_row(issues, expected_row, row, index) do
    path = "$.pareto_frontier_report.rows[#{index}]"

    Enum.reduce(@strategy_pareto_frontier_row_fields, issues, fn field, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{field}",
        row,
        field,
        Map.get(expected_row, field),
        "must match the Pareto row replayed from branch_comparison_report"
      )
    end)
  end

  defp validate_branch_comparison_target_identity(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_target_identity_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_target_identity(issues, _artifact), do: issues

  defp validate_branch_comparison_target_identity_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    metadata = branch |> map_value("provenance") |> map_value("branch_metadata")

    Enum.reduce(@branch_comparison_target_identity_fields, issues, fn field, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{field}",
        row,
        field,
        Map.get(metadata, field),
        "must match the enclosing branch provenance branch_metadata.#{field}"
      )
    end)
  end

  defp validate_branch_comparison_event_summary(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_event_summary_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_event_summary(issues, _artifact), do: issues

  defp validate_branch_comparison_event_summary_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    events = Map.get(branch, "events", [])

    issues
    |> validate_optional_copy(
      path <> ".branch_event_count",
      row,
      "branch_event_count",
      list_length(events),
      "must match the enclosing branch event count"
    )
    |> validate_optional_copy(
      path <> ".branch_event_types",
      row,
      "branch_event_types",
      branch_event_types(events),
      "must match the enclosing branch event types"
    )
    |> validate_optional_copy(
      path <> ".combined_source_branch_ids",
      row,
      "combined_source_branch_ids",
      branch_combined_source_branch_ids(events),
      "must match the enclosing branch event source-branch IDs"
    )
    |> validate_optional_copy(
      path <> ".branch_event_trust_boundary_status_counts",
      row,
      "branch_event_trust_boundary_status_counts",
      branch_event_trust_boundary_status_counts(events),
      "must match the enclosing branch event trust-boundary status counts"
    )
    |> validate_optional_copy(
      path <> ".branch_earliest_starts_at_s",
      row,
      "branch_earliest_starts_at_s",
      event_minimum_present(events, "starts_at_s"),
      "must match the enclosing branch earliest event start"
    )
    |> validate_optional_copy(
      path <> ".branch_latest_ends_at_s",
      row,
      "branch_latest_ends_at_s",
      event_maximum_present(events, "ends_at_s"),
      "must match the enclosing branch latest event end"
    )
    |> validate_optional_copy(
      path <> ".branch_station_availabilities",
      row,
      "branch_station_availabilities",
      branch_event_station_availabilities(events),
      "must match the enclosing branch station availabilities"
    )
    |> validate_optional_copy(
      path <> ".branch_station_contention_statuses",
      row,
      "branch_station_contention_statuses",
      branch_event_unique_values(events, ["station_contention_status", "contention_status"]),
      "must match the enclosing branch station contention statuses"
    )
    |> validate_optional_copy(
      path <> ".branch_ground_station_ids",
      row,
      "branch_ground_station_ids",
      branch_event_unique_values(events, ["ground_station_id", "station_id"]),
      "must match the enclosing branch ground-station IDs"
    )
    |> validate_optional_copy(
      path <> ".branch_directions",
      row,
      "branch_directions",
      branch_event_unique_values(events, ["direction"]),
      "must match the enclosing branch directions"
    )
    |> validate_branch_comparison_source_window_fields(path, row, events)
    |> validate_branch_comparison_operational_event_fields(path, row, events)
    |> validate_branch_comparison_execution_uncertainty_fields(path, row, events)
    |> validate_branch_comparison_operational_readiness_fields(path, row, branch, events)
    |> validate_branch_comparison_mission_identity_fields(path, row, events)
    |> validate_branch_comparison_station_calendar_fields(path, row, events)
    |> validate_branch_comparison_station_reservation_fields(path, row, branch, events)
    |> validate_branch_comparison_station_reservation_conflict_fields(
      path,
      row,
      branch,
      events
    )
    |> validate_branch_comparison_event_quality_fields(path, row, events)
    |> validate_branch_comparison_event_downlink_fields(path, row, events)
    |> validate_branch_comparison_capacity_pack_fields(path, row, events)
    |> validate_branch_comparison_timeline_integrity_fields(path, row, events)
    |> validate_branch_comparison_timeline_dependency_impact_fields(path, row, events)
    |> validate_branch_comparison_timeline_publication_fields(path, row, branch, events)
    |> validate_branch_comparison_timeline_lifecycle_state_fields(path, row, branch, events)
    |> validate_branch_comparison_timeline_activity_lifecycle_state_fields(
      path,
      row,
      branch,
      events
    )
    |> validate_branch_comparison_timeline_activity_precondition_fields(path, row, events)
    |> validate_branch_comparison_timeline_preservation_fields(path, row, events)
  end

  defp validate_branch_comparison_operational_readiness_fields(
         issues,
         path,
         row,
         branch,
         events
       ) do
    readiness_risks =
      branch
      |> map_field("risk_indicators")
      |> list_maps()
      |> Enum.filter(&(map_field(&1, "type") == "operational_readiness_pressure"))

    issues =
      validate_optional_copy(
        issues,
        path <> ".branch_operational_readiness_gate_ids",
        row,
        "branch_operational_readiness_gate_ids",
        branch_event_unique_values(events, ["readiness_gate_id"]),
        "must match the enclosing branch operational-readiness gate IDs"
      )

    Enum.reduce(
      @branch_comparison_operational_readiness_fields,
      issues,
      fn {row_field, event_sources, risk_sources}, acc ->
        event_values = branch_event_unique_values(events, event_sources)
        risk_values = branch_event_unique_values(readiness_risks, risk_sources)
        expected = if risk_values == [], do: event_values, else: risk_values

        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          expected,
          "must match the enclosing branch operational-readiness values"
        )
      end
    )
  end

  defp validate_branch_comparison_execution_uncertainty_fields(issues, path, row, events) do
    uncertainty_events =
      events
      |> list_maps()
      |> Enum.filter(&(map_field(&1, "type") == "maneuver_execution_uncertainty_feedback"))

    issues =
      validate_optional_copy(
        issues,
        path <> ".branch_missed_downlink_activity_ids",
        row,
        "branch_missed_downlink_activity_ids",
        branch_event_unique_values(events, [
          "missed_downlink_activity_id",
          "missed_downlink_activity_ids"
        ]),
        "must match the enclosing branch missed-downlink activity IDs"
      )

    issues =
      Enum.reduce(
        @branch_comparison_execution_uncertainty_fields,
        issues,
        fn {row_field, source}, acc ->
          validate_optional_copy(
            acc,
            path <> ".#{row_field}",
            row,
            row_field,
            branch_event_unique_values(uncertainty_events, [source]),
            "must match the enclosing branch execution-uncertainty #{source} values"
          )
        end
      )

    Enum.reduce(
      @branch_comparison_execution_uncertainty_maximum_fields,
      issues,
      fn {row_field, source}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          event_maximum_present(uncertainty_events, source),
          "must match the enclosing branch execution-uncertainty #{source} maximum"
        )
      end
    )
  end

  defp validate_branch_comparison_operational_event_fields(issues, path, row, events) do
    issues =
      Enum.reduce(@branch_comparison_operational_event_fields, issues, fn {row_field, sources},
                                                                          acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          branch_event_unique_values(events, sources),
          "must match the enclosing branch operational-event values"
        )
      end)

    issues =
      Enum.reduce(@branch_comparison_transition_fields, issues, fn {row_field, source}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          branch_event_transition_values(events, source),
          "must match the enclosing branch transition values"
        )
      end)

    issues
    |> validate_optional_copy(
      path <> ".branch_requires_operator_review",
      row,
      "branch_requires_operator_review",
      branch_event_requires_operator_review(events),
      "must match the enclosing branch operator-review requirement"
    )
    |> validate_optional_copy(
      path <> ".branch_requires_operator_review_count",
      row,
      "branch_requires_operator_review_count",
      branch_event_operator_review_count(events),
      "must match the enclosing branch operator-review event count"
    )
  end

  defp validate_branch_comparison_source_window_fields(issues, path, row, events) do
    expected = branch_source_window_context(events)

    Enum.reduce(@branch_comparison_source_window_fields, issues, fn field, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{field}",
        row,
        field,
        Map.get(expected, field),
        "must match the enclosing branch source-window context"
      )
    end)
  end

  defp validate_branch_comparison_mission_identity_fields(issues, path, row, events) do
    Enum.reduce(@branch_comparison_mission_identity_fields, issues, fn {row_field, sources},
                                                                       acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        branch_event_unique_values(events, sources),
        "must match the enclosing branch mission identity values"
      )
    end)
  end

  defp validate_branch_comparison_station_calendar_fields(issues, path, row, events) do
    Enum.reduce(@branch_comparison_station_calendar_fields, issues, fn {row_field, sources},
                                                                       acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        branch_event_unique_values(events, sources),
        "must match the enclosing branch station-calendar #{row_field}"
      )
    end)
  end

  defp validate_branch_comparison_station_reservation_fields(
         issues,
         path,
         row,
         branch,
         events
       ) do
    issues
    |> then(fn issues ->
      Enum.reduce(
        @branch_comparison_station_reservation_fields,
        issues,
        fn {row_field, sources}, acc ->
          validate_optional_copy(
            acc,
            path <> ".#{row_field}",
            row,
            row_field,
            branch_event_unique_values(events, sources),
            "must match the enclosing branch station-reservation #{row_field}"
          )
        end
      )
    end)
    |> validate_optional_copy(
      path <> ".branch_station_reservation_expiration_statuses",
      row,
      "branch_station_reservation_expiration_statuses",
      branch_station_reservation_expiration_statuses(branch, events),
      "must match the enclosing branch station-reservation expiration pressure risks"
    )
  end

  defp branch_station_reservation_expiration_statuses(branch, events) do
    pressure_statuses =
      branch
      |> Map.get("risk_indicators")
      |> list_maps()
      |> Enum.filter(fn risk ->
        Map.get(risk, "station_reservation_expiration_status") in ["expired", "missing"]
      end)
      |> branch_event_unique_values([
        "station_reservation_expiration_status",
        "station_reservation_expiration_statuses"
      ])

    case pressure_statuses do
      [] ->
        branch_event_unique_values(events, [
          "station_reservation_expiration_status",
          "station_reservation_expiration_statuses"
        ])

      statuses ->
        statuses
    end
  end

  defp validate_branch_comparison_station_reservation_conflict_fields(
         issues,
         path,
         row,
         branch,
         events
       ) do
    conflict_events =
      events
      |> list_maps()
      |> Enum.filter(&branch_station_reservation_conflict_event?/1)

    conflict_risks =
      branch
      |> Map.get("risk_indicators")
      |> list_maps()
      |> Enum.filter(&branch_station_reservation_conflict_risk?/1)

    Enum.reduce(
      @branch_comparison_station_reservation_conflict_fields,
      issues,
      fn {row_field, sources, filter_match_statuses?}, acc ->
        event_values =
          conflict_events
          |> branch_event_unique_values(sources)
          |> maybe_filter_branch_station_reservation_conflict_match_statuses(
            filter_match_statuses?
          )

        expected =
          case branch_event_unique_values(conflict_risks, sources) do
            [] -> event_values
            risk_values -> risk_values
          end

        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          expected,
          "must match the enclosing branch station-reservation conflict #{row_field}"
        )
      end
    )
  end

  defp branch_station_reservation_conflict_event?(event) do
    event
    |> List.wrap()
    |> branch_event_unique_values([
      "station_reservation_match_status",
      "reservation_match_status"
    ])
    |> Enum.any?(&branch_station_reservation_conflict_match_status?/1)
  end

  defp branch_station_reservation_conflict_risk?(risk) do
    Map.get(risk, "type") in [
      "downlink_completion_gap",
      "provider_reservation_request_review"
    ] and not is_nil(Map.get(risk, "station_reservation_match_status"))
  end

  defp maybe_filter_branch_station_reservation_conflict_match_statuses(values, true),
    do: Enum.filter(values, &branch_station_reservation_conflict_match_status?/1)

  defp maybe_filter_branch_station_reservation_conflict_match_statuses(values, false),
    do: values

  defp branch_station_reservation_conflict_match_status?(status) when is_binary(status) do
    normalized_status =
      status
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    normalized_status not in ["", "matched", "owner_matched", "owned", "owner"]
  end

  defp branch_station_reservation_conflict_match_status?(_status), do: false

  defp validate_branch_comparison_event_quality_fields(issues, path, row, events) do
    issues
    |> validate_optional_copy(
      path <> ".branch_image_quality_min_score",
      row,
      "branch_image_quality_min_score",
      event_minimum_present(events, "image_quality_score"),
      "must match the enclosing branch minimum image-quality score"
    )
    |> validate_optional_copy(
      path <> ".branch_image_quality_statuses",
      row,
      "branch_image_quality_statuses",
      branch_event_unique_values(events, ["image_quality_status"]),
      "must match the enclosing branch image-quality statuses"
    )
    |> validate_optional_copy(
      path <> ".branch_image_quality_sources",
      row,
      "branch_image_quality_sources",
      branch_event_unique_values(events, ["image_quality_source"]),
      "must match the enclosing branch image-quality sources"
    )
    |> validate_optional_copy(
      path <> ".branch_cloud_cover_max_fraction",
      row,
      "branch_cloud_cover_max_fraction",
      event_maximum_present(events, "cloud_cover_fraction"),
      "must match the enclosing branch maximum cloud-cover fraction"
    )
    |> validate_optional_copy(
      path <> ".branch_blur_max_score",
      row,
      "branch_blur_max_score",
      event_maximum_present(events, "blur_score"),
      "must match the enclosing branch maximum blur score"
    )
  end

  defp validate_branch_comparison_event_downlink_fields(issues, path, row, events) do
    issues
    |> validate_optional_copy(
      path <> ".branch_max_latency_s",
      row,
      "branch_max_latency_s",
      event_maximum_present(events, "max_latency_s"),
      "must match the enclosing branch maximum required latency"
    )
    |> validate_optional_copy(
      path <> ".branch_planned_latency_s",
      row,
      "branch_planned_latency_s",
      event_maximum_present(events, "planned_latency_s"),
      "must match the enclosing branch maximum planned latency"
    )
    |> validate_optional_copy(
      path <> ".branch_required_contacts",
      row,
      "branch_required_contacts",
      event_maximum_present(events, "required_contacts"),
      "must match the enclosing branch maximum required contacts"
    )
    |> validate_optional_copy(
      path <> ".branch_planned_contacts",
      row,
      "branch_planned_contacts",
      event_maximum_present(events, "planned_contacts"),
      "must match the enclosing branch maximum planned contacts"
    )
    |> validate_optional_copy(
      path <> ".branch_required_downlink_mb",
      row,
      "branch_required_downlink_mb",
      event_maximum_present(events, "required_downlink_mb"),
      "must match the enclosing branch maximum required downlink"
    )
    |> validate_optional_copy(
      path <> ".branch_planned_downlink_mb",
      row,
      "branch_planned_downlink_mb",
      event_maximum_present(events, "planned_downlink_mb"),
      "must match the enclosing branch maximum planned downlink"
    )
    |> validate_optional_copy(
      path <> ".branch_actual_downlink_completion_ratio",
      row,
      "branch_actual_downlink_completion_ratio",
      event_minimum_present(events, "actual_downlink_completion_ratio"),
      "must match the enclosing branch minimum actual downlink completion ratio"
    )
  end

  defp validate_branch_comparison_capacity_pack_fields(issues, path, row, events) do
    issues
    |> validate_optional_copy(
      path <> ".capacity_pack_group_ids",
      row,
      "capacity_pack_group_ids",
      branch_event_unique_values(events, ["capacity_pack_group_id"]),
      "must match the enclosing branch capacity-pack group IDs"
    )
    |> validate_optional_copy(
      path <> ".capacity_pack_statuses",
      row,
      "capacity_pack_statuses",
      branch_event_unique_values(events, ["capacity_pack_status"]),
      "must match the enclosing branch capacity-pack statuses"
    )
    |> validate_optional_copy(
      path <> ".capacity_pack_min_capacity_fraction",
      row,
      "capacity_pack_min_capacity_fraction",
      event_minimum_present(events, "capacity_pack_capacity_fraction"),
      "must match the enclosing branch minimum capacity-pack capacity fraction"
    )
    |> validate_optional_copy(
      path <> ".capacity_pack_max_used_fraction",
      row,
      "capacity_pack_max_used_fraction",
      event_maximum_present(events, "capacity_pack_used_fraction"),
      "must match the enclosing branch maximum capacity-pack used fraction"
    )
    |> validate_optional_copy(
      path <> ".capacity_pack_max_required_capacity_fraction",
      row,
      "capacity_pack_max_required_capacity_fraction",
      event_maximum_present(events, "required_capacity_fraction"),
      "must match the enclosing branch maximum required capacity fraction"
    )
    |> validate_optional_copy(
      path <> ".capacity_pack_total_required_capacity_fraction",
      row,
      "capacity_pack_total_required_capacity_fraction",
      event_sum_present(events, "required_capacity_fraction"),
      "must match the enclosing branch total required capacity fraction"
    )
    |> validate_optional_copy(
      path <> ".capacity_pack_required_capacity_sources",
      row,
      "capacity_pack_required_capacity_sources",
      branch_event_unique_values(events, ["required_capacity_fraction_source"]),
      "must match the enclosing branch required capacity-fraction sources"
    )
    |> then(fn issues ->
      Enum.reduce(@branch_comparison_capacity_pack_contact_map_fields, issues, fn field, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{field}",
          row,
          field,
          event_merged_string_list_maps(events, field),
          "must match the enclosing branch merged #{field}"
        )
      end)
    end)
    |> then(fn issues ->
      Enum.reduce(@branch_comparison_capacity_pack_numeric_map_fields, issues, fn field, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{field}",
          row,
          field,
          event_merged_numeric_maps(events, field),
          "must match the enclosing branch summed #{field}"
        )
      end)
    end)
  end

  defp validate_branch_comparison_timeline_integrity_fields(issues, path, row, events) do
    validate_branch_comparison_filtered_event_fields(
      issues,
      path,
      row,
      events,
      "timeline_integrity_feedback",
      @branch_comparison_timeline_integrity_fields,
      "timeline-integrity"
    )
  end

  defp validate_branch_comparison_timeline_dependency_impact_fields(
         issues,
         path,
         row,
         events
       ) do
    validate_branch_comparison_filtered_event_fields(
      issues,
      path,
      row,
      events,
      "timeline_dependency_impact_pressure",
      @branch_comparison_timeline_dependency_impact_fields,
      "timeline-dependency-impact"
    )
  end

  defp validate_branch_comparison_timeline_publication_fields(
         issues,
         path,
         row,
         branch,
         events
       ) do
    publication_events =
      events
      |> list_maps()
      |> Enum.filter(&(Map.get(&1, "type") == "timeline_publication_pressure"))

    publication_risks =
      branch
      |> map_field("risk_indicators")
      |> list_maps()
      |> Enum.filter(&(Map.get(&1, "type") == "timeline_publication_pressure"))

    Enum.reduce(
      @branch_comparison_timeline_publication_fields,
      issues,
      fn {row_field, event_field, risk_field}, acc ->
        event_values = branch_event_unique_values(publication_events, [event_field])

        risk_values =
          if is_binary(risk_field) do
            branch_event_unique_values(publication_risks, [risk_field])
          else
            []
          end

        expected = if risk_values == [], do: event_values, else: risk_values

        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          expected,
          "must match the enclosing branch timeline-publication #{event_field} values using nonempty risk-summary precedence"
        )
      end
    )
  end

  defp validate_branch_comparison_timeline_lifecycle_state_fields(
         issues,
         path,
         row,
         branch,
         events
       ) do
    lifecycle_events =
      events
      |> list_maps()
      |> Enum.filter(&(Map.get(&1, "type") == "timeline_lifecycle_state_pressure"))

    lifecycle_risks =
      branch
      |> map_field("risk_indicators")
      |> list_maps()
      |> Enum.filter(&(Map.get(&1, "type") == "timeline_lifecycle_state_review"))

    issues =
      Enum.reduce(
        @branch_comparison_timeline_lifecycle_state_value_fields,
        issues,
        fn {row_field, event_field, risk_field}, acc ->
          event_values = branch_event_unique_values(lifecycle_events, [event_field])

          risk_values =
            if is_binary(risk_field) do
              branch_event_unique_values(lifecycle_risks, [risk_field])
            else
              []
            end

          expected = if risk_values == [], do: event_values, else: risk_values

          validate_optional_copy(
            acc,
            path <> ".#{row_field}",
            row,
            row_field,
            expected,
            "must match the enclosing branch timeline lifecycle-state #{event_field} values using nonempty risk-summary precedence"
          )
        end
      )

    Enum.reduce(
      @branch_comparison_timeline_lifecycle_state_action_fields,
      issues,
      fn {row_field, event_field, rejected_values}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          branch_event_unique_map_keys(lifecycle_events, event_field, rejected_values),
          "must match the enclosing branch timeline lifecycle-state #{event_field} keys"
        )
      end
    )
  end

  defp validate_branch_comparison_timeline_activity_lifecycle_state_fields(
         issues,
         path,
         row,
         branch,
         events
       ) do
    lifecycle_events =
      events
      |> list_maps()
      |> Enum.filter(&(Map.get(&1, "type") == "timeline_activity_lifecycle_state_pressure"))

    lifecycle_risks =
      branch
      |> map_field("risk_indicators")
      |> list_maps()
      |> Enum.filter(&(Map.get(&1, "type") == "timeline_activity_lifecycle_state_review"))

    Enum.reduce(
      @branch_comparison_timeline_activity_lifecycle_state_fields,
      issues,
      fn {row_field, event_fields, risk_fields}, acc ->
        event_values = branch_event_unique_values(lifecycle_events, event_fields)
        risk_values = branch_event_unique_values(lifecycle_risks, risk_fields)
        expected = if risk_values == [], do: event_values, else: risk_values

        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          expected,
          "must match the enclosing branch timeline activity lifecycle-state values using nonempty risk-summary precedence"
        )
      end
    )
  end

  defp validate_branch_comparison_timeline_activity_precondition_fields(
         issues,
         path,
         row,
         events
       ) do
    validate_branch_comparison_filtered_event_fields(
      issues,
      path,
      row,
      events,
      "timeline_activity_precondition_pressure",
      @branch_comparison_timeline_activity_precondition_fields,
      "timeline activity-precondition"
    )
  end

  defp validate_branch_comparison_timeline_preservation_fields(issues, path, row, events) do
    validate_branch_comparison_filtered_event_fields(
      issues,
      path,
      row,
      events,
      "timeline_preservation_pressure",
      @branch_comparison_timeline_preservation_fields,
      "timeline-preservation"
    )
  end

  defp validate_branch_comparison_filtered_event_fields(
         issues,
         path,
         row,
         events,
         event_type,
         fields,
         context
       ) do
    filtered_events =
      events
      |> list_maps()
      |> Enum.filter(&(Map.get(&1, "type") == event_type))

    Enum.reduce(fields, issues, fn {row_field, event_field}, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        branch_event_unique_values(filtered_events, [event_field]),
        "must match the enclosing branch #{context} #{event_field} values"
      )
    end)
  end

  defp branch_event_unique_values(events, fields) when is_list(events) do
    events
    |> Enum.flat_map(fn event -> Enum.map(fields, &map_field(event, &1)) end)
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_unique_values(_events, _fields), do: []

  defp branch_combined_source_branch_ids(events) do
    events
    |> list_maps()
    |> Enum.flat_map(fn event ->
      event
      |> Map.get("source_branch_ids", List.wrap(Map.get(event, "source_branch_id")))
      |> List.wrap()
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_transition_values(events, field) do
    events
    |> list_maps()
    |> Enum.flat_map(fn event ->
      [map_field(event, field), event |> map_field("status_transition") |> map_field(field)]
    end)
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_requires_operator_review(events) do
    values =
      events
      |> list_maps()
      |> Enum.map(&branch_event_operator_review_value/1)
      |> Enum.filter(&is_boolean/1)

    cond do
      Enum.any?(values, &(&1 == true)) -> true
      values != [] -> false
      true -> nil
    end
  end

  defp branch_event_operator_review_count(events) do
    count =
      events
      |> list_maps()
      |> Enum.count(&(branch_event_operator_review_value(&1) == true))

    if count > 0, do: count
  end

  defp branch_event_operator_review_value(event) do
    [
      map_field(event, "requires_operator_review"),
      event
      |> map_field("status_transition")
      |> map_field("requires_operator_review")
    ]
    |> Enum.map(&event_boolean/1)
    |> Enum.find(&is_boolean/1)
  end

  defp event_boolean(value) when is_boolean(value), do: value

  defp event_boolean(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp event_boolean(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      token when token in ["true", "1", "yes", "y"] -> true
      token when token in ["false", "0", "no", "n"] -> false
      _token -> nil
    end
  end

  defp event_boolean(_value), do: nil

  defp branch_source_window_context(events) do
    source_window_ids =
      branch_event_unique_values(events, ["source_window_id", "source_window_ids"])

    source_window_bounds = branch_source_window_bounds(events)
    bounded_source_window_ids = Enum.map(source_window_bounds, & &1["source_window_id"])
    untimed_source_window_ids = source_window_ids -- bounded_source_window_ids

    partially_timed_source_window_ids =
      Enum.flat_map(source_window_bounds, fn bound ->
        has_start = is_number(bound["earliest_starts_at_s"])
        has_end = is_number(bound["latest_ends_at_s"])

        if has_start != has_end, do: [bound["source_window_id"]], else: []
      end)

    complete_source_window_bound_count =
      Enum.count(source_window_bounds, fn bound ->
        is_number(bound["earliest_starts_at_s"]) and
          is_number(bound["latest_ends_at_s"])
      end)

    source_window_timing_coverage_status =
      cond do
        source_window_ids == [] -> nil
        source_window_bounds == [] -> "untimed"
        complete_source_window_bound_count == length(source_window_ids) -> "complete"
        true -> "partial"
      end

    %{
      "branch_source_window_ids" => source_window_ids,
      "branch_source_window_count" => optional_count(source_window_ids, source_window_ids),
      "branch_source_window_bounds" => source_window_bounds,
      "branch_source_window_bound_count" =>
        optional_count(source_window_ids, source_window_bounds),
      "branch_untimed_source_window_ids" => untimed_source_window_ids,
      "branch_untimed_source_window_count" =>
        optional_count(source_window_ids, untimed_source_window_ids),
      "branch_partially_timed_source_window_ids" => partially_timed_source_window_ids,
      "branch_partially_timed_source_window_count" =>
        optional_count(source_window_ids, partially_timed_source_window_ids),
      "branch_source_window_timing_coverage_status" => source_window_timing_coverage_status
    }
  end

  defp branch_source_window_bounds(events) do
    events
    |> list_maps()
    |> Enum.reduce(%{}, fn event, bounds_by_id ->
      source_window_ids =
        branch_event_unique_values([event], ["source_window_id", "source_window_ids"])

      earliest_starts_at_s = event_number(map_field(event, "starts_at_s"))
      latest_ends_at_s = event_number(map_field(event, "ends_at_s"))

      if source_window_ids == [] or
           (is_nil(earliest_starts_at_s) and is_nil(latest_ends_at_s)) do
        bounds_by_id
      else
        Enum.reduce(source_window_ids, bounds_by_id, fn source_window_id, acc ->
          Map.update(
            acc,
            source_window_id,
            source_window_bound(source_window_id, earliest_starts_at_s, latest_ends_at_s),
            fn bound ->
              bound
              |> put_source_window_minimum("earliest_starts_at_s", earliest_starts_at_s)
              |> put_source_window_maximum("latest_ends_at_s", latest_ends_at_s)
            end
          )
        end)
      end
    end)
    |> Map.values()
    |> Enum.sort_by(& &1["source_window_id"])
  end

  defp source_window_bound(source_window_id, earliest_starts_at_s, latest_ends_at_s) do
    %{"source_window_id" => source_window_id}
    |> put_source_window_minimum("earliest_starts_at_s", earliest_starts_at_s)
    |> put_source_window_maximum("latest_ends_at_s", latest_ends_at_s)
  end

  defp put_source_window_minimum(bound, _field, nil), do: bound

  defp put_source_window_minimum(bound, field, value) do
    Map.update(bound, field, value, &min(&1, value))
  end

  defp put_source_window_maximum(bound, _field, nil), do: bound

  defp put_source_window_maximum(bound, field, value) do
    Map.update(bound, field, value, &max(&1, value))
  end

  defp optional_count([], _values), do: nil
  defp optional_count(_source_window_ids, values), do: length(values)

  defp branch_event_unique_map_keys(events, field, rejected_values) when is_list(events) do
    events
    |> Enum.flat_map(fn event ->
      case map_field(event, field) do
        %{} = map -> Map.keys(map)
        _value -> []
      end
    end)
    |> Enum.map(fn
      value when is_atom(value) -> Atom.to_string(value)
      value -> value
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != "" and &1 not in rejected_values))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_unique_map_keys(_events, _field, _rejected_values), do: []

  defp branch_event_station_availabilities(events) when is_list(events) do
    events
    |> Enum.map(fn event ->
      cond do
        is_map(event) and Map.has_key?(event, "station_availability") ->
          map_field(event, "station_availability")

        is_map(event) and Map.has_key?(event, "availability") ->
          map_field(event, "availability")

        true ->
          station_availability_for_event_type(map_field(event, "type"))
      end
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_station_availabilities(_events), do: []

  defp station_availability_for_event_type("ground_station_outage"), do: "unavailable"
  defp station_availability_for_event_type("ground_station_reserved"), do: "reserved"
  defp station_availability_for_event_type(_type), do: nil

  defp branch_event_types(events) when is_list(events) do
    events
    |> Enum.map(&map_field(&1, "type"))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_types(_events), do: []

  defp branch_event_trust_boundary_status_counts(events) when is_list(events) do
    events
    |> Enum.map(&branch_event_trust_boundary_status/1)
    |> Enum.frequencies()
  end

  defp branch_event_trust_boundary_status_counts(_events), do: %{}

  defp branch_event_trust_boundary_status(event) do
    trust_boundary =
      [
        map_field(event, "trust_boundary"),
        event |> map_field("provenance") |> map_field("trust_boundary")
      ]
      |> Enum.find(&(is_binary(&1) and &1 != ""))

    if is_binary(trust_boundary), do: "declared", else: "missing"
  end

  defp event_minimum_present(events, field) do
    events
    |> event_numeric_values(field)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp event_maximum_present(events, field) do
    events
    |> event_numeric_values(field)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp event_sum_present(events, field) do
    events
    |> event_numeric_values(field)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp event_numeric_values(events, field) when is_list(events) do
    events
    |> Enum.map(&(&1 |> map_field(field) |> event_number()))
    |> Enum.filter(&is_number/1)
  end

  defp event_numeric_values(_events, _field), do: []

  defp event_merged_string_list_maps(events, field) when is_list(events) do
    events
    |> Enum.map(&map_field(&1, field))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn map, acc ->
      Enum.reduce(map, acc, fn {key, value}, inner ->
        values =
          value
          |> List.wrap()
          |> Enum.filter(&(is_binary(&1) and &1 != ""))

        Map.update(inner, key, values, fn existing ->
          (List.wrap(existing) ++ values)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      end)
    end)
    |> Map.new(fn {key, values} -> {key, Enum.sort(Enum.uniq(values))} end)
  end

  defp event_merged_string_list_maps(_events, _field), do: %{}

  defp event_merged_numeric_maps(events, field) when is_list(events) do
    events
    |> Enum.map(&map_field(&1, field))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn map, acc ->
      Enum.reduce(map, acc, fn {key, value}, inner ->
        case event_number(value) do
          nil -> inner
          number -> Map.update(inner, key, number, &(&1 + number))
        end
      end)
    end)
  end

  defp event_merged_numeric_maps(_events, _field), do: %{}

  defp event_number(value) when is_integer(value) or is_float(value), do: value

  defp event_number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp event_number(_value), do: nil

  defp branch_id_input?(%{"branch_id" => branch_id}), do: is_binary(branch_id)
  defp branch_id_input?(_row), do: false

  defp validate_branch_comparison_score_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_score_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_score_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_score_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    score_terms = Map.get(branch, "score_terms", %{})

    issues
    |> validate_optional_copy(
      path <> ".score",
      row,
      "score",
      Map.get(branch, "score"),
      "must match the enclosing branch score"
    )
    |> validate_optional_copy(
      path <> ".raw_score",
      row,
      "raw_score",
      Map.get(score_terms, "raw_score"),
      "must match the enclosing branch score_terms.raw_score"
    )
    |> validate_optional_copy(
      path <> ".branch_probability",
      row,
      "branch_probability",
      Map.get(branch, "probability"),
      "must match the enclosing branch probability"
    )
    |> validate_optional_copy(
      path <> ".expected_score",
      row,
      "expected_score",
      Map.get(score_terms, "expected_score", Map.get(branch, "score")),
      "must match the enclosing branch expected score"
    )
    |> validate_optional_copy(
      path <> ".score_terms",
      row,
      "score_terms",
      score_terms,
      "must match the enclosing branch score_terms"
    )
  end

  defp validate_branch_comparison_operational_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_operational_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_operational_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_operational_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"

    issues
    |> validate_optional_copy(
      path <> ".approval_status",
      row,
      "approval_status",
      Map.get(branch, "approval_status"),
      "must match the enclosing branch approval_status"
    )
    |> validate_optional_copy(
      path <> ".risk_count",
      row,
      "risk_count",
      list_length(Map.get(branch, "risk_indicators")),
      "must match the enclosing branch risk_indicators count"
    )
    |> validate_optional_copy(
      path <> ".approval_requirement_count",
      row,
      "approval_requirement_count",
      list_length(Map.get(branch, "approval_requirements")),
      "must match the enclosing branch approval_requirements count"
    )
    |> validate_optional_copy(
      path <> ".candidate_activity_count",
      row,
      "candidate_activity_count",
      nested_list_length(Map.get(branch, "candidate_plan"), "strategic_additions"),
      "must match the enclosing branch strategic_additions count"
    )
    |> validate_optional_copy(
      path <> ".repair_delta_count",
      row,
      "repair_delta_count",
      nested_list_length(Map.get(branch, "repair_result"), "deltas"),
      "must match the enclosing branch repair deltas count"
    )
  end

  defp list_length(values) when is_list(values), do: length(values)
  defp list_length(_values), do: nil

  defp nested_list_length(%{} = container, field),
    do: container |> Map.get(field, []) |> list_length()

  defp nested_list_length(_container, _field), do: nil

  defp validate_branch_comparison_risk_classifications(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_risk_classification_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_risk_classifications(issues, _artifact), do: issues

  defp validate_branch_comparison_risk_classification_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    risk_indicators = Map.get(branch, "risk_indicators", [])
    feedback_adjustments = map_value(branch, "feedback_adjustments")
    resource_impacts = map_value(branch, "resource_impacts")

    issues
    |> validate_optional_copy(
      path <> ".risk_types",
      row,
      "risk_types",
      branch_risk_types(risk_indicators),
      "must match the enclosing branch risk indicator types"
    )
    |> validate_optional_copy(
      path <> ".high_risk_types",
      row,
      "high_risk_types",
      branch_risk_types(risk_indicators, "high"),
      "must match the enclosing branch high-severity risk indicator types"
    )
    |> validate_optional_copy(
      path <> ".feedback_risk_types",
      row,
      "feedback_risk_types",
      feedback_adjustments |> Map.get("risk_indicators", []) |> risk_type_values(),
      "must match the enclosing branch feedback risk indicator types"
    )
    |> validate_optional_copy(
      path <> ".resource_risk_types",
      row,
      "resource_risk_types",
      resource_impacts
      |> Map.get("risk_indicators", [])
      |> risk_type_values()
      |> Enum.sort(),
      "must match the enclosing branch resource risk indicator types"
    )
  end

  defp branch_risk_types(risk_indicators, severity \\ nil) do
    risk_indicators
    |> list_maps()
    |> Enum.filter(fn risk -> is_nil(severity) or Map.get(risk, "severity") == severity end)
    |> risk_type_values()
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp risk_type_values(risk_indicators) do
    risk_indicators
    |> list_maps()
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
  end

  defp list_maps(values) when is_list(values), do: Enum.filter(values, &is_map/1)
  defp list_maps(_values), do: []

  defp validate_branch_comparison_resource_impacts(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_impact_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_impacts(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_impact_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    resource_impacts = map_value(branch, "resource_impacts")

    Enum.reduce(
      @branch_comparison_resource_impact_fields,
      issues,
      fn {row_field, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          Map.get(resource_impacts, source_field),
          "must match the enclosing branch resource_impacts.#{source_field}"
        )
      end
    )
  end

  defp validate_branch_comparison_resource_projection_summary(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_summary_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_summary(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_projection_summary_row(
         issues,
         branch,
         row,
         index
       ) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows} = report
      when is_list(resource_rows) and resource_rows != [] ->
        path = "$.branch_comparison_report.rows[#{index}]"

        issues
        |> validate_optional_copy(
          path <> ".resource_projection_spacecraft_count",
          row,
          "resource_projection_spacecraft_count",
          length(resource_rows),
          "must match the enclosing branch resource projection spacecraft count"
        )
        |> validate_optional_copy(
          path <> ".resource_projection_flow_count",
          row,
          "resource_projection_flow_count",
          resource_projection_flow_count(resource_rows),
          "must match the enclosing branch resource projection flow count"
        )
        |> validate_optional_copy(
          path <> ".resource_projection_warning_count",
          row,
          "resource_projection_warning_count",
          report |> Map.get("warnings", []) |> list_length(),
          "must match the enclosing branch resource projection warning count"
        )
        |> validate_optional_copy(
          path <> ".resource_source_quality_counts",
          row,
          "resource_source_quality_counts",
          Map.get(report, "resource_source_quality_counts"),
          "must match the enclosing branch resource projection source-quality counts"
        )
        |> validate_optional_copy(
          path <> ".resource_trust_boundary_status_counts",
          row,
          "resource_trust_boundary_status_counts",
          Map.get(report, "resource_trust_boundary_status_counts"),
          "must match the enclosing branch resource projection trust-boundary counts"
        )

      _report ->
        issues
    end
  end

  defp resource_projection_flow_count(resource_rows) do
    resource_rows
    |> resource_projection_flow_rows()
    |> length()
  end

  defp resource_projection_flow_rows(resource_rows) do
    resource_rows
    |> Enum.flat_map(fn
      %{"activity_resource_flow" => flows} when is_list(flows) -> flows
      _row -> []
    end)
  end

  defp validate_branch_comparison_resource_projection_aggregates(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_aggregate_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_aggregates(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_projection_aggregate_row(
         issues,
         branch,
         row,
         index
       ) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows}
      when is_list(resource_rows) and resource_rows != [] ->
        path = "$.branch_comparison_report.rows[#{index}]"

        issues
        |> validate_resource_projection_aggregate_fields(
          path,
          row,
          resource_rows,
          @branch_comparison_resource_projection_minimum_fields,
          &minimum_present/2
        )
        |> validate_resource_projection_aggregate_fields(
          path,
          row,
          resource_rows,
          @branch_comparison_resource_projection_maximum_fields,
          &maximum_present/2
        )
        |> validate_optional_copy(
          path <> ".projected_storage_remaining_mb",
          row,
          "projected_storage_remaining_mb",
          minimum_projected_remaining(
            resource_rows,
            "projected_storage_remaining_mb",
            "storage_capacity_mb",
            "projected_storage_used_mb"
          ),
          "must match the enclosing branch projected storage remaining aggregate"
        )
        |> validate_optional_copy(
          path <> ".projected_downlink_remaining_mb",
          row,
          "projected_downlink_remaining_mb",
          minimum_projected_remaining(
            resource_rows,
            "projected_downlink_remaining_mb",
            "downlink_capacity_mb",
            "estimated_downlink_mb"
          ),
          "must match the enclosing branch projected downlink remaining aggregate"
        )

      _report ->
        issues
    end
  end

  defp validate_resource_projection_aggregate_fields(
         issues,
         path,
         row,
         resource_rows,
         fields,
         aggregate
       ) do
    Enum.reduce(fields, issues, fn {row_field, source_field}, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        aggregate.(resource_rows, source_field),
        "must match the enclosing branch resource projection #{source_field} aggregate"
      )
    end)
  end

  defp minimum_present(rows, field) do
    rows
    |> Enum.map(&map_field(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp maximum_present(rows, field) do
    rows
    |> Enum.map(&map_field(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp minimum_projected_remaining(rows, remaining_field, capacity_field, used_or_demand_field) do
    rows
    |> Enum.flat_map(fn row ->
      remaining = map_field(row, remaining_field)
      capacity = map_field(row, capacity_field)
      used_or_demand = map_field(row, used_or_demand_field)

      cond do
        is_number(remaining) ->
          [remaining]

        is_number(capacity) and is_number(used_or_demand) ->
          [max(capacity - used_or_demand, 0.0)]

        true ->
          []
      end
    end)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp map_field(%{} = map, field), do: Map.get(map, field)
  defp map_field(_value, _field), do: nil

  defp validate_branch_comparison_resource_projection_availability(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_availability_row(
          acc,
          branch,
          row,
          index
        )
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_availability(issues, _artifact),
    do: issues

  defp validate_branch_comparison_resource_projection_availability_row(
         issues,
         branch,
         row,
         index
       ) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows}
      when is_list(resource_rows) and resource_rows != [] ->
        path = "$.branch_comparison_report.rows[#{index}]"
        unavailable_ids = resource_projection_unavailable_spacecraft_ids(resource_rows)

        issues
        |> validate_optional_copy(
          path <> ".resource_projection_unavailable_spacecraft_count",
          row,
          "resource_projection_unavailable_spacecraft_count",
          length(unavailable_ids),
          "must match the enclosing branch unavailable spacecraft count"
        )
        |> validate_optional_copy(
          path <> ".resource_projection_unavailable_spacecraft_ids",
          row,
          "resource_projection_unavailable_spacecraft_ids",
          unavailable_ids,
          "must match the enclosing branch unavailable spacecraft IDs"
        )
        |> validate_resource_projection_availability_pairs(path, row, resource_rows)
        |> validate_optional_copy(
          path <> ".resource_projection_availability_pressure_types",
          row,
          "resource_projection_availability_pressure_types",
          resource_projection_availability_pressure_types(resource_rows),
          "must match the enclosing branch resource availability pressure types"
        )

      _report ->
        issues
    end
  end

  defp validate_resource_projection_availability_pairs(issues, path, row, resource_rows) do
    Enum.reduce(
      @branch_comparison_resource_projection_availability_pairs,
      issues,
      fn {count_field, ids_field, pressure_type}, acc ->
        ids =
          resource_projection_availability_pressure_spacecraft_ids(resource_rows, pressure_type)

        acc
        |> validate_optional_copy(
          path <> ".#{count_field}",
          row,
          count_field,
          length(ids),
          "must match the enclosing branch #{pressure_type} spacecraft count"
        )
        |> validate_optional_copy(
          path <> ".#{ids_field}",
          row,
          ids_field,
          ids,
          "must match the enclosing branch #{pressure_type} spacecraft IDs"
        )
      end
    )
  end

  defp resource_projection_unavailable_spacecraft_ids(resource_rows) do
    resource_rows
    |> Enum.filter(&(map_field(&1, "spacecraft_available") == false))
    |> Enum.map(&map_field(&1, "spacecraft_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_projection_availability_pressure_spacecraft_ids(resource_rows, pressure_type) do
    resource_rows
    |> Enum.filter(fn resource_row ->
      pressure_type in List.wrap(map_field(resource_row, "resource_pressure_types"))
    end)
    |> Enum.map(fn resource_row ->
      map_field(resource_row, "spacecraft_id") || map_field(resource_row, "scenario_id")
    end)
    |> Enum.filter(&stable_id_string?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_projection_availability_pressure_types(resource_rows) do
    resource_rows
    |> Enum.flat_map(&(map_field(&1, "resource_pressure_types") |> List.wrap()))
    |> Enum.filter(&(&1 in @resource_projection_availability_pressure_types))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_id_string?(value),
    do: is_binary(value) and value != "" and Regex.match?(@stable_id_regex, value)

  defp validate_branch_comparison_resource_projection_peaks(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_resource_projection_peak_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_resource_projection_peaks(issues, _artifact), do: issues

  defp validate_branch_comparison_resource_projection_peak_row(issues, branch, row, index) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows}
      when is_list(resource_rows) and resource_rows != [] ->
        validate_resource_projection_aggregate_fields(
          issues,
          "$.branch_comparison_report.rows[#{index}]",
          row,
          resource_projection_flow_rows(resource_rows),
          @branch_comparison_resource_projection_peak_fields,
          &maximum_present/2
        )

      _report ->
        issues
    end
  end

  defp validate_branch_comparison_first_resource_pressure_context(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_first_resource_pressure_context_row(
          acc,
          branch,
          row,
          index
        )
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_first_resource_pressure_context(issues, _artifact),
    do: issues

  defp validate_branch_comparison_first_resource_pressure_context_row(
         issues,
         branch,
         row,
         index
       ) do
    case Map.get(branch, "resource_projection_report") do
      %{"projected_resources" => resource_rows}
      when is_list(resource_rows) and resource_rows != [] ->
        path = "$.branch_comparison_report.rows[#{index}]"
        first_pressure = resource_rows |> resource_projection_flow_rows() |> first_pressure()

        issues
        |> validate_first_resource_pressure_fields(path, row, first_pressure)
        |> validate_optional_copy(
          path <> ".first_resource_pressure_kind",
          row,
          "first_resource_pressure_kind",
          resource_pressure_kind(first_pressure),
          "must match the enclosing branch first resource pressure kind"
        )

      _report ->
        issues
    end
  end

  defp validate_first_resource_pressure_fields(issues, path, row, first_pressure) do
    Enum.reduce(
      @branch_comparison_first_resource_pressure_fields,
      issues,
      fn {row_field, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          map_field(first_pressure, source_field),
          "must match the enclosing branch first resource pressure #{source_field}"
        )
      end
    )
  end

  defp first_pressure(flow_rows) do
    Enum.find(flow_rows, %{}, fn flow_row ->
      positive_number?(map_field(flow_row, "storage_overflow_mb")) or
        positive_number?(map_field(flow_row, "downlink_shortfall_mb")) or
        positive_number?(map_field(flow_row, "battery_overuse_wh")) or
        map_field(flow_row, "resource_effect_reason") in @resource_projection_availability_pressure_types
    end)
  end

  defp resource_pressure_kind(flow_row) do
    cond do
      positive_number?(map_field(flow_row, "storage_overflow_mb")) ->
        "storage_overflow"

      positive_number?(map_field(flow_row, "downlink_shortfall_mb")) ->
        "downlink_shortfall"

      positive_number?(map_field(flow_row, "battery_overuse_wh")) ->
        "battery_depletion"

      map_field(flow_row, "resource_effect_reason") in @resource_projection_availability_pressure_types ->
        map_field(flow_row, "resource_effect_reason")

      true ->
        nil
    end
  end

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp validate_branch_comparison_feedback_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_feedback_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_feedback_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_feedback_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    feedback_adjustments = map_value(branch, "feedback_adjustments")

    Enum.reduce(@branch_comparison_feedback_fields, issues, fn {row_field, source_field}, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        Map.get(feedback_adjustments, source_field),
        "must match the enclosing branch feedback_adjustments.#{source_field}"
      )
    end)
  end

  defp validate_branch_comparison_priority_commitments(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_priority_commitment_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_priority_commitments(issues, _artifact), do: issues

  defp validate_branch_comparison_priority_commitment_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"

    priority_commitments =
      branch
      |> map_value("objective_satisfaction")
      |> map_value("priority_commitments")

    issues =
      Enum.reduce(
        @branch_comparison_priority_target_fields,
        issues,
        fn {kind, source_field}, acc ->
          target_ids = list_value(priority_commitments, source_field)
          count_field = "priority_commitment_#{kind}_target_count"
          ids_field = "priority_commitment_#{kind}_target_ids"

          acc
          |> validate_optional_copy(
            path <> ".#{count_field}",
            row,
            count_field,
            length(target_ids),
            "must match the enclosing branch #{source_field} count"
          )
          |> validate_optional_copy(
            path <> ".#{ids_field}",
            row,
            ids_field,
            target_ids,
            "must match the enclosing branch objective priority #{source_field}"
          )
        end
      )

    Enum.reduce(
      @branch_comparison_priority_scalar_fields,
      issues,
      fn {row_field, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          Map.get(priority_commitments, source_field),
          "must match the enclosing branch objective priority #{source_field}"
        )
      end
    )
  end

  defp list_value(%{} = container, field) do
    case Map.get(container, field, []) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp validate_branch_comparison_downlink_completion(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_downlink_completion_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_downlink_completion(issues, _artifact), do: issues

  defp validate_branch_comparison_downlink_completion_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"

    downlink_completion =
      branch
      |> map_value("objective_satisfaction")
      |> map_value("downlink_completion")

    Enum.reduce(@branch_comparison_downlink_fields, issues, fn {row_field, source_field}, acc ->
      validate_optional_copy(
        acc,
        path <> ".#{row_field}",
        row,
        row_field,
        Map.get(downlink_completion, source_field),
        "must match the enclosing branch objective downlink_completion.#{source_field}"
      )
    end)
  end

  defp validate_branch_comparison_coverage_and_revisit(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_coverage_and_revisit_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_coverage_and_revisit(issues, _artifact), do: issues

  defp validate_branch_comparison_coverage_and_revisit_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"
    objective_satisfaction = map_value(branch, "objective_satisfaction")

    Enum.reduce(
      @branch_comparison_coverage_revisit_fields,
      issues,
      fn {row_field, group, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          objective_satisfaction |> map_value(group) |> Map.get(source_field),
          "must match the enclosing branch objective #{group}.#{source_field}"
        )
      end
    )
  end

  defp validate_branch_comparison_collection_latency(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_collection_latency_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_collection_latency(issues, _artifact), do: issues

  defp validate_branch_comparison_collection_latency_row(issues, branch, row, index) do
    path = "$.branch_comparison_report.rows[#{index}]"

    collection_latency =
      branch
      |> map_value("objective_satisfaction")
      |> map_value("collection_latency")

    Enum.reduce(
      @branch_comparison_collection_latency_fields,
      issues,
      fn {row_field, source_field}, acc ->
        validate_optional_copy(
          acc,
          path <> ".#{row_field}",
          row,
          row_field,
          Map.get(collection_latency, source_field),
          "must match the enclosing branch objective collection_latency.#{source_field}"
        )
      end
    )
  end

  defp validate_branch_comparison_repair_score_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_repair_score_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_repair_score_evidence(issues, _artifact), do: issues

  defp validate_branch_comparison_repair_score_row(
         issues,
         %{"repair_result" => %{} = repair_result},
         row,
         index
       ) do
    path = "$.branch_comparison_report.rows[#{index}]"
    score_terms = map_value(repair_result, "score_terms")
    score_term_report = map_value(repair_result, "score_term_report")

    issues
    |> validate_optional_copy(
      path <> ".repair_score",
      row,
      "repair_score",
      Map.get(repair_result, "score"),
      "must match the enclosing branch repair score"
    )
    |> validate_optional_copy(
      path <> ".repair_score_term_count",
      row,
      "repair_score_term_count",
      Map.get(score_term_report, "row_count"),
      "must match the enclosing branch repair score_term_report.row_count"
    )
    |> validate_optional_copy(
      path <> ".repair_score_term_keys",
      row,
      "repair_score_term_keys",
      Map.get(score_term_report, "score_term_keys"),
      "must match the enclosing branch repair score_term_report.score_term_keys"
    )
    |> validate_optional_copy(
      path <> ".repair_activity_score",
      row,
      "repair_activity_score",
      Map.get(score_terms, "activity_score"),
      "must match the enclosing branch repair score_terms.activity_score"
    )
    |> validate_optional_copy(
      path <> ".repair_schedule_churn_penalty",
      row,
      "repair_schedule_churn_penalty",
      Map.get(score_terms, "schedule_churn_penalty"),
      "must match the enclosing branch repair score_terms.schedule_churn_penalty"
    )
    |> validate_optional_copy(
      path <> ".repair_schedule_move_penalty",
      row,
      "repair_schedule_move_penalty",
      Map.get(score_terms, "schedule_move_penalty"),
      "must match the enclosing branch repair score_terms.schedule_move_penalty"
    )
  end

  defp validate_branch_comparison_repair_score_row(issues, _branch, _row, _index),
    do: issues

  defp validate_branch_comparison_repair_link_selection_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_repair_link_selection_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_repair_link_selection_evidence(issues, _artifact),
    do: issues

  defp validate_branch_comparison_repair_link_selection_row(
         issues,
         %{"repair_result" => %{} = repair_result},
         row,
         index
       ) do
    path = "$.branch_comparison_report.rows[#{index}]"
    link_capacity_report = map_value(repair_result, "link_capacity_report")

    issues
    |> validate_optional_copy(
      path <> ".repair_link_contact_count",
      row,
      "repair_link_contact_count",
      Map.get(link_capacity_report, "contact_count"),
      "must match the enclosing branch repair link_capacity_report.contact_count"
    )
    |> validate_optional_copy(
      path <> ".repair_link_selected_contact_count",
      row,
      "repair_link_selected_contact_count",
      Map.get(link_capacity_report, "selected_contact_count"),
      "must match the enclosing branch repair link_capacity_report.selected_contact_count"
    )
    |> validate_optional_copy(
      path <> ".repair_link_selected_estimated_throughput_mb",
      row,
      "repair_link_selected_estimated_throughput_mb",
      Map.get(link_capacity_report, "selected_estimated_throughput_mb"),
      "must match the enclosing branch repair link_capacity_report.selected_estimated_throughput_mb"
    )
    |> validate_optional_copy(
      path <> ".repair_link_selected_capacity_adjusted_throughput_mb",
      row,
      "repair_link_selected_capacity_adjusted_throughput_mb",
      Map.get(link_capacity_report, "selected_capacity_adjusted_throughput_mb"),
      "must match the enclosing branch repair link_capacity_report.selected_capacity_adjusted_throughput_mb"
    )
    |> validate_optional_copy(
      path <> ".repair_link_required_downlink_mb",
      row,
      "repair_link_required_downlink_mb",
      Map.get(link_capacity_report, "required_downlink_mb"),
      "must match the enclosing branch repair link_capacity_report.required_downlink_mb"
    )
    |> validate_optional_copy(
      path <> ".repair_link_selected_downlink_shortfall_mb",
      row,
      "repair_link_selected_downlink_shortfall_mb",
      Map.get(link_capacity_report, "selected_downlink_shortfall_mb"),
      "must match the enclosing branch repair link_capacity_report.selected_downlink_shortfall_mb"
    )
    |> validate_optional_copy(
      path <> ".repair_link_downlink_requirement_status",
      row,
      "repair_link_downlink_requirement_status",
      Map.get(link_capacity_report, "downlink_requirement_status"),
      "must match the enclosing branch repair link_capacity_report.downlink_requirement_status"
    )
    |> validate_optional_copy(
      path <> ".repair_link_actual_throughput_mb",
      row,
      "repair_link_actual_throughput_mb",
      Map.get(link_capacity_report, "actual_throughput_mb"),
      "must match the enclosing branch repair link_capacity_report.actual_throughput_mb"
    )
    |> validate_optional_copy(
      path <> ".repair_link_actual_downlink_completion_ratio",
      row,
      "repair_link_actual_downlink_completion_ratio",
      Map.get(link_capacity_report, "actual_downlink_completion_ratio"),
      "must match the enclosing branch repair link_capacity_report.actual_downlink_completion_ratio"
    )
    |> validate_optional_copy(
      path <> ".repair_link_actual_downlink_shortfall_mb",
      row,
      "repair_link_actual_downlink_shortfall_mb",
      Map.get(link_capacity_report, "actual_downlink_shortfall_mb"),
      "must match the enclosing branch repair link_capacity_report.actual_downlink_shortfall_mb"
    )
    |> validate_optional_copy(
      path <> ".repair_link_actual_downlink_requirement_status",
      row,
      "repair_link_actual_downlink_requirement_status",
      Map.get(link_capacity_report, "actual_downlink_requirement_status"),
      "must match the enclosing branch repair link_capacity_report.actual_downlink_requirement_status"
    )
  end

  defp validate_branch_comparison_repair_link_selection_row(
         issues,
         _branch,
         _row,
         _index
       ),
       do: issues

  defp validate_branch_comparison_repair_constraint_evidence(
         issues,
         %{
           "branches" => branches,
           "branch_comparison_report" => %{"rows" => rows}
         }
       )
       when is_list(branches) and is_list(rows) do
    if Enum.all?(branches, &branch_id_input?/1) and Enum.all?(rows, &branch_id_input?/1) and
         Enum.map(rows, &Map.fetch!(&1, "branch_id")) ==
           Enum.map(branches, &Map.fetch!(&1, "branch_id")) do
      branches
      |> Enum.zip(rows)
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {{branch, row}, index}, acc ->
        validate_branch_comparison_repair_constraint_row(acc, branch, row, index)
      end)
    else
      issues
    end
  end

  defp validate_branch_comparison_repair_constraint_evidence(issues, _artifact),
    do: issues

  defp validate_branch_comparison_repair_constraint_row(
         issues,
         %{"repair_result" => %{} = repair_result},
         row,
         index
       ) do
    path = "$.branch_comparison_report.rows[#{index}]"
    constraint_report = map_value(repair_result, "constraint_report")

    issues
    |> validate_optional_copy(
      path <> ".repair_constraint_count",
      row,
      "repair_constraint_count",
      Map.get(constraint_report, "constraint_count"),
      "must match the enclosing branch repair constraint_report.constraint_count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_row_count",
      row,
      "repair_constraint_row_count",
      Map.get(constraint_report, "row_count"),
      "must match the enclosing branch repair constraint_report.row_count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_status",
      row,
      "repair_constraint_status",
      Map.get(constraint_report, "status"),
      "must match the enclosing branch repair constraint_report.status"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_pass_count",
      row,
      "repair_constraint_pass_count",
      constraint_status_count(constraint_report, "pass"),
      "must match the enclosing branch repair constraint pass count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_warning_count",
      row,
      "repair_constraint_warning_count",
      constraint_status_count(constraint_report, "warning"),
      "must match the enclosing branch repair constraint warning count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_fail_count",
      row,
      "repair_constraint_fail_count",
      constraint_status_count(constraint_report, "fail"),
      "must match the enclosing branch repair constraint fail count"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_failed_ids",
      row,
      "repair_constraint_failed_ids",
      constraint_ids_for_status(constraint_report, "fail"),
      "must match the enclosing branch failed repair constraint IDs"
    )
    |> validate_optional_copy(
      path <> ".repair_constraint_warning_ids",
      row,
      "repair_constraint_warning_ids",
      constraint_ids_for_status(constraint_report, "warning"),
      "must match the enclosing branch warning repair constraint IDs"
    )
  end

  defp validate_branch_comparison_repair_constraint_row(issues, _branch, _row, _index),
    do: issues

  defp constraint_status_count(report, status) do
    report
    |> constraint_rows()
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  defp constraint_ids_for_status(report, status) do
    report
    |> constraint_rows()
    |> Enum.filter(&(Map.get(&1, "status") == status))
    |> Enum.map(&Map.get(&1, "constraint_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp constraint_rows(%{} = report) do
    case Map.get(report, "rows") do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp map_value(%{} = container, field) do
    case Map.get(container, field) do
      %{} = value -> value
      _value -> %{}
    end
  end

  defp validate_source_provenance(issues, artifact) do
    provenance = Map.get(artifact, "provenance")

    issues
    |> validate_optional_copy(
      "$.provenance.source_plan_id",
      provenance,
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing CampaignStrategy source_plan_id"
    )
    |> validate_operator_review_provenance(
      provenance,
      get_in(artifact, ["operator_review_package", "provenance"])
    )
    |> validate_optional_copy(
      "$.cadence_import_manifest.provenance.source_plan_id",
      get_in(artifact, ["cadence_import_manifest", "provenance"]),
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing CampaignStrategy source_plan_id"
    )
  end

  defp validate_operator_review_provenance(
         issues,
         %{} = provenance,
         %{} = review_provenance
       ) do
    Enum.reduce(@source_provenance_fields, issues, fn field, acc ->
      if Map.has_key?(provenance, field) and Map.has_key?(review_provenance, field) do
        validate_optional_copy(
          acc,
          "$.operator_review_package.provenance.#{field}",
          review_provenance,
          field,
          Map.get(provenance, field),
          "must match enclosing CampaignStrategy provenance.#{field}"
        )
      else
        acc
      end
    end)
  end

  defp validate_operator_review_provenance(issues, _provenance, _review_provenance),
    do: issues

  defp validate_optional_copy(issues, path, %{} = container, field, expected, message) do
    if Map.has_key?(container, field) and Map.get(container, field) != expected,
      do: [error(path, message) | issues],
      else: issues
  end

  defp validate_optional_copy(issues, _path, _container, _field, _expected, _message),
    do: issues

  defp validate_optional_score_term_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_score_term_report(issues, %{} = report) do
    DecisionSupportValidation.validate_score_term_report(
      issues,
      "$.score_term_report",
      report
    )
  end

  defp validate_optional_score_term_report(issues, _report),
    do: [error("$.score_term_report", "must be an object") | issues]

  defp validate_optional_objective_tradeoff_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_objective_tradeoff_report(issues, %{} = report) do
    DecisionSupportValidation.validate_objective_tradeoff_report(
      issues,
      "$.objective_tradeoff_report",
      report
    )
  end

  defp validate_optional_objective_tradeoff_report(issues, _report),
    do: [error("$.objective_tradeoff_report", "must be an object") | issues]

  defp validate_optional_pareto_frontier_report(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_pareto_frontier_report(issues, %{} = report) do
    DecisionSupportValidation.validate_pareto_frontier_report(
      issues,
      "$.pareto_frontier_report",
      report
    )
  end

  defp validate_optional_pareto_frontier_report(issues, _report),
    do: [error("$.pareto_frontier_report", "must be an object") | issues]

  defp validate_optional_cadence_import_manifest(issues, value) when value in [nil, :null],
    do: issues

  defp validate_optional_cadence_import_manifest(issues, %{} = manifest) do
    CadenceImportValidation.validate_manifest_artifact(
      issues,
      "$.cadence_import_manifest",
      manifest
    )
  end

  defp validate_optional_cadence_import_manifest(issues, _manifest),
    do: [error("$.cadence_import_manifest", "must be an object") | issues]

  defp validate_optional_operational_feedback_provenance(issues, artifact) do
    case Map.get(artifact, "operational_feedback_provenance") do
      value when value in [nil, :null] ->
        issues

      %{} = provenance ->
        issues
        |> require_fields(@provenance_path, provenance, @provenance_fields)
        |> expect_equal(@provenance_path, provenance, "model", @provenance_model)
        |> expect_type(@provenance_path, provenance, "merge_order", :list)
        |> expect_type(@provenance_path, provenance, "input_keys", :list)
        |> expect_type(@provenance_path, provenance, "effective_sources", :map)
        |> expect_type(@provenance_path, provenance, "overridden_sources", :map)
        |> expect_type(@provenance_path, provenance, "source_count", :integer)
        |> expect_non_negative_integer(@provenance_path, provenance, "source_count")
        |> expect_type(@provenance_path, provenance, "sources", :list)
        |> expect_type(@provenance_path, provenance, "explicit_request_override", :boolean)
        |> validate_unique_string_list(
          "#{@provenance_path}.merge_order",
          provenance["merge_order"],
          false
        )
        |> validate_unique_string_list(
          "#{@provenance_path}.input_keys",
          provenance["input_keys"],
          true
        )
        |> validate_source_rows(provenance["sources"])
        |> validate_source_count(provenance)
        |> validate_source_resolution(provenance)
        |> validate_feedback_input_keys(provenance, artifact["operational_feedback"])

      _value ->
        [error(@provenance_path, "must be an object") | issues]
    end
  end

  defp validate_source_rows(issues, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = row, index}, acc ->
        path = "#{@provenance_path}.sources[#{index}]"

        acc
        |> require_fields(path, row, ["source", "input_keys"])
        |> expect_type(path, row, "source", :binary)
        |> expect_type(path, row, "input_keys", :list)
        |> validate_unique_string_list("#{path}.input_keys", row["input_keys"], true)

      {_row, index}, acc ->
        [error("#{@provenance_path}.sources[#{index}]", "must be an object") | acc]
    end)
  end

  defp validate_source_rows(issues, _rows), do: issues

  defp validate_source_count(issues, %{"sources" => rows, "source_count" => count})
       when is_list(rows) and is_integer(count) do
    if count == length(rows) do
      issues
    else
      [error("#{@provenance_path}.source_count", "must equal sources row count") | issues]
    end
  end

  defp validate_source_count(issues, _provenance), do: issues

  defp validate_source_resolution(
         issues,
         %{
           "input_keys" => input_keys,
           "effective_sources" => effective_sources,
           "overridden_sources" => overridden_sources,
           "sources" => sources
         }
       )
       when is_list(input_keys) and is_map(effective_sources) and is_map(overridden_sources) and
              is_list(sources) do
    source_names =
      sources
      |> Enum.flat_map(fn
        %{"source" => source} when is_binary(source) -> [source]
        _row -> []
      end)
      |> MapSet.new()

    issues
    |> validate_effective_source_keys(input_keys, effective_sources)
    |> validate_string_source_map(
      "#{@provenance_path}.effective_sources",
      effective_sources,
      source_names
    )
    |> validate_string_source_list_map(
      "#{@provenance_path}.overridden_sources",
      overridden_sources,
      input_keys,
      source_names
    )
  end

  defp validate_source_resolution(issues, _provenance), do: issues

  defp validate_effective_source_keys(issues, input_keys, effective_sources) do
    if Enum.sort(Map.keys(effective_sources)) == input_keys do
      issues
    else
      [
        error(
          "#{@provenance_path}.effective_sources",
          "keys must equal sorted operational-feedback input keys"
        )
        | issues
      ]
    end
  end

  defp validate_string_source_map(issues, path, values, source_names) do
    Enum.reduce(values, issues, fn {key, value}, acc ->
      cond do
        not is_binary(key) ->
          [error(path, "keys must be strings") | acc]

        not is_binary(value) ->
          [error("#{path}.#{key}", "must be a string") | acc]

        not MapSet.member?(source_names, value) ->
          [error("#{path}.#{key}", "must reference a declared source") | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_string_source_list_map(issues, path, values, input_keys, source_names) do
    input_key_set = MapSet.new(input_keys)

    Enum.reduce(values, issues, fn {key, source_values}, acc ->
      acc =
        if is_binary(key) and MapSet.member?(input_key_set, key) do
          acc
        else
          [error(path, "keys must reference operational-feedback input keys") | acc]
        end

      case source_values do
        values when is_list(values) ->
          values
          |> Enum.with_index()
          |> Enum.reduce(acc, fn {source, index}, nested_acc ->
            if is_binary(source) and MapSet.member?(source_names, source) do
              nested_acc
            else
              [error("#{path}.#{key}[#{index}]", "must reference a declared source") | nested_acc]
            end
          end)

        _value ->
          [error("#{path}.#{key}", "must be a list") | acc]
      end
    end)
  end

  defp validate_feedback_input_keys(issues, provenance, %{} = operational_feedback) do
    expected_input_keys =
      @operational_feedback_fields
      |> Enum.filter(fn field ->
        case Map.get(operational_feedback, field) do
          %{} = values -> map_size(values) > 0
          _value -> false
        end
      end)
      |> Enum.sort()

    if provenance["input_keys"] == expected_input_keys do
      issues
    else
      [
        error(
          "#{@provenance_path}.input_keys",
          "must equal nonempty operational-feedback field keys"
        )
        | issues
      ]
    end
  end

  defp validate_feedback_input_keys(issues, _provenance, _operational_feedback), do: issues

  defp validate_unique_string_list(issues, path, values, sorted?) when is_list(values) do
    issues =
      values
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {value, index}, acc ->
        if is_binary(value), do: acc, else: [error("#{path}[#{index}]", "must be a string") | acc]
      end)

    cond do
      Enum.uniq(values) != values -> [error(path, "must contain unique values") | issues]
      sorted? and Enum.sort(values) != values -> [error(path, "must be sorted") | issues]
      true -> issues
    end
  end

  defp validate_unique_string_list(issues, _path, _values, _sorted?), do: issues
end
