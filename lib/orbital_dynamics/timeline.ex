defmodule OrbitalDynamics.Timeline do
  @moduledoc """
  Builds artifact-only operational timeline reports.

  The report exposes command/contact classification, approval state, lock state,
  source-window lineage, Cadence import presence, and stable timeline identity
  without mutating schedules or executing operational work.
  """

  alias OrbitalDynamics.Timeline.RevisionReplay

  @schema_contract "operational_timeline_report.v1"
  @diff_schema_contract "timeline_diff_report.v1"
  @diff_summary_schema_contract "timeline_diff_summary.v1"
  @integrity_report_schema_contract "timeline_integrity_report.v1"
  @dependency_impact_summary_schema_contract "timeline_dependency_impact_summary.v1"
  @publication_summary_schema_contract "timeline_publication_summary.v1"
  @activity_state_schema_contract "timeline_activity_state.v1"
  @activity_precondition_summary_schema_contract "timeline_activity_precondition_summary.v1"
  @activity_status_state_schema_contract "timeline_activity_status_state.v1"
  @activity_approval_state_schema_contract "timeline_activity_approval_state.v1"
  @activity_lifecycle_state_schema_contract "timeline_activity_lifecycle_state.v1"
  @preservation_report_schema_contract "timeline_preservation_report.v1"
  @preservation_status_schema_contract "timeline_preservation_status.v1"
  @lifecycle_state_summary_schema_contract "timeline_lifecycle_state_summary.v1"
  @transition_application_schema_contract "timeline_transition_application_report.v1"
  @transition_application_summary_schema_contract "timeline_transition_application_summary.v1"
  @candidate_rejection_schema_contract "candidate_rejection_report.v1"
  @executed_statuses ~w(completed partial executed)
  @terminal_exception_statuses ~w(missed failed canceled cancelled rejected)
  @protected_approval_statuses ~w(approved auto_approvable locked)
  @review_approval_statuses ~w(pending operator_review_required not_evaluated)
  @approval_statuses @protected_approval_statuses ++
                       @review_approval_statuses ++
                       ~w(blocked_by_policy not_required rejected)
  @activity_statuses Enum.uniq(
                       ~w(draft planned approved delayed invalid executing) ++
                         @executed_statuses ++ @terminal_exception_statuses ++ @approval_statuses
                     )
  @lifecycle_events ~w(
    approve
    reject
    lock
    start_execution
    record_execution
    record_completion
    record_partial
    record_failure
    record_miss
    delay
    cancel
  )
  @required_operator_actions ~w(
    monitor_activity
    none_locked_activity
    none_terminal_activity
    prepare_cadence_import
    resolve_blocked_activity
    resolve_contact_conflict
    resolve_rejected_activity
    review_activity_approval
    review_command_contact
    review_duplicate_timeline_identity
    review_invalid_activity_input
    review_invalid_cadence_import
    review_terminal_activity_exception
    review_timeline_integrity
  )
  @timeline_diff_required_operator_actions ~w(
    none
    record_timeline_change
    review_added_activity
    review_changed_executed_activity
    review_changed_protected_activity
    review_duplicate_timeline_identity
    review_invalid_activity_input
    review_removed_activity
    review_removed_executed_activity
    review_removed_protected_activity
    review_timeline_change
    review_timeline_integrity
  )
  @transition_decision_required_operator_actions Enum.sort(
                                                   @timeline_diff_required_operator_actions ++
                                                     ["review_activity_transition"]
                                                 )
  @timeline_diff_statuses ~w(added removed changed unchanged)
  @transition_decisions ~w(none preserve_source record review)
  @transition_application_statuses ~w(
    no_activity
    operator_review_required
    replacement_recorded
    replacement_unchanged
    selected_timeline_integrity_review_required
    source_preserved_pending_review
    source_unchanged
  )
  @lifecycle_transition_types ~w(added changed removed)
  @status_transition_categories ~w(
    executed_activity_changed
    executed_activity_removed
    execution_recorded
    repair_status_recorded
    status_added
    status_block_cleared
    status_blocked
    status_changed
    status_removed
    terminal_exception_recorded
    terminal_exception_reopened
    unsupported_status
  )
  @approval_transition_categories ~w(
    approval_added
    approval_blocked
    approval_changed
    approval_granted
    approval_regressed
    approval_rejected
    approval_removed
    approval_review_required
    protected_approval_removed
    unsupported_approval_status
  )
  @cadence_import_statuses ~w(invalid missing not_applicable present)
  @execution_boundaries ~w(planned_not_commanded)
  @timeline_integrity_issue_types ~w(
    dependency_cycle
    dependency_order_violation
    duplicate_dependency_activity
    duplicate_dependency_timeline
    duplicate_exclusivity_activity
    duplicate_exclusivity_timeline
    exclusivity_group_overlap
    exclusivity_overlap
    invalid_activity_input
    missing_dependency_activity
    missing_dependency_timeline
    self_dependency_activity
    self_dependency_timeline
  )
  @dependency_impact_summary_fields ~w(
    changed_source_activity_count
    changed_source_timeline_count
    dependency_impact_status
    dependent_activity_count
    source_dependent_activity_count
    replacement_dependent_activity_count
    impacted_source_activity_ids
    impacted_source_timeline_ids
    dependent_activity_ids
    dependent_timeline_ids
    source_dependent_activity_ids
    source_dependent_timeline_ids
    replacement_dependent_activity_ids
    replacement_dependent_timeline_ids
    impacted_dependency_activity_ids
    impacted_dependency_timeline_ids
    impacted_exclusive_with_activity_ids
    impacted_exclusive_with_timeline_ids
    dependency_impact_rows
  )
  @publication_summary_fields ~w(
    publication_id
    publication_sequence
    publication_status
    downstream_invalidation_status
    publication_authority
    source_artifact_id
    source_artifact_type
    supersedes_artifact_ids
    downstream_product_ids
    invalidated_downstream_product_ids
    downstream_invalidation_reason_counts
    invalidated_downstream_product_ids_by_reason
    dependency_impact_status
    dependency_impact_row_count
    source_timeline_dependency_impact_summary
    impacted_source_activity_ids
    impacted_source_timeline_ids
    dependent_activity_ids
    dependent_timeline_ids
    source_dependent_activity_ids
    source_dependent_timeline_ids
    replacement_dependent_activity_ids
    replacement_dependent_timeline_ids
    impacted_dependency_activity_ids
    impacted_dependency_timeline_ids
    impacted_exclusive_with_activity_ids
    impacted_exclusive_with_timeline_ids
    source_timeline_diff_summary
    timeline_diff_row_count
    timeline_diff_changed_count
    timeline_diff_review_required_count
    changed_field_counts
    changed_timeline_ids
    review_timeline_ids
    timeline_ids_by_changed_field
  )
  @dependency_impact_statuses ~w(clear review_required)
  @publication_dependency_impact_statuses ~w(clear not_evaluated review_required)
  @publication_downstream_invalidation_statuses ~w(clear invalidated)
  @publication_downstream_invalidation_reasons ~w(
    dependency_impact_review_required
    explicit_downstream_invalidation
    superseded_publication
  )
  @publication_statuses ~w(published published_with_downstream_invalidations review_required)
  @candidate_rejection_reasons ~w(
    no_access_window
    no_target_visibility_window
    eclipse_conflict
    battery_margin_too_low
    storage_full
    fuel_margin_too_low
    payload_unavailable
    antenna_unavailable
    station_unavailable
    station_reserved
    station_capacity_reduced
    contact_too_short
    target_already_satisfied
    better_spacecraft_assigned
    overlaps_locked_timeline_item
    command_authority_missing
    policy_blocked
    stale_state
    model_incompatible
    quality_gate_failed
    invalid_candidate_input
    declared_rejection
  )
  @candidate_rejection_station_capacity_fraction_fields OrbitalDynamics.Timeline.CandidateRejectionStationPolicy.capacity_fraction_fields()
  @candidate_rejection_station_capacity_fraction_paths Enum.flat_map(
                                                         @candidate_rejection_station_capacity_fraction_fields,
                                                         fn field ->
                                                           [
                                                             [field],
                                                             ["metadata", field],
                                                             [
                                                               "source_station_calendar_entry",
                                                               field
                                                             ],
                                                             [
                                                               "source_station_calendar_overlaps",
                                                               field
                                                             ]
                                                           ]
                                                         end
                                                       )
  @candidate_rejection_station_capacity_value_paths for path <-
                                                          @candidate_rejection_station_capacity_fraction_paths,
                                                        do: {:fraction, path}
  @candidate_rejection_actions ~w(none review_candidate_rejection)
  @command_health_activity_types ~w(command health_check)
  @command_contact_directions OrbitalDynamics.Timeline.OperationalRowClassificationPolicy.command_contact_directions()
  @operational_kinds ~w(activity attitude coast command contact health_check maneuver observation)
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @activity_lighting_field_aliases [
    {"lighting_condition", ["lighting_condition", "lighting_status"]},
    {"lighting_condition_detail", ["lighting_condition_detail", "lighting_detail"]},
    {"lighting_condition_model", ["lighting_condition_model", "lighting_model"]},
    {"lighting_detail_model", ["lighting_detail_model", "lighting_detail_source"]},
    {"lighting_confidence", ["lighting_confidence", "lighting_confidence_label"]}
  ]
  @unit_interval_activity_field_aliases [
    {"contact_success_factor", ["contact_success_factor"]},
    {"command_success_factor", ["command_success_factor"]},
    {"observation_success_factor", ["observation_success_factor"]},
    {"maneuver_success_factor", ["maneuver_success_factor"]},
    {"cloud_cover_fraction", ["cloud_cover_fraction", "cloud_fraction", "cloud_cover"]},
    {"blur_score", ["blur_score", "image_blur_score", "sharpness_loss_fraction"]},
    {"fuel_margin", ["fuel_margin"]},
    {"power_margin", ["power_margin"]},
    {"storage_margin", ["storage_margin", "storage_capacity_margin"]},
    {"downlink_margin", ["downlink_margin"]},
    {"battery_state_of_charge", ["battery_state_of_charge", "battery_soc"]}
  ]
  @activity_stable_identity_paths [
    {"scenario_id", ["scenario_id"]},
    {"ground_station_id", ["ground_station_id"]},
    {"target_id", ["target_id"]},
    {"maneuver_id", ["maneuver_id"]},
    {"spacecraft_id", ["spacecraft_id"]},
    {"resource_id", ["resource_id"]},
    {"collection_id", ["collection_id"]},
    {"collection_id", ["collection"]},
    {"product_id", ["product_id"]},
    {"product_id", ["data_product_id"]},
    {"payload_id", ["payload_id"]},
    {"payload_id", ["payload"]},
    {"instrument_id", ["instrument_id"]},
    {"instrument_id", ["instrument"]},
    {"source_window_id", ["source_window_id"]},
    {"source_window_id", ["source_window", "id"]},
    {"source_window_id", ["metadata", "source_window_id"]},
    {"station_calendar_entry_id", ["station_calendar_entry_id"]},
    {"station_calendar_provider_id", ["station_calendar_provider_id"]},
    {"station_calendar_provider_entry_id", ["station_calendar_provider_entry_id"]},
    {"station_reservation_id", ["station_reservation_id"]},
    {"timeline_id", ["timeline_id"]},
    {"timeline_id", ["persistent_id"]},
    {"timeline_id", ["metadata", "timeline_id"]},
    {"timeline_id", ["metadata", "persistent_id"]}
  ]
  @diff_activity_context_compare_fields ~w(
    contact_result
    command_result
    command_success
    command_window_id
    command_window_type
    maneuver_id
    command_success_factor
    command_success_factor_source
    contact_success
    contact_success_factor
    contact_success_factor_source
    pointing_mode
    pointing_target_id
    boresight_axis
    off_nadir_angle_deg
    slew_angle_deg
    slew_rate_deg_s
    pointing_error_deg
    pointing_status
    pointing_model
    pointing_source
    pointing_confidence
    attitude_mode
    attitude_target_id
    roll_deg
    pitch_deg
    yaw_deg
    attitude_error_deg
    attitude_status
    attitude_model
    attitude_source
    attitude_confidence
    link_protocol
    frequency_band
    modulation
    coding_scheme
    polarization
    data_rate_mbps
    downlink_rate_mbps
    data_rate_mb_s
    downlink_rate_mb_s
    actual_data_rate_mbps
    actual_downlink_rate_mbps
    actual_data_rate_mb_s
    actual_downlink_rate_mb_s
    actual_data_rate_throughput_derivation
    delivered_rate_mbps
    received_rate_mbps
    delivered_rate_mb_s
    received_rate_mb_s
    actual_duration_s
    actual_contact_duration_s
    contact_duration_s
    link_margin_db
    snr_db
    eb_no_db
    bit_error_rate
    packet_loss_rate
    frame_loss_rate
    carrier_lock
    symbol_lock
    link_quality_status
    thermal_zone_id
    temperature_c
    planned_temperature_c
    actual_temperature_c
    temperature_delta_c
    min_operating_temperature_c
    max_operating_temperature_c
    thermal_margin_c
    thermal_status
    thermal_model
    thermal_source
    thermal_confidence
    resource_id
    eclipse_overlap_fraction
    eclipse_overlap_s
    image_quality_score
    image_quality_status
    image_quality_source
    cloud_cover_fraction
    blur_score
    lighting_condition
    lighting_condition_detail
    lighting_condition_model
    lighting_detail_model
    lighting_confidence
    source_window
    resource_source_quality
    resource_trust_boundary
    resource_trust_boundary_status
    fuel_margin
    power_margin
    storage_margin
    downlink_margin
    battery_capacity_wh
    battery_energy_used_wh
    battery_energy_generated_wh
    battery_state_of_charge
    spacecraft_available
    payload_available
    antenna_available
    degraded
    planned_data_volume_mb
    planned_volume_mb
    actual_data_volume_mb
    actual_volume_mb
    data_volume_completion_fraction
    data_volume_delta_mb
    collection_ends_at_s
    planned_delivery_at_s
    actual_delivery_at_s
    max_latency_s
    planned_latency_s
    actual_latency_s
    latency_delta_s
    latency_margin_s
    execution_uncertainty
    maneuver_success_factor
    maneuver_success_factor_source
    observation_objective_count
    observation_objective_ids
    observation_objective_source
    observation_objective_types
    observation_success_factor
    observation_success_factor_source
    planned_estimated_throughput_mb
    actual_throughput_mb
    throughput_completion_fraction
    throughput_delta_mb
    required_downlink_mb
    required_volume_mb
    required_data_volume_mb
    target_downlink_mb
    target_volume_mb
    target_data_volume_mb
    min_downlink_mb
    candidate_downlink_mb
    selected_downlink_mb
    selected_data_volume_mb
    selected_volume_mb
    delivered_data_volume_mb
    received_data_volume_mb
    downlink_completion_ratio
    selected_downlink_shortfall_mb
    selected_data_volume_shortfall_mb
    data_volume_shortfall_mb
    actual_data_volume_shortfall_mb
    missing_data_volume_mb
    required_data_volume_gap_mb
    downlink_requirement_status
    downlink_completion_source
    downlink_completion_sources
    station_calendar_trust_boundary_status
    station_calendar_provider_id
    station_calendar_provider_entry_id
    setup_duration_s
    cooldown_duration_s
    telemetry_confirmation_required
    telemetry_confirmation_status
    trust_boundary
    provenance
    source_station_calendar_entry
    source_station_calendar_overlaps
    station_calendar_directions
  )
  @activity_context_keys ~w(
    approval_status
    approved
    cadence_import
    capacity_fraction
    capacity_pack_capacity_fraction
    contact_result
    command_result
    command_success
    command_window_id
    command_window_type
    command_success_factor
    command_success_factor_source
    collection_id
    collection_latency_objective_count
    collection_latency_objective_ids
    collection_latency_objective_source
    collection_latency_objective_types
    data_volume_mb
    actual_data_volume_mb
    data_volume_completion_fraction
    data_volume_delta_mb
    collection_ends_at_s
    contact_success
    contact_success_factor
    contact_success_factor_source
    cooldown_duration_s
    dependencies
    direction
    ends_at_s
    estimated_data_volume_mb
    estimated_downlink_mb
    estimated_storage_mb
    estimated_throughput_mb
    eclipse_overlap_fraction
    eclipse_overlap_s
    actual_throughput_mb
    planned_delivery_at_s
    actual_delivery_at_s
    max_latency_s
    planned_latency_s
    actual_latency_s
    latency_delta_s
    latency_margin_s
    execution_uncertainty
    exclusivity_group
    ground_station_id
    instrument_id
    locked
    lighting_condition
    lighting_condition_detail
    lighting_condition_model
    lighting_detail_model
    lighting_confidence
    metadata
    maneuver_id
    maneuver_result
    maneuver_success
    maneuver_success_factor
    maneuver_success_factor_source
    observation_result
    observation_success
    observation_success_factor
    observation_success_factor_source
    image_quality_score
    image_quality_status
    image_quality_source
    cloud_cover_fraction
    blur_score
    observation_objective_count
    observation_objective_ids
    observation_objective_source
    observation_objective_types
    pointing_mode
    pointing_target_id
    boresight_axis
    off_nadir_angle_deg
    slew_angle_deg
    slew_rate_deg_s
    pointing_error_deg
    pointing_status
    pointing_model
    pointing_source
    pointing_confidence
    attitude_mode
    attitude_target_id
    roll_deg
    pitch_deg
    yaw_deg
    attitude_error_deg
    attitude_status
    attitude_model
    attitude_source
    attitude_confidence
    link_protocol
    frequency_band
    modulation
    coding_scheme
    polarization
    data_rate_mbps
    downlink_rate_mbps
    data_rate_mb_s
    downlink_rate_mb_s
    actual_data_rate_mbps
    actual_downlink_rate_mbps
    actual_data_rate_mb_s
    actual_downlink_rate_mb_s
    delivered_rate_mbps
    received_rate_mbps
    delivered_rate_mb_s
    received_rate_mb_s
    actual_duration_s
    actual_contact_duration_s
    contact_duration_s
    link_margin_db
    snr_db
    eb_no_db
    bit_error_rate
    packet_loss_rate
    frame_loss_rate
    carrier_lock
    symbol_lock
    link_quality_status
    thermal_zone_id
    temperature_c
    planned_temperature_c
    actual_temperature_c
    temperature_delta_c
    min_operating_temperature_c
    max_operating_temperature_c
    thermal_margin_c
    thermal_status
    thermal_model
    thermal_source
    thermal_confidence
    payload_id
    product_id
    product_ids
    resource_id
    resource_source_quality
    resource_trust_boundary
    resource_trust_boundary_status
    resource_provenance
    resource_blocking_dimension
    fuel_margin
    power_margin
    storage_margin
    downlink_margin
    battery_capacity_wh
    battery_energy_used_wh
    battery_energy_generated_wh
    battery_state_of_charge
    spacecraft_available
    payload_available
    antenna_available
    degraded
    mode
    incompatible_activity_types
    suppressed_activity_types
    spacecraft_id
    planned_data_volume_mb
    planned_volume_mb
    planned_estimated_throughput_mb
    provenance
    required_downlink_mb
    required_volume_mb
    required_data_volume_mb
    target_downlink_mb
    target_volume_mb
    target_data_volume_mb
    min_downlink_mb
    candidate_downlink_mb
    selected_downlink_mb
    selected_data_volume_mb
    selected_volume_mb
    actual_data_volume_mb
    actual_volume_mb
    delivered_data_volume_mb
    received_data_volume_mb
    downlink_completion_ratio
    selected_downlink_shortfall_mb
    selected_data_volume_shortfall_mb
    data_volume_shortfall_mb
    actual_data_volume_shortfall_mb
    missing_data_volume_mb
    required_data_volume_gap_mb
    downlink_requirement_status
    downlink_completion_source
    downlink_completion_sources
    feedback_weight
    feedback_weight_source
    required_observations
    schedule_conflict_status
    score
    score_terms
    source_station_calendar_entry
    source_station_calendar_overlaps
    setup_duration_s
    source_window
    source_window_id
    source_window_type
    starts_at_s
    status
    telemetry_confirmation_required
    telemetry_confirmation_status
    station_availability
    station_capacity_fraction
    station_calendar_ambiguous_entry_count
    station_calendar_ambiguous_entry_ids
    station_calendar_directions
    station_calendar_entry_ambiguous
    station_calendar_entry_id
    station_calendar_provider_id
    station_calendar_provider_entry_id
    station_calendar_overlap_availabilities
    station_calendar_overlap_count
    station_calendar_overlap_entry_ids
    station_calendar_reservation_expires_at_s
    station_calendar_reservation_ids
    station_calendar_reservation_overlap_count
    station_calendar_reservation_statuses
    station_calendar_reserved_by
    station_calendar_status
    station_calendar_trust_boundary_status
    station_contention_status
    station_reservation_expires_at_s
    station_reservation_id
    station_reservation_match_status
    station_reservation_status
    station_reserved_by
    target_priority
    target_priority_objective_ids
    target_priority_objective_type
    target_priority_source
    target_id
    throughput_model
    trust_boundary
    transition_application_provenance
  )
  @diff_compare_fields [
                         "activity_id",
                         "activity_type",
                         "status",
                         "approval_status",
                         "locked",
                         "allow_overlap",
                         "starts_at_s",
                         "ends_at_s",
                         "direction",
                         "spacecraft_id",
                         "ground_station_id",
                         "target_id",
                         "source_window_id",
                         "source_window_type",
                         "station_availability",
                         "station_calendar_entry_id",
                         "station_calendar_provider_id",
                         "station_calendar_provider_entry_id",
                         "station_calendar_status",
                         "station_calendar_overlap_count",
                         "station_calendar_overlap_entry_ids",
                         "station_calendar_overlap_availabilities",
                         "station_calendar_entry_ambiguous",
                         "station_calendar_ambiguous_entry_count",
                         "station_calendar_ambiguous_entry_ids",
                         "station_contention_status",
                         "station_reservation_id",
                         "station_reservation_expires_at_s",
                         "station_reserved_by",
                         "station_reservation_status",
                         "station_reservation_match_status",
                         "station_calendar_reservation_overlap_count",
                         "station_calendar_reservation_expires_at_s",
                         "station_calendar_reservation_ids",
                         "station_calendar_reserved_by",
                         "station_calendar_reservation_statuses",
                         "schedule_conflict_status",
                         "dependency_activity_ids",
                         "dependency_timeline_ids",
                         "exclusive_with_activity_ids",
                         "exclusive_with_timeline_ids"
                       ] ++ @diff_activity_context_compare_fields

  @doc """
  Declares the operational timeline report model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      diff_artifact_contract: @diff_schema_contract,
      diff_summary_artifact_contract: @diff_summary_schema_contract,
      integrity_report_artifact_contract: @integrity_report_schema_contract,
      dependency_impact_summary_artifact_contract: @dependency_impact_summary_schema_contract,
      publication_summary_artifact_contract: @publication_summary_schema_contract,
      activity_state_artifact_contract: @activity_state_schema_contract,
      activity_precondition_summary_artifact_contract:
        @activity_precondition_summary_schema_contract,
      activity_status_state_artifact_contract: @activity_status_state_schema_contract,
      activity_approval_state_artifact_contract: @activity_approval_state_schema_contract,
      activity_lifecycle_state_artifact_contract: @activity_lifecycle_state_schema_contract,
      preservation_report_artifact_contract: @preservation_report_schema_contract,
      preservation_status_artifact_contract: @preservation_status_schema_contract,
      lifecycle_state_summary_artifact_contract: @lifecycle_state_summary_schema_contract,
      transition_application_artifact_contract: @transition_application_schema_contract,
      transition_application_summary_artifact_contract:
        @transition_application_summary_schema_contract,
      timeline_revision_contract: RevisionReplay.schema_contract(),
      timeline_revision_identity_scheme: RevisionReplay.identity_scheme(),
      timeline_revision_canonicalization: RevisionReplay.canonicalization(),
      timeline_revision_replay_limits: [
        :pure_artifact_replay,
        :no_revision_store,
        :no_locking,
        :no_external_workflow,
        :no_planner_default_change,
        :no_schedule_mutation,
        :no_distributed_concurrency_guarantee
      ],
      candidate_rejection_artifact_contract: @candidate_rejection_schema_contract,
      model: :selected_activity_operational_context_summary,
      validation_level: :artifact_contract,
      supported_activity_types: [
        "observe",
        "downlink",
        "planned_contact",
        "contact",
        "command",
        "tracking",
        "health_check",
        "slew",
        "attitude",
        "coast",
        "impulsive_burn"
      ],
      operational_kinds: @operational_kinds,
      activity_statuses: @activity_statuses,
      approval_statuses: @approval_statuses,
      provider_direction_aliases: provider_direction_aliases(),
      activity_status_aliases: activity_status_aliases(),
      approval_status_aliases: approval_status_aliases(),
      provider_result_map_value_keys: @provider_result_map_value_keys,
      activity_lighting_field_aliases: field_alias_metadata(@activity_lighting_field_aliases),
      unit_interval_activity_field_aliases:
        field_alias_metadata(@unit_interval_activity_field_aliases),
      required_operator_actions: @required_operator_actions,
      timeline_diff_required_operator_actions: @timeline_diff_required_operator_actions,
      timeline_diff_statuses: @timeline_diff_statuses,
      timeline_diff_compare_fields: @diff_compare_fields,
      timeline_diff_activity_context_compare_fields: @diff_activity_context_compare_fields,
      transition_decision_required_operator_actions:
        @transition_decision_required_operator_actions,
      transition_decisions: @transition_decisions,
      transition_application_statuses: @transition_application_statuses,
      lifecycle_transition_types: @lifecycle_transition_types,
      status_transition_categories: @status_transition_categories,
      approval_transition_categories: @approval_transition_categories,
      activity_precondition_statuses:
        OrbitalDynamics.MissionPlan.Activity.capabilities().precondition_statuses,
      activity_precondition_types:
        OrbitalDynamics.MissionPlan.Activity.capabilities().precondition_types,
      activity_precondition_row_semantics:
        OrbitalDynamics.MissionPlan.Activity.capabilities().precondition_row_semantics,
      diff_helpers: [
        :diff_report,
        :diff_summary
      ],
      timeline_integrity_helpers: [
        :integrity_report,
        :dependency_impact_summary,
        :publication_summary
      ],
      lifecycle_preservation_helpers: [
        :preservation_status,
        :preservation_report
      ],
      normalization_helpers: [
        :normalize_activity,
        :normalize_activities,
        :timeline_identity,
        :activity_precondition_summary,
        :activity_context
      ],
      candidate_rejection_helpers: [
        :candidate_rejection_report
      ],
      transition_helpers: [
        :activity_transition,
        :activity_lifecycle_state,
        :lifecycle_state_summary,
        :activity_status_state,
        :activity_approval_state,
        :status_transition,
        :approval_transition,
        :transition_activity_status,
        :transition_activity_approval_status,
        :apply_lifecycle_event,
        :protection_decision,
        :transition_decision,
        :transition_application,
        :transition_application_summary,
        :transition_application_report,
        :replay_transition_application_report,
        :transition_selected_activities
      ],
      public_facades: [
        :operational_timeline_report,
        :normalize_timeline_activity,
        :normalize_timeline_activities,
        :timeline_diff_report,
        :timeline_activity_transition,
        :timeline_activity_context,
        :timeline_activity_precondition_summary,
        :timeline_identity,
        :timeline_link,
        :timeline_preservation_report,
        :timeline_dependency_impact_summary,
        :timeline_publication_summary,
        :timeline_diff_summary,
        :timeline_activity_state,
        :timeline_activity_lifecycle_state,
        :timeline_lifecycle_state_summary,
        :timeline_activity_status_state,
        :timeline_activity_approval_state,
        :timeline_status_transition,
        :timeline_approval_transition,
        :timeline_transition_activity_status,
        :timeline_transition_activity_status!,
        :timeline_transition_activity_approval_status,
        :timeline_transition_activity_approval_status!,
        :timeline_apply_lifecycle_event,
        :timeline_apply_lifecycle_event!,
        :timeline_protection_decision,
        :timeline_integrity_report,
        :candidate_rejection_report,
        :timeline_transition_decision,
        :timeline_transition_application,
        :timeline_transition_application_summary,
        :timeline_transition_application_report,
        :timeline_replay_transition_application_report,
        :timeline_transition_selected_activities,
        :timeline_preservation_status
      ],
      cadence_import_statuses: @cadence_import_statuses,
      execution_boundaries: @execution_boundaries,
      timeline_integrity_issue_types: @timeline_integrity_issue_types,
      dependency_impact_summary_fields: @dependency_impact_summary_fields,
      dependency_impact_statuses: @dependency_impact_statuses,
      publication_summary_fields: @publication_summary_fields,
      publication_dependency_impact_statuses: @publication_dependency_impact_statuses,
      publication_downstream_invalidation_statuses: @publication_downstream_invalidation_statuses,
      publication_downstream_invalidation_reasons: @publication_downstream_invalidation_reasons,
      publication_statuses: @publication_statuses,
      candidate_rejection_reasons: @candidate_rejection_reasons,
      candidate_rejection_station_capacity_fraction_paths:
        @candidate_rejection_station_capacity_fraction_paths,
      candidate_rejection_station_capacity_value_paths:
        capacity_value_path_metadata(@candidate_rejection_station_capacity_value_paths),
      candidate_rejection_actions: @candidate_rejection_actions,
      command_contact_directions: @command_contact_directions,
      classification_counts: [:contact_count, :command_count],
      identity_fields: [
        :timeline_id,
        :activity_id,
        :activity_type,
        :scenario_id,
        :spacecraft_id,
        :subject_id
      ],
      activity_stable_identity_paths: field_path_metadata(@activity_stable_identity_paths),
      row_semantics: [
        :operational_kind,
        :operational_kind_counts,
        :command_contact_directions,
        :activity_status_aliases,
        :activity_status_counts,
        :approval_status_aliases,
        :approval_status_counts,
        :activity_lighting_field_aliases,
        :unit_interval_activity_field_aliases,
        :required_operator_action,
        :required_operator_action_counts,
        :operator_action_reason,
        :cadence_import_status,
        :cadence_import_status_counts,
        :cadence_import_identity,
        :execution_boundary,
        :timeline_diff_status,
        :timeline_diff_compare_fields,
        :timeline_diff_activity_context_compare_fields,
        :timeline_diff_changed_field_counts,
        :timeline_diff_summary,
        :timeline_diff_summary_status_id_sets,
        :normalized_activity,
        :normalized_activity_list,
        :activity_stable_identity_paths,
        :status_transition,
        :approval_transition,
        :activity_transition,
        :transition_decision,
        :transition_decision_counts,
        :transition_application,
        :transition_application_status,
        :transition_application_status_counts,
        :transition_application_summary,
        :transition_application_timeline_id_sets,
        :transition_application_summary_row_derived_counts,
        :transition_application_report,
        :timeline_revision_identity,
        :idempotent_transition_application_replay,
        :revision_conflict,
        :transition_batch_conflict,
        :status_transition_counts,
        :approval_transition_counts,
        :status_transition_category_counts,
        :approval_transition_category_counts,
        :activity_lifecycle_state,
        :activity_lifecycle_state_transition_decision,
        :activity_lifecycle_state_required_operator_actions,
        :lifecycle_state_summary,
        :lifecycle_state_summary_row_derived_counts,
        :lifecycle_state_summary_transition_decision_counts,
        :lifecycle_state_summary_required_operator_action_counts,
        :lifecycle_state_summary_import_action_counts,
        :lifecycle_state_summary_status_approval_category_counts,
        :lifecycle_state_summary_timeline_id_sets,
        :lifecycle_state_summary_review_routing,
        :lifecycle_state_summary_duplicate_timeline_identity,
        :lifecycle_state_summary_invalid_activity_input,
        :candidate_rejection_report,
        :candidate_rejection_status,
        :candidate_rejection_reason,
        :candidate_rejection_reason_counts,
        :candidate_rejection_routing_id_sets,
        :candidate_rejection_reason_id_sets,
        :candidate_rejection_action_id_sets,
        :candidate_rejection_station_capacity_value_paths,
        :timeline_integrity_report,
        :timeline_integrity_status,
        :timeline_integrity_review_count,
        :timeline_integrity_issue_count,
        :timeline_integrity_issue_type_counts,
        :timeline_integrity_routing_id_sets,
        :timeline_integrity_issue_id_sets,
        :timeline_integrity_issue_type_routing,
        :timeline_integrity_action_routing,
        :dependency_issue_count,
        :exclusivity_issue_count,
        :dependency_impact_summary,
        :dependency_impact_dependent_id_sets,
        :dependency_impact_impacted_source_id_sets,
        :dependency_impact_impacted_dependency_id_sets,
        :dependency_impact_impacted_exclusivity_id_sets,
        :publication_summary,
        :publication_summary_downstream_invalidation,
        :publication_summary_dependency_impact,
        :publication_summary_changed_field_audit,
        :single_activity_transition_integrity_gate,
        :lifecycle_preservation_report,
        :lifecycle_preservation_status,
        :preserve_activity_count,
        :review_change_activity_count,
        :mutable_activity_count,
        :preservation_sensitive_activity_count,
        :protection_decision_counts,
        :protection_category_counts,
        :lifecycle_preservation_routing_id_sets,
        :lifecycle_preservation_category_id_sets,
        :lifecycle_preservation_reason_id_sets,
        :lifecycle_preservation_timeline_id_sets,
        :transition_selected_activities,
        :activity_context,
        :activity_template_provenance,
        :activity_precondition_status,
        :activity_precondition_counts,
        :activity_precondition_types,
        :activity_precondition_rows,
        :product_identity,
        :pointing_context,
        :attitude_context,
        :link_context,
        :thermal_context,
        :data_volume_evidence,
        :downlink_completion_evidence,
        :execution_uncertainty,
        :unit_interval_activity_context_validation,
        :maneuver_success_factor,
        :provider_result_map_value_keys,
        :timeline_link,
        :protection_decision,
        :terminal_exception_review,
        :dependency_activity_ids,
        :exclusive_with_activity_ids,
        :timeline_integrity_review,
        :normalized_timeline_integrity_review,
        :invalid_activity_input_review,
        :duplicate_timeline_identity,
        :station_reservation_context,
        :station_calendar_trust_evidence
      ],
      known_limits: [
        :artifact_level_only,
        :no_schedule_mutation,
        :no_command_execution,
        :derived_identity_when_no_persistent_timeline_id
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  defp field_alias_metadata(fields) do
    Enum.map(fields, fn {field, aliases} -> %{field: field, aliases: aliases} end)
  end

  defp field_path_metadata(paths) do
    Enum.map(paths, fn {field, path} -> %{field: field, path: path} end)
  end

  @doc """
  Builds an `operational_timeline_report.v1` from planned activities.
  """
  def operational_report(activities, opts \\ [])

  def operational_report(%{"schema_contract" => @schema_contract} = report, _opts) do
    report
  end

  def operational_report(%{schema_contract: @schema_contract} = report, opts) do
    report
    |> stringify_keys()
    |> operational_report(opts)
  end

  def operational_report(activities, opts) when is_list(activities) do
    source = opts |> Keyword.get(:source, "activities") |> to_string()

    source_assumption = Keyword.get(opts, :source_assumption, source)
    validate_missing_dependencies? = Keyword.get(opts, :validate_missing_dependencies?, false)

    rows =
      activities
      |> Enum.with_index(1)
      |> Enum.map(&activity_input_to_timeline_row/1)

    rows = annotate_duplicate_timeline_identity_rows(rows)
    rows = annotate_timeline_integrity_rows(rows, validate_missing_dependencies?)
    rows_by_timeline = rows_by_timeline_id(rows)

    %{
      "schema_contract" => @schema_contract,
      "model" => "selected_activity_operational_context_summary",
      "source" => source,
      "activity_count" => length(rows),
      "valid_activity_count" => Enum.count(rows, &(&1["invalid_activity_input"] != true)),
      "invalid_activity_input_count" => Enum.count(rows, &(&1["invalid_activity_input"] == true)),
      "invalid_activity_input_ids" =>
        rows
        |> Enum.filter(& &1["invalid_activity_input"])
        |> Enum.map(& &1["activity_id"]),
      "row_count" => length(rows),
      "contact_count" => Enum.count(rows, &contact_timeline_row?/1),
      "command_count" => Enum.count(rows, &command_timeline_row?/1),
      "locked_count" => Enum.count(rows, & &1["locked"]),
      "approved_count" => Enum.count(rows, &approved_timeline_row?/1),
      "executed_count" => Enum.count(rows, &executed_timeline_row?/1),
      "terminal_exception_count" => Enum.count(rows, &terminal_exception_timeline_row?/1),
      "activity_status_counts" => count_by(rows, "status"),
      "approval_status_counts" => count_by(rows, "approval_status"),
      "required_operator_action_counts" => count_by(rows, "required_operator_action"),
      "cadence_import_status_counts" => count_by(rows, "cadence_import_status"),
      "operational_kind_counts" => count_by(rows, "operational_kind"),
      "execution_uncertainty_declared_count" =>
        Enum.count(rows, &(&1["execution_uncertainty_status"] == "declared")),
      "execution_uncertainty_missing_count" =>
        Enum.count(rows, &(&1["execution_uncertainty_status"] == "missing")),
      "dependency_count" => Enum.count(rows, &timeline_row_has_dependencies?/1),
      "exclusivity_count" => Enum.count(rows, &timeline_row_has_exclusivity?/1),
      "timeline_integrity_review_count" => Enum.count(rows, &timeline_integrity_review?/1),
      "timeline_integrity_issue_count" => timeline_integrity_issue_count(rows),
      "dependency_issue_count" => dependency_issue_count(rows),
      "exclusivity_issue_count" => exclusivity_issue_count(rows),
      "duplicate_dependency_activity_ids" =>
        timeline_integrity_row_list_ids(rows, "duplicate_dependency_activity_ids"),
      "duplicate_dependency_timeline_ids" =>
        timeline_integrity_row_list_ids(rows, "duplicate_dependency_timeline_ids"),
      "duplicate_exclusivity_activity_ids" =>
        timeline_integrity_row_list_ids(rows, "duplicate_exclusivity_activity_ids"),
      "duplicate_exclusivity_timeline_ids" =>
        timeline_integrity_row_list_ids(rows, "duplicate_exclusivity_timeline_ids"),
      "duplicate_timeline_identity_count" => duplicate_group_count(rows_by_timeline),
      "duplicate_timeline_identity_activity_count" => duplicate_activity_count(rows_by_timeline),
      "source_window_lineage_count" => Enum.count(rows, & &1["has_source_window"]),
      "model_limits" => model_limits(),
      "rows" => rows,
      "assumptions" => %{
        "execution_boundary" => "planned_not_commanded",
        "source" => source_assumption,
        "timeline_identity" => "derived_when_activity_has_no_persistent_timeline_id",
        "duplicate_timeline_identity" =>
          "duplicate timeline identities are preserved as operator-review collision rows",
        "dependency_model" =>
          "dependencies and exclusivity are checked inside the artifact when referenced rows are present; missing dependency checks are opt-in and schedules are not mutated",
        "missing_dependency_validation" =>
          if(validate_missing_dependencies?, do: "enabled", else: "disabled"),
        "invalid_activity_input" =>
          "activity inputs missing stable identity or activity type are preserved as operator-review rows and excluded from typed activity semantics"
      }
    }
  end

  def operational_report(_activities, _opts),
    do: raise(ArgumentError, "activities must be a list")

  @doc """
  Builds an artifact-only timeline integrity summary for planned activities.

  This helper exposes the same dependency and exclusivity validation evidence
  used by operational timeline reports, but returns only integrity-review rows
  and row-derived counts. It does not mutate schedules, approve work, or execute
  commands. Missing-dependency validation defaults on because callers are asking
  explicitly for integrity validation; pass `validate_missing_dependencies?: false`
  to mirror partial-list operational report behavior.
  """
  def integrity_report(activities, opts \\ [])

  def integrity_report(
        %{"schema_contract" => @integrity_report_schema_contract} = integrity_report,
        _opts
      ) do
    integrity_report
  end

  def integrity_report(
        %{schema_contract: @integrity_report_schema_contract} = integrity_report,
        opts
      ) do
    integrity_report
    |> stringify_keys()
    |> integrity_report(opts)
  end

  def integrity_report(activities, opts) when is_list(activities) do
    source = opts |> Keyword.get(:source, "timeline.activities") |> to_string()
    validate_missing_dependencies? = Keyword.get(opts, :validate_missing_dependencies?, true)

    rows =
      activities
      |> Enum.with_index(1)
      |> Enum.map(&activity_input_to_timeline_row/1)
      |> annotate_duplicate_timeline_identity_rows()
      |> annotate_timeline_integrity_rows(validate_missing_dependencies?)

    review_rows = Enum.filter(rows, &timeline_integrity_review?/1)

    %{
      "schema_contract" => @integrity_report_schema_contract,
      "model" => "artifact_only_timeline_integrity_summary",
      "validation_level" => "artifact_contract",
      "source" => source,
      "activity_count" => length(rows),
      "valid_activity_count" => Enum.count(rows, &(&1["invalid_activity_input"] != true)),
      "invalid_activity_input_count" => Enum.count(rows, &(&1["invalid_activity_input"] == true)),
      "timeline_integrity_status" => if(review_rows == [], do: "clear", else: "review_required"),
      "timeline_integrity_review_count" => length(review_rows),
      "timeline_integrity_issue_count" => timeline_integrity_issue_count(rows),
      "timeline_integrity_issue_types" => timeline_integrity_issue_types(rows),
      "timeline_integrity_issue_type_counts" => timeline_integrity_issue_type_counts(rows),
      "required_operator_action_counts" => count_by(review_rows, "required_operator_action"),
      "operator_action_reason_counts" => count_by(review_rows, "operator_action_reason"),
      "dependency_issue_count" => dependency_issue_count(rows),
      "exclusivity_issue_count" => exclusivity_issue_count(rows),
      "review_activity_ids" => timeline_row_ids(review_rows, "activity_id"),
      "review_timeline_ids" => timeline_row_ids(review_rows, "timeline_id"),
      "review_activity_ids_by_issue_type" =>
        timeline_integrity_ids_by_issue_type(review_rows, "activity_id"),
      "review_timeline_ids_by_issue_type" =>
        timeline_integrity_ids_by_issue_type(review_rows, "timeline_id"),
      "review_activity_ids_by_required_operator_action" =>
        timeline_integrity_ids_by_field(review_rows, "required_operator_action", "activity_id"),
      "review_timeline_ids_by_required_operator_action" =>
        timeline_integrity_ids_by_field(review_rows, "required_operator_action", "timeline_id"),
      "review_activity_ids_by_operator_action_reason" =>
        timeline_integrity_ids_by_field(review_rows, "operator_action_reason", "activity_id"),
      "review_timeline_ids_by_operator_action_reason" =>
        timeline_integrity_ids_by_field(review_rows, "operator_action_reason", "timeline_id"),
      "dependency_review_activity_ids" =>
        timeline_integrity_scope_ids(review_rows, "dependency", "activity_id"),
      "dependency_review_timeline_ids" =>
        timeline_integrity_scope_ids(review_rows, "dependency", "timeline_id"),
      "exclusivity_review_activity_ids" =>
        timeline_integrity_scope_ids(review_rows, "exclusivity", "activity_id"),
      "exclusivity_review_timeline_ids" =>
        timeline_integrity_scope_ids(review_rows, "exclusivity", "timeline_id"),
      "invalid_activity_input_ids" =>
        timeline_integrity_scope_ids(review_rows, "invalid_activity_input", "activity_id"),
      "missing_dependency_activity_ids" =>
        timeline_integrity_row_list_ids(review_rows, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" =>
        timeline_integrity_row_list_ids(review_rows, "missing_dependency_timeline_ids"),
      "self_dependency_activity_ids" =>
        timeline_integrity_row_list_ids(review_rows, "self_dependency_activity_ids"),
      "self_dependency_timeline_ids" =>
        timeline_integrity_row_list_ids(review_rows, "self_dependency_timeline_ids"),
      "duplicate_dependency_activity_ids" =>
        timeline_integrity_row_list_ids(review_rows, "duplicate_dependency_activity_ids"),
      "duplicate_dependency_timeline_ids" =>
        timeline_integrity_row_list_ids(review_rows, "duplicate_dependency_timeline_ids"),
      "duplicate_exclusivity_activity_ids" =>
        timeline_integrity_row_list_ids(review_rows, "duplicate_exclusivity_activity_ids"),
      "duplicate_exclusivity_timeline_ids" =>
        timeline_integrity_row_list_ids(review_rows, "duplicate_exclusivity_timeline_ids"),
      "dependency_cycle_activity_ids" =>
        timeline_integrity_row_list_ids(review_rows, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" =>
        timeline_integrity_row_list_ids(review_rows, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        timeline_integrity_row_list_ids(review_rows, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        timeline_integrity_row_list_ids(review_rows, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        timeline_integrity_row_list_ids(review_rows, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        timeline_integrity_row_list_ids(review_rows, "exclusivity_violation_timeline_ids"),
      "rows" => review_rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "dependency_and_exclusivity_integrity_validation",
        "missing_dependency_validation" =>
          if(validate_missing_dependencies?, do: "enabled", else: "disabled"),
        "source" => source
      },
      "model_limits" => model_limits()
    }
  end

  def integrity_report(_activities, _opts),
    do: raise(ArgumentError, "activities must be a list")

  @doc """
  Builds a `candidate_rejection_report.v1` from candidate activities.

  The report is an explanation artifact. It preserves declared and safely
  derived rejection reasons without selecting replacements, mutating schedules,
  or executing operational work.
  """
  def candidate_rejection_report(candidates, opts \\ [])

  def candidate_rejection_report(
        %{"schema_contract" => @candidate_rejection_schema_contract} = report,
        _opts
      ) do
    report
  end

  def candidate_rejection_report(
        %{schema_contract: @candidate_rejection_schema_contract} = report,
        opts
      ) do
    report
    |> stringify_keys()
    |> candidate_rejection_report(opts)
  end

  def candidate_rejection_report(candidates, opts) when is_list(candidates) do
    source = opts |> Keyword.get(:source, "candidate_activities") |> to_string()

    rows =
      candidates
      |> Enum.with_index(1)
      |> Enum.map(&candidate_rejection_row/1)

    %{
      "schema_contract" => @candidate_rejection_schema_contract,
      "model" => "artifact_only_candidate_rejection_explanation",
      "source" => source,
      "candidate_count" => length(rows),
      "row_count" => length(rows),
      "rejected_count" => Enum.count(rows, &(&1["rejection_status"] == "rejected")),
      "not_rejected_count" => Enum.count(rows, &(&1["rejection_status"] == "not_rejected")),
      "invalid_candidate_input_count" =>
        Enum.count(rows, &("invalid_candidate_input" in &1["rejection_reasons"])),
      "reviewable_count" => Enum.count(rows, & &1["reviewable"]),
      "rejection_reason_counts" => reason_counts(rows),
      "rejected_candidate_ids" =>
        candidate_rejection_row_ids(rows, &(&1["rejection_status"] == "rejected")),
      "not_rejected_candidate_ids" =>
        candidate_rejection_row_ids(rows, &(&1["rejection_status"] == "not_rejected")),
      "reviewable_candidate_ids" => candidate_rejection_row_ids(rows, & &1["reviewable"]),
      "invalid_candidate_input_ids" =>
        candidate_rejection_row_ids(
          rows,
          &("invalid_candidate_input" in &1["rejection_reasons"])
        ),
      "candidate_id_sets_by_rejection_reason" => candidate_id_sets_by_rejection_reason(rows),
      "candidate_ids_by_required_operator_action" =>
        candidate_ids_by_required_operator_action(rows),
      "required_operator_action_counts" => count_by(rows, "required_operator_action"),
      "model_limits" => [
        "artifact_only",
        "does_not_select_candidates",
        "does_not_mutate_schedules",
        "derived_reasons_use_declared_candidate_fields"
      ],
      "rows" => rows,
      "assumptions" => %{
        "scope" =>
          "candidate rejection explanations preserve declared and locally-derived evidence only",
        "reviewability" =>
          "rows with any rejection reason are reviewable unless the candidate explicitly sets reviewable false",
        "unknown_declared_reasons" =>
          "unrecognized declared reasons are preserved as declared_rejection with raw reason evidence"
      }
    }
  end

  def candidate_rejection_report(_candidates, _opts),
    do: raise(ArgumentError, "candidate activities must be a list")

  @doc """
  Builds a `timeline_diff_report.v1` from source and replacement activities.
  """
  def diff_report(timeline_diff_report)

  def diff_report(%{"schema_contract" => @diff_schema_contract} = timeline_diff_report) do
    timeline_diff_report
  end

  def diff_report(%{schema_contract: @diff_schema_contract} = timeline_diff_report) do
    stringify_keys(timeline_diff_report)
  end

  def diff_report(_timeline_diff_report) do
    raise ArgumentError, "timeline diff report must be a map"
  end

  def diff_report(source_activities, replacement_activities, opts \\ [])

  def diff_report(source_activities, replacement_activities, opts)
      when is_list(source_activities) and is_list(replacement_activities) do
    source = opts |> Keyword.get(:source, "timeline.activities") |> to_string()
    validate_missing_dependencies? = Keyword.get(opts, :validate_missing_dependencies?, false)

    source_rows =
      source_activities
      |> Enum.with_index(1)
      |> Enum.map(&activity_input_to_timeline_row/1)
      |> annotate_timeline_integrity_rows(validate_missing_dependencies?)

    replacement_rows =
      replacement_activities
      |> Enum.with_index(1)
      |> Enum.map(&activity_input_to_timeline_row/1)
      |> annotate_timeline_integrity_rows(validate_missing_dependencies?)

    invalid_source_rows = invalid_activity_input_rows(source_rows)
    invalid_replacement_rows = invalid_activity_input_rows(replacement_rows)

    source_by_timeline = rows_by_timeline_id(source_rows)
    replacement_by_timeline = rows_by_timeline_id(replacement_rows)

    rows =
      (Map.keys(source_by_timeline) ++ Map.keys(replacement_by_timeline))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.with_index(1)
      |> Enum.map(fn {timeline_id, rank} ->
        source_matches = Map.get(source_by_timeline, timeline_id, [])
        replacement_matches = Map.get(replacement_by_timeline, timeline_id, [])

        timeline_diff_row(
          timeline_id,
          rank,
          source_matches,
          replacement_matches
        )
      end)
      |> Enum.map(&put_transition_decision/1)

    %{
      "schema_contract" => @diff_schema_contract,
      "model" => "timeline_identity_activity_diff",
      "source" => source,
      "source_activity_count" => length(source_rows),
      "replacement_activity_count" => length(replacement_rows),
      "valid_source_activity_count" => length(source_rows) - length(invalid_source_rows),
      "valid_replacement_activity_count" =>
        length(replacement_rows) - length(invalid_replacement_rows),
      "invalid_source_activity_input_count" => length(invalid_source_rows),
      "invalid_replacement_activity_input_count" => length(invalid_replacement_rows),
      "invalid_source_activity_input_ids" => Enum.map(invalid_source_rows, & &1["activity_id"]),
      "invalid_replacement_activity_input_ids" =>
        Enum.map(invalid_replacement_rows, & &1["activity_id"]),
      "row_count" => length(rows),
      "added_count" => Enum.count(rows, &(&1["diff_status"] == "added")),
      "removed_count" => Enum.count(rows, &(&1["diff_status"] == "removed")),
      "changed_count" => Enum.count(rows, &(&1["diff_status"] == "changed")),
      "unchanged_count" => Enum.count(rows, &(&1["diff_status"] == "unchanged")),
      "diff_status_counts" => count_by(rows, "diff_status"),
      "required_operator_action_counts" => count_by(rows, "required_operator_action"),
      "transition_decision_counts" => count_by(rows, "transition_decision"),
      "changed_field_counts" => changed_field_counts(rows),
      "status_transition_counts" => transition_counts(rows, "status_transition"),
      "approval_transition_counts" => transition_counts(rows, "approval_transition"),
      "status_transition_category_counts" =>
        transition_category_counts(rows, "status_transition"),
      "approval_transition_category_counts" =>
        transition_category_counts(rows, "approval_transition"),
      "duplicate_timeline_identity_count" =>
        Enum.count(rows, & &1["timeline_identity_collision"]),
      "duplicate_source_timeline_identity_count" => duplicate_group_count(source_by_timeline),
      "duplicate_replacement_timeline_identity_count" =>
        duplicate_group_count(replacement_by_timeline),
      "review_required_count" => Enum.count(rows, & &1["requires_operator_review"]),
      "model_limits" => model_limits(),
      "rows" => rows,
      "assumptions" => %{
        "identity_match" => "timeline_id derived from persistent metadata or activity context",
        "comparison" =>
          "activity identity, timing, status, approval, lock, contact, execution uncertainty, lineage, and typed status transitions",
        "duplicate_timeline_identity" =>
          "duplicate timeline identities are preserved as operator-review collision rows",
        "invalid_activity_input" =>
          "source and replacement inputs missing stable identity or activity type are preserved as reviewable diff rows",
        "timeline_integrity" =>
          "source and replacement dependency/exclusivity integrity issues are preserved as reviewable diff rows",
        "missing_dependency_validation" =>
          if(validate_missing_dependencies?, do: "enabled", else: "disabled"),
        "execution_boundary" => "artifact_only_no_schedule_mutation"
      }
    }
  end

  def diff_report(_source_activities, _replacement_activities, _opts),
    do: raise(ArgumentError, "source and replacement activities must be lists")

  @doc """
  Builds a compact artifact-only summary of a timeline diff report.

  This helper accepts either an existing `timeline_diff_report.v1` artifact or
  source/replacement activity lists. It returns row-derived counters and
  review-required diff rows without mutating schedules, approving work, or
  executing commands.
  """
  def diff_summary(%{"schema_contract" => @diff_summary_schema_contract} = timeline_diff_summary) do
    timeline_diff_summary
  end

  def diff_summary(%{schema_contract: @diff_summary_schema_contract} = timeline_diff_summary) do
    timeline_diff_summary
    |> stringify_keys()
    |> diff_summary()
  end

  def diff_summary(%{} = timeline_diff_report) do
    report = stringify_keys(timeline_diff_report)
    rows = report |> Map.get("rows", []) |> Enum.filter(&is_map/1)
    review_rows = Enum.filter(rows, &(&1["requires_operator_review"] == true))

    %{
      "schema_contract" => @diff_summary_schema_contract,
      "model" => "artifact_only_timeline_diff_summary",
      "validation_level" => "artifact_contract",
      "source_artifact_type" => Map.get(report, "schema_contract", @diff_schema_contract),
      "source" => report["source"],
      "source_activity_count" => report["source_activity_count"],
      "replacement_activity_count" => report["replacement_activity_count"],
      "row_count" => report["row_count"] || length(rows),
      "added_count" => report["added_count"],
      "removed_count" => report["removed_count"],
      "changed_count" => report["changed_count"],
      "unchanged_count" => report["unchanged_count"],
      "review_required_count" => report["review_required_count"] || length(review_rows),
      "duplicate_timeline_identity_count" => report["duplicate_timeline_identity_count"],
      "invalid_source_activity_input_count" => report["invalid_source_activity_input_count"],
      "invalid_replacement_activity_input_count" =>
        report["invalid_replacement_activity_input_count"],
      "diff_status_counts" => report["diff_status_counts"] || %{},
      "transition_decision_counts" => report["transition_decision_counts"] || %{},
      "required_operator_action_counts" => report["required_operator_action_counts"] || %{},
      "changed_field_counts" => report["changed_field_counts"] || %{},
      "status_transition_category_counts" => report["status_transition_category_counts"] || %{},
      "approval_transition_category_counts" =>
        report["approval_transition_category_counts"] || %{},
      "added_timeline_ids" => timeline_diff_status_ids(rows, "added"),
      "removed_timeline_ids" => timeline_diff_status_ids(rows, "removed"),
      "changed_timeline_ids" => timeline_diff_status_ids(rows, "changed"),
      "unchanged_timeline_ids" => timeline_diff_status_ids(rows, "unchanged"),
      "duplicate_timeline_identity_ids" =>
        rows
        |> Enum.filter(&(&1["timeline_identity_collision"] == true))
        |> timeline_row_ids("timeline_id"),
      "invalid_source_activity_input_ids" => report["invalid_source_activity_input_ids"] || [],
      "invalid_replacement_activity_input_ids" =>
        report["invalid_replacement_activity_input_ids"] || [],
      "review_timeline_ids" => timeline_row_ids(review_rows, "timeline_id"),
      "review_timeline_ids_by_required_operator_action" =>
        timeline_ids_by(
          review_rows,
          & &1["required_operator_action"],
          &(&1["requires_operator_review"] == true)
        ),
      "review_timeline_ids_by_status_transition_category" =>
        timeline_ids_by(
          review_rows,
          &get_in(&1, ["status_transition", "transition_category"]),
          &(&1["requires_operator_review"] == true)
        ),
      "review_timeline_ids_by_approval_transition_category" =>
        timeline_ids_by(
          review_rows,
          &get_in(&1, ["approval_transition", "transition_category"]),
          &(&1["requires_operator_review"] == true)
        ),
      "timeline_ids_by_changed_field" =>
        timeline_ids_by_each(
          rows,
          &list_value(&1, "changed_fields"),
          &(list_value(&1, "changed_fields") != [])
        ),
      "review_rows" => review_rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "source" => "timeline_diff_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => model_limits()
    }
    |> compact_map()
  end

  def diff_summary(source_activities, replacement_activities, opts \\ [])

  def diff_summary(source_activities, replacement_activities, opts)
      when is_list(source_activities) and is_list(replacement_activities) do
    source_activities
    |> diff_report(replacement_activities, opts)
    |> diff_summary()
  end

  def diff_summary(_source_activities, _replacement_activities, _opts),
    do: raise(ArgumentError, "source and replacement activities must be lists")

  @doc """
  Summarizes downstream dependency impact from changed or removed source work.

  The helper derives its impacted source identities from `diff_report/3` and
  then identifies normalized source/replacement activities whose dependency or
  exclusivity lists still point at those changed or removed identities. It does
  not mutate schedules, approve work, or execute commands.
  """
  def dependency_impact_summary(source_activities, replacement_activities, opts \\ [])

  def dependency_impact_summary(source_activities, replacement_activities, opts)
      when is_list(source_activities) and is_list(replacement_activities) do
    diff_report = diff_report(source_activities, replacement_activities, opts)
    source_rows = normalize_activities(source_activities, opts)
    replacement_rows = normalize_activities(replacement_activities, opts)

    OrbitalDynamics.Timeline.DependencyImpactSummaryPolicy.build(
      diff_report,
      source_rows,
      replacement_rows,
      @dependency_impact_summary_schema_contract,
      model_limits(),
      &sorted_uniq/1
    )
  end

  def dependency_impact_summary(_source_activities, _replacement_activities, _opts),
    do: raise(ArgumentError, "source and replacement activities must be lists")

  @doc """
  Builds artifact-only plan publication metadata for downstream handoff.

  The summary records deterministic publication identity, sequence,
  supersession, downstream invalidation, and dependency-impact evidence without
  publishing notifications, granting authority, or mutating schedules.
  """
  def publication_summary(source_artifact, opts \\ [])

  def publication_summary(%{} = source_artifact, opts) when is_list(opts) do
    source_artifact = stringify_keys(source_artifact)
    source_artifact_id = publication_source_artifact_id(source_artifact, opts)
    source_artifact_type = publication_source_artifact_type(source_artifact)
    supersedes_artifact_ids = publication_stable_id_list(opts, :supersedes_artifact_ids)
    downstream_product_ids = publication_stable_id_list(opts, :downstream_product_ids)
    publication_sequence = publication_sequence!(opts)

    dependency_impact_summary =
      opts
      |> Keyword.get(:dependency_impact_summary)
      |> publication_dependency_impact_summary()

    timeline_diff_summary =
      opts
      |> Keyword.get(:timeline_diff_summary)
      |> publication_timeline_diff_summary()

    invalidated_downstream_product_ids =
      opts
      |> publication_stable_id_list(:invalidated_downstream_product_ids)
      |> publication_invalidation_ids(
        downstream_product_ids,
        dependency_impact_summary,
        supersedes_artifact_ids
      )

    invalidation_reason =
      publication_invalidation_reason(
        invalidated_downstream_product_ids,
        dependency_impact_summary,
        supersedes_artifact_ids
      )

    invalidated_downstream_product_ids_by_reason =
      publication_invalidation_ids_by_reason(
        invalidated_downstream_product_ids,
        invalidation_reason
      )

    publication_authority =
      opts
      |> Keyword.get(:publication_authority, "not_granted_by_summary")
      |> encode_value()

    %{
      "schema_contract" => @publication_summary_schema_contract,
      "model" => "artifact_only_timeline_publication_summary",
      "validation_level" => "artifact_contract",
      "source" => source_artifact_type,
      "publication_id" =>
        publication_summary_id(source_artifact_id, publication_sequence, supersedes_artifact_ids),
      "publication_sequence" => publication_sequence,
      "publication_status" =>
        publication_status(invalidated_downstream_product_ids, dependency_impact_summary),
      "downstream_invalidation_status" =>
        publication_downstream_invalidation_status(invalidated_downstream_product_ids),
      "publication_authority" => publication_authority,
      "source_artifact_id" => source_artifact_id,
      "source_artifact_type" => source_artifact_type,
      "supersedes_artifact_ids" => supersedes_artifact_ids,
      "downstream_product_ids" => downstream_product_ids,
      "invalidated_downstream_product_ids" => invalidated_downstream_product_ids,
      "downstream_invalidation_reason_counts" =>
        publication_invalidation_reason_counts(invalidated_downstream_product_ids_by_reason),
      "invalidated_downstream_product_ids_by_reason" =>
        invalidated_downstream_product_ids_by_reason,
      "dependency_impact_status" =>
        Map.get(dependency_impact_summary, "dependency_impact_status", "not_evaluated"),
      "dependency_impact_row_count" =>
        dependency_impact_summary |> Map.get("dependency_impact_rows", []) |> length(),
      "source_timeline_dependency_impact_summary" =>
        publication_optional_source_timeline_dependency_impact_summary(dependency_impact_summary),
      "impacted_source_activity_ids" =>
        Map.get(dependency_impact_summary, "impacted_source_activity_ids", []),
      "impacted_source_timeline_ids" =>
        Map.get(dependency_impact_summary, "impacted_source_timeline_ids", []),
      "dependent_activity_ids" =>
        Map.get(dependency_impact_summary, "dependent_activity_ids", []),
      "dependent_timeline_ids" =>
        Map.get(dependency_impact_summary, "dependent_timeline_ids", []),
      "source_dependent_activity_ids" =>
        Map.get(dependency_impact_summary, "source_dependent_activity_ids", []),
      "source_dependent_timeline_ids" =>
        Map.get(dependency_impact_summary, "source_dependent_timeline_ids", []),
      "replacement_dependent_activity_ids" =>
        Map.get(dependency_impact_summary, "replacement_dependent_activity_ids", []),
      "replacement_dependent_timeline_ids" =>
        Map.get(dependency_impact_summary, "replacement_dependent_timeline_ids", []),
      "impacted_dependency_activity_ids" =>
        Map.get(dependency_impact_summary, "impacted_dependency_activity_ids", []),
      "impacted_dependency_timeline_ids" =>
        Map.get(dependency_impact_summary, "impacted_dependency_timeline_ids", []),
      "impacted_exclusive_with_activity_ids" =>
        Map.get(dependency_impact_summary, "impacted_exclusive_with_activity_ids", []),
      "impacted_exclusive_with_timeline_ids" =>
        Map.get(dependency_impact_summary, "impacted_exclusive_with_timeline_ids", []),
      "source_timeline_diff_summary" =>
        publication_optional_source_timeline_diff_summary(timeline_diff_summary),
      "timeline_diff_row_count" => Map.get(timeline_diff_summary, "row_count"),
      "timeline_diff_changed_count" => Map.get(timeline_diff_summary, "changed_count"),
      "timeline_diff_review_required_count" =>
        Map.get(timeline_diff_summary, "review_required_count"),
      "changed_field_counts" => Map.get(timeline_diff_summary, "changed_field_counts"),
      "changed_timeline_ids" =>
        timeline_diff_summary |> Map.get("changed_timeline_ids") |> publication_id_list(),
      "review_timeline_ids" =>
        timeline_diff_summary |> Map.get("review_timeline_ids") |> publication_id_list(),
      "timeline_ids_by_changed_field" =>
        timeline_diff_summary
        |> Map.get("timeline_ids_by_changed_field")
        |> publication_id_array_map(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "notification_delivery" => "host_system_owned",
        "publication_authority" => publication_authority,
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => model_limits()
    }
    |> compact_map()
  end

  def publication_summary(_source_artifact, _opts),
    do: raise(ArgumentError, "source artifact must be a map")

  defp publication_source_artifact_id(source_artifact, opts) do
    OrbitalDynamics.Timeline.PublicationIdentifierPolicy.publication_source_artifact_id(
      source_artifact,
      opts,
      &stable_id_value/1
    )
  end

  defp publication_source_artifact_type(source_artifact) do
    OrbitalDynamics.Timeline.PublicationScalarInputPolicy.publication_source_artifact_type(
      source_artifact,
      &encode_value/1
    )
  end

  defp publication_sequence!(opts) do
    OrbitalDynamics.Timeline.PublicationScalarInputPolicy.publication_sequence!(opts)
  end

  defp publication_stable_id_list(opts, key) do
    OrbitalDynamics.Timeline.PublicationIdentifierPolicy.publication_stable_id_list(
      opts,
      key,
      &stable_id_value/1,
      &sorted_uniq/1
    )
  end

  defp publication_dependency_impact_summary(summary) do
    OrbitalDynamics.Timeline.PublicationSourceSummaryPolicy.publication_dependency_impact_summary(
      summary,
      &stringify_keys/1,
      @dependency_impact_summary_schema_contract
    )
  end

  defp publication_optional_source_timeline_dependency_impact_summary(summary) do
    OrbitalDynamics.Timeline.PublicationSourceSummaryPolicy.publication_optional_source_timeline_dependency_impact_summary(
      summary
    )
  end

  defp publication_timeline_diff_summary(summary) do
    OrbitalDynamics.Timeline.PublicationSourceSummaryPolicy.publication_timeline_diff_summary(
      summary,
      &stringify_keys/1,
      @diff_summary_schema_contract
    )
  end

  defp publication_optional_source_timeline_diff_summary(summary) do
    OrbitalDynamics.Timeline.PublicationSourceSummaryPolicy.publication_optional_source_timeline_diff_summary(
      summary
    )
  end

  defp publication_id_list(values) do
    OrbitalDynamics.Timeline.PublicationIdentifierPolicy.publication_id_list(
      values,
      &stable_id_value/1,
      &sorted_uniq/1
    )
  end

  defp publication_id_array_map(values) do
    OrbitalDynamics.Timeline.PublicationIdentifierPolicy.publication_id_array_map(
      values,
      &stable_id_value/1,
      &sorted_uniq/1
    )
  end

  defp publication_invalidation_ids(
         invalidated,
         downstream_product_ids,
         dependency_impact_summary,
         supersedes
       ) do
    OrbitalDynamics.Timeline.PublicationInvalidationPolicy.publication_invalidation_ids(
      invalidated,
      downstream_product_ids,
      dependency_impact_summary,
      supersedes
    )
  end

  defp publication_invalidation_reason(invalidated, dependency_impact_summary, supersedes) do
    OrbitalDynamics.Timeline.PublicationInvalidationPolicy.publication_invalidation_reason(
      invalidated,
      dependency_impact_summary,
      supersedes
    )
  end

  defp publication_invalidation_ids_by_reason(invalidated, reason) do
    OrbitalDynamics.Timeline.PublicationInvalidationPolicy.publication_invalidation_ids_by_reason(
      invalidated,
      reason
    )
  end

  defp publication_invalidation_reason_counts(ids_by_reason) do
    OrbitalDynamics.Timeline.PublicationInvalidationPolicy.publication_invalidation_reason_counts(
      ids_by_reason
    )
  end

  defp publication_status(invalidated_downstream_product_ids, dependency_impact_summary) do
    OrbitalDynamics.Timeline.PublicationInvalidationPolicy.publication_status(
      invalidated_downstream_product_ids,
      dependency_impact_summary
    )
  end

  defp publication_downstream_invalidation_status(invalidated_downstream_product_ids) do
    OrbitalDynamics.Timeline.PublicationInvalidationPolicy.publication_downstream_invalidation_status(
      invalidated_downstream_product_ids
    )
  end

  defp publication_summary_id(source_artifact_id, publication_sequence, supersedes_artifact_ids) do
    OrbitalDynamics.Timeline.PublicationInvalidationPolicy.publication_summary_id(
      source_artifact_id,
      publication_sequence,
      supersedes_artifact_ids
    )
  end

  defp application_timeline_ids(applications, predicate) when is_list(applications) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.application_timeline_ids(
      applications,
      predicate,
      &sorted_uniq/1
    )
  end

  defp application_activity_ids(applications, predicate) when is_list(applications) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.application_activity_ids(
      applications,
      predicate,
      &sorted_uniq/1
    )
  end

  defp timeline_ids_by(rows, key_fun, predicate) when is_list(rows) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.timeline_ids_by(
      rows,
      key_fun,
      predicate,
      &sorted_uniq/1
    )
  end

  defp timeline_ids_by_each(rows, values_fun, predicate) when is_list(rows) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.timeline_ids_by_each(
      rows,
      values_fun,
      predicate,
      &sorted_uniq/1
    )
  end

  defp sorted_uniq(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Returns the declared model limits for timeline reports.
  """
  def model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp activity_input_to_timeline_row({activity, sequence}) do
    case activity_input_to_map(activity, sequence) do
      {:ok, activity} -> operational_timeline_row(activity, sequence)
      {:error, row} -> row
    end
  end

  defp candidate_rejection_row({candidate, sequence}) do
    {activity, timeline_row} =
      case activity_input_to_map(candidate, sequence) do
        {:ok, activity} -> {activity, operational_timeline_row(activity, sequence)}
        {:error, row} -> {%{}, row}
      end

    candidate_id = candidate_id(activity, timeline_row, sequence)
    reasons = candidate_rejection_reasons(activity, timeline_row)
    reviewable = candidate_reviewable?(activity, reasons)
    rejection_status = if reasons == [], do: "not_rejected", else: "rejected"
    action = if reviewable, do: "review_candidate_rejection", else: "none"

    %{
      "id" => "candidate_rejection:#{sequence}:#{candidate_id}",
      "candidate_id" => candidate_id,
      "activity_id" => timeline_row["activity_id"],
      "timeline_id" => timeline_row["timeline_id"],
      "activity_type" => timeline_row["activity_type"],
      "operational_kind" => timeline_row["operational_kind"],
      "source_window_id" => timeline_row["source_window_id"],
      "source_window_type" => timeline_row["source_window_type"],
      "rejection_status" => rejection_status,
      "primary_rejection_reason" => List.first(reasons),
      "rejection_reasons" => reasons,
      "reason_count" => length(reasons),
      "reviewable" => reviewable,
      "required_operator_action" => action,
      "violated_constraint" =>
        first_scalar_string(activity, ["violated_constraint", "constraint"]),
      "required_margin" => first_number(activity, ["required_margin", "required_margin_value"]),
      "actual_margin" => first_number(activity, ["actual_margin", "observed_margin"]),
      "declared_rejection_reasons" => declared_rejection_reason_values(activity),
      "activity_context" => timeline_row["activity_context"]
    }
    |> compact_map()
  end

  defp candidate_id(activity, timeline_row, sequence) do
    [
      first_scalar_string(activity, ["candidate_id", "id", "activity_id"]),
      timeline_row["activity_id"],
      "candidate:#{sequence}"
    ]
    |> Enum.find(&(is_binary(&1) and stable_activity_id?(&1)))
  end

  defp candidate_rejection_reasons(activity, timeline_row) do
    (declared_candidate_rejection_reasons(activity) ++
       derived_candidate_rejection_reasons(activity, timeline_row))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp declared_candidate_rejection_reasons(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionReasonPolicy.declared(
      activity,
      @candidate_rejection_reasons
    )
  end

  defp declared_rejection_reason_values(activity) do
    OrbitalDynamics.Timeline.CandidateRejectionReasonPolicy.declared_values(activity)
  end

  defp derived_candidate_rejection_reasons(activity, timeline_row) do
    OrbitalDynamics.Timeline.CandidateRejectionDerivedReasonPolicy.derive(
      activity,
      timeline_row
    )
  end

  defp normalized_token(value) do
    OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy.normalized_token(value)
  end

  defp candidate_reviewable?(_activity, []), do: false

  defp candidate_reviewable?(activity, _reasons) do
    case first_boolean(activity, ["reviewable", "candidate_reviewable"]) do
      false -> false
      _value -> true
    end
  end

  defp reason_counts(rows) do
    OrbitalDynamics.Timeline.CandidateRejectionSummaryPolicy.reason_counts(rows)
  end

  defp candidate_rejection_row_ids(rows, predicate) do
    OrbitalDynamics.Timeline.CandidateRejectionSummaryPolicy.candidate_rejection_row_ids(
      rows,
      predicate
    )
  end

  defp candidate_id_sets_by_rejection_reason(rows) do
    OrbitalDynamics.Timeline.CandidateRejectionSummaryPolicy.candidate_id_sets_by_rejection_reason(
      rows
    )
  end

  defp candidate_ids_by_required_operator_action(rows) do
    OrbitalDynamics.Timeline.CandidateRejectionSummaryPolicy.candidate_ids_by_required_operator_action(
      rows
    )
  end

  defp normalize_activity_input({activity, sequence}, opts) do
    OrbitalDynamics.Timeline.ActivityInputNormalization.normalize(
      {activity, sequence},
      opts,
      &activity_to_map/1,
      &activity_input_issue/1,
      &invalid_activity_input_row/3,
      &normalize_valid_activity/2
    )
  end

  defp activity_input_to_map(activity, sequence) do
    OrbitalDynamics.Timeline.ActivityInputNormalization.to_map(
      activity,
      sequence,
      &activity_to_map/1,
      &activity_input_issue/1,
      &invalid_activity_input_row/3
    )
  end

  defp activity_input_issue(activity) do
    OrbitalDynamics.Timeline.ActivityInputPolicy.issue(
      activity,
      @activity_statuses,
      @approval_statuses,
      @unit_interval_activity_field_aliases,
      @activity_stable_identity_paths,
      &activity_status/1,
      &activity_approval_status/1,
      &numeric_value/1,
      &stable_activity_id?/1
    )
  end

  defp stable_activity_id?(id) do
    OrbitalDynamics.Timeline.StableIdentifierPolicy.valid?(id, @stable_id_pattern)
  end

  defp invalid_activity_input_rows(rows) do
    OrbitalDynamics.Timeline.ActivityInputPolicy.invalid_rows(rows)
  end

  defp invalid_activity_input_row(source_activity, sequence, reason) do
    OrbitalDynamics.Timeline.InvalidActivityRow.build(
      source_activity,
      sequence,
      reason,
      &stable_activity_id?/1,
      &issue/2,
      &compact_map/1
    )
  end

  @doc """
  Builds one deterministic timeline row.
  """
  def operational_timeline_row(activity, sequence) when is_integer(sequence) and sequence > 0 do
    activity = activity_to_map(activity)
    timeline_identity = timeline_identity(activity)
    source_window = Map.get(activity, "source_window", %{})
    operational_kind = operational_kind(activity)
    cadence_import = cadence_import(activity)
    cadence_import_status = cadence_import_status(activity, operational_kind)
    precondition_summary = activity_precondition_row_summary(activity)

    {required_operator_action, operator_action_reason} =
      required_operator_action(activity, operational_kind, cadence_import_status)

    %{
      "id" => "timeline_row:#{sequence}:#{activity_id(activity)}",
      "activity_id" => activity_id(activity),
      "timeline_id" => Map.get(timeline_identity, "timeline_id"),
      "scenario_id" => Map.get(activity, "scenario_id"),
      "activity_type" => Map.get(activity, "type"),
      "status" => activity_status(activity),
      "approval_status" => activity_approval_status(activity),
      "activity_template" => activity_template_provenance(activity),
      "locked" => activity_locked?(activity),
      "allow_overlap" => activity_allow_overlap(activity),
      "operational_kind" => operational_kind,
      "required_operator_action" => required_operator_action,
      "operator_action_reason" => operator_action_reason,
      "precondition_status" => precondition_summary["precondition_status"],
      "blocked_precondition_count" => precondition_summary["blocked_precondition_count"],
      "review_precondition_count" => precondition_summary["review_precondition_count"],
      "blocked_precondition_types" => precondition_summary["blocked_precondition_types"],
      "review_precondition_types" => precondition_summary["review_precondition_types"],
      "preconditions" => precondition_summary["preconditions"],
      "execution_boundary" => "planned_not_commanded",
      "cadence_import_status" => cadence_import_status,
      "starts_at_s" => activity_start(activity),
      "ends_at_s" => activity_end(activity),
      "setup_duration_s" => activity_operational_hint_number(activity, "setup_duration_s"),
      "cooldown_duration_s" => activity_operational_hint_number(activity, "cooldown_duration_s"),
      "telemetry_confirmation_required" =>
        activity_operational_hint_boolean(activity, [
          "telemetry_confirmation_required",
          "telemetry_confirmation_required?"
        ]),
      "telemetry_confirmation_status" =>
        activity_operational_hint_string(activity, "telemetry_confirmation_status"),
      "direction" => Map.get(activity, "direction"),
      "spacecraft_id" => Map.get(activity, "spacecraft_id"),
      "ground_station_id" => Map.get(activity, "ground_station_id"),
      "target_id" => Map.get(activity, "target_id"),
      "contact_result" => provider_result_artifact_value(Map.get(activity, "contact_result")),
      "command_result" => provider_result_artifact_value(Map.get(activity, "command_result")),
      "station_availability" => Map.get(activity, "station_availability"),
      "schedule_conflict_status" => activity_schedule_conflict_status(activity),
      "exclusivity_group" => Map.get(activity, "exclusivity_group"),
      "dependency_activity_ids" => dependency_activity_ids(activity),
      "dependency_timeline_ids" => dependency_timeline_ids(activity),
      "exclusive_with_activity_ids" => exclusive_with_activity_ids(activity),
      "exclusive_with_timeline_ids" => exclusive_with_timeline_ids(activity),
      "duplicate_dependency_activity_ids" => duplicate_dependency_activity_ids(activity),
      "duplicate_dependency_timeline_ids" => duplicate_dependency_timeline_ids(activity),
      "duplicate_exclusivity_activity_ids" => duplicate_exclusivity_activity_ids(activity),
      "duplicate_exclusivity_timeline_ids" => duplicate_exclusivity_timeline_ids(activity),
      "source_window_id" => activity_source_window_id(activity),
      "source_window_type" => activity_source_window_type(activity),
      "cadence_import_type" => Map.get(cadence_import, "activity_type"),
      "cadence_import_id" => Map.get(cadence_import, "external_id"),
      "cadence_import_contract" => Map.get(cadence_import, "schema_contract"),
      "cadence_import_provider" => Map.get(cadence_import, "provider"),
      "cadence_import_adapter" => Map.get(cadence_import, "adapter"),
      "cadence_import_adapter_version" => Map.get(cadence_import, "adapter_version"),
      "cadence_import_trust_boundary" =>
        Map.get(cadence_import, "trust_boundary") ||
          get_in(cadence_import, ["provenance", "trust_boundary"]),
      "cadence_import_provenance" => Map.get(cadence_import, "provenance"),
      "has_source_window" =>
        map_size(source_window) > 0 or not is_nil(activity_source_window_id(activity)),
      "has_cadence_import" =>
        is_map(Map.get(activity, "cadence_import")) and not invalid_cadence_import?(activity),
      "timeline_identity" => timeline_identity,
      "activity_context" => activity_context(activity)
    }
    |> Map.merge(invalid_cadence_import_context(activity))
    |> Map.merge(activity_product_context(activity))
    |> Map.merge(activity_pointing_context(activity))
    |> Map.merge(activity_attitude_context(activity))
    |> Map.merge(activity_link_context(activity))
    |> Map.merge(activity_command_authority_context(activity))
    |> Map.merge(activity_lighting_context(activity))
    |> Map.merge(activity_thermal_context(activity))
    |> Map.merge(activity_throughput_context(activity))
    |> Map.merge(activity_resource_context(activity))
    |> Map.merge(activity_execution_uncertainty_context(activity))
    |> Map.merge(activity_command_window_context(activity))
    |> Map.merge(station_calendar_context(activity))
    |> compact_map()
  end

  @doc """
  Normalizes one planned activity into the operational timeline activity shape.

  The result is report-row compatible but omits the report-row ID, making it a
  reusable typed activity payload for repair, approval, review, and import code.
  """
  def normalize_activity(activity, opts \\ [])

  def normalize_activity(activity, opts) when is_map(activity) do
    sequence = Keyword.get(opts, :sequence, 1)

    case activity_input_to_map(activity, sequence) do
      {:ok, activity} -> normalize_valid_activity(activity, opts)
      {:error, row} -> Map.drop(row, ["id"])
    end
  end

  def normalize_activity(_activity, _opts),
    do: raise(ArgumentError, "activity must be a map or MissionPlan.Activity")

  defp normalize_valid_activity(activity, opts) do
    sequence = Keyword.get(opts, :sequence, 1)
    activity = activity_to_map(activity)
    protection_decision = valid_protection_decision(activity, opts)

    activity
    |> operational_timeline_row(sequence)
    |> Map.drop(["id"])
    |> Map.merge(%{
      "approved" => activity_approved?(activity),
      "activity_context" => activity_context(activity),
      "protection_decision" => protection_decision["protection_decision"],
      "protection_category" => protection_decision["protection_category"],
      "protection_reason" => protection_decision["reason"]
    })
    |> compact_map()
    |> maybe_preserve_transition_application_provenance(activity)
  end

  @doc """
  Normalizes planned activities into reusable operational timeline activity rows.

  Unlike `operational_report/2`, this returns only the typed activity payloads.
  Duplicate timeline identities are still annotated so downstream repair,
  approval, review, and import code cannot accidentally treat a derived or
  provider-supplied timeline ID as unique. Timeline integrity checks are also
  applied to dependency ordering and exclusivity overlaps; missing dependency
  checks are opt-in through `validate_missing_dependencies?: true`.
  """
  def normalize_activities(activities, opts \\ [])

  def normalize_activities(activities, opts) when is_list(activities) do
    validate_missing_dependencies? = Keyword.get(opts, :validate_missing_dependencies?, false)

    activities
    |> Enum.with_index(1)
    |> Enum.map(&normalize_activity_input(&1, opts))
    |> annotate_duplicate_timeline_identity_rows()
    |> annotate_timeline_integrity_rows(validate_missing_dependencies?)
  end

  def normalize_activities(_activities, _opts),
    do: raise(ArgumentError, "activities must be a list")

  @doc """
  Returns persistent or derived timeline identity for an activity.
  """
  def timeline_identity(activity) do
    case activity_input_to_map(activity, 1) do
      {:ok, activity} ->
        valid_timeline_identity(activity)

      {:error, row} ->
        row["timeline_identity"]
    end
  end

  @doc """
  Returns the durable operational context that repair, approval, review, and
  import artifacts can carry without embedding an entire activity payload.
  """
  def activity_context(activity) do
    case activity_input_to_map(activity, 1) do
      {:ok, activity} ->
        valid_activity_context(activity)

      {:error, row} ->
        row
        |> Map.take([
          "timeline_identity",
          "invalid_activity_input",
          "invalid_activity_input_reason",
          "source_activity"
        ])
        |> compact_map()
    end
  end

  @doc """
  Summarizes state and resource preconditions carried by one timeline activity.

  The summary matches the precondition status/count fields emitted by
  `operational_timeline_row/2`. It is artifact-only: it does not mutate
  schedules, reserve resources, grant operator authority, or execute commands.
  """
  def activity_precondition_summary(activity) do
    case activity_input_to_map(activity, 1) do
      {:ok, activity} ->
        activity = activity_to_map(activity)
        timeline_identity = valid_timeline_identity(activity)

        activity
        |> activity_precondition_row_summary()
        |> Map.merge(%{
          "schema_contract" => @activity_precondition_summary_schema_contract,
          "model" => "artifact_only_timeline_activity_precondition_summary",
          "validation_level" => "artifact_contract",
          "model_limits" => model_limits(),
          "activity_id" => activity_id(activity),
          "timeline_id" => Map.get(timeline_identity, "timeline_id"),
          "activity_type" => Map.get(activity, "type"),
          "timeline_identity" => timeline_identity,
          "assumptions" => %{
            "execution_boundary" => "artifact_only_no_schedule_mutation",
            "operator_authority" => "not_granted_by_precondition_summary",
            "resource_authority" => "not_reserved_by_precondition_summary"
          }
        })
        |> Map.merge(activity_dependency_context(activity))
        |> compact_map()

      {:error, row} ->
        %{
          "schema_contract" => @activity_precondition_summary_schema_contract,
          "model" => "artifact_only_timeline_activity_precondition_summary",
          "validation_level" => "artifact_contract",
          "model_limits" => model_limits(),
          "activity_id" => row["activity_id"],
          "timeline_id" => row["timeline_id"],
          "activity_type" => row["activity_type"],
          "precondition_status" => "review_required",
          "blocked_precondition_count" => 0,
          "review_precondition_count" => 0,
          "blocked_precondition_types" => [],
          "review_precondition_types" => [],
          "preconditions" => [],
          "timeline_identity" => row["timeline_identity"],
          "invalid_activity_input" => true,
          "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
          "source_activity" => row["source_activity"],
          "assumptions" => %{
            "execution_boundary" => "artifact_only_no_schedule_mutation",
            "operator_authority" => "not_granted_by_precondition_summary",
            "resource_authority" => "not_reserved_by_precondition_summary",
            "input_review" => "invalid_activity_input_requires_timeline_integrity_review"
          }
        }
        |> compact_map()
    end
  end

  defp valid_timeline_identity(activity) do
    activity = activity_to_map(activity)

    %{
      "timeline_id" => activity_timeline_id(activity),
      "activity_id" => activity_id(activity),
      "activity_type" => activity["type"],
      "scenario_id" => activity["scenario_id"],
      "subject_id" => activity_subject_id(activity),
      "source_window_id" => activity_source_window_id(activity)
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
    |> Map.new()
  end

  defp valid_activity_context(activity) do
    activity = activity_to_map(activity)

    activity
    |> Map.take(@activity_context_keys)
    |> Map.drop([
      "setup_duration_s",
      "cooldown_duration_s",
      "telemetry_confirmation_required",
      "telemetry_confirmation_status"
    ])
    |> drop_invalid_activity_context_cadence_import(activity)
    |> Enum.reject(fn {_key, value} -> value in [nil, []] end)
    |> Map.new()
    |> Map.merge(activity_lifecycle_context(activity))
    |> Map.merge(invalid_cadence_import_context(activity))
    |> Map.merge(activity_timing_context(activity))
    |> Map.merge(activity_operational_hint_context(activity))
    |> Map.merge(activity_source_window_context(activity))
    |> Map.merge(activity_product_context(activity))
    |> Map.merge(activity_observation_quality_context(activity))
    |> Map.merge(activity_throughput_context(activity))
    |> Map.merge(activity_attitude_context(activity))
    |> Map.merge(activity_link_context(activity))
    |> Map.merge(activity_lighting_context(activity))
    |> Map.merge(activity_thermal_context(activity))
    |> Map.merge(activity_resource_context(activity))
    |> Map.merge(activity_command_authority_context(activity))
    |> Map.merge(activity_execution_uncertainty_context(activity))
    |> Map.merge(activity_feedback_context(activity))
    |> Map.merge(activity_command_window_context(activity))
    |> Map.merge(station_calendar_context(activity))
    |> Map.merge(activity_dependency_context(activity))
    |> Map.merge(activity_template_context(activity))
    |> Map.put("timeline_identity", valid_timeline_identity(activity))
  end

  defp activity_template_context(activity) do
    OrbitalDynamics.Timeline.ActivityTemplateProvenancePolicy.activity_template_context(activity)
  end

  defp activity_template_provenance(activity) do
    OrbitalDynamics.Timeline.ActivityTemplateProvenancePolicy.activity_template_provenance(
      activity
    )
  end

  defp activity_lifecycle_context(activity) do
    OrbitalDynamics.Timeline.ActivityLifecycleContext.build(activity)
  end

  defp activity_command_authority_context(activity) do
    OrbitalDynamics.Timeline.ActivityCommandAuthorityContext.build(activity)
  end

  defp activity_timing_context(activity) do
    OrbitalDynamics.Timeline.ActivitySchedulingCoordinateContext.timing(activity)
  end

  defp activity_operational_hint_context(activity) do
    OrbitalDynamics.Timeline.ActivityOperationalHintContext.build(activity)
  end

  defp activity_operational_hint_number(activity, key) do
    OrbitalDynamics.Timeline.ActivityOperationalHintContext.number(activity, key)
  end

  defp activity_operational_hint_boolean(activity, keys) do
    OrbitalDynamics.Timeline.ActivityOperationalHintContext.boolean(activity, keys)
  end

  defp activity_operational_hint_string(activity, key) do
    OrbitalDynamics.Timeline.ActivityOperationalHintContext.string(activity, key)
  end

  defp activity_source_window_context(activity) do
    OrbitalDynamics.Timeline.ActivitySchedulingCoordinateContext.source_window(activity)
  end

  defp activity_dependency_context(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.build(activity, @stable_id_pattern)
  end

  defp activity_feedback_context(activity) do
    OrbitalDynamics.Timeline.ActivityFeedbackContext.build(
      activity,
      @provider_result_map_value_keys
    )
  end

  defp activity_product_context(activity) do
    OrbitalDynamics.Timeline.ActivityProductDeliveryContext.build(activity, @stable_id_pattern)
  end

  defp activity_observation_quality_context(activity) do
    OrbitalDynamics.Timeline.ActivityObservationEvidenceContext.quality(activity)
  end

  defp activity_pointing_context(activity) do
    OrbitalDynamics.Timeline.ActivityOrientationContext.pointing(activity, @stable_id_pattern)
  end

  defp activity_attitude_context(activity) do
    OrbitalDynamics.Timeline.ActivityOrientationContext.attitude(activity, @stable_id_pattern)
  end

  defp activity_thermal_context(activity) do
    OrbitalDynamics.Timeline.ActivityThermalContext.build(activity, @stable_id_pattern)
  end

  defp activity_lighting_context(activity) do
    OrbitalDynamics.Timeline.ActivityObservationEvidenceContext.lighting(activity)
  end

  defp activity_resource_context(activity) do
    OrbitalDynamics.Timeline.ActivityResourceContext.build(activity)
  end

  defp activity_precondition_row_summary(activity) do
    OrbitalDynamics.Timeline.ActivityPreconditionContext.build(
      activity,
      first_boolean: &first_boolean/2,
      first_value: &first_value/2,
      encode_value: &encode_value/1,
      first_number: &first_number/2,
      first_scalar_string: &first_scalar_string/2,
      normalized_token: &normalized_token/1,
      activity_template_provenance: &activity_template_provenance/1,
      stringify_keys: &stringify_keys/1,
      normalize_id_list: &normalize_id_list/2,
      compact_map: &compact_map/1,
      unit_interval_activity_field_aliases: @unit_interval_activity_field_aliases
    )
  end

  defp activity_throughput_context(activity) do
    OrbitalDynamics.Timeline.ThroughputContext.build(
      activity,
      first_number: &first_number/2,
      first_value: &first_value/2,
      stringify_keys: &stringify_keys/1,
      delta: &delta/2,
      completion_fraction: &completion_fraction/2,
      compact_map: &compact_map/1
    )
  end

  defp activity_link_context(activity) do
    OrbitalDynamics.Timeline.ActivityLinkContext.build(activity)
  end

  defp activity_execution_uncertainty_context(activity) do
    OrbitalDynamics.Timeline.ExecutionUncertaintyContext.build(
      activity,
      stringify_keys: &stringify_keys/1,
      numeric_value: &numeric_value/1,
      numeric_triplet: &numeric_triplet/1,
      vector_norm: &vector_norm/1,
      compact_map: &compact_map/1
    )
  end

  defp activity_command_window_context(activity) do
    OrbitalDynamics.Timeline.CommandWindowContext.build(
      activity,
      activity_id: &activity_id/1,
      compact_map: &compact_map/1
    )
  end

  defp numeric_triplet(value) do
    OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_triplet(value)
  end

  defp numeric_value(value) do
    OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value(value)
  end

  defp vector_norm(value) do
    OrbitalDynamics.Timeline.ActivityNumericValuePolicy.vector_norm(value)
  end

  defp station_calendar_context(activity) do
    OrbitalDynamics.Timeline.StationCalendarContext.build(
      activity,
      numeric_value: &numeric_value/1,
      encode_value: &encode_value/1,
      stable_id_value: &stable_id_value/1,
      normalize_id_list: &normalize_id_list/2,
      compact_map: &compact_map/1
    )
  end

  @doc """
  Builds a stable source-to-replacement timeline link for repair and diff rows.
  """
  def timeline_link(source_activity, replacement_activity) do
    source_link = timeline_link_side("source", source_activity)
    replacement_link = timeline_link_side("replacement", replacement_activity)

    Map.merge(source_link, replacement_link)
  end

  defp timeline_link_side(prefix, activity) do
    case activity_input_to_map(activity, 1) do
      {:ok, activity} ->
        activity = activity_to_map(activity)

        %{
          "#{prefix}_timeline_id" => activity_timeline_id(activity),
          "#{prefix}_activity_id" => activity_id(activity)
        }

      {:error, row} ->
        %{
          "#{prefix}_timeline_id" => row["timeline_id"],
          "#{prefix}_activity_id" => row["activity_id"],
          "#{prefix}_invalid_activity_input" => true,
          "#{prefix}_invalid_activity_input_reason" => row["invalid_activity_input_reason"],
          "#{prefix}_activity" => row["source_activity"],
          "#{prefix}_timeline_identity" => row["timeline_identity"]
        }
        |> compact_map()
    end
  end

  @doc """
  Builds the status and approval transition objects for a source/replacement pair.
  """
  def activity_transition(source_activity, replacement_activity) do
    source_activity = optional_activity_to_map(source_activity)
    replacement_activity = optional_activity_to_map(replacement_activity)

    %{
      "status_transition" => status_transition(source_activity, replacement_activity),
      "approval_transition" => approval_transition(source_activity, replacement_activity)
    }
    |> compact_map()
  end

  @doc """
  Builds the typed activity-status transition object for a source/replacement pair.
  """
  def status_transition(source_activity, replacement_activity) do
    source_activity = optional_activity_to_map(source_activity)
    replacement_activity = optional_activity_to_map(replacement_activity)

    lifecycle_transition(
      "status",
      source_activity && activity_status(source_activity),
      replacement_activity && activity_status(replacement_activity)
    )
  end

  @doc """
  Returns a normalized timeline activity row with a safe lifecycle status transition.

  The helper is artifact state only: it reuses `status_transition/2` semantics,
  blocks transitions that require operator review, and does not mutate schedules,
  grant operator authority, or execute commands.
  """
  def transition_activity_status(activity, status, opts \\ [])

  def transition_activity_status(activity, status, opts)
      when is_map(activity) and is_list(opts) do
    source_activity = activity_to_map(activity)
    replacement_activity = Map.put(source_activity, "status", status)

    transition =
      source_activity
      |> optional_activity_state_input(1)
      |> activity_state_status_transition(optional_activity_state_input(replacement_activity, 2))

    if transition_requires_operator_review?(transition) do
      {:error, transition}
    else
      replacement_activity
      |> put_transition_application_provenance(
        "transition_activity_status",
        "status",
        transition
      )
      |> normalize_activity()
      |> maybe_validate_transition_helper_selected_integrity(opts)
    end
  end

  def transition_activity_status(_activity, _status, _opts),
    do: raise(ArgumentError, "activity must be a map or MissionPlan.Activity")

  @doc """
  Returns a normalized timeline activity row with a safe lifecycle status transition.

  Raises when the transition would require operator review.
  """
  def transition_activity_status!(activity, status, opts \\ []) do
    case transition_activity_status(activity, status, opts) do
      {:ok, activity} ->
        activity

      {:error, transition} ->
        raise_transition_activity_status_error(transition)
    end
  end

  @doc """
  Normalizes planned and realized activity status into a compact state surface.

  The helper reuses the same status aliases and transition semantics as
  `status_transition/2`, then exposes the review and import decision fields
  adapters need without mutating schedules, approving work, or executing
  commands.
  """
  def activity_status_state(planned_activity, realized_activity) do
    planned_activity = optional_activity_state_input(planned_activity, 1)
    realized_activity = optional_activity_state_input(realized_activity, 2)

    if is_nil(planned_activity) and is_nil(realized_activity) do
      raise ArgumentError, "planned or realized activity is required"
    end

    planned_status = planned_activity && activity_status(planned_activity)
    realized_status = realized_activity && activity_status(realized_activity)
    status_transition = activity_state_status_transition(planned_activity, realized_activity)
    transition_decision = status_state_transition_decision(status_transition)

    %{
      "schema_contract" => @activity_status_state_schema_contract,
      "model" => "artifact_only_timeline_activity_status_state",
      "model_limits" => model_limits(),
      "validation_level" => "artifact_contract",
      "activity_id" => status_state_activity_id(planned_activity, realized_activity),
      "planned_activity_id" => planned_activity && state_activity_id(planned_activity),
      "realized_activity_id" => realized_activity && state_activity_id(realized_activity),
      "timeline_id" => status_state_timeline_id(planned_activity, realized_activity),
      "planned_timeline_id" => planned_activity && state_timeline_id(planned_activity),
      "realized_timeline_id" => realized_activity && state_timeline_id(realized_activity),
      "planned_status" => planned_status,
      "realized_status" => realized_status,
      "planned_status_category" => status_lifecycle_category(planned_status),
      "realized_status_category" => status_lifecycle_category(realized_status),
      "status_transition" => status_transition,
      "transition_decision" => transition_decision,
      "review_required" => status_state_review_required?(status_transition),
      "required_operator_action" => status_state_required_operator_action(transition_decision),
      "operator_action_reason" => status_state_operator_action_reason(status_transition),
      "import_action" => status_state_import_action(transition_decision),
      "invalid_activity_input" => invalid_activity_state?(planned_activity, realized_activity),
      "invalid_activity_input_count" =>
        invalid_activity_state_count(planned_activity, realized_activity),
      "invalid_activity_input_reasons" =>
        invalid_activity_state_reasons(planned_activity, realized_activity),
      "planned_activity_context" => planned_activity && activity_context(planned_activity),
      "realized_activity_context" => realized_activity && activity_context(realized_activity),
      "assumptions" => %{
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_command_execution" => true
      }
    }
    |> compact_map()
  end

  @doc """
  Normalizes planned and realized activity approval status into a compact state surface.

  The helper reuses the same approval aliases and transition semantics as
  `approval_transition/2`, then exposes the review and import decision fields
  adapters need without mutating schedules, granting operator authority, or
  executing commands.
  """
  def activity_approval_state(planned_activity, realized_activity) do
    planned_activity = optional_activity_state_input(planned_activity, 1)
    realized_activity = optional_activity_state_input(realized_activity, 2)

    if is_nil(planned_activity) and is_nil(realized_activity) do
      raise ArgumentError, "planned or realized activity is required"
    end

    planned_approval_status = planned_activity && activity_approval_status(planned_activity)
    realized_approval_status = realized_activity && activity_approval_status(realized_activity)

    approval_transition = activity_state_approval_transition(planned_activity, realized_activity)

    transition_decision = status_state_transition_decision(approval_transition)

    %{
      "schema_contract" => @activity_approval_state_schema_contract,
      "model" => "artifact_only_timeline_activity_approval_state",
      "model_limits" => model_limits(),
      "validation_level" => "artifact_contract",
      "activity_id" => status_state_activity_id(planned_activity, realized_activity),
      "planned_activity_id" => planned_activity && state_activity_id(planned_activity),
      "realized_activity_id" => realized_activity && state_activity_id(realized_activity),
      "timeline_id" => status_state_timeline_id(planned_activity, realized_activity),
      "planned_timeline_id" => planned_activity && state_timeline_id(planned_activity),
      "realized_timeline_id" => realized_activity && state_timeline_id(realized_activity),
      "planned_approval_status" => planned_approval_status,
      "realized_approval_status" => realized_approval_status,
      "planned_approval_category" => approval_lifecycle_category(planned_approval_status),
      "realized_approval_category" => approval_lifecycle_category(realized_approval_status),
      "approval_transition" => approval_transition,
      "transition_decision" => transition_decision,
      "review_required" => status_state_review_required?(approval_transition),
      "required_operator_action" => approval_state_required_operator_action(transition_decision),
      "operator_action_reason" => approval_state_operator_action_reason(approval_transition),
      "import_action" => status_state_import_action(transition_decision),
      "invalid_activity_input" => invalid_activity_state?(planned_activity, realized_activity),
      "invalid_activity_input_count" =>
        invalid_activity_state_count(planned_activity, realized_activity),
      "invalid_activity_input_reasons" =>
        invalid_activity_state_reasons(planned_activity, realized_activity),
      "planned_activity_context" => planned_activity && activity_context(planned_activity),
      "realized_activity_context" => realized_activity && activity_context(realized_activity),
      "assumptions" => %{
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_command_execution" => true
      }
    }
    |> compact_map()
  end

  @doc """
  Normalizes planned and realized lifecycle state into one compact handoff.

  This combines the status-state, approval-state, lock/protection, and executed
  classifications used by the timeline helpers. It remains artifact-only: it
  does not mutate schedules, grant operator authority, import to Cadence, or
  execute commands.
  """
  def activity_lifecycle_state(planned_activity, realized_activity) do
    planned_activity = optional_activity_state_input(planned_activity, 1)
    realized_activity = optional_activity_state_input(realized_activity, 2)

    if is_nil(planned_activity) and is_nil(realized_activity) do
      raise ArgumentError, "planned or realized activity is required"
    end

    status_state = activity_status_state(planned_activity, realized_activity)
    approval_state = activity_approval_state(planned_activity, realized_activity)
    planned_status = planned_activity && activity_status(planned_activity)
    realized_status = realized_activity && activity_status(realized_activity)
    planned_approval_status = planned_activity && activity_approval_status(planned_activity)
    realized_approval_status = realized_activity && activity_approval_status(realized_activity)
    planned_protection = planned_activity && protection_decision(planned_activity)
    realized_protection = realized_activity && protection_decision(realized_activity)

    transition_decision =
      lifecycle_state_transition_decision(status_state, approval_state, [
        planned_protection,
        realized_protection
      ])

    required_operator_actions =
      lifecycle_state_required_operator_actions(
        status_state,
        approval_state,
        [planned_protection, realized_protection],
        transition_decision
      )

    %{
      "schema_contract" => @activity_lifecycle_state_schema_contract,
      "model" => "artifact_only_timeline_activity_lifecycle_state",
      "model_limits" => model_limits(),
      "validation_level" => "artifact_contract",
      "activity_id" => status_state_activity_id(planned_activity, realized_activity),
      "planned_activity_id" => planned_activity && state_activity_id(planned_activity),
      "realized_activity_id" => realized_activity && state_activity_id(realized_activity),
      "timeline_id" => status_state_timeline_id(planned_activity, realized_activity),
      "planned_timeline_id" => planned_activity && state_timeline_id(planned_activity),
      "realized_timeline_id" => realized_activity && state_timeline_id(realized_activity),
      "planned_status" => planned_status,
      "realized_status" => realized_status,
      "planned_status_category" => status_lifecycle_category(planned_status),
      "realized_status_category" => status_lifecycle_category(realized_status),
      "planned_approval_status" => planned_approval_status,
      "realized_approval_status" => realized_approval_status,
      "planned_approval_category" => approval_lifecycle_category(planned_approval_status),
      "realized_approval_category" => approval_lifecycle_category(realized_approval_status),
      "planned_locked" => planned_activity && activity_locked?(planned_activity),
      "realized_locked" => realized_activity && activity_locked?(realized_activity),
      "planned_executed" => planned_status && executed_status?(planned_status),
      "realized_executed" => realized_status && executed_status?(realized_status),
      "status_transition" => Map.get(status_state, "status_transition"),
      "approval_transition" => Map.get(approval_state, "approval_transition"),
      "status_transition_decision" => Map.get(status_state, "transition_decision"),
      "approval_transition_decision" => Map.get(approval_state, "transition_decision"),
      "transition_decision" => transition_decision,
      "review_required" => transition_decision == "review",
      "required_operator_action" =>
        lifecycle_state_required_operator_action(required_operator_actions, transition_decision),
      "required_operator_actions" => required_operator_actions,
      "operator_action_reasons" =>
        lifecycle_state_operator_action_reasons(
          status_state,
          approval_state,
          [planned_protection, realized_protection]
        ),
      "import_action" => status_state_import_action(transition_decision),
      "invalid_activity_input" => invalid_activity_state?(planned_activity, realized_activity),
      "invalid_activity_input_count" =>
        invalid_activity_state_count(planned_activity, realized_activity),
      "invalid_activity_input_reasons" =>
        invalid_activity_state_reasons(planned_activity, realized_activity),
      "planned_protection_decision" => planned_protection,
      "realized_protection_decision" => realized_protection,
      "planned_activity_context" => planned_activity && activity_context(planned_activity),
      "realized_activity_context" => realized_activity && activity_context(realized_activity),
      "assumptions" => %{
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_cadence_import" => true,
        "no_command_execution" => true
      }
    }
    |> compact_map()
  end

  @doc """
  Builds a compact artifact-only lifecycle-state summary for planned and realized activities.

  The helper pairs activities by durable timeline identity, reuses
  `activity_lifecycle_state/2` for unique pairs, and routes duplicate or invalid
  activity inputs as review rows. It does not mutate schedules, grant operator
  authority, import to Cadence, or execute commands.
  """
  def lifecycle_state_summary(planned_activities, realized_activities, opts \\ [])

  def lifecycle_state_summary(planned_activities, realized_activities, opts)
      when is_list(planned_activities) and is_list(realized_activities) do
    source = opts |> Keyword.get(:source, "timeline.lifecycle_state") |> to_string()
    {planned_rows, planned_by_timeline} = lifecycle_state_input_groups(planned_activities)
    {realized_rows, realized_by_timeline} = lifecycle_state_input_groups(realized_activities)

    rows =
      (Map.keys(planned_by_timeline) ++ Map.keys(realized_by_timeline))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.with_index(1)
      |> Enum.map(fn {timeline_id, rank} ->
        OrbitalDynamics.Timeline.LifecycleStateSummaryRowPolicy.build(
          timeline_id,
          rank,
          Map.get(planned_by_timeline, timeline_id, []),
          Map.get(realized_by_timeline, timeline_id, []),
          &activity_lifecycle_state/2,
          &sorted_uniq/1
        )
      end)

    OrbitalDynamics.Timeline.LifecycleStateSummaryPolicy.build(
      rows,
      planned_rows,
      realized_rows,
      source,
      @lifecycle_state_summary_schema_contract,
      model_limits(),
      &sorted_uniq/1
    )
  end

  def lifecycle_state_summary(_planned_activities, _realized_activities, _opts),
    do: raise(ArgumentError, "planned and realized activities must be lists")

  defp lifecycle_state_input_groups(activities) do
    OrbitalDynamics.Timeline.LifecycleStateInputPolicy.groups(
      activities,
      &activity_input_to_map/2,
      &activity_to_map/1,
      &activity_timeline_id/1
    )
  end

  @doc """
  Builds the typed approval-status transition object for a source/replacement pair.
  """
  def approval_transition(source_activity, replacement_activity) do
    source_activity = optional_activity_to_map(source_activity)
    replacement_activity = optional_activity_to_map(replacement_activity)

    lifecycle_transition(
      "approval_status",
      source_activity && activity_approval_status(source_activity),
      replacement_activity && activity_approval_status(replacement_activity)
    )
  end

  @doc """
  Returns a normalized timeline activity row with a safe approval-status transition.

  The helper is artifact state only: it reuses `approval_transition/2` semantics,
  blocks transitions that require operator review, and does not grant operator
  authority, mutate schedules, or execute commands.
  """
  def transition_activity_approval_status(activity, approval_status, opts \\ [])

  def transition_activity_approval_status(activity, approval_status, opts)
      when is_map(activity) and is_list(opts) do
    source_activity = activity_to_map(activity)
    replacement_activity = Map.put(source_activity, "approval_status", approval_status)

    transition =
      source_activity
      |> optional_activity_state_input(1)
      |> activity_state_approval_transition(
        optional_activity_state_input(replacement_activity, 2)
      )

    if transition_requires_operator_review?(transition) do
      {:error, transition}
    else
      replacement_activity
      |> put_transition_application_provenance(
        "transition_activity_approval_status",
        "approval_status",
        transition
      )
      |> normalize_activity()
      |> maybe_validate_transition_helper_selected_integrity(opts)
    end
  end

  def transition_activity_approval_status(_activity, _approval_status, _opts),
    do: raise(ArgumentError, "activity must be a map or MissionPlan.Activity")

  @doc """
  Returns a normalized timeline activity row with a safe approval-status transition.

  Raises when the transition would require operator review.
  """
  def transition_activity_approval_status!(activity, approval_status, opts \\ []) do
    case transition_activity_approval_status(activity, approval_status, opts) do
      {:ok, activity} ->
        activity

      {:error, transition} ->
        raise_transition_activity_approval_status_error(transition)
    end
  end

  @doc """
  Applies a normalized lifecycle event to one timeline activity row.

  The helper is artifact state only: it uses `MissionPlan.Activity` lifecycle
  event aliases to derive the replacement state, validates the resulting status
  and approval transitions with timeline review semantics, and does not mutate
  schedules, grant operator authority, or execute commands.
  """
  def apply_lifecycle_event(activity, event, opts \\ [])

  def apply_lifecycle_event(activity, event, opts) when is_map(activity) and is_list(opts) do
    source_activity = activity_to_map(activity)
    replacement_activity = lifecycle_event_replacement_activity!(source_activity, event)
    source_state = optional_activity_state_input(source_activity, 1)
    replacement_state = optional_activity_state_input(replacement_activity, 2)
    status_transition = activity_state_status_transition(source_state, replacement_state)
    approval_transition = activity_state_approval_transition(source_state, replacement_state)

    case lifecycle_event_review_transition(status_transition, approval_transition) do
      nil ->
        replacement_activity
        |> put_transition_application_provenance(
          "apply_lifecycle_event",
          lifecycle_event_provenance_field(status_transition, approval_transition),
          lifecycle_event_provenance_transition(status_transition, approval_transition)
        )
        |> normalize_activity()
        |> maybe_validate_transition_helper_selected_integrity(opts)

      transition ->
        {:error, transition}
    end
  end

  def apply_lifecycle_event(_activity, _event, _opts),
    do: raise(ArgumentError, "activity must be a map or MissionPlan.Activity")

  @doc """
  Applies a normalized lifecycle event to one timeline activity row.

  Raises when the resulting status or approval transition would require
  operator review.
  """
  def apply_lifecycle_event!(activity, event, opts \\ []) do
    case apply_lifecycle_event(activity, event, opts) do
      {:ok, activity} ->
        activity

      {:error, transition} ->
        raise_apply_lifecycle_event_error(transition)
    end
  end

  @doc """
  Classifies the artifact-only transition decision for one proposed activity change.

  The helper reuses the same timeline-diff semantics as `diff_report/3` while
  returning only the decision surface that repair, review, and import adapters
  need for a single source/replacement pair. It does not mutate schedules,
  approve work, or execute commands.
  """
  def transition_decision(source_activity, replacement_activity, opts \\ []) do
    source_activity
    |> base_transition_decision(replacement_activity, opts)
    |> maybe_gate_single_transition_decision_integrity(
      source_activity,
      replacement_activity,
      opts
    )
  end

  defp base_transition_decision(source_activity, replacement_activity, opts) do
    OrbitalDynamics.Timeline.TransitionDecisionPolicy.build(
      source_activity,
      replacement_activity,
      opts,
      &diff_report/3,
      &compact_map/1
    )
  end

  @doc """
  Resolves one source/replacement activity pair into a safe artifact-only application plan.

  The result carries the transition decision plus the normalized activity that
  downstream repair/import code may keep or record without mutating schedules.
  Review-required transitions deliberately omit `selected_activity` unless the
  safe action is preserving an existing protected source activity.
  """
  def transition_application(source_activity, replacement_activity, opts \\ []) do
    decision = base_transition_decision(source_activity, replacement_activity, opts)
    source = transition_application_activity(source_activity, opts)
    replacement = transition_application_activity(replacement_activity, opts)

    decision
    |> Map.merge(
      transition_application_selection(
        Map.get(decision, "transition_decision"),
        source,
        replacement
      )
    )
    |> maybe_gate_single_transition_selected_activity(opts)
    |> compact_map()
  end

  @doc """
  Builds a batch artifact-only application plan for a source and replacement timeline.

  The plan uses the same `diff_report/3` transition decisions, then selects only
  activities that are safe to carry forward without mutating an external
  schedule: unchanged source rows, recordable replacement rows, and protected
  source rows that must be preserved while a replacement waits for review.
  Review-only changes deliberately omit a selected activity.
  """
  def transition_application_report(transition_application_report)

  def transition_application_report(
        %{"schema_contract" => @transition_application_schema_contract} =
          transition_application_report
      ) do
    transition_application_report
  end

  def transition_application_report(
        %{schema_contract: @transition_application_schema_contract} =
          transition_application_report
      ) do
    stringify_keys(transition_application_report)
  end

  def transition_application_report(_transition_application_report) do
    raise ArgumentError, "transition application report must be a map"
  end

  def transition_application_report(source_activities, replacement_activities, opts \\ [])

  def transition_application_report(source_activities, replacement_activities, opts)
      when is_list(source_activities) and is_list(replacement_activities) do
    diff_report = diff_report(source_activities, replacement_activities, opts)
    source_by_timeline = normalized_activity_groups(source_activities, opts)
    replacement_by_timeline = normalized_activity_groups(replacement_activities, opts)

    applications =
      diff_report
      |> Map.get("rows", [])
      |> Enum.map(
        &transition_application_from_diff_row(&1, source_by_timeline, replacement_by_timeline)
      )

    selected_activities =
      applications
      |> Enum.map(&Map.get(&1, "selected_activity"))
      |> Enum.reject(&is_nil/1)
      |> annotate_transition_selected_activities(opts)

    applications =
      put_transition_selected_activity_integrity(applications, selected_activities)

    selected_integrity_issue_types = timeline_integrity_issue_types(selected_activities)

    %{
      "schema_contract" => @transition_application_schema_contract,
      "model" => "artifact_only_timeline_transition_application",
      "source" => diff_report["source"],
      "source_activity_count" => diff_report["source_activity_count"],
      "replacement_activity_count" => diff_report["replacement_activity_count"],
      "application_count" => length(applications),
      "selected_activity_count" => length(selected_activities),
      "review_required_count" =>
        Enum.count(applications, &(&1["requires_operator_review"] == true)),
      "preserved_source_count" =>
        Enum.count(
          applications,
          &(&1["application_status"] == "source_preserved_pending_review")
        ),
      "recorded_replacement_count" =>
        Enum.count(applications, &(&1["application_status"] == "replacement_recorded")),
      "withheld_review_count" =>
        Enum.count(applications, &(&1["application_status"] == "operator_review_required")),
      "application_status_counts" => count_by(applications, "application_status"),
      "transition_decision_counts" => count_by(applications, "transition_decision"),
      "required_operator_action_counts" => count_by(applications, "required_operator_action"),
      "status_transition_counts" => transition_counts(applications, "status_transition"),
      "approval_transition_counts" => transition_counts(applications, "approval_transition"),
      "status_transition_category_counts" =>
        transition_category_counts(applications, "status_transition"),
      "approval_transition_category_counts" =>
        transition_category_counts(applications, "approval_transition"),
      "selected_timeline_integrity_review_count" =>
        Enum.count(selected_activities, &timeline_integrity_review?/1),
      "selected_timeline_integrity_issue_count" =>
        timeline_integrity_issue_count(selected_activities),
      "selected_timeline_integrity_issue_types" => selected_integrity_issue_types,
      "selected_activities" => selected_activities,
      "applications" => applications,
      "model_limits" => model_limits(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "selection" =>
          "only unchanged, recordable, or preserved protected activities are selected automatically",
        "review_gate" =>
          "review-required transitions withhold replacement selection until an operator decision",
        "selected_timeline_integrity" =>
          "selected activities are rechecked as their own artifact-only timeline subset because withheld review rows can remove dependencies",
        "selected_missing_dependency_validation" =>
          if(Keyword.get(opts, :validate_selected_dependencies?, true),
            do: "enabled",
            else: "disabled"
          )
      }
    }
    |> compact_map()
    |> RevisionReplay.put_revision_evidence(
      source_activities,
      opts,
      &normalize_activities/2
    )
  end

  def transition_application_report(_source_activities, _replacement_activities, _opts),
    do: raise(ArgumentError, "source and replacement activities must be lists")

  @doc """
  Purely reapplies a named transition batch to its named prior timeline revision.

  The replay report must contain the opt-in `timeline_revision.v1` evidence
  emitted by `transition_application_report/3` with `timeline_revision?: true`.
  A matching replay returns the deterministically rebuilt report. A different
  prior timeline returns inspectable `revision_conflict` evidence, while a
  changed transition batch returns `batch_conflict` evidence. This helper owns
  no store, lock, workflow, schedule mutation, or distributed concurrency
  guarantee.
  """
  def replay_transition_application_report(
        source_activities,
        replacement_activities,
        replay_report,
        opts \\ []
      ) do
    RevisionReplay.replay(
      source_activities,
      replacement_activities,
      replay_report,
      opts,
      &transition_application_report/3,
      &normalize_activities/2
    )
  end

  @doc """
  Builds a compact artifact-only summary of a transition application report.

  This helper accepts either an existing
  `timeline_transition_application_report.v1` artifact or source/replacement
  activity lists. It returns the selected activity IDs, review-gated
  application rows, and row-derived counters without mutating schedules,
  approving work, or executing commands.
  """
  def transition_application_summary(
        %{"schema_contract" => @transition_application_summary_schema_contract} =
          transition_application_summary
      ) do
    transition_application_summary
  end

  def transition_application_summary(
        %{schema_contract: @transition_application_summary_schema_contract} =
          transition_application_summary
      ) do
    transition_application_summary
    |> stringify_keys()
    |> transition_application_summary()
  end

  def transition_application_summary(%{} = transition_application_report) do
    report = stringify_keys(transition_application_report)
    applications = report |> Map.get("applications", []) |> Enum.filter(&is_map/1)
    review_applications = Enum.filter(applications, &(&1["requires_operator_review"] == true))
    selected_activities = report |> Map.get("selected_activities", []) |> Enum.filter(&is_map/1)

    %{
      "schema_contract" => @transition_application_summary_schema_contract,
      "model" => "artifact_only_timeline_transition_application_summary",
      "validation_level" => "artifact_contract",
      "source_artifact_type" =>
        Map.get(report, "schema_contract", @transition_application_schema_contract),
      "source" => report["source"],
      "timeline_revision" => report["timeline_revision"],
      "source_activity_count" => report["source_activity_count"],
      "replacement_activity_count" => report["replacement_activity_count"],
      "application_count" => length(applications),
      "selected_activity_count" => length(selected_activities),
      "review_required_count" => length(review_applications),
      "preserved_source_count" =>
        Enum.count(applications, &(&1["application_status"] == "source_preserved_pending_review")),
      "recorded_replacement_count" =>
        Enum.count(applications, &(&1["application_status"] == "replacement_recorded")),
      "withheld_review_count" =>
        Enum.count(applications, &(&1["application_status"] == "operator_review_required")),
      "selected_timeline_integrity_review_count" =>
        Enum.count(selected_activities, &timeline_integrity_review?/1),
      "selected_timeline_integrity_issue_count" =>
        timeline_integrity_issue_count(selected_activities),
      "selected_timeline_integrity_issue_types" =>
        timeline_integrity_issue_types(selected_activities),
      "application_status_counts" => count_by(applications, "application_status"),
      "transition_decision_counts" => count_by(applications, "transition_decision"),
      "required_operator_action_counts" => count_by(applications, "required_operator_action"),
      "status_transition_category_counts" =>
        transition_category_counts(applications, "status_transition"),
      "approval_transition_category_counts" =>
        transition_category_counts(applications, "approval_transition"),
      "selected_activity_ids" => Enum.map(selected_activities, & &1["activity_id"]),
      "selected_timeline_ids" =>
        selected_activities |> Enum.map(& &1["timeline_id"]) |> sorted_uniq(),
      "review_timeline_ids" =>
        application_timeline_ids(applications, &(&1["requires_operator_review"] == true)),
      "review_activity_ids" =>
        application_activity_ids(applications, &(&1["requires_operator_review"] == true)),
      "review_timeline_ids_by_required_operator_action" =>
        timeline_ids_by(
          applications,
          & &1["required_operator_action"],
          &(&1["requires_operator_review"] == true)
        ),
      "review_timeline_ids_by_status_transition_category" =>
        timeline_ids_by(
          applications,
          &get_in(&1, ["status_transition", "transition_category"]),
          &(&1["requires_operator_review"] == true)
        ),
      "review_timeline_ids_by_approval_transition_category" =>
        timeline_ids_by(
          applications,
          &get_in(&1, ["approval_transition", "transition_category"]),
          &(&1["requires_operator_review"] == true)
        ),
      "preserved_source_timeline_ids" =>
        application_timeline_ids(
          applications,
          &(&1["transition_decision"] == "preserve_source" and
              &1["selected_activity_source"] == "source")
        ),
      "recorded_replacement_timeline_ids" =>
        application_timeline_ids(
          applications,
          &(&1["transition_decision"] == "record" and
              &1["selected_activity_source"] == "replacement")
        ),
      "withheld_review_timeline_ids" =>
        application_timeline_ids(
          applications,
          &(&1["application_status"] == "operator_review_required")
        ),
      "review_applications" => review_applications,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "selection" => "summary_reuses_timeline_transition_application_report",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => model_limits()
    }
    |> compact_map()
  end

  def transition_application_summary(source_activities, replacement_activities, opts \\ [])

  def transition_application_summary(source_activities, replacement_activities, opts)
      when is_list(source_activities) and is_list(replacement_activities) do
    source_activities
    |> transition_application_report(replacement_activities, opts)
    |> transition_application_summary()
  end

  def transition_application_summary(_source_activities, _replacement_activities, _opts),
    do: raise(ArgumentError, "source and replacement activities must be lists")

  @doc """
  Returns the normalized activities that a transition-application report selected as safe.

  This helper accepts either an existing `timeline_transition_application_report.v1`
  artifact or source/replacement activity lists. It exposes the artifact-only
  safe subset without selecting review-gated replacement rows.
  """
  def transition_selected_activities(%{} = transition_application_report) do
    transition_application_report
    |> stringify_keys()
    |> Map.get("selected_activities", [])
    |> case do
      activities when is_list(activities) -> activities
      _other -> []
    end
    |> Enum.filter(&is_map/1)
  end

  def transition_selected_activities(source_activities, replacement_activities, opts \\ [])

  def transition_selected_activities(source_activities, replacement_activities, opts)
      when is_list(source_activities) and is_list(replacement_activities) do
    source_activities
    |> transition_application_report(replacement_activities, opts)
    |> transition_selected_activities()
  end

  def transition_selected_activities(_source_activities, _replacement_activities, _opts),
    do: raise(ArgumentError, "source and replacement activities must be lists")

  @doc """
  Builds an artifact-only lifecycle preservation summary for timeline activities.

  The report reuses `protection_decision/2` for each activity and returns only
  rows that are preservation-sensitive or require review. It does not mutate
  schedules, approve work, or execute commands.
  """
  def preservation_report(activities, opts \\ [])

  def preservation_report(
        %{"schema_contract" => @preservation_report_schema_contract} = preservation_report,
        _opts
      ) do
    preservation_report
  end

  def preservation_report(
        %{schema_contract: @preservation_report_schema_contract} = preservation_report,
        opts
      ) do
    preservation_report
    |> stringify_keys()
    |> preservation_report(opts)
  end

  def preservation_report(activities, opts) when is_list(activities) do
    source = opts |> Keyword.get(:source, "timeline.activities") |> to_string()

    rows =
      activities
      |> Enum.with_index(1)
      |> Enum.map(fn {activity, sequence} ->
        protection_decision(activity, Keyword.put(opts, :sequence, sequence))
      end)

    preservation_rows =
      Enum.reject(rows, &(&1["protection_decision"] == "mutable"))

    review_count = Enum.count(rows, &(&1["protection_decision"] == "review_change"))
    preserve_count = Enum.count(rows, &(&1["protection_decision"] == "preserve"))

    %{
      "schema_contract" => @preservation_report_schema_contract,
      "model" => "artifact_only_lifecycle_preservation_summary",
      "source" => source,
      "activity_count" => length(rows),
      "mutable_activity_count" => Enum.count(rows, &(&1["protection_decision"] == "mutable")),
      "preserve_activity_count" => preserve_count,
      "review_change_activity_count" => review_count,
      "preservation_sensitive_activity_count" => preserve_count + review_count,
      "timeline_preservation_status" =>
        preservation_status_from_counts(preserve_count, review_count),
      "protection_decision_counts" => count_by(rows, "protection_decision"),
      "protection_category_counts" => count_by(rows, "protection_category"),
      "protection_reason_counts" => count_by(rows, "reason"),
      "preserve_activity_ids" => protection_decision_ids(rows, "preserve", "activity_id"),
      "preserve_timeline_ids" => protection_decision_ids(rows, "preserve", "timeline_id"),
      "review_change_activity_ids" =>
        protection_decision_ids(rows, "review_change", "activity_id"),
      "review_change_timeline_ids" =>
        protection_decision_ids(rows, "review_change", "timeline_id"),
      "mutable_activity_ids" => protection_decision_ids(rows, "mutable", "activity_id"),
      "preservation_sensitive_activity_ids" =>
        preservation_rows |> Enum.map(& &1["activity_id"]) |> sorted_uniq(),
      "preservation_sensitive_timeline_ids" =>
        preservation_rows |> Enum.map(& &1["timeline_id"]) |> sorted_uniq(),
      "activity_id_sets_by_protection_decision" =>
        protection_id_sets_by_field(rows, "protection_decision", "activity_id"),
      "timeline_id_sets_by_protection_decision" =>
        protection_id_sets_by_field(rows, "protection_decision", "timeline_id"),
      "activity_id_sets_by_protection_category" => protection_category_activity_ids(rows),
      "timeline_id_sets_by_protection_category" =>
        protection_id_sets_by_field(rows, "protection_category", "timeline_id"),
      "activity_id_sets_by_protection_reason" =>
        protection_id_sets_by_field(rows, "reason", "activity_id"),
      "timeline_id_sets_by_protection_reason" =>
        protection_id_sets_by_field(rows, "reason", "timeline_id"),
      "model_limits" => model_limits(),
      "rows" => preservation_rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "lifecycle_lock_approval_and_executed_preservation_review",
        "source" => source
      }
    }
  end

  def preservation_report(_activities, _opts),
    do: raise(ArgumentError, "activities must be a list")

  @doc """
  Builds an artifact-only preservation status preflight for one activity.

  The helper reuses `protection_decision/2`, so invalid activity inputs, locked
  or approved activities, and executed statuses are classified consistently with
  `preservation_report/2`. It does not mutate schedules, approve work, or
  execute commands.
  """
  def preservation_status(activity, opts \\ [])

  def preservation_status(
        %{"schema_contract" => @preservation_status_schema_contract} = preservation_status,
        _opts
      ) do
    preservation_status
  end

  def preservation_status(
        %{schema_contract: @preservation_status_schema_contract} = preservation_status,
        opts
      ) do
    preservation_status
    |> stringify_keys()
    |> preservation_status(opts)
  end

  def preservation_status(activity, opts) do
    decision = protection_decision(activity, opts)

    status =
      case Map.get(decision, "protection_decision") do
        "review_change" -> "review_required"
        "preserve" -> "preservation_required"
        _decision -> "clear"
      end

    %{
      "schema_contract" => @preservation_status_schema_contract,
      "model" => "artifact_only_lifecycle_preservation_status",
      "timeline_preservation_status" => status,
      "requires_preservation" => status == "preservation_required",
      "requires_operator_review" => status == "review_required",
      "activity_id" => decision["activity_id"],
      "timeline_id" => decision["timeline_id"],
      "status" => decision["status"],
      "approval_status" => decision["approval_status"],
      "locked" => decision["locked"],
      "approved" => decision["approved"],
      "protection_decision" => decision["protection_decision"],
      "protection_category" => decision["protection_category"],
      "protection_reason" => decision["reason"],
      "timeline_identity" => decision["timeline_identity"],
      "invalid_activity_input" => decision["invalid_activity_input"],
      "invalid_activity_input_reason" => decision["invalid_activity_input_reason"],
      "model_limits" => model_limits(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "single_activity_lifecycle_preservation_preflight"
      }
    }
    |> compact_map()
  end

  defp protection_decision_ids(rows, decision, field) do
    OrbitalDynamics.Timeline.ProtectionSummaryPolicy.protection_decision_ids(
      rows,
      decision,
      field,
      &sorted_uniq/1
    )
  end

  defp protection_category_activity_ids(rows) do
    OrbitalDynamics.Timeline.ProtectionSummaryPolicy.protection_category_activity_ids(
      rows,
      &sorted_uniq/1
    )
  end

  defp protection_id_sets_by_field(rows, group_field, id_field) do
    OrbitalDynamics.Timeline.ProtectionSummaryPolicy.protection_id_sets_by_field(
      rows,
      group_field,
      id_field,
      &sorted_uniq/1
    )
  end

  @doc """
  Classifies whether an activity should be preserved, reviewed, or left mutable.

  This is a deterministic policy-shape helper only. It does not mutate a
  schedule, approve work, or execute commands.
  """
  def protection_decision(activity, opts \\ []) do
    sequence = Keyword.get(opts, :sequence, 1)

    cond do
      invalid_activity_state_row?(activity) ->
        activity
        |> activity_to_map()
        |> invalid_activity_protection_decision()

      true ->
        case activity_input_to_map(activity, sequence) do
          {:ok, activity} -> valid_protection_decision(activity, opts)
          {:error, row} -> invalid_activity_protection_decision(row)
        end
    end
  end

  defp valid_protection_decision(activity, opts) do
    activity = activity_to_map(activity)

    status =
      opts
      |> Keyword.get(:realized_status, activity_status(activity))
      |> normalize_lifecycle_value()

    preserve_approved? = Keyword.get(opts, :preserve_approved?, true)
    preserve_executed? = Keyword.get(opts, :preserve_executed?, true)
    allow_locked_changes? = Keyword.get(opts, :allow_locked_changes?, false)

    base =
      %{
        "activity_id" => activity_id(activity),
        "timeline_id" => activity_timeline_id(activity),
        "status" => status,
        "approval_status" => activity_approval_status(activity),
        "locked" => activity_locked?(activity),
        "approved" => activity_approved?(activity),
        "timeline_identity" => timeline_identity(activity)
      }
      |> compact_map()

    decision =
      cond do
        activity["invalid_activity_input"] == true ->
          %{
            "protection_decision" => "review_change",
            "protection_category" => "invalid_activity_input",
            "reason" => activity["invalid_activity_input_reason"] || "invalid_activity_input"
          }

        unsupported_activity_status?(status) ->
          %{
            "protection_decision" => "review_change",
            "protection_category" => "unsupported_status",
            "reason" => "unsupported_realized_status"
          }

        preserve_executed? and executed_status?(status) ->
          %{
            "protection_decision" => "preserve",
            "protection_category" => "executed",
            "reason" => "activity_already_#{status}"
          }

        protected_by_lock_or_approval?(activity) and preserve_approved? and
          not allow_locked_changes? and
            repairable_status?(status) ->
          %{
            "protection_decision" => "review_change",
            "protection_category" => "locked_or_approved",
            "reason" => "realized_status_#{status}_requires_repair_review"
          }

        protected_by_lock_or_approval?(activity) and preserve_approved? and
            not allow_locked_changes? ->
          %{
            "protection_decision" => "preserve",
            "protection_category" => "locked_or_approved",
            "reason" => "activity_locked_or_approved"
          }

        protected_by_lock_or_approval?(activity) and allow_locked_changes? ->
          %{
            "protection_decision" => "review_change",
            "protection_category" => "locked_or_approved",
            "reason" => "locked_or_approved_changes_allowed_with_review"
          }

        true ->
          %{
            "protection_decision" => "mutable",
            "protection_category" => "none",
            "reason" => "no_timeline_protection"
          }
      end

    Map.merge(base, decision)
  end

  defp invalid_activity_protection_decision(row) do
    %{
      "activity_id" => row["activity_id"],
      "timeline_id" => row["timeline_id"],
      "status" => row["status"],
      "approval_status" => row["approval_status"],
      "locked" => row["locked"],
      "approved" => false,
      "timeline_identity" => row["timeline_identity"],
      "invalid_activity_input" => true,
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "protection_decision" => "review_change",
      "protection_category" => "invalid_activity_input",
      "reason" => row["invalid_activity_input_reason"]
    }
    |> compact_map()
  end

  defp preservation_status_from_counts(preserve_count, review_count) do
    OrbitalDynamics.Timeline.ProtectionSummaryPolicy.preservation_status_from_counts(
      preserve_count,
      review_count
    )
  end

  defp transition_application_activity(activity, opts) do
    OrbitalDynamics.Timeline.TransitionApplicationActivityPolicy.transition_application_activity(
      activity,
      opts,
      &normalize_activity/2
    )
  end

  defp maybe_gate_single_transition_selected_activity(
         application,
         opts
       ) do
    OrbitalDynamics.Timeline.TransitionApplicationIntegrityPolicy.gate_single(
      application,
      opts,
      &annotate_transition_selected_activities/2,
      &maybe_gate_selected_activity_integrity/2
    )
  end

  defp maybe_validate_transition_helper_selected_integrity(activity, opts) do
    OrbitalDynamics.Timeline.TransitionHelperIntegrityPolicy.validate(
      activity,
      opts,
      &annotate_transition_selected_activities/2,
      &timeline_integrity_review?/1,
      &selected_integrity_reason/1,
      &list_value/2,
      &selected_integrity_context/1,
      &compact_map/1
    )
  end

  defp raise_transition_activity_status_error(transition) do
    OrbitalDynamics.Timeline.TransitionHelperIntegrityPolicy.raise_status_error!(transition)
  end

  defp raise_transition_activity_approval_status_error(transition) do
    OrbitalDynamics.Timeline.TransitionHelperIntegrityPolicy.raise_approval_status_error!(
      transition
    )
  end

  defp raise_apply_lifecycle_event_error(transition) do
    OrbitalDynamics.Timeline.TransitionHelperIntegrityPolicy.raise_lifecycle_event_error!(
      transition
    )
  end

  defp maybe_gate_single_transition_decision_integrity(
         transition_decision,
         source_activity,
         replacement_activity,
         opts
       ) do
    OrbitalDynamics.Timeline.TransitionDecisionIntegrityPolicy.gate(
      transition_decision,
      source_activity,
      replacement_activity,
      opts,
      &transition_application_activity/2,
      &transition_application_selection/3,
      &annotate_transition_selected_activities/2,
      &timeline_integrity_review?/1,
      &list_value/2,
      &selected_integrity_reason/1,
      &selected_integrity_context/1,
      &compact_map/1
    )
  end

  defp annotate_transition_selected_activities(selected_activities, opts) do
    validate_selected_dependencies? = Keyword.get(opts, :validate_selected_dependencies?, true)

    annotate_timeline_integrity_rows(selected_activities, validate_selected_dependencies?)
  end

  defp put_transition_selected_activity_integrity(applications, selected_activities) do
    OrbitalDynamics.Timeline.TransitionApplicationIntegrityPolicy.put_batch(
      applications,
      selected_activities,
      &maybe_gate_selected_activity_integrity/2
    )
  end

  defp maybe_gate_selected_activity_integrity(application, selected_activity) do
    OrbitalDynamics.Timeline.SelectedIntegrityPolicy.gate_application(
      application,
      selected_activity,
      &timeline_integrity_review?/1,
      &list_value/2,
      &compact_map/1
    )
  end

  defp selected_integrity_context(selected_activity) do
    OrbitalDynamics.Timeline.SelectedIntegrityPolicy.context(selected_activity, &list_value/2)
  end

  defp selected_integrity_reason(issue_types) do
    OrbitalDynamics.Timeline.SelectedIntegrityPolicy.reason(issue_types)
  end

  defp transition_application_selection(decision, source, replacement) do
    OrbitalDynamics.Timeline.TransitionApplicationPolicy.selection(
      decision,
      source,
      replacement
    )
  end

  defp put_transition_application_provenance(activity, helper, field, transition) do
    OrbitalDynamics.Timeline.TransitionApplicationPolicy.put_provenance(
      activity,
      helper,
      field,
      transition,
      &compact_map/1
    )
  end

  defp lifecycle_event_replacement_activity!(source_activity, event) do
    OrbitalDynamics.Timeline.LifecycleEventPolicy.replacement_activity!(
      source_activity,
      event,
      &timeline_lifecycle_event!/1,
      &maybe_put_lifecycle_status_unless_preserved/2
    )
  end

  defp lifecycle_event_review_transition(status_transition, approval_transition) do
    OrbitalDynamics.Timeline.LifecycleEventPolicy.review_transition(
      status_transition,
      approval_transition,
      &transition_requires_operator_review?/1
    )
  end

  defp lifecycle_event_provenance_field(status_transition, approval_transition) do
    OrbitalDynamics.Timeline.LifecycleEventPolicy.provenance_field(
      status_transition,
      approval_transition
    )
  end

  defp lifecycle_event_provenance_transition(status_transition, approval_transition) do
    OrbitalDynamics.Timeline.LifecycleEventPolicy.provenance_transition(
      status_transition,
      approval_transition
    )
  end

  defp maybe_preserve_transition_application_provenance(row, activity) do
    OrbitalDynamics.Timeline.TransitionApplicationActivityPolicy.maybe_preserve_transition_application_provenance(
      row,
      activity
    )
  end

  defp normalized_activity_groups(activities, opts) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.normalized_activity_groups(
      activities,
      opts,
      &normalize_activities/2
    )
  end

  defp transition_application_from_diff_row(row, source_by_timeline, replacement_by_timeline) do
    source = unique_timeline_activity(source_by_timeline, row["timeline_id"])
    replacement = unique_timeline_activity(replacement_by_timeline, row["timeline_id"])

    row
    |> Map.take([
      "id",
      "rank",
      "timeline_id",
      "diff_status",
      "transition_decision",
      "transition_decision_reason",
      "requires_operator_review",
      "required_operator_action",
      "reason",
      "operator_action_reason",
      "changed_fields",
      "status_transition",
      "approval_transition",
      "source_activity_id",
      "replacement_activity_id",
      "source_activity_type",
      "replacement_activity_type",
      "source_protection_decision",
      "replacement_protection_decision",
      "timeline_identity_collision",
      "duplicate_timeline_identity_scope",
      "source_duplicate_activity_count",
      "replacement_duplicate_activity_count",
      "source_duplicate_activity_ids",
      "replacement_duplicate_activity_ids",
      "source_duplicate_activities",
      "replacement_duplicate_activities"
    ])
    |> Map.merge(
      transition_application_selection(
        row["transition_decision"],
        source,
        replacement
      )
    )
    |> Map.put("source_timeline_diff", row)
    |> compact_map()
  end

  defp unique_timeline_activity(groups, timeline_id) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.unique_timeline_activity(groups, timeline_id)
  end

  defp rows_by_timeline_id(rows) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.rows_by_timeline_id(rows)
  end

  defp duplicate_group_count(groups) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.duplicate_group_count(groups)
  end

  defp duplicate_activity_count(groups) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.duplicate_activity_count(groups)
  end

  defp count_by(rows, field) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.count_by(rows, field)
  end

  defp changed_field_counts(rows) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.changed_field_counts(rows, &list_value/2)
  end

  defp transition_counts(rows, field) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.transition_counts(rows, field)
  end

  defp transition_category_counts(rows, field) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.transition_category_counts(rows, field)
  end

  defp sort_count_map(counts) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.sort_count_map(counts)
  end

  defp annotate_duplicate_timeline_identity_rows(rows) do
    OrbitalDynamics.Timeline.DuplicateTimelineIdentityAnnotation.annotate(rows)
  end

  defp annotate_timeline_integrity_rows(rows, validate_missing_dependencies?) do
    OrbitalDynamics.Timeline.IntegrityAnnotation.annotate(
      rows,
      validate_missing_dependencies?,
      issue: &issue/2,
      list_value: &list_value/2,
      compact_map: &compact_map/1
    )
  end

  defp issue(type, fields) do
    OrbitalDynamics.Timeline.IntegrityIssuePolicy.issue(type, fields)
  end

  defp timeline_diff_row(timeline_id, rank, source_matches, replacement_matches) do
    OrbitalDynamics.Timeline.DiffRow.build(
      timeline_id,
      rank,
      source_matches,
      replacement_matches,
      diff_row_callbacks()
    )
  end

  defp put_transition_decision(row) do
    OrbitalDynamics.Timeline.DiffRow.put_transition_decision(row, diff_row_callbacks())
  end

  defp diff_row_callbacks do
    [
      activity_context: &activity_context/1,
      approval_protected?: &approval_protected?/1,
      approval_transition: &approval_transition/2,
      changed_fields: &changed_fields/2,
      compact_map: &compact_map/1,
      delta: &delta/2,
      diff_dependency_context: &diff_dependency_context/2,
      diff_invalid_activity_input_context: &diff_invalid_activity_input_context/2,
      diff_protection_context: &diff_protection_context/2,
      diff_schedule_context: &diff_schedule_context/2,
      preservation_sensitive_source?: &preservation_sensitive_source?/1,
      review_significant_change?: &review_significant_change?/1,
      status_transition: &status_transition/2,
      timeline_integrity_review?: &timeline_integrity_review?/1,
      diff_required_operator_action: &diff_required_operator_action/2,
      diff_reason: &diff_reason/4,
      transition_requires_operator_review?: &transition_requires_operator_review?/1
    ]
  end

  def contact_timeline_row?(row) do
    OrbitalDynamics.Timeline.OperationalRowClassificationPolicy.contact?(row)
  end

  def command_timeline_row?(row) do
    OrbitalDynamics.Timeline.OperationalRowClassificationPolicy.command?(
      row,
      @command_health_activity_types,
      @command_contact_directions
    )
  end

  defp operational_kind(activity) do
    OrbitalDynamics.Timeline.OperationalRowClassificationPolicy.operational_kind(activity)
  end

  defp cadence_import_status(activity, operational_kind) do
    OrbitalDynamics.Timeline.OperationalActionPolicy.cadence_import_status(
      activity,
      operational_kind,
      &invalid_cadence_import?/1
    )
  end

  defp required_operator_action(activity, operational_kind, cadence_import_status) do
    OrbitalDynamics.Timeline.OperationalActionPolicy.required_operator_action(
      activity,
      operational_kind,
      cadence_import_status,
      @terminal_exception_statuses,
      @executed_statuses,
      &activity_status/1,
      &activity_approval_status/1,
      &activity_schedule_conflict_status/1,
      &provider_execution_failure_reason/2,
      &cadence_import_issue/1,
      &activity_locked?/1
    )
  end

  defp provider_execution_failure_reason(activity, kind) do
    OrbitalDynamics.Timeline.ProviderResult.execution_failure_reason(
      activity,
      kind,
      @provider_result_map_value_keys
    )
  end

  defp provider_result_failure?(result) do
    OrbitalDynamics.Timeline.ProviderResult.failure?(result, @provider_result_map_value_keys)
  end

  defp provider_result_artifact_value(result) do
    OrbitalDynamics.Timeline.ProviderResult.artifact_value(
      result,
      @provider_result_map_value_keys
    )
  end

  defp cadence_import(activity) do
    OrbitalDynamics.Timeline.CadenceImportPolicy.cadence_import(
      activity,
      &stable_activity_id?/1
    )
  end

  defp invalid_cadence_import?(activity) do
    OrbitalDynamics.Timeline.CadenceImportPolicy.invalid_cadence_import?(
      activity,
      &stable_activity_id?/1
    )
  end

  defp invalid_cadence_import_context(activity) do
    OrbitalDynamics.Timeline.CadenceImportPolicy.invalid_cadence_import_context(
      activity,
      &stable_activity_id?/1,
      &encode_value/1
    )
  end

  defp cadence_import_issue(cadence_import) do
    OrbitalDynamics.Timeline.CadenceImportPolicy.cadence_import_issue(
      cadence_import,
      &stable_activity_id?/1
    )
  end

  defp drop_invalid_activity_context_cadence_import(context, activity) do
    OrbitalDynamics.Timeline.CadenceImportPolicy.drop_invalid_activity_context_cadence_import(
      context,
      activity,
      &stable_activity_id?/1
    )
  end

  defp activity_to_map(%OrbitalDynamics.MissionPlan.Activity{} = activity) do
    activity
    |> OrbitalDynamics.MissionPlan.Activity.to_map()
    |> activity_to_map()
  end

  defp activity_to_map(%{} = activity) do
    activity
    |> stringify_keys()
    |> normalize_activity_row_aliases()
    |> normalize_spacecraft_id()
    |> normalize_target_id()
    |> normalize_station_id()
    |> normalize_activity_time("starts_at_s", "start_s")
    |> normalize_activity_time("ends_at_s", "end_s")
    |> normalize_activity_direction()
    |> normalize_station_calendar_status_fields()
    |> normalize_numeric_activity_fields()
    |> normalize_source_window()
    |> normalize_cadence_import()
    |> normalize_activity_type_alias()
    |> normalize_provider_downlink_activity()
    |> normalize_direction_contact_activity()
  end

  defp normalize_activity_row_aliases(activity) do
    OrbitalDynamics.Timeline.ActivityRowAliasPolicy.normalize(activity)
  end

  defp normalize_source_window(activity) do
    OrbitalDynamics.Timeline.SourceWindowNormalizationPolicy.normalize(
      activity,
      &put_new_present/3
    )
  end

  defp put_new_present(activity, key, value) do
    OrbitalDynamics.Timeline.ActivityRowAliasPolicy.put_new_present(activity, key, value)
  end

  defp normalize_cadence_import(activity) do
    OrbitalDynamics.Timeline.CadenceImportPolicy.normalize(activity, &put_new_present/3)
  end

  defp normalize_station_calendar_status_fields(activity) do
    OrbitalDynamics.Timeline.StationCalendarStatusNormalizationPolicy.normalize(activity)
  end

  defp normalize_spacecraft_id(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityNormalizationPolicy.normalize_spacecraft_id(activity)
  end

  defp normalize_station_id(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityNormalizationPolicy.normalize_station_id(activity)
  end

  defp normalize_target_id(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityNormalizationPolicy.normalize_target_id(activity)
  end

  defp normalize_activity_time(activity, canonical_key, alternate_key) do
    OrbitalDynamics.Timeline.ActivityNumericNormalizationPolicy.normalize_time(
      activity,
      canonical_key,
      alternate_key,
      &numeric_value/1
    )
  end

  defp normalize_activity_direction(activity) do
    OrbitalDynamics.Timeline.ContactDirectionNormalizationPolicy.normalize_activity(
      activity,
      &encode_value/1
    )
  end

  @doc """
  Normalizes provider-shaped contact direction labels into canonical timeline directions.

  Accepts atoms or strings with case, whitespace, and hyphen variants. Unknown
  non-empty values are returned as normalized snake-case strings so review
  artifacts can preserve provider evidence without accepting it as a known
  contact direction.
  """
  def normalize_contact_direction(direction) when direction in [nil, ""] do
    OrbitalDynamics.Timeline.ContactDirectionNormalizationPolicy.normalize(
      direction,
      &encode_value/1
    )
  end

  def normalize_contact_direction(direction) do
    OrbitalDynamics.Timeline.ContactDirectionNormalizationPolicy.normalize(
      direction,
      &encode_value/1
    )
  end

  defp normalize_numeric_activity_fields(activity) do
    OrbitalDynamics.Timeline.ActivityNumericNormalizationPolicy.normalize(
      activity,
      &numeric_value/1
    )
  end

  defp normalize_provider_downlink_activity(activity) do
    OrbitalDynamics.Timeline.ProviderContactNormalizationPolicy.normalize_provider_downlink(
      activity
    )
  end

  defp normalize_direction_contact_activity(activity) do
    OrbitalDynamics.Timeline.ProviderContactNormalizationPolicy.normalize_direction_contact(
      activity
    )
  end

  defp normalize_activity_type_alias(activity) do
    OrbitalDynamics.Timeline.ProviderContactNormalizationPolicy.normalize_type_alias(activity)
  end

  defp optional_activity_to_map(activity) do
    OrbitalDynamics.Timeline.OptionalActivityInputPolicy.convert(
      activity,
      &activity_to_map/1
    )
  end

  defp provider_direction_aliases do
    OrbitalDynamics.Timeline.ContactDirectionNormalizationPolicy.provider_direction_aliases()
  end

  defp timeline_lifecycle_event!(event) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.lifecycle_event!(
      event,
      @lifecycle_events,
      &encode_value/1
    )
  end

  defp maybe_put_lifecycle_status_unless_preserved(activity, status) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.maybe_put_status_unless_preserved(
      activity,
      status,
      @executed_statuses,
      @terminal_exception_statuses,
      &encode_value/1
    )
  end

  defp activity_status(activity) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.activity_status(
      activity,
      &encode_value/1
    )
  end

  defp activity_approval_status(activity) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.activity_approval_status(
      activity,
      &encode_value/1
    )
  end

  defp activity_status_aliases do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.activity_status_aliases()
  end

  defp approval_status_aliases do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.approval_status_aliases()
  end

  defp normalize_lifecycle_value(value) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.normalize_lifecycle_value(
      value,
      &encode_value/1
    )
  end

  defp activity_locked?(activity) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.locked?(activity)
  end

  defp activity_allow_overlap(activity) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.allow_overlap(activity)
  end

  defp activity_approved?(activity) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.approved?(
      activity,
      &activity_approval_status/1,
      @protected_approval_statuses
    )
  end

  defp protected_by_lock_or_approval?(activity) do
    OrbitalDynamics.Timeline.ApprovalProtectionPolicy.protected_by_lock_or_approval?(
      activity,
      &activity_locked?/1,
      &activity_approved?/1
    )
  end

  defp preservation_sensitive_source?(%{"status" => status}) when status in @executed_statuses,
    do: true

  defp preservation_sensitive_source?(source) do
    OrbitalDynamics.Timeline.ApprovalProtectionPolicy.preservation_sensitive_source?(
      source,
      @protected_approval_statuses
    )
  end

  defp approval_protected?(source) do
    OrbitalDynamics.Timeline.ApprovalProtectionPolicy.approval_protected?(
      source,
      @protected_approval_statuses
    )
  end

  defp executed_status?(status) do
    OrbitalDynamics.Timeline.LifecycleStatusMembershipPolicy.executed?(
      status,
      @executed_statuses
    )
  end

  defp repairable_status?(status) do
    OrbitalDynamics.Timeline.LifecycleStatusMembershipPolicy.repairable?(status)
  end

  defp activity_schedule_conflict_status(activity) do
    OrbitalDynamics.Timeline.ScheduleConflictPolicy.status(activity)
  end

  defp approved_timeline_row?(row) do
    OrbitalDynamics.Timeline.RowStateClassificationPolicy.approved?(row)
  end

  defp executed_timeline_row?(row) do
    OrbitalDynamics.Timeline.RowStateClassificationPolicy.executed?(row, @executed_statuses)
  end

  defp terminal_exception_timeline_row?(row) do
    OrbitalDynamics.Timeline.TerminalExceptionPolicy.terminal?(
      row,
      @terminal_exception_statuses,
      &provider_result_failure?/1
    )
  end

  defp changed_fields(source, replacement) do
    OrbitalDynamics.Timeline.DiffFieldSelectionPolicy.changed_fields(
      source,
      replacement,
      @diff_compare_fields,
      @diff_activity_context_compare_fields
    )
  end

  defp review_significant_change?(changed_fields) do
    OrbitalDynamics.Timeline.DiffFieldSelectionPolicy.review_significant_change?(
      changed_fields,
      @diff_compare_fields
    )
  end

  defp timeline_row_has_dependencies?(row) do
    OrbitalDynamics.Timeline.RelationshipPresencePolicy.has_dependencies?(row)
  end

  defp timeline_row_has_exclusivity?(row) do
    OrbitalDynamics.Timeline.RelationshipPresencePolicy.has_exclusivity?(row)
  end

  defp timeline_integrity_review?(row) do
    OrbitalDynamics.Timeline.RowStateClassificationPolicy.integrity_review?(row)
  end

  defp timeline_integrity_issue_count(rows) do
    OrbitalDynamics.Timeline.IntegrityCountPolicy.timeline_integrity_issue_count(rows)
  end

  defp timeline_integrity_issue_types(rows) do
    OrbitalDynamics.Timeline.IntegrityCountPolicy.timeline_integrity_issue_types(
      rows,
      &list_value/2
    )
  end

  defp timeline_integrity_issue_type_counts(rows) do
    OrbitalDynamics.Timeline.IntegrityCountPolicy.timeline_integrity_issue_type_counts(
      rows,
      &list_value/2,
      &sort_count_map/1
    )
  end

  defp timeline_row_ids(rows, field) do
    OrbitalDynamics.Timeline.IntegrityIdGroupingPolicy.timeline_row_ids(
      rows,
      field,
      &sorted_uniq/1
    )
  end

  defp timeline_integrity_scope_ids(rows, issue_type_fragment, field) do
    OrbitalDynamics.Timeline.IntegrityIdGroupingPolicy.timeline_integrity_scope_ids(
      rows,
      issue_type_fragment,
      field,
      &list_value/2,
      &sorted_uniq/1
    )
  end

  defp timeline_integrity_ids_by_issue_type(rows, id_field) do
    OrbitalDynamics.Timeline.IntegrityIdGroupingPolicy.timeline_integrity_ids_by_issue_type(
      rows,
      id_field,
      &list_value/2,
      &sorted_uniq/1
    )
  end

  defp timeline_integrity_ids_by_field(rows, group_field, id_field) do
    OrbitalDynamics.Timeline.IntegrityIdGroupingPolicy.timeline_integrity_ids_by_field(
      rows,
      group_field,
      id_field,
      &sorted_uniq/1
    )
  end

  defp timeline_integrity_row_list_ids(rows, field) do
    OrbitalDynamics.Timeline.IntegrityIdGroupingPolicy.timeline_integrity_row_list_ids(
      rows,
      field,
      &list_value/2,
      &sorted_uniq/1
    )
  end

  defp timeline_diff_status_ids(rows, status) do
    OrbitalDynamics.Timeline.IntegrityIdGroupingPolicy.timeline_diff_status_ids(
      rows,
      status,
      &sorted_uniq/1
    )
  end

  defp dependency_issue_count(rows) do
    OrbitalDynamics.Timeline.IntegrityCountPolicy.dependency_issue_count(rows, &list_value/2)
  end

  defp exclusivity_issue_count(rows) do
    OrbitalDynamics.Timeline.IntegrityCountPolicy.exclusivity_issue_count(rows, &list_value/2)
  end

  defp list_value(value, key) do
    OrbitalDynamics.Timeline.CollectionValuePolicy.list_value(value, key)
  end

  defp diff_dependency_context(prefix, row) do
    OrbitalDynamics.Timeline.DiffRelationshipContextPolicy.dependency(prefix, row)
  end

  defp diff_schedule_context(prefix, row) do
    OrbitalDynamics.Timeline.DiffRelationshipContextPolicy.schedule(prefix, row)
  end

  defp diff_protection_context(prefix, row) do
    OrbitalDynamics.Timeline.DiffProtectionContextPolicy.build(
      prefix,
      row,
      &protection_decision/1
    )
  end

  defp diff_invalid_activity_input_context(prefix, row) do
    OrbitalDynamics.Timeline.DiffInvalidInputContextPolicy.build(prefix, row)
  end

  defp diff_required_operator_action(diff_status, requires_review) do
    OrbitalDynamics.Timeline.DiffPresentationPolicy.required_operator_action(
      diff_status,
      requires_review
    )
  end

  defp diff_reason(diff_status, source, replacement, changed_fields) do
    OrbitalDynamics.Timeline.DiffPresentationPolicy.reason(
      diff_status,
      source,
      replacement,
      changed_fields
    )
  end

  defp lifecycle_transition(field, from, to) do
    OrbitalDynamics.Timeline.LifecycleTransitionPolicy.build(
      field,
      from,
      to,
      &status_lifecycle_category/1,
      &approval_lifecycle_category/1,
      &status_transition_review/2,
      &approval_transition_review/2,
      &compact_map/1
    )
  end

  defp activity_state_status_transition(planned_activity, realized_activity) do
    planned_status = planned_activity && activity_status(planned_activity)
    realized_status = realized_activity && activity_status(realized_activity)

    if invalid_activity_state?(planned_activity, realized_activity) do
      invalid_activity_state_transition(
        "status",
        planned_status,
        realized_status,
        &status_lifecycle_category/1
      )
    else
      lifecycle_transition("status", planned_status, realized_status)
    end
  end

  defp activity_state_approval_transition(planned_activity, realized_activity) do
    planned_approval_status = planned_activity && activity_approval_status(planned_activity)
    realized_approval_status = realized_activity && activity_approval_status(realized_activity)

    if invalid_activity_state?(planned_activity, realized_activity) do
      invalid_activity_state_transition(
        "approval_status",
        planned_approval_status,
        realized_approval_status,
        &approval_lifecycle_category/1
      )
    else
      lifecycle_transition("approval_status", planned_approval_status, realized_approval_status)
    end
  end

  defp invalid_activity_state_transition(field, from, to, category_fun) do
    {transition_type, values} =
      cond do
        is_nil(from) -> {"added", %{"to" => to, "to_category" => category_fun.(to)}}
        is_nil(to) -> {"removed", %{"from" => from, "from_category" => category_fun.(from)}}
        true -> {"changed", %{"from" => from, "to" => to}}
      end

    %{
      "field" => field,
      "transition_type" => transition_type,
      "from_category" => from && category_fun.(from),
      "to_category" => to && category_fun.(to),
      "transition_category" => "invalid_activity_input",
      "requires_operator_review" => true,
      "operator_action_reason" => "invalid_activity_input"
    }
    |> Map.merge(values)
    |> compact_map()
  end

  defp status_transition_review(from, to) do
    OrbitalDynamics.Timeline.LifecycleTransitionReviewPolicy.status_review(
      from,
      to,
      @executed_statuses,
      @terminal_exception_statuses,
      &unsupported_activity_status?/1,
      &repairable_status?/1
    )
  end

  defp approval_transition_review(from, to) do
    OrbitalDynamics.Timeline.LifecycleTransitionReviewPolicy.approval_review(
      from,
      to,
      @review_approval_statuses,
      @protected_approval_statuses,
      &unsupported_approval_status?/1
    )
  end

  defp transition_requires_operator_review?(transition) do
    OrbitalDynamics.Timeline.LifecycleTransitionReviewPolicy.requires_operator_review?(transition)
  end

  defp status_lifecycle_category(nil), do: nil
  defp status_lifecycle_category(status) when status in @executed_statuses, do: "executed"

  defp status_lifecycle_category(status) when status in @terminal_exception_statuses,
    do: "terminal_exception"

  defp status_lifecycle_category("blocked_by_policy"), do: "blocked"
  defp status_lifecycle_category(status) when status in ["delayed"], do: "repairable"
  defp status_lifecycle_category(status) when status in @activity_statuses, do: "planned"
  defp status_lifecycle_category(_status), do: "other"

  defp approval_lifecycle_category(nil), do: nil

  defp approval_lifecycle_category(status) when status in @protected_approval_statuses,
    do: "protected"

  defp approval_lifecycle_category(status) when status in @review_approval_statuses,
    do: "review_required"

  defp approval_lifecycle_category("blocked_by_policy"), do: "blocked"
  defp approval_lifecycle_category("rejected"), do: "rejected"
  defp approval_lifecycle_category(_status), do: "other"

  defp unsupported_approval_status?(status) do
    OrbitalDynamics.Timeline.LifecycleStatusMembershipPolicy.unsupported_approval?(
      status,
      @approval_statuses
    )
  end

  defp unsupported_activity_status?(status) do
    OrbitalDynamics.Timeline.LifecycleStatusMembershipPolicy.unsupported_activity?(
      status,
      @activity_statuses
    )
  end

  defp optional_activity_state_input(activity, sequence) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.optional_input(
      activity,
      sequence,
      &activity_to_map/1,
      &activity_input_to_map/2
    )
  end

  defp invalid_activity_state_row?(activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.invalid_row?(activity)
  end

  defp invalid_activity_state?(planned_activity, realized_activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.invalid?(
      planned_activity,
      realized_activity
    )
  end

  defp invalid_activity_state_count(planned_activity, realized_activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.invalid_count(
      planned_activity,
      realized_activity
    )
  end

  defp invalid_activity_state_reasons(planned_activity, realized_activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.invalid_reasons(
      planned_activity,
      realized_activity,
      &sorted_uniq/1
    )
  end

  defp state_activity_id(activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.state_activity_id(
      activity,
      &activity_id/1
    )
  end

  defp state_timeline_id(activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.state_timeline_id(
      activity,
      &activity_timeline_id/1
    )
  end

  defp status_state_activity_id(planned_activity, realized_activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.status_state_activity_id(
      planned_activity,
      realized_activity,
      &activity_id/1
    )
  end

  defp status_state_timeline_id(planned_activity, realized_activity) do
    OrbitalDynamics.Timeline.InvalidLifecycleStateInputPolicy.status_state_timeline_id(
      planned_activity,
      realized_activity,
      &activity_timeline_id/1
    )
  end

  defp status_state_transition_decision(status_transition) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.status_state_transition_decision(
      status_transition
    )
  end

  defp status_state_review_required?(status_transition) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.status_state_review_required?(status_transition)
  end

  defp status_state_required_operator_action(transition_decision) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.status_state_required_operator_action(
      transition_decision
    )
  end

  defp status_state_operator_action_reason(status_transition) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.status_state_operator_action_reason(
      status_transition
    )
  end

  defp status_state_import_action(transition_decision) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.status_state_import_action(transition_decision)
  end

  defp approval_state_required_operator_action(transition_decision) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.approval_state_required_operator_action(
      transition_decision
    )
  end

  defp approval_state_operator_action_reason(approval_transition) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.approval_state_operator_action_reason(
      approval_transition
    )
  end

  defp lifecycle_state_transition_decision(status_state, approval_state, protections) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.lifecycle_state_transition_decision(
      status_state,
      approval_state,
      protections
    )
  end

  defp lifecycle_state_required_operator_actions(
         status_state,
         approval_state,
         protections,
         transition_decision
       ) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.lifecycle_state_required_operator_actions(
      status_state,
      approval_state,
      protections,
      transition_decision,
      &sorted_uniq/1
    )
  end

  defp lifecycle_state_required_operator_action(actions, transition_decision) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.lifecycle_state_required_operator_action(
      actions,
      transition_decision
    )
  end

  defp lifecycle_state_operator_action_reasons(status_state, approval_state, protections) do
    OrbitalDynamics.Timeline.LifecycleStatePolicy.lifecycle_state_operator_action_reasons(
      status_state,
      approval_state,
      protections,
      &sorted_uniq/1
    )
  end

  defp delta(replacement, source) do
    OrbitalDynamics.Timeline.ActivityMetricCalculationPolicy.delta(replacement, source)
  end

  defp completion_fraction(actual, planned) do
    OrbitalDynamics.Timeline.ActivityMetricCalculationPolicy.completion_fraction(actual, planned)
  end

  defp activity_timeline_id(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityPolicy.timeline_id(
      activity,
      &activity_start/1,
      &encode_value/1
    )
  end

  defp activity_subject_id(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityPolicy.subject_id(activity)
  end

  defp activity_source_window_id(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityPolicy.source_window_id(activity)
  end

  defp activity_source_window_type(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityPolicy.source_window_type(activity)
  end

  defp dependency_activity_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.dependency_activity_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp duplicate_dependency_activity_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.duplicate_dependency_activity_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp dependency_timeline_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.dependency_timeline_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp duplicate_dependency_timeline_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.duplicate_dependency_timeline_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp exclusive_with_activity_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.exclusive_with_activity_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp duplicate_exclusivity_activity_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.duplicate_exclusivity_activity_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp exclusive_with_timeline_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.exclusive_with_timeline_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp duplicate_exclusivity_timeline_ids(activity) do
    OrbitalDynamics.Timeline.ActivityRelationshipContext.duplicate_exclusivity_timeline_ids(
      activity,
      @stable_id_pattern
    )
  end

  defp first_value(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_value(activity, keys)
  end

  defp first_number(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      keys,
      &numeric_value/1
    )
  end

  defp first_scalar_string(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, keys)
  end

  defp first_boolean(activity, keys) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.first_boolean(activity, keys)
  end

  defp normalize_id_list(value, map_keys) do
    OrbitalDynamics.Timeline.ActivityReferenceIdPolicy.normalize(
      value,
      map_keys,
      &stable_activity_id?/1
    )
  end

  defp stable_id_value(value) do
    OrbitalDynamics.Timeline.ActivityReferenceIdPolicy.stable_id_value(
      value,
      &stable_activity_id?/1
    )
  end

  defp activity_start(activity) do
    OrbitalDynamics.Timeline.ActivityTimingPolicy.start(activity)
  end

  defp activity_end(activity) do
    OrbitalDynamics.Timeline.ActivityTimingPolicy.end_time(activity)
  end

  defp activity_id(activity) do
    OrbitalDynamics.Timeline.ActivityIdentityPolicy.activity_id(activity, &encode_value/1)
  end

  defp stringify_keys(value) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.stringify_keys(value)
  end

  defp encode_value(value) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.encode(value)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
