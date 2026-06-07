defmodule OrbitalDynamics.Timeline do
  @moduledoc """
  Builds artifact-only operational timeline reports.

  The report exposes command/contact classification, approval state, lock state,
  source-window lineage, Cadence import presence, and stable timeline identity
  without mutating schedules or executing operational work.
  """

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
    publication_authority
    source_artifact_id
    source_artifact_type
    supersedes_artifact_ids
    downstream_product_ids
    invalidated_downstream_product_ids
    dependency_impact_status
    dependency_impact_row_count
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
  @candidate_rejection_station_capacity_fraction_fields ~w(
    capacity_fraction
    station_capacity_fraction
    capacity_pack_capacity_fraction
  )
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
  @command_contact_directions ~w(command uplink)
  @command_window_activity_types ~w(command tracking health_check)
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
  @numeric_activity_fields ~w(
    actual_data_volume_mb
    actual_volume_mb
    actual_data_volume_shortfall_mb
    actual_delivery_at_s
    actual_downlink_at_s
    actual_downlink_mb
    actual_latency_s
    actual_storage_mb
    actual_throughput_mb
    attitude_confidence
    attitude_error_deg
    battery_capacity_wh
    battery_energy_used_wh
    battery_energy_generated_wh
    battery_state_of_charge
    bit_error_rate
    blur_score
    candidate_downlink_mb
    capacity_fraction
    capacity_pack_capacity_fraction
    cloud_cover_fraction
    collection_end_s
    collection_ends_at_s
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
    data_volume_completion_fraction
    data_volume_delta_mb
    data_volume_mb
    data_volume_shortfall_mb
    delivered_at_s
    delivered_data_mb
    delivered_data_volume_mb
    delivered_throughput_mb
    downlink_completion_ratio
    downlink_margin
    eb_no_d_b
    eb_no_db
    ebn0_db
    eclipse_overlap_fraction
    eclipse_overlap_s
    estimated_data_volume_mb
    estimated_downlink_mb
    estimated_storage_mb
    estimated_throughput_mb
    frame_loss_rate
    fuel_margin
    image_quality_score
    link_margin_d_b
    link_margin_db
    look_angle_deg
    max_latency_s
    observation_ends_at_s
    observed_ends_at_s
    off_nadir_angle_deg
    packet_loss_rate
    pitch_deg
    planned_data_volume_mb
    planned_volume_mb
    planned_delivered_at_s
    planned_delivery_at_s
    planned_downlink_at_s
    planned_estimated_throughput_mb
    planned_latency_s
    pointing_confidence
    pointing_error_deg
    power_margin
    received_at_s
    received_data_mb
    received_data_volume_mb
    received_throughput_mb
    required_downlink_mb
    required_volume_mb
    required_data_volume_mb
    required_latency_s
    required_data_volume_gap_mb
    roll_deg
    selected_downlink_mb
    selected_downlink_shortfall_mb
    selected_data_volume_mb
    selected_volume_mb
    selected_data_volume_shortfall_mb
    slew_angle_deg
    slew_rate_deg_s
    snr_db
    station_capacity_fraction
    station_reservation_expires_at_s
    storage_margin
    target_downlink_mb
    target_latency_s
    target_volume_mb
    target_data_volume_mb
    min_downlink_mb
    temperature_c
    planned_temperature_c
    actual_temperature_c
    min_operating_temperature_c
    max_operating_temperature_c
    temperature_delta_c
    thermal_confidence
    thermal_margin_c
    throughput_completion_fraction
    throughput_delta_mb
    yaw_deg
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
    impacted = dependency_impact_source_identities(diff_report)

    source_rows = normalize_activities(source_activities, opts)
    replacement_rows = normalize_activities(replacement_activities, opts)

    impact_rows =
      dependency_impact_rows("source", source_rows, impacted) ++
        dependency_impact_rows("replacement", replacement_rows, impacted)

    %{
      "schema_contract" => @dependency_impact_summary_schema_contract,
      "model" => "artifact_only_timeline_dependency_impact_summary",
      "validation_level" => "artifact_contract",
      "source" => "timeline_diff_report.v1",
      "source_activity_count" => diff_report["source_activity_count"],
      "replacement_activity_count" => diff_report["replacement_activity_count"],
      "changed_source_activity_count" => length(impacted.activity_ids),
      "changed_source_timeline_count" => length(impacted.timeline_ids),
      "dependency_impact_status" => if(impact_rows == [], do: "clear", else: "review_required"),
      "dependent_activity_count" => length(impact_rows),
      "source_dependent_activity_count" => Enum.count(impact_rows, &(&1["scope"] == "source")),
      "replacement_dependent_activity_count" =>
        Enum.count(impact_rows, &(&1["scope"] == "replacement")),
      "impacted_source_activity_ids" => impacted.activity_ids,
      "impacted_source_timeline_ids" => impacted.timeline_ids,
      "dependent_activity_ids" => impact_rows |> Enum.map(& &1["activity_id"]) |> sorted_uniq(),
      "dependent_timeline_ids" => impact_rows |> Enum.map(& &1["timeline_id"]) |> sorted_uniq(),
      "source_dependent_activity_ids" =>
        dependency_impact_scope_ids(impact_rows, "source", "activity_id"),
      "source_dependent_timeline_ids" =>
        dependency_impact_scope_ids(impact_rows, "source", "timeline_id"),
      "replacement_dependent_activity_ids" =>
        dependency_impact_scope_ids(impact_rows, "replacement", "activity_id"),
      "replacement_dependent_timeline_ids" =>
        dependency_impact_scope_ids(impact_rows, "replacement", "timeline_id"),
      "impacted_dependency_activity_ids" =>
        dependency_impact_row_ids(impact_rows, "impacted_dependency_activity_ids"),
      "impacted_dependency_timeline_ids" =>
        dependency_impact_row_ids(impact_rows, "impacted_dependency_timeline_ids"),
      "impacted_exclusive_with_activity_ids" =>
        dependency_impact_row_ids(impact_rows, "impacted_exclusive_with_activity_ids"),
      "impacted_exclusive_with_timeline_ids" =>
        dependency_impact_row_ids(impact_rows, "impacted_exclusive_with_timeline_ids"),
      "dependency_impact_rows" => impact_rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "source" => "timeline_diff_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => model_limits()
    }
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
      "publication_authority" => publication_authority,
      "source_artifact_id" => source_artifact_id,
      "source_artifact_type" => source_artifact_type,
      "supersedes_artifact_ids" => supersedes_artifact_ids,
      "downstream_product_ids" => downstream_product_ids,
      "invalidated_downstream_product_ids" => invalidated_downstream_product_ids,
      "dependency_impact_status" =>
        Map.get(dependency_impact_summary, "dependency_impact_status", "not_evaluated"),
      "dependency_impact_row_count" =>
        dependency_impact_summary |> Map.get("dependency_impact_rows", []) |> length(),
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
    [
      Keyword.get(opts, :source_artifact_id),
      source_artifact["id"],
      source_artifact["artifact_id"],
      source_artifact["refresh_id"],
      source_artifact["summary_id"],
      source_artifact["plan_id"]
    ]
    |> Enum.flat_map(&stable_id_value/1)
    |> List.first()
    |> case do
      nil -> "timeline_publication_source"
      value -> value
    end
  end

  defp publication_source_artifact_type(source_artifact) do
    [
      source_artifact["schema_contract"],
      source_artifact["artifact_type"],
      source_artifact["model"]
    ]
    |> Enum.map(&encode_value/1)
    |> Enum.find(&(&1 not in [nil, ""]))
    |> case do
      nil -> "unknown_artifact"
      value -> value
    end
  end

  defp publication_sequence!(opts) do
    case Keyword.get(opts, :publication_sequence, Keyword.get(opts, :sequence, 1)) do
      value when is_integer(value) and value >= 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {integer, ""} when integer >= 0 -> integer
          _parsed -> raise ArgumentError, "publication_sequence must be a non-negative integer"
        end

      _value ->
        raise ArgumentError, "publication_sequence must be a non-negative integer"
    end
  end

  defp publication_stable_id_list(opts, key) do
    opts
    |> Keyword.get(key, [])
    |> List.wrap()
    |> Enum.flat_map(&stable_id_value/1)
    |> sorted_uniq()
  end

  defp publication_dependency_impact_summary(%{} = summary) do
    summary
    |> stringify_keys()
    |> case do
      %{"schema_contract" => @dependency_impact_summary_schema_contract} = summary -> summary
      %{"model" => "artifact_only_timeline_dependency_impact_summary"} = summary -> summary
      _summary -> %{}
    end
  end

  defp publication_dependency_impact_summary(_summary), do: %{}

  defp publication_timeline_diff_summary(%{} = summary) do
    summary
    |> stringify_keys()
    |> case do
      %{"schema_contract" => @diff_summary_schema_contract} = summary -> summary
      %{"model" => "artifact_only_timeline_diff_summary"} = summary -> summary
      _summary -> %{}
    end
  end

  defp publication_timeline_diff_summary(_summary), do: %{}

  defp publication_optional_source_timeline_diff_summary(summary) when summary == %{}, do: nil

  defp publication_optional_source_timeline_diff_summary(summary), do: summary

  defp publication_id_list(nil), do: nil

  defp publication_id_list(values) do
    values
    |> List.wrap()
    |> Enum.flat_map(&stable_id_value/1)
    |> sorted_uniq()
  end

  defp publication_id_array_map(%{} = values) do
    values
    |> Enum.map(fn {key, ids} ->
      {to_string(key), publication_id_list(ids)}
    end)
    |> Enum.reject(fn {key, ids} -> key in ["", "nil"] or ids in [nil, []] end)
    |> Map.new()
  end

  defp publication_id_array_map(nil), do: nil

  defp publication_id_array_map(_values), do: %{}

  defp publication_invalidation_ids(
         [],
         downstream_product_ids,
         dependency_impact_summary,
         supersedes
       ) do
    cond do
      publication_dependency_impact_review_required?(dependency_impact_summary) ->
        downstream_product_ids

      supersedes != [] ->
        downstream_product_ids

      true ->
        []
    end
  end

  defp publication_invalidation_ids(invalidated, downstream_product_ids, _summary, _supersedes) do
    unknown_ids = invalidated -- downstream_product_ids

    if unknown_ids == [] do
      invalidated
    else
      raise ArgumentError,
            "invalidated_downstream_product_ids must be included in downstream_product_ids"
    end
  end

  defp publication_dependency_impact_review_required?(%{
         "dependency_impact_status" => "review_required"
       }),
       do: true

  defp publication_dependency_impact_review_required?(_summary), do: false

  defp publication_status(invalidated_downstream_product_ids, dependency_impact_summary) do
    cond do
      invalidated_downstream_product_ids != [] ->
        "published_with_downstream_invalidations"

      publication_dependency_impact_review_required?(dependency_impact_summary) ->
        "review_required"

      true ->
        "published"
    end
  end

  defp publication_summary_id(source_artifact_id, publication_sequence, supersedes_artifact_ids) do
    supersedes =
      case supersedes_artifact_ids do
        [] -> "initial"
        ids -> Enum.join(ids, "_")
      end

    "timeline_publication:#{publication_sequence}:#{source_artifact_id}:#{supersedes}"
  end

  defp dependency_impact_source_identities(diff_report) do
    rows =
      diff_report
      |> Map.get("rows", [])
      |> Enum.filter(&(&1["diff_status"] in ["changed", "removed"]))

    %{
      activity_ids:
        rows
        |> Enum.flat_map(fn row ->
          [row["source_activity_id"] | list_value(row, "source_duplicate_activity_ids")]
        end)
        |> sorted_uniq(),
      timeline_ids:
        rows
        |> Enum.map(& &1["timeline_id"])
        |> sorted_uniq()
    }
  end

  defp dependency_impact_rows(scope, rows, impacted) do
    rows
    |> Enum.flat_map(fn row ->
      activity_impacts =
        intersection(list_value(row, "dependency_activity_ids"), impacted.activity_ids)

      timeline_impacts =
        intersection(list_value(row, "dependency_timeline_ids"), impacted.timeline_ids)

      exclusive_activity_impacts =
        intersection(list_value(row, "exclusive_with_activity_ids"), impacted.activity_ids)

      exclusive_timeline_impacts =
        intersection(list_value(row, "exclusive_with_timeline_ids"), impacted.timeline_ids)

      if dependency_impact_row?(
           row,
           activity_impacts,
           timeline_impacts,
           exclusive_activity_impacts,
           exclusive_timeline_impacts,
           impacted
         ) do
        [
          %{
            "id" => dependency_impact_row_id(scope, row),
            "scope" => scope,
            "dependency_impact_status" => "review_required",
            "required_operator_action" => "review_timeline_integrity",
            "operator_action_reason" =>
              dependency_impact_operator_action_reason(
                activity_impacts,
                timeline_impacts,
                exclusive_activity_impacts,
                exclusive_timeline_impacts
              ),
            "activity_id" => row["activity_id"],
            "timeline_id" => row["timeline_id"],
            "activity_type" => row["activity_type"],
            "status" => row["status"],
            "approval_status" => row["approval_status"],
            "dependency_activity_ids" => list_value(row, "dependency_activity_ids"),
            "dependency_timeline_ids" => list_value(row, "dependency_timeline_ids"),
            "exclusive_with_activity_ids" => list_value(row, "exclusive_with_activity_ids"),
            "exclusive_with_timeline_ids" => list_value(row, "exclusive_with_timeline_ids"),
            "impacted_dependency_activity_ids" => activity_impacts,
            "impacted_dependency_timeline_ids" => timeline_impacts,
            "impacted_exclusive_with_activity_ids" => exclusive_activity_impacts,
            "impacted_exclusive_with_timeline_ids" => exclusive_timeline_impacts
          }
          |> compact_map()
        ]
      else
        []
      end
    end)
  end

  defp dependency_impact_row?(
         row,
         activity_impacts,
         timeline_impacts,
         exclusive_activity_impacts,
         exclusive_timeline_impacts,
         impacted
       ) do
    (activity_impacts != [] or timeline_impacts != [] or exclusive_activity_impacts != [] or
       exclusive_timeline_impacts != []) and
      row["activity_id"] not in impacted.activity_ids and
      row["timeline_id"] not in impacted.timeline_ids
  end

  defp dependency_impact_operator_action_reason(
         activity_impacts,
         timeline_impacts,
         exclusive_activity_impacts,
         exclusive_timeline_impacts
       ) do
    dependency? = activity_impacts != [] or timeline_impacts != []
    exclusivity? = exclusive_activity_impacts != [] or exclusive_timeline_impacts != []

    case {dependency?, exclusivity?} do
      {true, true} -> "dependency_and_exclusivity_changed_or_removed_source_activity"
      {true, false} -> "dependency_changed_or_removed_source_activity"
      {false, true} -> "exclusivity_changed_or_removed_source_activity"
      {false, false} -> "dependency_changed_or_removed_source_activity"
    end
  end

  defp dependency_impact_row_id(scope, row) do
    row_id = row["timeline_id"] || row["activity_id"] || "unknown"
    "dependency_impact:#{scope}:#{row_id}"
  end

  defp dependency_impact_scope_ids(rows, scope, field) do
    rows
    |> Enum.filter(&(&1["scope"] == scope))
    |> Enum.map(& &1[field])
    |> sorted_uniq()
  end

  defp dependency_impact_row_ids(rows, field) do
    rows
    |> Enum.flat_map(&list_value(&1, field))
    |> sorted_uniq()
  end

  defp application_timeline_ids(applications, predicate) when is_list(applications) do
    applications
    |> Enum.filter(predicate)
    |> Enum.map(& &1["timeline_id"])
    |> sorted_uniq()
  end

  defp application_activity_ids(applications, predicate) when is_list(applications) do
    applications
    |> Enum.filter(predicate)
    |> Enum.flat_map(&[&1["source_activity_id"], &1["replacement_activity_id"]])
    |> sorted_uniq()
  end

  defp timeline_ids_by(rows, key_fun, predicate) when is_list(rows) do
    rows
    |> Enum.filter(predicate)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = key_fun.(row)
      timeline_id = row["timeline_id"]

      if key in [nil, ""] or timeline_id in [nil, ""] do
        grouped
      else
        Map.update(grouped, key, [timeline_id], &[timeline_id | &1])
      end
    end)
    |> Enum.map(fn {key, timeline_ids} -> {key, sorted_uniq(timeline_ids)} end)
    |> Enum.sort_by(fn {key, _timeline_ids} -> key end)
    |> Map.new()
  end

  defp timeline_ids_by_each(rows, values_fun, predicate) when is_list(rows) do
    rows
    |> Enum.filter(predicate)
    |> Enum.reduce(%{}, fn row, grouped ->
      timeline_id = row["timeline_id"]

      if timeline_id in [nil, ""] do
        grouped
      else
        row
        |> values_fun.()
        |> List.wrap()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.reduce(grouped, fn key, nested ->
          Map.update(nested, key, [timeline_id], &[timeline_id | &1])
        end)
      end
    end)
    |> Enum.map(fn {key, timeline_ids} -> {key, sorted_uniq(timeline_ids)} end)
    |> Enum.sort_by(fn {key, _timeline_ids} -> key end)
    |> Map.new()
  end

  defp intersection(left, right) do
    right = MapSet.new(right)

    left
    |> Enum.filter(&MapSet.member?(right, &1))
    |> sorted_uniq()
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
    values =
      activity
      |> declared_rejection_reason_values()
      |> Enum.map(&candidate_rejection_reason/1)

    if Enum.any?(values, &(&1 == "declared_rejection")) do
      values
    else
      values
    end
  end

  defp declared_rejection_reason_values(activity) do
    activity
    |> rejection_reason_values([
      "rejection_reason",
      "rejection_reasons",
      "candidate_rejection_reason",
      "candidate_rejection_reasons",
      "why_rejected"
    ])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp rejection_reason_values(activity, keys) do
    keys
    |> Enum.flat_map(fn key ->
      [Map.get(activity, key), get_in(activity, ["metadata", key])]
    end)
    |> Enum.flat_map(&split_rejection_reason_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp split_rejection_reason_value(values) when is_list(values),
    do: Enum.flat_map(values, &split_rejection_reason_value/1)

  defp split_rejection_reason_value(value) when value in [nil, ""], do: []

  defp split_rejection_reason_value(value) when is_atom(value),
    do: split_rejection_reason_value(Atom.to_string(value))

  defp split_rejection_reason_value(value) when is_binary(value) do
    value
    |> String.split([",", ";", "|"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp split_rejection_reason_value(_value), do: []

  defp candidate_rejection_reason(value) do
    normalized =
      value
      |> to_string()
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "_")
      |> String.trim("_")

    aliases = %{
      "access_window_missing" => "no_access_window",
      "no_access" => "no_access_window",
      "target_visibility_missing" => "no_target_visibility_window",
      "no_target_visibility" => "no_target_visibility_window",
      "eclipse" => "eclipse_conflict",
      "low_battery" => "battery_margin_too_low",
      "battery_low" => "battery_margin_too_low",
      "storage_margin_too_low" => "storage_full",
      "fuel_low" => "fuel_margin_too_low",
      "payload_not_available" => "payload_unavailable",
      "antenna_not_available" => "antenna_unavailable",
      "station_not_available" => "station_unavailable",
      "reserved_station" => "station_reserved",
      "reduced_station_capacity" => "station_capacity_reduced",
      "short_contact" => "contact_too_short",
      "locked_overlap" => "overlaps_locked_timeline_item",
      "activity_overlap_locked" => "overlaps_locked_timeline_item",
      "authority_missing" => "command_authority_missing",
      "blocked_by_policy" => "policy_blocked",
      "policy" => "policy_blocked",
      "state_stale" => "stale_state",
      "incompatible_model" => "model_incompatible",
      "schema_validation_failed" => "quality_gate_failed"
    }

    canonical = Map.get(aliases, normalized, normalized)

    if canonical in @candidate_rejection_reasons do
      canonical
    else
      "declared_rejection"
    end
  end

  defp derived_candidate_rejection_reasons(activity, timeline_row) do
    []
    |> maybe_add_reason(timeline_row["invalid_activity_input"] == true, "invalid_candidate_input")
    |> maybe_add_reason(station_unavailable?(activity), "station_unavailable")
    |> maybe_add_reason(station_reserved?(activity), "station_reserved")
    |> maybe_add_reason(station_capacity_reduced?(activity), "station_capacity_reduced")
    |> maybe_add_reason(locked_overlap?(activity), "overlaps_locked_timeline_item")
    |> maybe_add_reason(
      first_boolean(activity, ["payload_available"]) == false,
      "payload_unavailable"
    )
    |> maybe_add_reason(
      first_boolean(activity, ["antenna_available"]) == false,
      "antenna_unavailable"
    )
    |> maybe_add_reason(negative_margin?(activity, ["fuel_margin"]), "fuel_margin_too_low")
    |> maybe_add_reason(negative_margin?(activity, ["storage_margin"]), "storage_full")
    |> maybe_add_reason(
      negative_margin?(activity, ["battery_margin", "power_margin", "battery_state_of_charge"]),
      "battery_margin_too_low"
    )
    |> maybe_add_reason(contact_too_short?(activity), "contact_too_short")
    |> maybe_add_reason(policy_blocked?(activity), "policy_blocked")
    |> maybe_add_reason(stale_state?(activity), "stale_state")
    |> maybe_add_reason(model_incompatible?(activity), "model_incompatible")
    |> maybe_add_reason(quality_gate_failed?(activity), "quality_gate_failed")
  end

  defp maybe_add_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_add_reason(reasons, _condition, _reason), do: reasons

  defp station_unavailable?(activity) do
    status =
      activity
      |> candidate_rejection_station_status([
        "station_availability",
        "station_calendar_status",
        "availability",
        "status"
      ])
      |> normalized_token()

    status in ["unavailable", "not_available", "closed", "outage"]
  end

  defp station_reserved?(activity) do
    status =
      activity
      |> candidate_rejection_station_status([
        "station_availability",
        "station_reservation_match_status",
        "station_calendar_status",
        "availability",
        "status",
        "reservation_status"
      ])
      |> normalized_token()

    status in ["reserved", "reservation_hold", "hold", "held", "matched_reserved"]
  end

  defp candidate_rejection_station_status(activity, fields) do
    first_scalar_string(activity, fields) ||
      source_station_status(activity["source_station_calendar_entry"], fields) ||
      source_station_status(activity["source_station_calendar_overlaps"], fields)
  end

  defp source_station_status(sources, fields) when is_list(sources),
    do: Enum.find_value(sources, &source_station_status(&1, fields))

  defp source_station_status(%{} = source, fields), do: first_scalar_string(source, fields)

  defp source_station_status(_source, _fields), do: nil

  defp station_capacity_reduced?(activity) do
    status =
      activity
      |> candidate_rejection_station_status([
        "station_availability",
        "station_calendar_status",
        "availability",
        "status"
      ])
      |> normalized_token()

    capacity_fraction = candidate_rejection_station_capacity_fraction(activity)

    status in ["reduced_capacity", "degraded_capacity"] or
      (is_number(capacity_fraction) and capacity_fraction >= 0.0 and capacity_fraction < 1.0)
  end

  defp candidate_rejection_station_capacity_fraction(activity) do
    first_number(activity, @candidate_rejection_station_capacity_fraction_fields) ||
      source_station_capacity_fraction(activity["source_station_calendar_entry"]) ||
      source_station_capacity_fraction(activity["source_station_calendar_overlaps"])
  end

  defp source_station_capacity_fraction(sources) when is_list(sources),
    do: Enum.find_value(sources, &source_station_capacity_fraction/1)

  defp source_station_capacity_fraction(%{} = source),
    do: first_number(source, @candidate_rejection_station_capacity_fraction_fields)

  defp source_station_capacity_fraction(_source), do: nil

  defp locked_overlap?(activity) do
    status =
      activity
      |> first_scalar_string(["schedule_conflict_status", "conflict_status"])
      |> normalized_token()

    status in ["locked_overlap", "overlaps_locked", "conflict_locked", "locked_conflict"]
  end

  defp negative_margin?(activity, fields) do
    case first_number(activity, fields) do
      value when is_number(value) -> value < 0.0
      _value -> false
    end
  end

  defp contact_too_short?(activity) do
    duration = activity_duration_s(activity)

    minimum =
      first_number(activity, ["minimum_duration_s", "min_duration_s", "required_duration_s"])

    is_number(duration) and is_number(minimum) and duration < minimum
  end

  defp policy_blocked?(activity) do
    activity_status(activity) == "blocked_by_policy" or
      activity_approval_status(activity) == "blocked_by_policy"
  end

  defp stale_state?(activity) do
    status =
      activity
      |> first_scalar_string(["freshness_status", "state_freshness_status"])
      |> normalized_token()

    status == "stale"
  end

  defp model_incompatible?(activity) do
    status =
      activity
      |> first_scalar_string(["model_compatibility_status", "compatibility_status"])
      |> normalized_token()

    status in ["incompatible", "model_incompatible"]
  end

  defp quality_gate_failed?(activity) do
    status =
      activity
      |> first_scalar_string([
        "quality_gate_status",
        "schema_validation_status",
        "validation_status"
      ])
      |> normalized_token()

    status in ["fail", "failed", "blocked"]
  end

  defp normalized_token(nil), do: nil

  defp normalized_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end

  defp candidate_reviewable?(_activity, []), do: false

  defp candidate_reviewable?(activity, _reasons) do
    case first_boolean(activity, ["reviewable", "candidate_reviewable"]) do
      false -> false
      _value -> true
    end
  end

  defp reason_counts(rows) do
    rows
    |> Enum.flat_map(& &1["rejection_reasons"])
    |> Enum.frequencies()
  end

  defp candidate_rejection_row_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(& &1["candidate_id"])
    |> sorted_uniq()
  end

  defp candidate_id_sets_by_rejection_reason(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("rejection_reasons", [])
      |> Enum.map(&{&1, row["candidate_id"]})
    end)
    |> Enum.group_by(fn {reason, _candidate_id} -> reason end, fn {_reason, candidate_id} ->
      candidate_id
    end)
    |> Map.new(fn {reason, candidate_ids} -> {reason, sorted_uniq(candidate_ids)} end)
  end

  defp candidate_ids_by_required_operator_action(rows) do
    rows
    |> Enum.group_by(& &1["required_operator_action"], & &1["candidate_id"])
    |> Map.new(fn {action, candidate_ids} -> {action, sorted_uniq(candidate_ids)} end)
  end

  defp normalize_activity_input({activity, sequence}, opts) do
    case activity_input_to_map(activity, sequence) do
      {:ok, activity} ->
        normalize_valid_activity(activity, Keyword.put(opts, :sequence, sequence))

      {:error, row} ->
        Map.drop(row, ["id"])
    end
  end

  defp activity_input_to_map(activity, sequence) do
    case safe_activity_to_map(activity) do
      {:ok, activity} ->
        maybe_valid_activity_map(activity, sequence)

      {:error, reason, source_activity} ->
        {:error, invalid_activity_input_row(source_activity, sequence, reason)}
    end
  end

  defp safe_activity_to_map(activity) do
    {:ok, activity_to_map(activity)}
  rescue
    _error ->
      {:error, "invalid_activity_shape", %{"raw_input" => inspect(activity)}}
  end

  defp maybe_valid_activity_map(activity, sequence) do
    case activity_input_issue(activity) do
      nil ->
        {:ok, activity}

      reason ->
        {:error, invalid_activity_input_row(activity, sequence, reason)}
    end
  end

  defp activity_input_issue(activity) do
    activity_id_issue(activity["id"]) ||
      activity_type_issue(activity["type"]) ||
      activity_status_issue(activity) ||
      activity_approval_status_issue(activity) ||
      activity_nested_shape_issue(activity) ||
      activity_unit_interval_issue(activity) ||
      activity_identity_issue(activity)
  end

  defp activity_type_issue(type) do
    if valid_activity_type?(type), do: nil, else: "missing_activity_type"
  end

  defp activity_status_issue(activity) do
    status = activity_status(activity)

    if status in @activity_statuses,
      do: nil,
      else: "unsupported_activity_status"
  end

  defp activity_approval_status_issue(activity) do
    approval_status = activity_approval_status(activity)

    if approval_status in @approval_statuses,
      do: nil,
      else: "unsupported_approval_status"
  end

  defp activity_nested_shape_issue(activity) do
    cond do
      malformed_nested_map?(activity, "metadata") ->
        "invalid_activity_metadata"

      malformed_nested_map?(activity, "source_window") ->
        "invalid_source_window"

      true ->
        nil
    end
  end

  defp activity_unit_interval_issue(activity) do
    Enum.find_value(@unit_interval_activity_field_aliases, fn {field, aliases} ->
      if invalid_unit_interval_declared?(activity, aliases), do: "invalid_#{field}"
    end)
  end

  defp invalid_unit_interval_declared?(activity, aliases) do
    Enum.any?(aliases, fn field_alias ->
      activity
      |> unit_interval_candidate_values(field_alias)
      |> Enum.any?(&invalid_unit_interval_value?/1)
    end)
  end

  defp unit_interval_candidate_values(activity, field) do
    [
      Map.get(activity, field),
      get_in(activity, ["metadata", field])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp invalid_unit_interval_value?(value) do
    case numeric_value(value) do
      value when is_number(value) -> value < 0.0 or value > 1.0
      _value -> false
    end
  end

  defp malformed_nested_map?(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, nil} -> false
      {:ok, value} -> not is_map(value)
      :error -> false
    end
  end

  defp activity_identity_issue(activity) do
    Enum.find_value(@activity_stable_identity_paths, fn {field, path} ->
      case activity_path_value(activity, path) do
        :missing ->
          nil

        value when value in [nil, ""] ->
          nil

        value when is_binary(value) ->
          if stable_activity_id?(value), do: nil, else: "invalid_#{field}"

        _value ->
          "invalid_#{field}"
      end
    end)
  end

  defp activity_path_value(%{} = activity, [field]) do
    case Map.fetch(activity, field) do
      {:ok, value} -> value
      :error -> :missing
    end
  end

  defp activity_path_value(%{} = activity, [field | rest]) do
    case Map.fetch(activity, field) do
      {:ok, nil} -> :missing
      {:ok, %{} = nested} -> activity_path_value(nested, rest)
      {:ok, _value} -> :missing
      :error -> :missing
    end
  end

  defp activity_path_value(_activity, _path), do: :missing

  defp activity_id_issue(id) when id in [nil, ""], do: "missing_activity_id"

  defp activity_id_issue(id) when is_binary(id),
    do: if(stable_activity_id?(id), do: nil, else: "invalid_activity_id")

  defp activity_id_issue(_id), do: "invalid_activity_id"

  defp stable_activity_id?(id) when is_binary(id), do: Regex.match?(@stable_id_pattern, id)

  defp valid_activity_type?(type) when is_binary(type), do: type != ""
  defp valid_activity_type?(_type), do: false

  defp invalid_activity_input_rows(rows) do
    Enum.filter(rows, &(&1["invalid_activity_input"] == true))
  end

  defp invalid_activity_input_row(source_activity, sequence, reason) do
    activity_id = invalid_activity_id(source_activity, sequence, reason)
    timeline_id = "timeline:invalid_activity_input:#{activity_id}"

    timeline_identity = %{
      "timeline_id" => timeline_id,
      "activity_id" => activity_id,
      "activity_type" => "invalid_activity_input"
    }

    %{
      "id" => "timeline_row:#{sequence}:#{activity_id}",
      "activity_id" => activity_id,
      "timeline_id" => timeline_id,
      "activity_type" => "invalid_activity_input",
      "status" => "invalid",
      "approval_status" => "operator_review_required",
      "locked" => false,
      "operational_kind" => "activity",
      "required_operator_action" => "review_invalid_activity_input",
      "operator_action_reason" => reason,
      "execution_boundary" => "planned_not_commanded",
      "cadence_import_status" => "not_applicable",
      "has_source_window" => false,
      "has_cadence_import" => false,
      "timeline_identity" => timeline_identity,
      "activity_context" => %{"timeline_identity" => timeline_identity},
      "timeline_integrity_status" => "review_required",
      "timeline_integrity_issue_count" => 1,
      "timeline_integrity_issue_types" => ["invalid_activity_input"],
      "timeline_integrity_issues" => [
        issue("invalid_activity_input", %{"invalid_activity_input_reason" => reason})
      ],
      "invalid_activity_input" => true,
      "invalid_activity_input_reason" => reason,
      "source_activity" => source_activity
    }
    |> compact_map()
  end

  defp invalid_activity_id(activity, sequence, reason) when is_map(activity) do
    case activity["id"] do
      value when is_binary(value) and value != "" ->
        if stable_activity_id?(value), do: value, else: "#{reason}:#{sequence}"

      value when is_atom(value) and not is_nil(value) ->
        Atom.to_string(value)

      _value ->
        "#{reason}:#{sequence}"
    end
  end

  defp invalid_activity_id(_activity, sequence, reason), do: "#{reason}:#{sequence}"

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
    case activity_template_provenance(activity) do
      nil -> %{}
      provenance -> %{"activity_template" => provenance}
    end
  end

  defp activity_template_provenance(%{"activity_template" => %{} = template}) do
    template = stringify_keys(template)

    if template["schema_contract"] == "activity_template.v1" and
         is_binary(template["id"]) and
         is_binary(template["activity_type"]) do
      template
      |> Map.take([
        "schema_contract",
        "id",
        "activity_type",
        "template_version",
        "validation_level",
        "known_limits",
        "operational_hints",
        "subsystem_state_hints",
        "assumptions"
      ])
      |> normalize_activity_template_provenance()
      |> compact_map()
    end
  end

  defp activity_template_provenance(_activity), do: nil

  defp normalize_activity_template_provenance(%{"operational_hints" => hints} = template) do
    case normalize_activity_template_operational_hints(hints) do
      hints when is_map(hints) and map_size(hints) > 0 ->
        Map.put(template, "operational_hints", hints)

      _hints ->
        Map.delete(template, "operational_hints")
    end
  end

  defp normalize_activity_template_provenance(template), do: template

  defp normalize_activity_template_operational_hints(%{} = hints) do
    hints = stringify_keys(hints)

    hints
    |> Map.drop([
      "setup_duration_s",
      "cooldown_duration_s",
      "telemetry_confirmation_required",
      "telemetry_confirmation_status"
    ])
    |> maybe_put_operational_hint_number("setup_duration_s", Map.get(hints, "setup_duration_s"))
    |> maybe_put_operational_hint_number(
      "cooldown_duration_s",
      Map.get(hints, "cooldown_duration_s")
    )
    |> maybe_put_operational_hint_boolean(
      "telemetry_confirmation_required",
      Map.get(hints, "telemetry_confirmation_required")
    )
    |> maybe_put_operational_hint_string(
      "telemetry_confirmation_status",
      Map.get(hints, "telemetry_confirmation_status")
    )
    |> compact_map()
  end

  defp normalize_activity_template_operational_hints(_hints), do: nil

  defp maybe_put_operational_hint_number(hints, key, value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0.0 -> Map.put(hints, key, number)
      _value -> hints
    end
  end

  defp maybe_put_operational_hint_boolean(hints, key, value) do
    case boolean_value(value) do
      value when is_boolean(value) -> Map.put(hints, key, value)
      _value -> hints
    end
  end

  defp maybe_put_operational_hint_string(hints, key, value) when is_binary(value) do
    case String.trim(value) do
      "" -> hints
      value -> Map.put(hints, key, value)
    end
  end

  defp maybe_put_operational_hint_string(hints, key, value)
       when is_atom(value) and not is_nil(value),
       do: Map.put(hints, key, Atom.to_string(value))

  defp maybe_put_operational_hint_string(hints, _key, _value), do: hints

  defp activity_lifecycle_context(activity) do
    %{}
    |> maybe_put_lifecycle_context(
      activity,
      "status",
      &activity_status/1
    )
    |> maybe_put_lifecycle_context(
      activity,
      "approval_status",
      &activity_approval_status/1
    )
  end

  defp maybe_put_lifecycle_context(context, activity, field, value_fun) do
    if Map.has_key?(activity, field) or not is_nil(get_in(activity, ["metadata", field])) do
      Map.put(context, field, value_fun.(activity))
    else
      context
    end
  end

  defp activity_command_authority_context(activity) do
    %{
      "command_authority_status" =>
        first_scalar_string(activity, ["command_authority_status", "authority_status"]),
      "required_authority" =>
        first_scalar_string(activity, ["required_authority", "required_escalation_authority"]),
      "command_safety_status" =>
        first_scalar_string(activity, ["command_safety_status", "safety_status"]),
      "command_authorized" =>
        first_boolean(activity, ["command_authorized", "command_authorized?", "authority_granted"]),
      "command_safety_checked" =>
        first_boolean(activity, [
          "command_safety_checked",
          "command_safety_checked?",
          "safety_checked"
        ])
    }
    |> compact_map()
  end

  defp activity_timing_context(activity) do
    %{
      "starts_at_s" => activity_start(activity),
      "ends_at_s" => activity_end(activity),
      "duration_s" => activity_duration_s(activity),
      "target_id" => activity["target_id"]
    }
    |> compact_map()
  end

  defp activity_operational_hint_context(activity) do
    %{
      "setup_duration_s" => activity_operational_hint_number(activity, "setup_duration_s"),
      "cooldown_duration_s" => activity_operational_hint_number(activity, "cooldown_duration_s"),
      "telemetry_confirmation_required" =>
        activity_operational_hint_boolean(activity, [
          "telemetry_confirmation_required",
          "telemetry_confirmation_required?"
        ]),
      "telemetry_confirmation_status" =>
        activity_operational_hint_string(activity, "telemetry_confirmation_status")
    }
    |> compact_map()
  end

  defp activity_operational_hint_number(activity, key) do
    case first_present_value(activity, [key]) do
      {:ok, value} ->
        numeric_value(value)

      :error ->
        activity
        |> activity_template_operational_hints()
        |> Map.get(key)
        |> numeric_value()
    end
  end

  defp activity_operational_hint_boolean(activity, keys) do
    case first_present_value(activity, keys) do
      {:ok, value} ->
        boolean_value(value)

      :error ->
        hints = activity_template_operational_hints(activity)

        keys
        |> Enum.find_value(fn key -> Map.get(hints, key) |> boolean_value() end)
    end
  end

  defp activity_operational_hint_string(activity, key) do
    case first_present_value(activity, [key]) do
      {:ok, value} when is_binary(value) and value != "" ->
        value

      {:ok, value} when is_atom(value) and not is_nil(value) ->
        Atom.to_string(value)

      {:ok, _value} ->
        nil

      :error ->
        case Map.get(activity_template_operational_hints(activity), key) do
          value when is_binary(value) and value != "" -> value
          value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
          _value -> nil
        end
    end
  end

  defp activity_template_operational_hints(activity) do
    case activity_template_provenance(activity) do
      %{"operational_hints" => %{} = hints} -> hints
      _provenance -> %{}
    end
  end

  defp activity_source_window_context(activity) do
    %{
      "source_window_id" => activity_source_window_id(activity),
      "source_window_type" => activity_source_window_type(activity)
    }
    |> compact_map()
  end

  defp activity_dependency_context(activity) do
    %{
      "dependency_activity_ids" => dependency_activity_ids(activity),
      "dependency_timeline_ids" => dependency_timeline_ids(activity),
      "exclusive_with_activity_ids" => exclusive_with_activity_ids(activity),
      "exclusive_with_timeline_ids" => exclusive_with_timeline_ids(activity),
      "allow_overlap" => activity_allow_overlap(activity)
    }
    |> compact_map()
  end

  defp activity_feedback_context(activity) do
    %{
      "contact_success" => first_boolean(activity, ["contact_success"]),
      "contact_result" => first_provider_result_string(activity, ["contact_result"]),
      "contact_success_factor" => first_number(activity, ["contact_success_factor"]),
      "contact_success_factor_source" =>
        first_scalar_string(activity, ["contact_success_factor_source"]),
      "command_success" => first_boolean(activity, ["command_success"]),
      "command_result" => first_provider_result_string(activity, ["command_result"]),
      "command_success_factor" => first_number(activity, ["command_success_factor"]),
      "command_success_factor_source" =>
        first_scalar_string(activity, ["command_success_factor_source"]),
      "observation_success" => first_boolean(activity, ["observation_success"]),
      "observation_result" => first_provider_result_string(activity, ["observation_result"]),
      "observation_success_factor" => first_number(activity, ["observation_success_factor"]),
      "observation_success_factor_source" =>
        first_scalar_string(activity, ["observation_success_factor_source"]),
      "maneuver_success" => first_boolean(activity, ["maneuver_success"]),
      "maneuver_result" => first_provider_result_string(activity, ["maneuver_result"]),
      "maneuver_success_factor" => first_number(activity, ["maneuver_success_factor"]),
      "maneuver_success_factor_source" =>
        first_scalar_string(activity, ["maneuver_success_factor_source"]),
      "feedback_weight" => first_number(activity, ["feedback_weight"]),
      "feedback_weight_source" => first_scalar_string(activity, ["feedback_weight_source"])
    }
    |> compact_map()
  end

  defp activity_product_context(activity) do
    collection_ends_at_s = collection_ends_at_s(activity)
    planned_delivery_at_s = planned_delivery_at_s(activity)
    actual_delivery_at_s = actual_delivery_at_s(activity)
    max_latency_s = max_latency_s(activity)
    planned_latency_s = planned_latency_s(activity, collection_ends_at_s, planned_delivery_at_s)
    actual_latency_s = actual_latency_s(activity, collection_ends_at_s, actual_delivery_at_s)

    %{
      "collection_id" => first_value(activity, ["collection_id", "collection"]),
      "product_id" => first_value(activity, ["product_id", "data_product_id"]),
      "product_ids" =>
        first_value(activity, ["product_ids", "data_product_ids"])
        |> normalize_id_list(["id", "product_id", "data_product_id"]),
      "payload_id" => first_value(activity, ["payload_id", "payload"]),
      "instrument_id" => first_value(activity, ["instrument_id", "instrument"]),
      "data_volume_mb" =>
        first_number(activity, [
          "data_volume_mb",
          "planned_data_volume_mb",
          "estimated_data_volume_mb",
          "estimated_storage_mb",
          "estimated_downlink_mb"
        ]),
      "planned_data_volume_mb" => planned_data_volume_mb(activity),
      "actual_data_volume_mb" => actual_data_volume_mb(activity),
      "data_volume_delta_mb" =>
        delta(actual_data_volume_mb(activity), planned_data_volume_mb(activity)),
      "data_volume_completion_fraction" =>
        completion_fraction(actual_data_volume_mb(activity), planned_data_volume_mb(activity)),
      "estimated_data_volume_mb" =>
        first_number(activity, [
          "estimated_data_volume_mb",
          "data_volume_mb",
          "planned_data_volume_mb"
        ]),
      "estimated_storage_mb" =>
        first_number(activity, [
          "estimated_storage_mb",
          "data_volume_mb",
          "planned_data_volume_mb"
        ]),
      "estimated_downlink_mb" => first_number(activity, ["estimated_downlink_mb"]),
      "required_downlink_mb" => first_number(activity, ["required_downlink_mb"]),
      "collection_ends_at_s" => collection_ends_at_s,
      "planned_delivery_at_s" => planned_delivery_at_s,
      "actual_delivery_at_s" => actual_delivery_at_s,
      "max_latency_s" => max_latency_s,
      "planned_latency_s" => planned_latency_s,
      "actual_latency_s" => actual_latency_s,
      "latency_delta_s" => delta(actual_latency_s, planned_latency_s),
      "latency_margin_s" => delta(max_latency_s, actual_latency_s || planned_latency_s),
      "target_priority" => first_number(activity, ["target_priority"]),
      "target_priority_source" => first_scalar_string(activity, ["target_priority_source"]),
      "target_priority_objective_ids" =>
        first_value(activity, ["target_priority_objective_ids", "observation_objective_ids"])
        |> normalize_id_list(["id", "objective_id"]),
      "target_priority_objective_type" =>
        first_scalar_string(activity, [
          "target_priority_objective_type",
          "observation_objective_type"
        ])
    }
    |> compact_map()
  end

  defp activity_observation_quality_context(activity) do
    %{
      "image_quality_score" =>
        first_number(activity, ["image_quality_score", "product_quality_score", "quality_score"]),
      "image_quality_status" =>
        first_scalar_string(activity, [
          "image_quality_status",
          "product_quality_status",
          "quality_status"
        ]),
      "image_quality_source" =>
        first_scalar_string(activity, [
          "image_quality_source",
          "product_quality_source",
          "quality_source"
        ]),
      "cloud_cover_fraction" =>
        first_number(activity, ["cloud_cover_fraction", "cloud_fraction", "cloud_cover"]),
      "blur_score" =>
        first_number(activity, ["blur_score", "image_blur_score", "sharpness_loss_fraction"])
    }
    |> compact_map()
  end

  defp activity_pointing_context(activity) do
    %{
      "pointing_mode" => first_scalar_string(activity, ["pointing_mode", "attitude_mode"]),
      "pointing_target_id" =>
        first_stable_identifier(activity, [
          "pointing_target_id",
          "attitude_target_id"
        ]),
      "boresight_axis" => first_scalar_string(activity, ["boresight_axis", "sensor_axis"]),
      "off_nadir_angle_deg" => first_number(activity, ["off_nadir_angle_deg", "look_angle_deg"]),
      "slew_angle_deg" => first_number(activity, ["slew_angle_deg"]),
      "slew_rate_deg_s" => first_number(activity, ["slew_rate_deg_s"]),
      "pointing_error_deg" =>
        first_number(activity, ["pointing_error_deg", "attitude_error_deg"]),
      "pointing_status" => first_scalar_string(activity, ["pointing_status", "attitude_status"]),
      "pointing_model" => first_scalar_string(activity, ["pointing_model", "attitude_model"]),
      "pointing_source" => first_scalar_string(activity, ["pointing_source", "attitude_source"]),
      "pointing_confidence" =>
        first_number(activity, ["pointing_confidence", "attitude_confidence"])
    }
    |> compact_map()
  end

  defp activity_attitude_context(activity) do
    %{
      "attitude_mode" => first_scalar_string(activity, ["attitude_mode"]),
      "attitude_target_id" => first_stable_identifier(activity, ["attitude_target_id"]),
      "roll_deg" => first_number(activity, ["roll_deg"]),
      "pitch_deg" => first_number(activity, ["pitch_deg"]),
      "yaw_deg" => first_number(activity, ["yaw_deg"]),
      "attitude_error_deg" => first_number(activity, ["attitude_error_deg"]),
      "attitude_status" => first_scalar_string(activity, ["attitude_status"]),
      "attitude_model" => first_scalar_string(activity, ["attitude_model"]),
      "attitude_source" => first_scalar_string(activity, ["attitude_source"]),
      "attitude_confidence" => first_number(activity, ["attitude_confidence"])
    }
    |> compact_map()
  end

  defp activity_thermal_context(activity) do
    planned_temperature_c = planned_temperature_c(activity)
    actual_temperature_c = actual_temperature_c(activity)

    observed_temperature_c =
      actual_temperature_c || planned_temperature_c || temperature_c(activity)

    %{
      "thermal_zone_id" =>
        first_stable_identifier(activity, [
          "thermal_zone_id",
          "thermal_component_id",
          "thermal_node_id"
        ]),
      "temperature_c" => temperature_c(activity),
      "planned_temperature_c" => planned_temperature_c,
      "actual_temperature_c" => actual_temperature_c,
      "temperature_delta_c" => delta(actual_temperature_c, planned_temperature_c),
      "min_operating_temperature_c" => min_operating_temperature_c(activity),
      "max_operating_temperature_c" => max_operating_temperature_c(activity),
      "thermal_margin_c" => thermal_margin_c(activity, observed_temperature_c),
      "thermal_status" => first_scalar_string(activity, ["thermal_status", "temperature_status"]),
      "thermal_model" => first_scalar_string(activity, ["thermal_model", "temperature_model"]),
      "thermal_source" => first_scalar_string(activity, ["thermal_source", "temperature_source"]),
      "thermal_confidence" =>
        first_number(activity, ["thermal_confidence", "temperature_confidence"])
    }
    |> compact_map()
  end

  defp activity_lighting_context(activity) do
    %{
      "eclipse_overlap_fraction" => first_number(activity, ["eclipse_overlap_fraction"]),
      "eclipse_overlap_s" => first_number(activity, ["eclipse_overlap_s"]),
      "lighting_condition" =>
        first_scalar_string(activity, ["lighting_condition", "lighting_status"]),
      "lighting_condition_detail" =>
        first_scalar_string(activity, ["lighting_condition_detail", "lighting_detail"]),
      "lighting_condition_model" =>
        first_scalar_string(activity, ["lighting_condition_model", "lighting_model"]),
      "lighting_detail_model" =>
        first_scalar_string(activity, ["lighting_detail_model", "lighting_detail_source"]),
      "lighting_confidence" =>
        first_number_or_scalar(activity, ["lighting_confidence", "lighting_confidence_label"])
    }
    |> compact_map()
  end

  defp temperature_c(activity) do
    first_number(activity, ["temperature_c", "temp_c"])
  end

  defp planned_temperature_c(activity) do
    first_number(activity, [
      "planned_temperature_c",
      "planned_temp_c",
      "predicted_temperature_c",
      "estimated_temperature_c"
    ])
  end

  defp actual_temperature_c(activity) do
    first_number(activity, [
      "actual_temperature_c",
      "actual_temp_c",
      "measured_temperature_c",
      "measured_temp_c"
    ])
  end

  defp min_operating_temperature_c(activity) do
    first_number(activity, [
      "min_operating_temperature_c",
      "minimum_operating_temperature_c",
      "min_temperature_c"
    ])
  end

  defp max_operating_temperature_c(activity) do
    first_number(activity, [
      "max_operating_temperature_c",
      "maximum_operating_temperature_c",
      "max_temperature_c"
    ])
  end

  defp thermal_margin_c(activity, observed_temperature_c) do
    first_number(activity, ["thermal_margin_c", "temperature_margin_c"]) ||
      derived_thermal_margin_c(
        observed_temperature_c,
        min_operating_temperature_c(activity),
        max_operating_temperature_c(activity)
      )
  end

  defp derived_thermal_margin_c(temperature_c, min_c, max_c)
       when is_number(temperature_c) and is_number(min_c) and is_number(max_c) do
    min(temperature_c - min_c, max_c - temperature_c)
  end

  defp derived_thermal_margin_c(temperature_c, nil, max_c)
       when is_number(temperature_c) and is_number(max_c),
       do: max_c - temperature_c

  defp derived_thermal_margin_c(temperature_c, min_c, nil)
       when is_number(temperature_c) and is_number(min_c),
       do: temperature_c - min_c

  defp derived_thermal_margin_c(_temperature_c, _min_c, _max_c), do: nil

  defp collection_ends_at_s(activity) do
    first_number(activity, [
      "collection_ends_at_s",
      "collection_end_s",
      "observation_ends_at_s",
      "observed_ends_at_s"
    ])
  end

  defp planned_delivery_at_s(activity) do
    first_number(activity, [
      "planned_delivery_at_s",
      "planned_delivered_at_s",
      "planned_downlink_at_s",
      "delivery_due_at_s"
    ])
  end

  defp actual_delivery_at_s(activity) do
    first_number(activity, [
      "actual_delivery_at_s",
      "actual_delivered_at_s",
      "delivered_at_s",
      "received_at_s",
      "actual_downlink_at_s"
    ])
  end

  defp max_latency_s(activity) do
    first_number(activity, [
      "max_latency_s",
      "required_latency_s",
      "target_latency_s"
    ])
  end

  defp planned_latency_s(activity, collection_ends_at_s, planned_delivery_at_s) do
    first_number(activity, ["planned_latency_s"]) ||
      delta(planned_delivery_at_s, collection_ends_at_s)
  end

  defp actual_latency_s(activity, collection_ends_at_s, actual_delivery_at_s) do
    first_number(activity, ["actual_latency_s"]) ||
      delta(actual_delivery_at_s, collection_ends_at_s)
  end

  defp planned_data_volume_mb(activity) do
    first_number(activity, [
      "planned_data_volume_mb",
      "data_volume_mb",
      "estimated_data_volume_mb",
      "estimated_storage_mb",
      "estimated_downlink_mb"
    ])
  end

  defp actual_data_volume_mb(activity) do
    first_number(activity, [
      "actual_data_volume_mb",
      "actual_storage_mb",
      "actual_downlink_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  defp activity_resource_context(activity) do
    %{
      "resource_id" => activity["resource_id"],
      "resource_source_quality" =>
        first_value(activity, ["resource_source_quality", "source_quality"]),
      "resource_trust_boundary" =>
        first_value(activity, ["resource_trust_boundary", "trust_boundary"]),
      "resource_trust_boundary_status" =>
        first_value(activity, ["resource_trust_boundary_status", "trust_boundary_status"]),
      "resource_provenance" => first_value(activity, ["resource_provenance", "provenance"]),
      "resource_blocking_dimension" => first_value(activity, ["resource_blocking_dimension"]),
      "fuel_margin" => first_number(activity, ["fuel_margin"]),
      "power_margin" => first_number(activity, ["power_margin"]),
      "storage_margin" => first_number(activity, ["storage_margin"]),
      "downlink_margin" => first_number(activity, ["downlink_margin"]),
      "battery_capacity_wh" => first_number(activity, ["battery_capacity_wh"]),
      "battery_energy_used_wh" => first_number(activity, ["battery_energy_used_wh"]),
      "battery_energy_generated_wh" =>
        first_number(activity, [
          "battery_energy_generated_wh",
          "energy_generated_wh",
          "estimated_energy_generated_wh",
          "estimated_battery_energy_generated_wh",
          "planned_energy_generated_wh",
          ["metadata", "battery_energy_generated_wh"],
          ["metadata", "energy_generated_wh"],
          ["metadata", "estimated_energy_generated_wh"],
          ["metadata", "estimated_battery_energy_generated_wh"],
          ["metadata", "planned_energy_generated_wh"]
        ]),
      "battery_state_of_charge" => first_number(activity, ["battery_state_of_charge"]),
      "spacecraft_available" => first_boolean(activity, ["spacecraft_available"]),
      "payload_available" => first_boolean(activity, ["payload_available"]),
      "antenna_available" => first_boolean(activity, ["antenna_available"]),
      "degraded" => first_boolean(activity, ["degraded"]),
      "mode" => first_value(activity, ["mode"]),
      "incompatible_activity_types" => first_value(activity, ["incompatible_activity_types"]),
      "suppressed_activity_types" => first_value(activity, ["suppressed_activity_types"])
    }
    |> compact_map()
  end

  defp activity_precondition_row_summary(activity) do
    preconditions =
      activity
      |> activity_precondition_rows()
      |> Enum.sort_by(&{&1["status"], &1["type"], &1["field"]})

    blocked = Enum.filter(preconditions, &(&1["status"] == "blocked"))
    review = Enum.filter(preconditions, &(&1["status"] == "review_required"))

    %{
      "precondition_status" => precondition_status(blocked, review),
      "blocked_precondition_count" => length(blocked),
      "review_precondition_count" => length(review),
      "blocked_precondition_types" => precondition_types(blocked),
      "review_precondition_types" => precondition_types(review),
      "preconditions" => preconditions
    }
  end

  defp activity_precondition_rows(activity) do
    []
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["spacecraft_available"]) == false,
      "spacecraft_unavailable",
      "blocked",
      "spacecraft_available",
      "spacecraft availability is explicitly false"
    )
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["payload_available"]) == false,
      "payload_unavailable",
      "blocked",
      "payload_available",
      "payload availability is explicitly false"
    )
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["antenna_available"]) == false,
      "antenna_unavailable",
      "blocked",
      "antenna_available",
      "antenna availability is explicitly false"
    )
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["degraded"]) == true,
      "degraded_mode",
      "review_required",
      "degraded",
      "activity is explicitly marked degraded"
    )
    |> maybe_add_activity_precondition(
      not is_nil(first_value(activity, ["resource_blocking_dimension"])),
      "resource_block_declared",
      "blocked",
      "resource_blocking_dimension",
      "resource blocking dimension is explicitly declared",
      encode_value(first_value(activity, ["resource_blocking_dimension"]))
    )
    |> maybe_add_depleted_margin_preconditions(activity)
    |> maybe_add_activity_type_membership_precondition(
      activity,
      first_value(activity, ["incompatible_activity_types"]),
      "activity_type_incompatible",
      "incompatible_activity_types",
      "activity type appears in incompatible activity types"
    )
    |> maybe_add_activity_type_membership_precondition(
      activity,
      first_value(activity, ["suppressed_activity_types"]),
      "activity_type_suppressed",
      "suppressed_activity_types",
      "activity type appears in suppressed activity types"
    )
    |> maybe_add_command_authority_precondition(activity)
    |> maybe_add_command_safety_preconditions(activity)
    |> add_activity_template_required_state_preconditions(activity)
  end

  defp maybe_add_command_authority_precondition(preconditions, activity) do
    case command_authority_precondition_evidence(activity) do
      nil ->
        preconditions

      {field, value, reason} ->
        maybe_add_activity_precondition(
          preconditions,
          true,
          "command_authority_missing",
          "review_required",
          field,
          reason,
          value
        )
    end
  end

  defp command_authority_precondition_evidence(activity) do
    authorized? =
      first_boolean(activity, ["command_authorized", "command_authorized?", "authority_granted"])

    status =
      activity
      |> first_scalar_string(["command_authority_status", "authority_status"])
      |> normalized_token()

    required_authority =
      first_scalar_string(activity, ["required_authority", "required_escalation_authority"])

    cond do
      authorized? == false ->
        {"command_authorized", false, "command authority is explicitly not granted"}

      status in [
        "missing",
        "authority_missing",
        "required",
        "operator_required",
        "review_required",
        "pending",
        "not_authorized",
        "unauthorized"
      ] ->
        {"command_authority_status",
         first_scalar_string(activity, ["command_authority_status", "authority_status"]),
         "command authority status requires operator review"}

      not is_nil(required_authority) and authorized? != true ->
        {"required_authority", required_authority, "required command authority is declared"}

      true ->
        nil
    end
  end

  defp maybe_add_command_safety_preconditions(preconditions, activity) do
    safety_status =
      activity
      |> first_scalar_string(["command_safety_status", "safety_status"])
      |> normalized_token()

    safety_checked? =
      first_boolean(activity, [
        "command_safety_checked",
        "command_safety_checked?",
        "safety_checked"
      ])

    preconditions
    |> maybe_add_activity_precondition(
      safety_status in ["failed", "fail", "unsafe", "blocked", "rejected"],
      "command_safety_failed",
      "blocked",
      "command_safety_status",
      "command safety status is explicitly unsafe or failed",
      first_scalar_string(activity, ["command_safety_status", "safety_status"])
    )
    |> maybe_add_activity_precondition(
      safety_checked? == false or
        safety_status in ["missing", "required", "unchecked", "not_checked", "pending"],
      "command_safety_unchecked",
      "review_required",
      if(safety_checked? == false, do: "command_safety_checked", else: "command_safety_status"),
      "command safety check requires review before command handoff",
      if(safety_checked? == false,
        do: false,
        else: first_scalar_string(activity, ["command_safety_status", "safety_status"])
      )
    )
  end

  defp add_activity_template_required_state_preconditions(preconditions, activity) do
    activity
    |> activity_template_required_states()
    |> Enum.reduce(preconditions, fn {index, %{"subsystem" => subsystem, "state" => state} = hint},
                                     rows ->
      maybe_add_activity_precondition(
        rows,
        true,
        "subsystem_state_required",
        "review_required",
        "activity_template.subsystem_state_hints.required_states[#{index}]",
        Map.get(hint, "reason") || "activity template declares required subsystem state",
        %{
          "subsystem" => subsystem,
          "state" => state,
          "blocking" => Map.get(hint, "blocking")
        }
        |> compact_map()
      )
    end)
  end

  defp activity_template_required_states(activity) do
    activity
    |> activity_template_required_state_sources()
    |> Enum.find_value([], fn template ->
      template
      |> get_in(["subsystem_state_hints", "required_states"])
      |> valid_required_state_hints()
      |> case do
        [] -> nil
        hints -> hints
      end
    end)
  end

  defp activity_template_required_state_sources(activity) do
    [
      activity_template_provenance(activity),
      activity_template_provenance(%{
        "activity_template" => get_in(activity, ["activity_context", "activity_template"])
      })
    ]
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  defp valid_required_state_hints(hints) when is_list(hints) do
    hints
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"subsystem" => subsystem, "state" => state} = hint, index}
      when is_binary(subsystem) and is_binary(state) ->
        [{index, hint}]

      _hint ->
        []
    end)
  end

  defp valid_required_state_hints(_hints), do: []

  defp maybe_add_depleted_margin_preconditions(preconditions, activity) do
    Enum.reduce(@unit_interval_activity_field_aliases, preconditions, fn {field, aliases}, rows ->
      maybe_add_activity_precondition(
        rows,
        first_number(activity, aliases) == 0.0,
        "#{field}_depleted",
        "blocked",
        field,
        "unit-interval resource margin is depleted",
        0.0
      )
    end)
  end

  defp maybe_add_activity_type_membership_precondition(
         preconditions,
         activity,
         activity_types,
         type,
         field,
         reason
       ) do
    activity_type = Map.get(activity, "type")
    activity_types = normalize_id_list(activity_types, []) || []

    maybe_add_activity_precondition(
      preconditions,
      activity_type in activity_types,
      type,
      "blocked",
      field,
      reason,
      activity_type
    )
  end

  defp maybe_add_activity_precondition(preconditions, false, _type, _status, _field, _reason),
    do: preconditions

  defp maybe_add_activity_precondition(preconditions, true, type, status, field, reason) do
    maybe_add_activity_precondition(preconditions, true, type, status, field, reason, nil)
  end

  defp maybe_add_activity_precondition(
         preconditions,
         false,
         _type,
         _status,
         _field,
         _reason,
         _value
       ),
       do: preconditions

  defp maybe_add_activity_precondition(preconditions, true, type, status, field, reason, value) do
    row =
      %{
        "type" => type,
        "status" => status,
        "field" => field,
        "reason" => reason,
        "value" => value
      }
      |> compact_map()

    [row | preconditions]
  end

  defp precondition_status([_blocked | _rest], _review), do: "blocked"
  defp precondition_status([], [_review | _rest]), do: "review_required"
  defp precondition_status([], []), do: "clear"

  defp precondition_types(preconditions) do
    preconditions
    |> Enum.map(& &1["type"])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp activity_throughput_context(activity) do
    planned = planned_estimated_throughput_mb(activity)
    derivation = actual_data_rate_throughput_derivation(activity)
    actual = actual_throughput_mb(activity) || get_in(derivation || %{}, ["actual_throughput_mb"])

    %{
      "planned_estimated_throughput_mb" => planned,
      "actual_throughput_mb" => actual,
      "actual_data_rate_throughput_derivation" => derivation,
      "throughput_delta_mb" => delta(actual, planned),
      "throughput_completion_fraction" => completion_fraction(actual, planned)
    }
    |> compact_map()
  end

  defp planned_estimated_throughput_mb(activity) do
    first_number(activity, [
      "planned_estimated_throughput_mb",
      "estimated_throughput_mb",
      "estimated_downlink_mb"
    ])
  end

  defp actual_throughput_mb(activity) do
    first_number(activity, [
      "actual_throughput_mb",
      "actual_downlink_mb",
      "delivered_throughput_mb",
      "received_throughput_mb"
    ])
  end

  defp actual_data_rate_throughput_derivation(activity) do
    cond do
      is_map(first_value(activity, ["actual_data_rate_throughput_derivation"])) ->
        activity
        |> first_value(["actual_data_rate_throughput_derivation"])
        |> stringify_keys()

      not is_nil(actual_throughput_mb(activity)) ->
        nil

      true ->
        derive_actual_data_rate_throughput(activity)
    end
  end

  defp derive_actual_data_rate_throughput(activity) do
    duration_s = actual_data_rate_duration_s(activity)

    cond do
      rate_mb_s = actual_data_rate_mb_s(activity) ->
        actual_data_rate_derivation("actual_data_rate_mb_s", rate_mb_s, duration_s)

      rate_mbps = actual_data_rate_mbps(activity) ->
        actual_data_rate_derivation("actual_data_rate_mbps", rate_mbps, duration_s)

      true ->
        nil
    end
  end

  defp actual_data_rate_derivation(_rate_unit, _rate, nil), do: nil

  defp actual_data_rate_derivation("actual_data_rate_mb_s", rate_mb_s, duration_s) do
    %{
      "derivation" => "actual_data_rate_times_duration",
      "rate_unit" => "MB/s",
      "actual_data_rate_mb_s" => rate_mb_s,
      "duration_s" => duration_s,
      "actual_throughput_mb" => rate_mb_s * duration_s
    }
  end

  defp actual_data_rate_derivation("actual_data_rate_mbps", rate_mbps, duration_s) do
    rate_mb_s = rate_mbps / 8.0

    %{
      "derivation" => "actual_data_rate_times_duration",
      "rate_unit" => "Mbps",
      "actual_data_rate_mbps" => rate_mbps,
      "actual_data_rate_mb_s" => rate_mb_s,
      "duration_s" => duration_s,
      "actual_throughput_mb" => rate_mb_s * duration_s
    }
  end

  defp actual_data_rate_mb_s(activity) do
    first_number(activity, [
      "actual_data_rate_mb_s",
      "actual_downlink_rate_mb_s",
      "delivered_rate_mb_s",
      "received_rate_mb_s"
    ])
  end

  defp actual_data_rate_mbps(activity) do
    first_number(activity, [
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      "delivered_rate_mbps",
      "received_rate_mbps"
    ])
  end

  defp actual_data_rate_duration_s(activity) do
    first_number(activity, [
      "actual_duration_s",
      "actual_contact_duration_s",
      "contact_duration_s"
    ])
  end

  defp activity_link_context(activity) do
    %{
      "link_protocol" => first_scalar_string(activity, ["link_protocol"]),
      "frequency_band" => first_scalar_string(activity, ["frequency_band", "rf_band"]),
      "modulation" => first_scalar_string(activity, ["modulation"]),
      "coding_scheme" => first_scalar_string(activity, ["coding_scheme"]),
      "polarization" => first_scalar_string(activity, ["polarization"]),
      "data_rate_mbps" => first_number(activity, ["data_rate_mbps"]),
      "downlink_rate_mbps" => first_number(activity, ["downlink_rate_mbps"]),
      "data_rate_mb_s" => first_number(activity, ["data_rate_mb_s"]),
      "downlink_rate_mb_s" => first_number(activity, ["downlink_rate_mb_s"]),
      "actual_data_rate_mbps" => first_number(activity, ["actual_data_rate_mbps"]),
      "actual_downlink_rate_mbps" => first_number(activity, ["actual_downlink_rate_mbps"]),
      "actual_data_rate_mb_s" => first_number(activity, ["actual_data_rate_mb_s"]),
      "actual_downlink_rate_mb_s" => first_number(activity, ["actual_downlink_rate_mb_s"]),
      "delivered_rate_mbps" => first_number(activity, ["delivered_rate_mbps"]),
      "received_rate_mbps" => first_number(activity, ["received_rate_mbps"]),
      "delivered_rate_mb_s" => first_number(activity, ["delivered_rate_mb_s"]),
      "received_rate_mb_s" => first_number(activity, ["received_rate_mb_s"]),
      "actual_duration_s" => first_number(activity, ["actual_duration_s"]),
      "actual_contact_duration_s" => first_number(activity, ["actual_contact_duration_s"]),
      "contact_duration_s" => first_number(activity, ["contact_duration_s"]),
      "link_margin_db" => first_number(activity, ["link_margin_db", "link_margin_d_b"]),
      "snr_db" => first_number(activity, ["snr_db"]),
      "eb_no_db" => first_number(activity, ["eb_no_db", "ebn0_db", "eb_no_d_b"]),
      "bit_error_rate" => first_number(activity, ["bit_error_rate", "ber"]),
      "packet_loss_rate" => first_number(activity, ["packet_loss_rate"]),
      "frame_loss_rate" => first_number(activity, ["frame_loss_rate"]),
      "carrier_lock" => first_boolean(activity, ["carrier_lock", "carrier_locked"]),
      "symbol_lock" => first_boolean(activity, ["symbol_lock", "symbol_locked"]),
      "link_quality_status" => first_scalar_string(activity, ["link_quality_status", "rf_status"])
    }
    |> compact_map()
  end

  defp activity_execution_uncertainty_context(activity) do
    uncertainty = activity_execution_uncertainty(activity)

    cond do
      is_map(uncertainty) ->
        uncertainty
        |> execution_uncertainty_fields()
        |> Map.merge(%{
          "execution_uncertainty_status" => "declared",
          "execution_uncertainty" => uncertainty
        })
        |> compact_map()

      execution_uncertainty_relevant?(activity) ->
        %{"execution_uncertainty_status" => "missing"}

      true ->
        %{}
    end
  end

  defp activity_execution_uncertainty(activity) do
    uncertainty =
      Map.get(activity, "execution_uncertainty") ||
        Map.get(activity, "maneuver_execution_uncertainty") ||
        get_in(activity, ["metadata", "execution_uncertainty"]) ||
        get_in(activity, ["metadata", "maneuver_execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "maneuver_execution_uncertainty"])

    case uncertainty do
      %{} = uncertainty -> normalize_execution_uncertainty(stringify_keys(uncertainty))
      _value -> nil
    end
  end

  defp execution_uncertainty_relevant?(%{"type" => "impulsive_burn"}), do: true
  defp execution_uncertainty_relevant?(_activity), do: false

  defp normalize_execution_uncertainty(%{} = uncertainty) do
    uncertainty
    |> normalize_uncertainty_number("timing_3sigma_s")
    |> normalize_uncertainty_triplet("delta_v_3sigma_km_s")
    |> normalize_uncertainty_number("delta_v_3sigma_magnitude_km_s")
  end

  defp normalize_uncertainty_number(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_value(value) do
          nil -> uncertainty
          number -> Map.put(uncertainty, key, number)
        end

      :error ->
        uncertainty
    end
  end

  defp normalize_uncertainty_triplet(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_triplet(value) do
          nil -> uncertainty
          triplet -> Map.put(uncertainty, key, triplet)
        end

      :error ->
        uncertainty
    end
  end

  defp execution_uncertainty_fields(uncertainty) do
    delta_v_3sigma_km_s = numeric_triplet(Map.get(uncertainty, "delta_v_3sigma_km_s"))

    %{
      "timing_3sigma_s" => numeric_value(Map.get(uncertainty, "timing_3sigma_s")),
      "delta_v_3sigma_km_s" => delta_v_3sigma_km_s,
      "delta_v_3sigma_magnitude_km_s" => vector_norm(delta_v_3sigma_km_s),
      "execution_uncertainty_source" =>
        Map.get(uncertainty, "source") || Map.get(uncertainty, "model")
    }
    |> compact_map()
  end

  defp activity_command_window_context(activity) do
    if command_window_context_relevant?(activity) do
      %{
        "command_window_id" => activity_command_window_id(activity),
        "command_window_type" => activity_command_window_type(activity)
      }
      |> compact_map()
    else
      %{}
    end
  end

  defp command_window_context_relevant?(activity) do
    activity["type"] in @command_window_activity_types or
      is_map(activity["command_window"]) or
      is_binary(activity["command_window_id"]) or
      is_binary(activity["command_window_type"]) or
      is_binary(activity["window_type"]) or
      is_binary(get_in(activity, ["metadata", "command_window_id"])) or
      is_binary(get_in(activity, ["metadata", "command_window_type"]))
  end

  defp activity_command_window_id(activity) do
    activity["command_window_id"] ||
      get_in(activity, ["command_window", "id"]) ||
      get_in(activity, ["metadata", "command_window_id"]) ||
      inferred_command_window_id(activity)
  end

  defp inferred_command_window_id(activity) do
    case activity_id(activity) do
      "" -> nil
      activity_id -> "command_window:#{activity_id}"
    end
  end

  defp activity_command_window_type(activity) do
    activity["command_window_type"] ||
      activity["window_type"] ||
      get_in(activity, ["command_window", "type"]) ||
      get_in(activity, ["command_window", "window_type"]) ||
      get_in(activity, ["metadata", "command_window_type"]) ||
      infer_command_window_type(activity)
  end

  defp infer_command_window_type(%{"type" => "command"}), do: "command_window"
  defp infer_command_window_type(%{"type" => "health_check"}), do: "health_check_window"
  defp infer_command_window_type(%{"type" => "tracking"}), do: "tracking_window"
  defp infer_command_window_type(%{"direction" => "tracking"}), do: "tracking_window"
  defp infer_command_window_type(%{"direction" => "uplink"}), do: "uplink_window"
  defp infer_command_window_type(%{"direction" => "command"}), do: "command_window"
  defp infer_command_window_type(_activity), do: "command_context_window"

  defp numeric_triplet([x, y, z]) do
    triplet = Enum.map([x, y, z], &numeric_value/1)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  defp numeric_triplet(_value), do: nil

  defp numeric_value(value) when is_number(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp first_numeric_value(values) do
    Enum.find_value(values, &numeric_value/1)
  end

  defp source_station_calendar_overlap_values(activity, field) do
    activity
    |> Map.get("source_station_calendar_overlaps")
    |> List.wrap()
    |> Enum.flat_map(fn
      %{} = overlap -> [Map.get(overlap, field)]
      _overlap -> []
    end)
  end

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&number_values/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

  defp number_values(%{} = value) do
    [
      Map.get(value, "station_calendar_reservation_expires_at_s"),
      Map.get(value, "station_reservation_expires_at_s"),
      Map.get(value, "reservation_expires_at_s")
    ]
    |> normalize_number_list()
    |> List.wrap()
  end

  defp number_values(values) when is_list(values), do: Enum.flat_map(values, &number_values/1)

  defp number_values(value) do
    case numeric_value(value) do
      nil -> []
      number -> [number]
    end
  end

  defp vector_norm(nil), do: nil

  defp vector_norm([x, y, z]) do
    :math.sqrt(x * x + y * y + z * z)
  end

  defp station_calendar_context(activity) do
    activity
    |> Map.take([
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_calendar_directions",
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
      "station_calendar_reservation_statuses"
    ])
    |> put_station_calendar_directions(activity)
    |> put_flattened_station_calendar_entry_id(activity)
    |> put_station_reservation_expiration_context(activity)
    |> normalize_station_calendar_id_lists()
    |> compact_map()
  end

  defp put_station_reservation_expiration_context(context, activity) do
    context
    |> put_station_reservation_expires_at_s(activity)
    |> put_station_calendar_reservation_expires_at_s(activity)
  end

  defp put_station_reservation_expires_at_s(context, activity) do
    case first_numeric_value([
           Map.get(context, "station_reservation_expires_at_s"),
           Map.get(activity, "reservation_expires_at_s"),
           get_in(activity, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
           get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"])
         ]) do
      nil -> context
      expires_at_s -> Map.put(context, "station_reservation_expires_at_s", expires_at_s)
    end
  end

  defp put_station_calendar_reservation_expires_at_s(context, activity) do
    expires_at_values =
      [
        Map.get(context, "station_calendar_reservation_expires_at_s"),
        Map.get(context, "station_reservation_expires_at_s"),
        get_in(activity, [
          "source_station_calendar_entry",
          "station_calendar_reservation_expires_at_s"
        ]),
        get_in(activity, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
        get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"]),
        source_station_calendar_overlap_values(
          activity,
          "station_calendar_reservation_expires_at_s"
        ),
        source_station_calendar_overlap_values(activity, "station_reservation_expires_at_s"),
        source_station_calendar_overlap_values(activity, "reservation_expires_at_s")
      ]
      |> normalize_number_list()

    case expires_at_values do
      nil -> context
      values -> Map.put(context, "station_calendar_reservation_expires_at_s", values)
    end
  end

  defp put_station_calendar_directions(context, activity) do
    directions =
      [
        Map.get(context, "station_calendar_directions"),
        get_in(activity, ["source_station_calendar_entry", "station_calendar_directions"]),
        get_in(activity, ["source_station_calendar_entry", "directions"]),
        get_in(activity, ["source_station_calendar_entry", "direction"])
      ]
      |> List.flatten()
      |> Enum.map(&normalize_station_calendar_direction/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    case directions do
      [] -> context
      directions -> Map.put(context, "station_calendar_directions", directions)
    end
  end

  defp normalize_station_calendar_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_station_calendar_direction(direction) do
    direction
    |> encode_value()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "cmd" -> "command"
      "commanding" -> "command"
      "commands" -> "command"
      "sband_command" -> "command"
      "s_band_command" -> "command"
      "uplink" -> "command"
      "up" -> "command"
      "up_link" -> "command"
      "dl" -> "downlink"
      "down" -> "downlink"
      "downlinking" -> "downlink"
      "down_link" -> "downlink"
      "track" -> "tracking"
      "track_ing" -> "tracking"
      "tracking_pass" -> "tracking"
      "health" -> "health_check"
      "health_check" -> "health_check"
      "healthcheck" -> "health_check"
      "health_check_window" -> "health_check"
      value when value in ["command", "downlink", "tracking", "health_check"] -> value
      _unknown -> nil
    end
  end

  defp put_flattened_station_calendar_entry_id(context, activity) do
    case first_stable_id([
           Map.get(context, "station_calendar_entry_id"),
           get_in(activity, ["source_station_calendar_entry", "station_calendar_entry_id"]),
           get_in(activity, ["source_station_calendar_entry", "id"])
         ]) do
      nil ->
        context

      station_calendar_entry_id ->
        Map.put(context, "station_calendar_entry_id", station_calendar_entry_id)
    end
  end

  defp first_stable_id(values) do
    values
    |> Enum.find_value(fn value ->
      case stable_id_value(value) do
        [id | _rest] -> id
        [] -> nil
      end
    end)
  end

  defp normalize_station_calendar_id_lists(context) do
    Enum.reduce(
      [
        "station_calendar_overlap_entry_ids",
        "station_calendar_ambiguous_entry_ids",
        "station_calendar_reservation_ids"
      ],
      context,
      fn field, acc ->
        case normalize_id_list(Map.get(acc, field), [
               "id",
               "station_calendar_entry_id",
               "station_reservation_id"
             ]) do
          nil -> Map.delete(acc, field)
          ids -> Map.put(acc, field, ids)
        end
      end
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
        lifecycle_state_summary_row(
          timeline_id,
          rank,
          Map.get(planned_by_timeline, timeline_id, []),
          Map.get(realized_by_timeline, timeline_id, [])
        )
      end)

    review_rows = Enum.filter(rows, &(&1["review_required"] == true))

    %{
      "schema_contract" => @lifecycle_state_summary_schema_contract,
      "model" => "artifact_only_timeline_lifecycle_state_summary",
      "source" => source,
      "validation_level" => "artifact_contract",
      "model_limits" => model_limits(),
      "planned_activity_count" => length(planned_rows),
      "realized_activity_count" => length(realized_rows),
      "row_count" => length(rows),
      "recordable_count" => Enum.count(rows, &(&1["transition_decision"] == "record")),
      "preserved_count" => Enum.count(rows, &(&1["transition_decision"] == "none")),
      "review_required_count" => length(review_rows),
      "duplicate_timeline_identity_count" =>
        Enum.count(rows, &(&1["timeline_identity_collision"] == true)),
      "invalid_activity_input_count" => Enum.count(rows, &(&1["invalid_activity_input"] == true)),
      "transition_decision_counts" => count_by(rows, "transition_decision"),
      "required_operator_action_counts" => count_by(rows, "required_operator_action"),
      "import_action_counts" => count_by(rows, "import_action"),
      "planned_status_category_counts" => count_by(rows, "planned_status_category"),
      "realized_status_category_counts" => count_by(rows, "realized_status_category"),
      "planned_approval_category_counts" => count_by(rows, "planned_approval_category"),
      "realized_approval_category_counts" => count_by(rows, "realized_approval_category"),
      "status_transition_category_counts" =>
        transition_category_counts(rows, "status_transition"),
      "approval_transition_category_counts" =>
        transition_category_counts(rows, "approval_transition"),
      "recordable_timeline_ids" =>
        lifecycle_state_timeline_ids(rows, &(&1["transition_decision"] == "record")),
      "preserved_timeline_ids" =>
        lifecycle_state_timeline_ids(rows, &(&1["transition_decision"] == "none")),
      "review_timeline_ids" => lifecycle_state_timeline_ids(review_rows, fn _row -> true end),
      "review_activity_ids" => lifecycle_state_activity_ids(review_rows),
      "invalid_activity_input_ids" =>
        lifecycle_state_activity_ids(Enum.filter(rows, &(&1["invalid_activity_input"] == true))),
      "review_timeline_ids_by_required_operator_action" =>
        timeline_ids_by(
          review_rows,
          & &1["required_operator_action"],
          &(&1["review_required"] == true)
        ),
      "review_timeline_ids_by_status_transition_category" =>
        timeline_ids_by(
          review_rows,
          &get_in(&1, ["status_transition", "transition_category"]),
          &(&1["review_required"] == true)
        ),
      "review_timeline_ids_by_approval_transition_category" =>
        timeline_ids_by(
          review_rows,
          &get_in(&1, ["approval_transition", "transition_category"]),
          &(&1["review_required"] == true)
        ),
      "rows" => rows,
      "review_rows" => review_rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "cadence_import" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "identity_match" => "planned and realized rows are paired by timeline identity"
      }
    }
    |> compact_map()
  end

  def lifecycle_state_summary(_planned_activities, _realized_activities, _opts),
    do: raise(ArgumentError, "planned and realized activities must be lists")

  defp lifecycle_state_input_groups(activities) do
    rows =
      activities
      |> Enum.with_index(1)
      |> Enum.map(&lifecycle_state_input_row/1)

    {rows, Enum.group_by(rows, &lifecycle_state_row_timeline_id/1)}
  end

  defp lifecycle_state_input_row({activity, sequence}) do
    case activity_input_to_map(activity, sequence) do
      {:ok, activity} -> activity_to_map(activity)
      {:error, row} -> row
    end
  end

  defp lifecycle_state_row_timeline_id(row) do
    row["timeline_id"] || get_in(row, ["timeline_identity", "timeline_id"]) ||
      activity_timeline_id(row)
  end

  defp lifecycle_state_summary_row(timeline_id, rank, planned_matches, realized_matches) do
    cond do
      length(planned_matches) > 1 or length(realized_matches) > 1 ->
        duplicate_lifecycle_state_summary_row(
          timeline_id,
          rank,
          planned_matches,
          realized_matches
        )

      Enum.any?(planned_matches ++ realized_matches, &(&1["invalid_activity_input"] == true)) ->
        invalid_lifecycle_state_summary_row(timeline_id, rank, planned_matches, realized_matches)

      true ->
        planned_activity = List.first(planned_matches)
        realized_activity = List.first(realized_matches)

        planned_activity
        |> activity_lifecycle_state(realized_activity)
        |> Map.put("rank", rank)
    end
  end

  defp duplicate_lifecycle_state_summary_row(
         timeline_id,
         rank,
         planned_matches,
         realized_matches
       ) do
    %{
      "rank" => rank,
      "timeline_id" => timeline_id,
      "planned_activity_ids" => lifecycle_state_match_activity_ids(planned_matches),
      "realized_activity_ids" => lifecycle_state_match_activity_ids(realized_matches),
      "planned_duplicate_activity_count" => duplicate_match_count(planned_matches),
      "realized_duplicate_activity_count" => duplicate_match_count(realized_matches),
      "timeline_identity_collision" => true,
      "transition_decision" => "review",
      "review_required" => true,
      "required_operator_action" => "review_duplicate_timeline_identity",
      "required_operator_actions" => ["review_duplicate_timeline_identity"],
      "operator_action_reasons" => ["duplicate_timeline_identity"],
      "import_action" => "review_timeline_diff",
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

  defp invalid_lifecycle_state_summary_row(timeline_id, rank, planned_matches, realized_matches) do
    invalid_rows =
      Enum.filter(planned_matches ++ realized_matches, &(&1["invalid_activity_input"] == true))

    %{
      "rank" => rank,
      "timeline_id" => timeline_id,
      "planned_activity_ids" => lifecycle_state_match_activity_ids(planned_matches),
      "realized_activity_ids" => lifecycle_state_match_activity_ids(realized_matches),
      "invalid_activity_input" => true,
      "invalid_activity_input_count" => length(invalid_rows),
      "invalid_activity_input_reasons" =>
        invalid_rows
        |> Enum.map(& &1["invalid_activity_input_reason"])
        |> sorted_uniq(),
      "transition_decision" => "review",
      "review_required" => true,
      "required_operator_action" => "review_invalid_activity_input",
      "required_operator_actions" => ["review_invalid_activity_input"],
      "operator_action_reasons" =>
        invalid_rows
        |> Enum.map(& &1["invalid_activity_input_reason"])
        |> sorted_uniq(),
      "import_action" => "review_timeline_diff",
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

  defp duplicate_match_count(matches) when length(matches) > 1, do: length(matches)
  defp duplicate_match_count(_matches), do: 0

  defp lifecycle_state_match_activity_ids(matches) do
    matches
    |> Enum.map(&(Map.get(&1, "id") || Map.get(&1, "activity_id")))
    |> sorted_uniq()
  end

  defp lifecycle_state_timeline_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(& &1["timeline_id"])
    |> sorted_uniq()
  end

  defp lifecycle_state_activity_ids(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["activity_id"],
        row["planned_activity_id"],
        row["realized_activity_id"]
        | list_value(row, "planned_activity_ids") ++ list_value(row, "realized_activity_ids")
      ]
    end)
    |> sorted_uniq()
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
    source_activities = if is_nil(source_activity), do: [], else: [source_activity]
    replacement_activities = if is_nil(replacement_activity), do: [], else: [replacement_activity]

    source_activities
    |> transition_decision_report(replacement_activities, opts)
    |> summarize_transition_decision_rows()
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
  end

  def transition_application_report(_source_activities, _replacement_activities, _opts),
    do: raise(ArgumentError, "source and replacement activities must be lists")

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
    rows
    |> Enum.filter(&(&1["protection_decision"] == decision))
    |> Enum.map(& &1[field])
    |> sorted_uniq()
  end

  defp protection_category_activity_ids(rows) do
    protection_id_sets_by_field(rows, "protection_category", "activity_id")
  end

  defp protection_id_sets_by_field(rows, group_field, id_field) do
    rows
    |> Enum.reject(&(is_nil(&1[group_field]) or is_nil(&1[id_field])))
    |> Enum.group_by(& &1[group_field], & &1[id_field])
    |> Enum.sort_by(fn {group, _ids} -> group end)
    |> Map.new(fn {group, ids} -> {group, sorted_uniq(ids)} end)
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

  defp preservation_status_from_counts(_preserve_count, review_count) when review_count > 0,
    do: "review_required"

  defp preservation_status_from_counts(preserve_count, _review_count) when preserve_count > 0,
    do: "preservation_required"

  defp preservation_status_from_counts(_preserve_count, _review_count), do: "clear"

  defp transition_decision_report([], [], _opts) do
    %{"rows" => []}
  end

  defp transition_decision_report(source_activities, replacement_activities, opts) do
    diff_report(source_activities, replacement_activities, opts)
  end

  defp summarize_transition_decision_rows(%{"rows" => []}) do
    %{
      "transition_decision" => "none",
      "transition_decision_reason" => "no_source_or_replacement_activity",
      "diff_status" => "unchanged",
      "requires_operator_review" => false,
      "changed_fields" => []
    }
  end

  defp summarize_transition_decision_rows(%{"rows" => [row]}) do
    row
    |> Map.take([
      "timeline_id",
      "diff_status",
      "transition_decision",
      "transition_decision_reason",
      "requires_operator_review",
      "required_operator_action",
      "reason",
      "changed_fields",
      "status_transition",
      "approval_transition",
      "source_activity_id",
      "replacement_activity_id",
      "source_activity_type",
      "replacement_activity_type",
      "source_status",
      "replacement_status",
      "source_approval_status",
      "replacement_approval_status",
      "source_locked",
      "replacement_locked",
      "source_protection_decision",
      "replacement_protection_decision",
      "source_timeline_identity",
      "replacement_timeline_identity"
    ])
    |> compact_map()
  end

  defp summarize_transition_decision_rows(%{"rows" => rows}) when is_list(rows) do
    %{
      "transition_decision" => "review",
      "transition_decision_reason" => "activity_transition_changes_timeline_identity",
      "diff_status" => "changed",
      "requires_operator_review" => true,
      "required_operator_action" => "review_activity_transition",
      "changed_fields" => ["timeline_identity"],
      "transition_row_count" => length(rows),
      "transition_rows" => Enum.map(rows, &summarize_transition_decision_rows(%{"rows" => [&1]}))
    }
  end

  defp transition_application_activity(nil, _opts), do: nil

  defp transition_application_activity(activity, opts) do
    normalize_activity(activity, opts)
  end

  defp maybe_gate_single_transition_selected_activity(
         %{"selected_activity" => %{} = selected_activity} = application,
         opts
       ) do
    [selected_activity]
    |> annotate_transition_selected_activities(opts)
    |> case do
      [%{} = selected_with_integrity] ->
        application
        |> Map.put("selected_activity", selected_with_integrity)
        |> maybe_gate_selected_activity_integrity(selected_with_integrity)

      _other ->
        application
    end
  end

  defp maybe_gate_single_transition_selected_activity(application, _opts), do: application

  defp maybe_validate_transition_helper_selected_integrity(activity, opts) do
    if Keyword.get(opts, :validate_selected_integrity?, false) do
      activity
      |> List.wrap()
      |> annotate_transition_selected_activities(opts)
      |> case do
        [%{} = selected_with_integrity] ->
          if timeline_integrity_review?(selected_with_integrity) do
            {:error, transition_helper_selected_integrity_error(selected_with_integrity)}
          else
            {:ok, selected_with_integrity}
          end

        _other ->
          {:ok, activity}
      end
    else
      {:ok, activity}
    end
  end

  defp transition_helper_selected_integrity_error(selected_activity) do
    %{
      "field" => "timeline_integrity",
      "transition_category" => "selected_timeline_integrity_review_required",
      "requires_operator_review" => true,
      "required_operator_action" => "review_timeline_integrity",
      "operator_action_reason" =>
        selected_integrity_reason(list_value(selected_activity, "timeline_integrity_issue_types"))
    }
    |> Map.merge(selected_integrity_context(selected_activity))
    |> compact_map()
  end

  defp raise_transition_activity_status_error(%{"field" => "timeline_integrity"} = transition) do
    raise ArgumentError,
          "unsafe timeline activity selected integrity: #{transition["operator_action_reason"]}"
  end

  defp raise_transition_activity_status_error(transition) do
    raise ArgumentError,
          "unsafe timeline activity status transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
  end

  defp raise_transition_activity_approval_status_error(
         %{"field" => "timeline_integrity"} = transition
       ) do
    raise ArgumentError,
          "unsafe timeline activity selected integrity: #{transition["operator_action_reason"]}"
  end

  defp raise_transition_activity_approval_status_error(transition) do
    raise ArgumentError,
          "unsafe timeline activity approval transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
  end

  defp raise_apply_lifecycle_event_error(%{"field" => "timeline_integrity"} = transition) do
    raise ArgumentError,
          "unsafe timeline activity selected integrity: #{transition["operator_action_reason"]}"
  end

  defp raise_apply_lifecycle_event_error(transition) do
    raise ArgumentError,
          "unsafe timeline activity lifecycle event #{transition["field"]} transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
  end

  defp maybe_gate_single_transition_decision_integrity(
         %{"transition_decision" => decision} = transition_decision,
         source_activity,
         replacement_activity,
         opts
       ) do
    source = transition_application_activity(source_activity, opts)
    replacement = transition_application_activity(replacement_activity, opts)

    decision
    |> transition_application_selection(source, replacement)
    |> Map.get("selected_activity")
    |> case do
      %{} = selected_activity ->
        selected_activity
        |> List.wrap()
        |> annotate_transition_selected_activities(opts)
        |> case do
          [%{} = selected_with_integrity] ->
            maybe_gate_transition_decision_integrity(
              transition_decision,
              selected_with_integrity
            )

          _other ->
            transition_decision
        end

      _other ->
        transition_decision
    end
  end

  defp maybe_gate_single_transition_decision_integrity(
         transition_decision,
         _source_activity,
         _replacement_activity,
         _opts
       ),
       do: transition_decision

  defp maybe_gate_transition_decision_integrity(transition_decision, selected_activity) do
    if timeline_integrity_review?(selected_activity) do
      issue_types = list_value(selected_activity, "timeline_integrity_issue_types")
      reason = selected_integrity_reason(issue_types)

      transition_decision
      |> Map.put("transition_decision", "review")
      |> Map.put("transition_decision_reason", reason)
      |> Map.put("requires_operator_review", true)
      |> Map.put("required_operator_action", "review_timeline_integrity")
      |> Map.merge(selected_integrity_context(selected_activity))
      |> Map.update("reason", reason, fn current_reason ->
        if current_reason in [nil, "no_timeline_change"], do: reason, else: current_reason
      end)
      |> compact_map()
    else
      transition_decision
    end
  end

  defp annotate_transition_selected_activities(selected_activities, opts) do
    validate_selected_dependencies? = Keyword.get(opts, :validate_selected_dependencies?, true)

    annotate_timeline_integrity_rows(selected_activities, validate_selected_dependencies?)
  end

  defp put_transition_selected_activity_integrity(applications, selected_activities) do
    selected_by_timeline_id = Map.new(selected_activities, &{&1["timeline_id"], &1})

    Enum.map(applications, fn application ->
      case Map.get(application, "selected_activity") do
        %{} = selected ->
          case Map.get(selected_by_timeline_id, selected["timeline_id"]) do
            nil ->
              application

            selected_with_integrity ->
              application
              |> Map.put("selected_activity", selected_with_integrity)
              |> maybe_gate_selected_activity_integrity(selected_with_integrity)
          end

        _other ->
          application
      end
    end)
  end

  defp maybe_gate_selected_activity_integrity(application, selected_activity) do
    if timeline_integrity_review?(selected_activity) do
      issue_types = list_value(selected_activity, "timeline_integrity_issue_types")

      application
      |> Map.put("requires_operator_review", true)
      |> put_selected_integrity_review_action()
      |> put_selected_integrity_application_status()
      |> Map.merge(selected_integrity_context(selected_activity))
      |> Map.update("reason", selected_integrity_reason(issue_types), fn reason ->
        if reason in [nil, "no_timeline_change"],
          do: selected_integrity_reason(issue_types),
          else: reason
      end)
      |> compact_map()
    else
      application
    end
  end

  defp selected_integrity_context(selected_activity) do
    %{
      "selected_timeline_integrity_status" => selected_activity["timeline_integrity_status"],
      "selected_timeline_integrity_issue_count" =>
        selected_activity["timeline_integrity_issue_count"],
      "selected_timeline_integrity_issue_types" =>
        list_value(selected_activity, "timeline_integrity_issue_types"),
      "selected_timeline_integrity_issues" => selected_activity["timeline_integrity_issues"],
      "selected_missing_dependency_activity_ids" =>
        selected_activity["missing_dependency_activity_ids"],
      "selected_missing_dependency_timeline_ids" =>
        selected_activity["missing_dependency_timeline_ids"],
      "selected_self_dependency_activity_ids" =>
        selected_activity["self_dependency_activity_ids"],
      "selected_self_dependency_timeline_ids" =>
        selected_activity["self_dependency_timeline_ids"],
      "selected_duplicate_dependency_activity_ids" =>
        selected_activity["duplicate_dependency_activity_ids"],
      "selected_duplicate_dependency_timeline_ids" =>
        selected_activity["duplicate_dependency_timeline_ids"],
      "selected_duplicate_exclusivity_activity_ids" =>
        selected_activity["duplicate_exclusivity_activity_ids"],
      "selected_duplicate_exclusivity_timeline_ids" =>
        selected_activity["duplicate_exclusivity_timeline_ids"],
      "selected_dependency_cycle_activity_ids" =>
        selected_activity["dependency_cycle_activity_ids"],
      "selected_dependency_cycle_timeline_ids" =>
        selected_activity["dependency_cycle_timeline_ids"],
      "selected_dependency_order_violation_activity_ids" =>
        selected_activity["dependency_order_violation_activity_ids"],
      "selected_dependency_order_violation_timeline_ids" =>
        selected_activity["dependency_order_violation_timeline_ids"],
      "selected_exclusivity_violation_activity_ids" =>
        selected_activity["exclusivity_violation_activity_ids"],
      "selected_exclusivity_violation_timeline_ids" =>
        selected_activity["exclusivity_violation_timeline_ids"]
    }
  end

  defp put_selected_integrity_review_action(%{"required_operator_action" => action} = application)
       when action in ["none", "record_timeline_change", nil] do
    Map.put(application, "required_operator_action", "review_timeline_integrity")
  end

  defp put_selected_integrity_review_action(application), do: application

  defp put_selected_integrity_application_status(%{"application_status" => status} = application)
       when status in ["source_unchanged", "replacement_unchanged", "replacement_recorded"] do
    Map.put(application, "application_status", "selected_timeline_integrity_review_required")
  end

  defp put_selected_integrity_application_status(application), do: application

  defp selected_integrity_reason([]), do: "selected_timeline_integrity_issue_requires_review"

  defp selected_integrity_reason(issue_types) do
    "selected_timeline_integrity_issue_requires_review:#{Enum.join(issue_types, ",")}"
  end

  defp transition_application_selection("preserve_source", source, _replacement)
       when is_map(source) do
    %{
      "application_status" => "source_preserved_pending_review",
      "selected_activity_source" => "source",
      "selected_activity" => source
    }
    |> maybe_put_selected_transition_application_provenance(source)
  end

  defp transition_application_selection("record", _source, replacement)
       when is_map(replacement) do
    %{
      "application_status" => "replacement_recorded",
      "selected_activity_source" => "replacement",
      "selected_activity" => replacement
    }
    |> maybe_put_selected_transition_application_provenance(replacement)
  end

  defp transition_application_selection("none", source, _replacement) when is_map(source) do
    %{
      "application_status" => "source_unchanged",
      "selected_activity_source" => "source",
      "selected_activity" => source
    }
    |> maybe_put_selected_transition_application_provenance(source)
  end

  defp transition_application_selection("none", _source, replacement)
       when is_map(replacement) do
    %{
      "application_status" => "replacement_unchanged",
      "selected_activity_source" => "replacement",
      "selected_activity" => replacement
    }
    |> maybe_put_selected_transition_application_provenance(replacement)
  end

  defp transition_application_selection("none", _source, _replacement) do
    %{"application_status" => "no_activity"}
  end

  defp transition_application_selection("review", _source, _replacement) do
    %{"application_status" => "operator_review_required"}
  end

  defp transition_application_selection(_decision, _source, _replacement) do
    %{"application_status" => "operator_review_required"}
  end

  defp put_transition_application_provenance(activity, helper, field, transition) do
    Map.put(
      activity,
      "transition_application_provenance",
      transition_application_provenance(helper, field, transition)
    )
  end

  defp transition_application_provenance(helper, field, nil) do
    %{
      "helper" => helper,
      "field" => field,
      "transition_type" => "unchanged",
      "requires_operator_review" => false,
      "operator_action_reason" => transition_application_no_change_reason(field)
    }
  end

  defp transition_application_provenance(helper, field, transition) when is_map(transition) do
    transition
    |> Map.take([
      "field",
      "transition_type",
      "from",
      "to",
      "transition_category",
      "requires_operator_review",
      "operator_action_reason"
    ])
    |> Map.put("helper", helper)
    |> Map.put_new("field", field)
    |> Map.put_new("requires_operator_review", false)
    |> compact_map()
  end

  defp transition_application_no_change_reason("approval_status"), do: "no_approval_status_change"
  defp transition_application_no_change_reason(_field), do: "no_status_change"

  defp lifecycle_event_replacement_activity!(source_activity, event) do
    case timeline_lifecycle_event!(event) do
      "approve" ->
        source_activity
        |> Map.put("approval_status", "approved")
        |> maybe_put_lifecycle_status_unless_preserved("approved")

      "reject" ->
        Map.put(source_activity, "approval_status", "rejected")

      "lock" ->
        source_activity
        |> Map.put("approval_status", "locked")
        |> Map.put("locked", true)
        |> maybe_put_lifecycle_status_unless_preserved("locked")

      "start_execution" ->
        Map.put(source_activity, "status", "executing")

      "record_execution" ->
        Map.put(source_activity, "status", "executed")

      "record_completion" ->
        Map.put(source_activity, "status", "completed")

      "record_partial" ->
        Map.put(source_activity, "status", "partial")

      "record_failure" ->
        Map.put(source_activity, "status", "failed")

      "record_miss" ->
        Map.put(source_activity, "status", "missed")

      "delay" ->
        Map.put(source_activity, "status", "delayed")

      "cancel" ->
        Map.put(source_activity, "status", "canceled")
    end
  end

  defp lifecycle_event_review_transition(status_transition, approval_transition) do
    Enum.find([status_transition, approval_transition], &transition_requires_operator_review?/1)
  end

  defp lifecycle_event_provenance_field(status_transition, approval_transition) do
    cond do
      is_map(status_transition) -> "status"
      is_map(approval_transition) -> "approval_status"
      true -> "lifecycle_event"
    end
  end

  defp lifecycle_event_provenance_transition(status_transition, approval_transition) do
    status_transition || approval_transition
  end

  defp maybe_preserve_transition_application_provenance(row, activity) do
    case Map.get(activity, "transition_application_provenance") do
      %{} = provenance -> Map.put(row, "transition_application_provenance", provenance)
      _other -> row
    end
  end

  defp maybe_put_selected_transition_application_provenance(application, selected_activity) do
    case Map.get(selected_activity, "transition_application_provenance") do
      %{} = provenance -> Map.put(application, "transition_application_provenance", provenance)
      _other -> application
    end
  end

  defp normalized_activity_groups(activities, opts) do
    activities
    |> normalize_activities(opts)
    |> Enum.group_by(& &1["timeline_id"])
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
    case Map.get(groups, timeline_id, []) do
      [activity] -> activity
      _duplicates_or_missing -> nil
    end
  end

  defp rows_by_timeline_id(rows) do
    rows
    |> Enum.group_by(& &1["timeline_id"])
    |> Map.new(fn {timeline_id, matches} ->
      {timeline_id, Enum.sort_by(matches, & &1["activity_id"])}
    end)
  end

  defp duplicate_group_count(groups) do
    groups
    |> Map.values()
    |> Enum.count(&(length(&1) > 1))
  end

  defp duplicate_activity_count(groups) do
    groups
    |> Map.values()
    |> Enum.filter(&(length(&1) > 1))
    |> Enum.map(&length/1)
    |> Enum.sum()
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map()
  end

  defp changed_field_counts(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "changed_fields"))
    |> Enum.frequencies()
    |> sort_count_map()
  end

  defp transition_counts(rows, field) do
    rows
    |> Enum.map(&get_in(&1, [field, "transition_type"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map()
  end

  defp transition_category_counts(rows, field) do
    rows
    |> Enum.map(&get_in(&1, [field, "transition_category"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map()
  end

  defp sort_count_map(counts) do
    counts
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp annotate_duplicate_timeline_identity_rows(rows) do
    duplicate_by_timeline =
      rows
      |> rows_by_timeline_id()
      |> Map.filter(fn {_timeline_id, matches} -> length(matches) > 1 end)

    Enum.map(rows, fn row ->
      case Map.get(duplicate_by_timeline, row["timeline_id"]) do
        nil ->
          row

        matches ->
          annotate_duplicate_timeline_identity_row(row, matches)
      end
    end)
  end

  defp annotate_duplicate_timeline_identity_row(row, matches) do
    activity_ids = Enum.map(matches, & &1["activity_id"])

    row
    |> Map.merge(%{
      "timeline_identity_collision" => true,
      "duplicate_timeline_identity_activity_count" => length(matches),
      "duplicate_timeline_identity_activity_ids" => activity_ids,
      "duplicate_timeline_identity_activities" => matches,
      "superseded_required_operator_action" => row["required_operator_action"],
      "superseded_operator_action_reason" => row["operator_action_reason"],
      "required_operator_action" => "review_duplicate_timeline_identity",
      "operator_action_reason" => "duplicate_timeline_identity_collision"
    })
    |> compact_map()
  end

  defp annotate_timeline_integrity_rows(rows, validate_missing_dependencies?) do
    by_activity_id = Map.new(rows, &{&1["activity_id"], &1})
    by_timeline_id = Map.new(rows, &{&1["timeline_id"], &1})
    by_activity_dependency = dependency_graph(rows, "activity_id", "dependency_activity_ids")
    by_timeline_dependency = dependency_graph(rows, "timeline_id", "dependency_timeline_ids")

    rows
    |> Enum.map(fn row ->
      issues =
        timeline_integrity_issues(
          row,
          rows,
          by_activity_id,
          by_timeline_id,
          by_activity_dependency,
          by_timeline_dependency,
          validate_missing_dependencies?
        )

      annotate_timeline_integrity_row(row, issues)
    end)
  end

  defp timeline_integrity_issues(
         row,
         rows,
         by_activity_id,
         by_timeline_id,
         by_activity_dependency,
         by_timeline_dependency,
         validate_missing_dependencies?
       ) do
    dependency_integrity_issues(
      row,
      by_activity_id,
      by_timeline_id,
      by_activity_dependency,
      by_timeline_dependency,
      validate_missing_dependencies?
    ) ++
      exclusivity_integrity_issues(row, rows, by_activity_id, by_timeline_id)
  end

  defp annotate_timeline_integrity_row(row, []), do: row

  defp annotate_timeline_integrity_row(row, issues) do
    issue_types = issues |> Enum.map(& &1["type"]) |> Enum.uniq() |> Enum.sort()

    fields =
      %{
        "timeline_integrity_status" => "review_required",
        "timeline_integrity_issue_count" => length(issues),
        "timeline_integrity_issue_types" => issue_types,
        "timeline_integrity_issues" => issues,
        "missing_dependency_activity_ids" => issue_ids(issues, "missing_dependency_activity_id"),
        "missing_dependency_timeline_ids" => issue_ids(issues, "missing_dependency_timeline_id"),
        "self_dependency_activity_ids" => issue_ids(issues, "self_dependency_activity_id"),
        "self_dependency_timeline_ids" => issue_ids(issues, "self_dependency_timeline_id"),
        "duplicate_dependency_activity_ids" =>
          issue_ids(issues, "duplicate_dependency_activity_id"),
        "duplicate_dependency_timeline_ids" =>
          issue_ids(issues, "duplicate_dependency_timeline_id"),
        "duplicate_exclusivity_activity_ids" =>
          issue_ids(issues, "duplicate_exclusivity_activity_id"),
        "duplicate_exclusivity_timeline_ids" =>
          issue_ids(issues, "duplicate_exclusivity_timeline_id"),
        "dependency_cycle_activity_ids" => issue_ids(issues, "dependency_cycle_activity_id"),
        "dependency_cycle_timeline_ids" => issue_ids(issues, "dependency_cycle_timeline_id"),
        "dependency_order_violation_activity_ids" =>
          issue_ids(issues, "dependency_order_violation_activity_id"),
        "dependency_order_violation_timeline_ids" =>
          issue_ids(issues, "dependency_order_violation_timeline_id"),
        "exclusivity_violation_activity_ids" =>
          issue_ids(issues, "exclusivity_violation_activity_id"),
        "exclusivity_violation_timeline_ids" =>
          issue_ids(issues, "exclusivity_violation_timeline_id"),
        "exclusivity_violation_group" => issue_value(issues, "exclusivity_violation_group")
      }
      |> compact_map()

    row
    |> maybe_supersede_for_timeline_integrity()
    |> Map.merge(fields)
  end

  defp maybe_supersede_for_timeline_integrity(
         %{"required_operator_action" => "review_duplicate_timeline_identity"} = row
       ) do
    row
  end

  defp maybe_supersede_for_timeline_integrity(row) do
    row
    |> Map.put_new("superseded_required_operator_action", row["required_operator_action"])
    |> Map.put_new("superseded_operator_action_reason", row["operator_action_reason"])
    |> Map.put("required_operator_action", "review_timeline_integrity")
    |> Map.put("operator_action_reason", "timeline_integrity_issue")
  end

  defp dependency_integrity_issues(
         row,
         by_activity_id,
         by_timeline_id,
         by_activity_dependency,
         by_timeline_dependency,
         validate_missing_dependencies?
       ) do
    activity_dependency_issues(
      row,
      by_activity_id,
      by_activity_dependency,
      validate_missing_dependencies?
    ) ++
      timeline_dependency_issues(
        row,
        by_timeline_id,
        by_timeline_dependency,
        validate_missing_dependencies?
      )
  end

  defp activity_dependency_issues(
         row,
         by_activity_id,
         by_activity_dependency,
         validate_missing_dependencies?
       ) do
    duplicate_reference_issues(
      row,
      "duplicate_dependency_activity_ids",
      "duplicate_dependency_activity",
      "duplicate_dependency_activity_id"
    ) ++
      (row
       |> list_value("dependency_activity_ids")
       |> Enum.flat_map(fn dependency_id ->
         cond do
           dependency_id == row["activity_id"] ->
             [
               issue("self_dependency_activity", %{
                 "self_dependency_activity_id" => dependency_id
               })
             ]

           validate_missing_dependencies? and not Map.has_key?(by_activity_id, dependency_id) ->
             [
               issue("missing_dependency_activity", %{
                 "missing_dependency_activity_id" => dependency_id
               })
             ]

           dependency_cycle?(by_activity_dependency, dependency_id, row["activity_id"]) ->
             [
               issue("dependency_cycle", %{
                 "dependency_cycle_activity_id" => dependency_id
               })
             ]

           Map.has_key?(by_activity_id, dependency_id) and
               dependency_order_violation?(Map.fetch!(by_activity_id, dependency_id), row) ->
             [
               issue("dependency_order_violation", %{
                 "dependency_order_violation_activity_id" => dependency_id
               })
             ]

           true ->
             []
         end
       end))
  end

  defp timeline_dependency_issues(
         row,
         by_timeline_id,
         by_timeline_dependency,
         validate_missing_dependencies?
       ) do
    duplicate_reference_issues(
      row,
      "duplicate_dependency_timeline_ids",
      "duplicate_dependency_timeline",
      "duplicate_dependency_timeline_id"
    ) ++
      (row
       |> list_value("dependency_timeline_ids")
       |> Enum.flat_map(fn dependency_id ->
         cond do
           dependency_id == row["timeline_id"] ->
             [
               issue("self_dependency_timeline", %{
                 "self_dependency_timeline_id" => dependency_id
               })
             ]

           validate_missing_dependencies? and not Map.has_key?(by_timeline_id, dependency_id) ->
             [
               issue("missing_dependency_timeline", %{
                 "missing_dependency_timeline_id" => dependency_id
               })
             ]

           dependency_cycle?(by_timeline_dependency, dependency_id, row["timeline_id"]) ->
             [
               issue("dependency_cycle", %{
                 "dependency_cycle_timeline_id" => dependency_id
               })
             ]

           Map.has_key?(by_timeline_id, dependency_id) and
               dependency_order_violation?(Map.fetch!(by_timeline_id, dependency_id), row) ->
             [
               issue("dependency_order_violation", %{
                 "dependency_order_violation_timeline_id" => dependency_id
               })
             ]

           true ->
             []
         end
       end))
  end

  defp dependency_graph(rows, id_field, dependency_field) do
    Map.new(rows, fn row ->
      {row[id_field], list_value(row, dependency_field)}
    end)
  end

  defp dependency_cycle?(_graph, nil, _target_id), do: false
  defp dependency_cycle?(_graph, dependency_id, dependency_id), do: false

  defp dependency_cycle?(graph, dependency_id, target_id) do
    dependency_path?(graph, dependency_id, target_id, MapSet.new())
  end

  defp dependency_path?(_graph, current_id, current_id, _visited), do: true

  defp dependency_path?(graph, current_id, target_id, visited) do
    cond do
      is_nil(current_id) or is_nil(target_id) ->
        false

      MapSet.member?(visited, current_id) ->
        false

      true ->
        graph
        |> Map.get(current_id, [])
        |> Enum.any?(&dependency_path?(graph, &1, target_id, MapSet.put(visited, current_id)))
    end
  end

  defp exclusivity_integrity_issues(row, rows, by_activity_id, by_timeline_id) do
    explicit_activity_exclusivity_issues(row, by_activity_id) ++
      explicit_timeline_exclusivity_issues(row, by_timeline_id) ++
      exclusivity_group_issues(row, rows)
  end

  defp explicit_activity_exclusivity_issues(row, by_activity_id) do
    duplicate_reference_issues(
      row,
      "duplicate_exclusivity_activity_ids",
      "duplicate_exclusivity_activity",
      "duplicate_exclusivity_activity_id"
    ) ++
      (row
       |> list_value("exclusive_with_activity_ids")
       |> Enum.flat_map(fn exclusive_id ->
         case Map.get(by_activity_id, exclusive_id) do
           nil ->
             []

           other ->
             if overlap?(row, other) do
               [
                 issue("exclusivity_overlap", %{
                   "exclusivity_violation_activity_id" => exclusive_id,
                   "exclusivity_violation_timeline_id" => other["timeline_id"]
                 })
               ]
             else
               []
             end
         end
       end))
  end

  defp explicit_timeline_exclusivity_issues(row, by_timeline_id) do
    duplicate_reference_issues(
      row,
      "duplicate_exclusivity_timeline_ids",
      "duplicate_exclusivity_timeline",
      "duplicate_exclusivity_timeline_id"
    ) ++
      (row
       |> list_value("exclusive_with_timeline_ids")
       |> Enum.flat_map(fn exclusive_id ->
         case Map.get(by_timeline_id, exclusive_id) do
           nil ->
             []

           other ->
             if overlap?(row, other) do
               [
                 issue("exclusivity_overlap", %{
                   "exclusivity_violation_activity_id" => other["activity_id"],
                   "exclusivity_violation_timeline_id" => exclusive_id
                 })
               ]
             else
               []
             end
         end
       end))
  end

  defp duplicate_reference_issues(row, row_field, issue_type, issue_field) do
    row
    |> list_value(row_field)
    |> Enum.map(fn duplicate_id ->
      issue(issue_type, %{issue_field => duplicate_id})
    end)
  end

  defp exclusivity_group_issues(row, rows) do
    case row["exclusivity_group"] || get_in(row, ["activity_context", "exclusivity_group"]) do
      nil ->
        []

      group ->
        rows
        |> Enum.reject(&(&1["activity_id"] == row["activity_id"]))
        |> Enum.filter(
          &((Map.get(&1, "exclusivity_group") ||
               get_in(&1, ["activity_context", "exclusivity_group"])) == group)
        )
        |> Enum.filter(&overlap?(row, &1))
        |> Enum.map(fn other ->
          issue("exclusivity_group_overlap", %{
            "exclusivity_violation_activity_id" => other["activity_id"],
            "exclusivity_violation_timeline_id" => other["timeline_id"],
            "exclusivity_violation_group" => group
          })
        end)
    end
  end

  defp dependency_order_violation?(dependency, row) do
    is_number(dependency["ends_at_s"]) and is_number(row["starts_at_s"]) and
      dependency["ends_at_s"] > row["starts_at_s"]
  end

  defp overlap?(left, right) do
    is_number(left["starts_at_s"]) and is_number(left["ends_at_s"]) and
      is_number(right["starts_at_s"]) and is_number(right["ends_at_s"]) and
      left["starts_at_s"] < right["ends_at_s"] and right["starts_at_s"] < left["ends_at_s"]
  end

  defp issue(type, fields), do: Map.put(fields, "type", type)

  defp issue_ids(issues, field) do
    issues
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp issue_value(issues, field) do
    issues
    |> Enum.find_value(&Map.get(&1, field))
  end

  defp timeline_diff_row(timeline_id, rank, source_matches, replacement_matches)
       when is_list(source_matches) and is_list(replacement_matches) and
              (length(source_matches) > 1 or length(replacement_matches) > 1) do
    source_activity_ids = Enum.map(source_matches, & &1["activity_id"])
    replacement_activity_ids = Enum.map(replacement_matches, & &1["activity_id"])

    %{
      "id" => "timeline_diff:#{timeline_id}:duplicate_identity",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => "changed",
      "changed_fields" => ["timeline_identity_collision"],
      "timeline_identity_collision" => true,
      "duplicate_timeline_identity_scope" =>
        duplicate_timeline_identity_scope(source_matches, replacement_matches),
      "source_duplicate_activity_count" => length(source_matches),
      "replacement_duplicate_activity_count" => length(replacement_matches),
      "source_duplicate_activity_ids" => source_activity_ids,
      "replacement_duplicate_activity_ids" => replacement_activity_ids,
      "source_duplicate_activities" => source_matches,
      "replacement_duplicate_activities" => replacement_matches,
      "scenario_id" => first_present(source_matches ++ replacement_matches, "scenario_id"),
      "source_activity_id" => List.first(source_activity_ids),
      "replacement_activity_id" => List.first(replacement_activity_ids),
      "source_activity_type" => first_present(source_matches, "activity_type"),
      "replacement_activity_type" => first_present(replacement_matches, "activity_type"),
      "source_spacecraft_id" => first_present(source_matches, "spacecraft_id"),
      "replacement_spacecraft_id" => first_present(replacement_matches, "spacecraft_id"),
      "source_ground_station_id" => first_present(source_matches, "ground_station_id"),
      "replacement_ground_station_id" => first_present(replacement_matches, "ground_station_id"),
      "source_target_id" => first_present(source_matches, "target_id"),
      "replacement_target_id" => first_present(replacement_matches, "target_id"),
      "source_source_window_id" => first_present(source_matches, "source_window_id"),
      "replacement_source_window_id" => first_present(replacement_matches, "source_window_id"),
      "requires_operator_review" => true,
      "required_operator_action" => "review_duplicate_timeline_identity",
      "reason" =>
        "timeline identity #{timeline_id} matches #{length(source_matches)} source and #{length(replacement_matches)} replacement activities",
      "source_timeline_identity" => first_present(source_matches, "timeline_identity"),
      "replacement_timeline_identity" => first_present(replacement_matches, "timeline_identity")
    }
    |> Map.merge(diff_dependency_context("source", first_row(source_matches)))
    |> Map.merge(diff_dependency_context("replacement", first_row(replacement_matches)))
    |> Map.merge(diff_schedule_context("source", first_row(source_matches)))
    |> Map.merge(diff_schedule_context("replacement", first_row(replacement_matches)))
    |> Map.merge(diff_protection_context("source", first_row(source_matches)))
    |> Map.merge(diff_protection_context("replacement", first_row(replacement_matches)))
    |> compact_map()
  end

  defp timeline_diff_row(timeline_id, rank, [], [replacement]) do
    {required_operator_action, reason} = added_activity_review(replacement)

    %{
      "id" => "timeline_diff:#{timeline_id}",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => "added",
      "replacement_activity_id" => replacement["activity_id"],
      "replacement_activity_type" => replacement["activity_type"],
      "replacement_spacecraft_id" => replacement["spacecraft_id"],
      "replacement_ground_station_id" => replacement["ground_station_id"],
      "replacement_target_id" => replacement["target_id"],
      "replacement_source_window_id" => replacement["source_window_id"],
      "scenario_id" => replacement["scenario_id"],
      "replacement_starts_at_s" => replacement["starts_at_s"],
      "replacement_ends_at_s" => replacement["ends_at_s"],
      "replacement_status" => replacement["status"],
      "replacement_approval_status" => replacement["approval_status"],
      "replacement_locked" => replacement["locked"],
      "status_transition" => status_transition(nil, replacement),
      "approval_transition" => approval_transition(nil, replacement),
      "changed_fields" => ["timeline_presence"],
      "requires_operator_review" => true,
      "required_operator_action" => required_operator_action,
      "reason" => reason,
      "replacement_activity_context" => diff_activity_context(replacement),
      "replacement_timeline_identity" => replacement["timeline_identity"]
    }
    |> Map.merge(diff_dependency_context("replacement", replacement))
    |> Map.merge(diff_schedule_context("replacement", replacement))
    |> Map.merge(diff_protection_context("replacement", replacement))
    |> Map.merge(diff_invalid_activity_input_context("replacement", replacement))
    |> compact_map()
  end

  defp timeline_diff_row(timeline_id, rank, [source], []) do
    {required_operator_action, reason} = removed_activity_review(source)

    %{
      "id" => "timeline_diff:#{timeline_id}",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => "removed",
      "source_activity_id" => source["activity_id"],
      "source_activity_type" => source["activity_type"],
      "source_spacecraft_id" => source["spacecraft_id"],
      "source_ground_station_id" => source["ground_station_id"],
      "source_target_id" => source["target_id"],
      "source_source_window_id" => source["source_window_id"],
      "scenario_id" => source["scenario_id"],
      "source_starts_at_s" => source["starts_at_s"],
      "source_ends_at_s" => source["ends_at_s"],
      "source_status" => source["status"],
      "source_approval_status" => source["approval_status"],
      "source_locked" => source["locked"],
      "status_transition" => status_transition(source, nil),
      "approval_transition" => approval_transition(source, nil),
      "changed_fields" => ["timeline_presence"],
      "requires_operator_review" => true,
      "required_operator_action" => required_operator_action,
      "reason" => reason,
      "source_activity_context" => diff_activity_context(source),
      "source_timeline_identity" => source["timeline_identity"]
    }
    |> Map.merge(diff_dependency_context("source", source))
    |> Map.merge(diff_schedule_context("source", source))
    |> Map.merge(diff_protection_context("source", source))
    |> Map.merge(diff_invalid_activity_input_context("source", source))
    |> compact_map()
  end

  defp timeline_diff_row(timeline_id, rank, [source], [replacement]) do
    changed_fields = changed_fields(source, replacement)
    diff_status = if changed_fields == [], do: "unchanged", else: "changed"
    status_transition = status_transition(source, replacement)
    approval_transition = approval_transition(source, replacement)

    integrity_review? =
      timeline_integrity_review?(source) or timeline_integrity_review?(replacement)

    helper_application? =
      not preservation_sensitive_source?(source) and
        safe_transition_application_provenance?(
          replacement,
          status_transition,
          approval_transition,
          changed_fields
        )

    requires_review =
      integrity_review? or
        (diff_status == "changed" and
           not helper_application? and
           (review_significant_change?(changed_fields) or preservation_sensitive_source?(source)))

    {required_operator_action, reason} =
      if integrity_review? do
        {"review_timeline_integrity", diff_timeline_integrity_reason(source, replacement)}
      else
        changed_activity_review(diff_status, requires_review, source, replacement, changed_fields)
      end

    %{
      "id" => "timeline_diff:#{timeline_id}",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => diff_status,
      "source_activity_id" => source["activity_id"],
      "replacement_activity_id" => replacement["activity_id"],
      "source_activity_type" => source["activity_type"],
      "replacement_activity_type" => replacement["activity_type"],
      "source_spacecraft_id" => source["spacecraft_id"],
      "replacement_spacecraft_id" => replacement["spacecraft_id"],
      "source_ground_station_id" => source["ground_station_id"],
      "replacement_ground_station_id" => replacement["ground_station_id"],
      "source_target_id" => source["target_id"],
      "replacement_target_id" => replacement["target_id"],
      "source_source_window_id" => source["source_window_id"],
      "replacement_source_window_id" => replacement["source_window_id"],
      "scenario_id" => replacement["scenario_id"] || source["scenario_id"],
      "source_starts_at_s" => source["starts_at_s"],
      "source_ends_at_s" => source["ends_at_s"],
      "replacement_starts_at_s" => replacement["starts_at_s"],
      "replacement_ends_at_s" => replacement["ends_at_s"],
      "start_delta_s" => delta(replacement["starts_at_s"], source["starts_at_s"]),
      "end_delta_s" => delta(replacement["ends_at_s"], source["ends_at_s"]),
      "source_status" => source["status"],
      "replacement_status" => replacement["status"],
      "source_approval_status" => source["approval_status"],
      "replacement_approval_status" => replacement["approval_status"],
      "source_locked" => source["locked"],
      "replacement_locked" => replacement["locked"],
      "status_transition" => status_transition,
      "approval_transition" => approval_transition,
      "changed_fields" => changed_fields,
      "requires_operator_review" => requires_review,
      "required_operator_action" => required_operator_action,
      "reason" => reason,
      "operator_action_reason" =>
        diff_transition_operator_action_reason(status_transition, approval_transition),
      "source_activity_context" => diff_activity_context(source),
      "replacement_activity_context" => diff_activity_context(replacement),
      "source_timeline_identity" => source["timeline_identity"],
      "replacement_timeline_identity" => replacement["timeline_identity"]
    }
    |> Map.merge(diff_dependency_context("source", source))
    |> Map.merge(diff_dependency_context("replacement", replacement))
    |> Map.merge(diff_schedule_context("source", source))
    |> Map.merge(diff_schedule_context("replacement", replacement))
    |> Map.merge(diff_protection_context("source", source))
    |> Map.merge(diff_protection_context("replacement", replacement))
    |> Map.merge(diff_invalid_activity_input_context("source", source))
    |> Map.merge(diff_invalid_activity_input_context("replacement", replacement))
    |> compact_map()
  end

  defp added_activity_review(%{"invalid_activity_input" => true} = replacement) do
    {
      "review_invalid_activity_input",
      "replacement timeline includes invalid activity input #{replacement["activity_id"]}: #{replacement["invalid_activity_input_reason"]}"
    }
  end

  defp added_activity_review(replacement) do
    {
      "review_added_activity",
      "replacement timeline adds activity #{replacement["activity_id"]}"
    }
  end

  defp removed_activity_review(%{"invalid_activity_input" => true} = source) do
    {
      "review_invalid_activity_input",
      "source timeline includes invalid activity input #{source["activity_id"]}: #{source["invalid_activity_input_reason"]}"
    }
  end

  defp removed_activity_review(%{"status" => status} = source)
       when status in @executed_statuses do
    {
      "review_removed_executed_activity",
      "replacement timeline removes executed activity #{source["activity_id"]}"
    }
  end

  defp removed_activity_review(source) do
    cond do
      source["locked"] ->
        {
          "review_removed_protected_activity",
          "replacement timeline removes locked activity #{source["activity_id"]}"
        }

      source["approval_status"] in @protected_approval_statuses ->
        {
          "review_removed_protected_activity",
          "replacement timeline removes approved activity #{source["activity_id"]}"
        }

      true ->
        {
          "review_removed_activity",
          "replacement timeline removes activity #{source["activity_id"]}"
        }
    end
  end

  defp changed_activity_review("unchanged", _requires_review, source, replacement, changed_fields) do
    {
      diff_required_operator_action("unchanged", false),
      diff_reason("unchanged", source, replacement, changed_fields)
    }
  end

  defp changed_activity_review(
         "changed",
         true,
         %{"status" => status} = source,
         _replacement,
         changed_fields
       )
       when status in @executed_statuses do
    {
      "review_changed_executed_activity",
      "replacement timeline changes executed activity #{source["activity_id"]}: #{Enum.join(changed_fields, ",")}"
    }
  end

  defp changed_activity_review("changed", true, source, replacement, changed_fields) do
    cond do
      source["locked"] ->
        {
          "review_changed_protected_activity",
          "replacement timeline changes locked activity #{source["activity_id"]}: #{Enum.join(changed_fields, ",")}"
        }

      approval_protected?(source) ->
        {
          "review_changed_protected_activity",
          "replacement timeline changes approved activity #{source["activity_id"]}: #{Enum.join(changed_fields, ",")}"
        }

      true ->
        {
          diff_required_operator_action("changed", true),
          diff_reason("changed", source, replacement, changed_fields)
        }
    end
  end

  defp changed_activity_review("changed", false, source, replacement, changed_fields) do
    {
      diff_required_operator_action("changed", false),
      diff_reason("changed", source, replacement, changed_fields)
    }
  end

  defp safe_transition_application_provenance?(
         replacement,
         status_transition,
         approval_transition,
         changed_fields
       ) do
    case transition_application_provenance_from_activity(replacement) do
      %{"helper" => "transition_activity_status"} = provenance ->
        safe_transition_application_provenance_field?(
          provenance,
          "status",
          status_transition,
          changed_fields
        )

      %{"helper" => "transition_activity_approval_status"} = provenance ->
        safe_transition_application_provenance_field?(
          provenance,
          "approval_status",
          approval_transition,
          changed_fields
        )

      %{"helper" => "apply_lifecycle_event"} = provenance ->
        safe_lifecycle_event_transition_application_provenance?(
          provenance,
          status_transition,
          approval_transition,
          changed_fields
        )

      _other ->
        false
    end
  end

  defp safe_transition_application_provenance_field?(
         provenance,
         field,
         transition,
         changed_fields
       )
       when is_map(transition) do
    changed_fields == [field] and
      safe_transition_application_provenance_values?(provenance, field, transition)
  end

  defp safe_transition_application_provenance_field?(
         _provenance,
         _field,
         _transition,
         _changed_fields
       ),
       do: false

  defp safe_transition_application_provenance_values?(provenance, field, transition)
       when is_map(transition) do
    provenance["field"] == field and
      provenance["transition_type"] == transition["transition_type"] and
      provenance["from"] == transition["from"] and
      provenance["to"] == transition["to"] and
      provenance["transition_category"] == transition["transition_category"] and
      provenance["operator_action_reason"] == transition["operator_action_reason"] and
      provenance["requires_operator_review"] == false and
      transition["requires_operator_review"] == false
  end

  defp safe_lifecycle_event_transition_application_provenance?(
         provenance,
         status_transition,
         approval_transition,
         changed_fields
       ) do
    not transition_requires_operator_review?(status_transition) and
      not transition_requires_operator_review?(approval_transition) and
      lifecycle_event_provenance_matches_transition?(
        provenance,
        status_transition,
        approval_transition,
        changed_fields
      )
  end

  defp lifecycle_event_provenance_matches_transition?(
         provenance,
         %{} = status_transition,
         _approval_transition,
         changed_fields
       ) do
    changed_fields == ["status"] and
      safe_transition_application_provenance_values?(provenance, "status", status_transition)
  end

  defp lifecycle_event_provenance_matches_transition?(
         provenance,
         _status_transition,
         %{} = approval_transition,
         changed_fields
       ) do
    changed_fields == ["approval_status"] and
      safe_transition_application_provenance_values?(
        provenance,
        "approval_status",
        approval_transition
      )
  end

  defp lifecycle_event_provenance_matches_transition?(provenance, nil, nil, changed_fields) do
    changed_fields == [] and
      provenance["field"] == "lifecycle_event" and
      provenance["requires_operator_review"] == false
  end

  defp transition_application_provenance_from_activity(%{
         "transition_application_provenance" => %{} = provenance
       }),
       do: provenance

  defp transition_application_provenance_from_activity(%{
         "activity_context" => %{"transition_application_provenance" => %{} = provenance}
       }),
       do: provenance

  defp transition_application_provenance_from_activity(_activity), do: nil

  defp diff_transition_operator_action_reason(
         %{"requires_operator_review" => true, "operator_action_reason" => reason},
         _approval_transition
       )
       when is_binary(reason) and reason != "",
       do: reason

  defp diff_transition_operator_action_reason(
         _status_transition,
         %{"requires_operator_review" => true, "operator_action_reason" => reason}
       )
       when is_binary(reason) and reason != "",
       do: reason

  defp diff_transition_operator_action_reason(_status_transition, _approval_transition), do: nil

  defp put_transition_decision(row) do
    {decision, reason} = transition_decision_for_diff_row(row)

    row
    |> Map.put("transition_decision", decision)
    |> Map.put("transition_decision_reason", reason)
  end

  defp diff_timeline_integrity_reason(source, replacement) do
    source? = timeline_integrity_review?(source)
    replacement? = timeline_integrity_review?(replacement)

    cond do
      source? and replacement? ->
        "source and replacement timeline activities require integrity review"

      source? ->
        "source timeline activity requires integrity review"

      replacement? ->
        "replacement timeline activity requires integrity review"
    end
  end

  defp transition_decision_for_diff_row(%{
         "diff_status" => "unchanged",
         "requires_operator_review" => false
       }) do
    {"none", "timeline_unchanged"}
  end

  defp transition_decision_for_diff_row(%{
         "diff_status" => diff_status,
         "source_protection_decision" => %{"protection_decision" => "preserve"} = protection
       })
       when diff_status in ["changed", "removed"] do
    {"preserve_source", Map.get(protection, "reason", "source_activity_requires_preservation")}
  end

  defp transition_decision_for_diff_row(%{"requires_operator_review" => true} = row) do
    {"review", row["operator_action_reason"] || row["reason"] || "operator_review_required"}
  end

  defp transition_decision_for_diff_row(%{"diff_status" => "changed"} = row) do
    {"record", row["operator_action_reason"] || row["reason"] || "record_timeline_change"}
  end

  defp transition_decision_for_diff_row(row) do
    {"review", row["operator_action_reason"] || row["reason"] || "operator_review_required"}
  end

  defp diff_activity_context(row) do
    Map.get(row, "activity_context") ||
      row
      |> Map.put("id", row["activity_id"])
      |> activity_context()
  end

  defp first_row([row | _rows]), do: row
  defp first_row([]), do: %{}

  defp first_present(rows, field) do
    Enum.find_value(rows, &Map.get(&1, field))
  end

  defp duplicate_timeline_identity_scope(source_matches, replacement_matches) do
    case {length(source_matches) > 1, length(replacement_matches) > 1} do
      {true, true} -> "source_and_replacement"
      {true, false} -> "source"
      {false, true} -> "replacement"
      {false, false} -> "none"
    end
  end

  def contact_timeline_row?(row) do
    row["activity_type"] in ["downlink", "planned_contact", "tracking"] ||
      is_binary(row["ground_station_id"])
  end

  def command_timeline_row?(row) do
    row["activity_type"] in @command_health_activity_types ||
      row["direction"] in @command_contact_directions
  end

  defp operational_kind(%{"type" => "command"}), do: "command"
  defp operational_kind(%{"type" => "health_check"}), do: "health_check"
  defp operational_kind(%{"type" => "observe"}), do: "observation"
  defp operational_kind(%{"type" => "impulsive_burn"}), do: "maneuver"
  defp operational_kind(%{"type" => "slew"}), do: "attitude"
  defp operational_kind(%{"type" => "attitude"}), do: "attitude"
  defp operational_kind(%{"type" => "coast"}), do: "coast"

  defp operational_kind(%{"direction" => direction})
       when direction in @command_contact_directions,
       do: "command"

  defp operational_kind(%{"type" => type})
       when type in ["downlink", "planned_contact", "contact", "tracking"] do
    "contact"
  end

  defp operational_kind(%{"ground_station_id" => ground_station_id})
       when is_binary(ground_station_id) and ground_station_id != "" do
    "contact"
  end

  defp operational_kind(_activity), do: "activity"

  defp cadence_import_status(activity, operational_kind) do
    cond do
      invalid_cadence_import?(activity) ->
        "invalid"

      is_map(Map.get(activity, "cadence_import")) ->
        "present"

      operational_kind in ["contact", "command"] ->
        "missing"

      true ->
        "not_applicable"
    end
  end

  defp required_operator_action(activity, operational_kind, cadence_import_status) do
    status = activity_status(activity)
    approval_status = activity_approval_status(activity)
    conflict_status = activity_schedule_conflict_status(activity)
    provider_failure_reason = provider_execution_failure_reason(activity, operational_kind)

    cond do
      status in @terminal_exception_statuses ->
        {"review_terminal_activity_exception", "activity_status_#{status}_requires_review"}

      is_binary(provider_failure_reason) ->
        {"review_terminal_activity_exception", provider_failure_reason}

      status == "blocked_by_policy" ->
        {"resolve_blocked_activity", "activity_status_blocked_by_policy"}

      approval_status == "rejected" ->
        {"resolve_rejected_activity", "approval_status_rejected"}

      approval_status == "blocked_by_policy" ->
        {"resolve_blocked_activity", "approval_status_blocked_by_policy"}

      status in @executed_statuses ->
        {"none_terminal_activity", "activity_status_terminal"}

      conflict_status in ["conflicted", "conflict", "overlap"] ->
        {"resolve_contact_conflict", "schedule_conflict_status_#{conflict_status}"}

      cadence_import_status == "invalid" ->
        {"review_invalid_cadence_import",
         cadence_import_issue(Map.get(activity, "cadence_import")) ||
           "cadence_import_invalid_shape"}

      command_review_required?(activity, operational_kind, approval_status) ->
        {"review_command_contact", "command_boundary_requires_review"}

      approval_status in ["pending", "operator_review_required", "not_evaluated"] ->
        {"review_activity_approval", "approval_status_#{approval_status}"}

      cadence_import_status == "missing" ->
        {"prepare_cadence_import", "cadence_import_missing"}

      activity_locked?(activity) ->
        {"none_locked_activity", "activity_locked"}

      true ->
        {"monitor_activity", "no_operator_action_required"}
    end
  end

  defp command_review_required?(_activity, operational_kind, approval_status) do
    operational_kind == "command" and
      approval_status not in ["approved", "auto_approvable", "locked"]
  end

  defp provider_execution_failure_reason(activity, "contact") do
    cond do
      provider_result_failure?(Map.get(activity, "contact_result")) ->
        "contact_result_#{provider_result_failure_token(activity["contact_result"])}_requires_review"

      Map.get(activity, "contact_success") == false ->
        "contact_success_false_requires_review"

      true ->
        nil
    end
  end

  defp provider_execution_failure_reason(activity, kind)
       when kind in ["command", "health_check"] do
    cond do
      provider_result_failure?(Map.get(activity, "command_result")) ->
        "command_result_#{provider_result_failure_token(activity["command_result"])}_requires_review"

      Map.get(activity, "command_success") == false ->
        "command_success_false_requires_review"

      provider_result_failure?(Map.get(activity, "contact_result")) ->
        "contact_result_#{provider_result_failure_token(activity["contact_result"])}_requires_review"

      Map.get(activity, "contact_success") == false ->
        "contact_success_false_requires_review"

      true ->
        nil
    end
  end

  defp provider_execution_failure_reason(_activity, _kind), do: nil

  defp provider_result_failure?(result) do
    result
    |> provider_result_outcomes()
    |> Enum.member?(:failure)
  end

  defp provider_result_failure_token(result) do
    result
    |> provider_result_values()
    |> Enum.find_value(fn token ->
      normalized = provider_result_token(token)
      if provider_result_token_outcome(normalized) == :failure, do: normalized
    end) || "failure"
  end

  defp provider_result_outcomes(result) do
    result
    |> provider_result_values()
    |> Enum.map(&provider_result_token/1)
    |> Enum.map(&provider_result_token_outcome/1)
    |> Enum.reject(&(&1 == :unknown))
  end

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp provider_result_token(token) when is_binary(token) do
    token
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp provider_result_token_outcome(value)
       when value in [
              "rejected",
              "failed",
              "failure",
              "timeout",
              "timed_out",
              "aborted",
              "error",
              "dropped",
              "lost",
              "missed",
              "canceled",
              "cancelled",
              "no_contact"
            ],
       do: :failure

  defp provider_result_token_outcome(value)
       when value in [
              "accepted",
              "acknowledged",
              "completed",
              "executed",
              "succeeded",
              "success",
              "ok",
              "acquired",
              "established",
              "delivered"
            ],
       do: :success

  defp provider_result_token_outcome(_value), do: :unknown

  defp cadence_import(%{"cadence_import" => cadence_import} = activity)
       when is_map(cadence_import) do
    if invalid_cadence_import?(activity), do: %{}, else: cadence_import
  end

  defp cadence_import(_activity), do: %{}

  defp invalid_cadence_import?(%{"cadence_import" => cadence_import}),
    do: cadence_import_issue(cadence_import) != nil

  defp invalid_cadence_import?(_activity), do: false

  defp invalid_cadence_import_context(%{"cadence_import" => cadence_import})
       when not is_map(cadence_import) do
    %{
      "invalid_cadence_import" => true,
      "invalid_cadence_import_reason" => "cadence_import_must_be_object",
      "source_cadence_import" => %{"invalid_import_shape" => encode_value(cadence_import)}
    }
  end

  defp invalid_cadence_import_context(%{"cadence_import" => cadence_import})
       when is_map(cadence_import) do
    case cadence_import_issue(cadence_import) do
      nil ->
        %{}

      reason ->
        %{
          "invalid_cadence_import" => true,
          "invalid_cadence_import_reason" => reason,
          "source_cadence_import" => cadence_import
        }
    end
  end

  defp invalid_cadence_import_context(_activity), do: %{}

  defp cadence_import_issue(cadence_import) when not is_map(cadence_import),
    do: "cadence_import_must_be_object"

  defp cadence_import_issue(cadence_import) do
    cond do
      cadence_import_external_id_issue?(cadence_import) ->
        "invalid_cadence_import_external_id"

      cadence_import_adapter_context?(cadence_import) and
          missing_cadence_import_trust_boundary?(cadence_import) ->
        "missing_cadence_import_trust_boundary"

      true ->
        nil
    end
  end

  defp cadence_import_external_id_issue?(cadence_import) do
    case Map.get(cadence_import, "external_id") do
      value when value in [nil, ""] -> false
      value when is_binary(value) -> not stable_activity_id?(value)
      _value -> true
    end
  end

  defp cadence_import_adapter_context?(cadence_import) do
    Enum.any?(["provider", "adapter", "adapter_version"], &Map.has_key?(cadence_import, &1))
  end

  defp missing_cadence_import_trust_boundary?(cadence_import) do
    case Map.get(cadence_import, "trust_boundary") ||
           get_in(cadence_import, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" -> false
      _value -> true
    end
  end

  defp drop_invalid_activity_context_cadence_import(context, activity) do
    if invalid_cadence_import?(activity), do: Map.delete(context, "cadence_import"), else: context
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
    activity
    |> put_new_present("id", Map.get(activity, "activity_id"))
    |> put_new_present("type", Map.get(activity, "activity_type"))
  end

  defp normalize_source_window(%{"source_window" => %{} = source_window} = activity) do
    activity
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", Map.get(activity, "source_window_kind"))
    |> put_new_present("source_window_type", get_in(activity, ["metadata", "source_window_kind"]))
  end

  defp normalize_source_window(
         %{"metadata" => %{"source_window" => %{} = source_window}} = activity
       ) do
    activity
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", get_in(activity, ["metadata", "source_window_kind"]))
  end

  defp normalize_source_window(activity) do
    activity
    |> put_new_present("source_window_type", Map.get(activity, "source_window_kind"))
    |> put_new_present("source_window_type", get_in(activity, ["metadata", "source_window_kind"]))
  end

  defp source_window_id_value(%{} = source_window) do
    Map.get(source_window, "id") || Map.get(source_window, "window_id")
  end

  defp source_window_type_value(%{} = source_window) do
    Map.get(source_window, "type") || Map.get(source_window, "kind") ||
      Map.get(source_window, "window_type")
  end

  defp put_new_present(activity, _key, value) when value in [nil, ""], do: activity

  defp put_new_present(activity, key, value) do
    Map.put_new(activity, key, value)
  end

  defp normalize_cadence_import(%{"cadence_import" => %{} = cadence_import} = activity) do
    Map.put(activity, "cadence_import", canonical_cadence_import(cadence_import))
  end

  defp normalize_cadence_import(activity), do: activity

  defp canonical_cadence_import(cadence_import) do
    cadence_import
    |> Map.drop(cadence_import_alias_keys())
    |> put_new_present(
      "external_id",
      first_present_cadence_import_value(cadence_import, [
        "external_id",
        "id",
        "cadence_id",
        "external_ref",
        "external_reference"
      ])
    )
    |> put_new_present(
      "activity_type",
      first_present_cadence_import_value(cadence_import, [
        "activity_type",
        "type",
        "import_type",
        "cadence_import_type"
      ])
    )
    |> put_new_present(
      "schema_contract",
      first_present_cadence_import_value(cadence_import, [
        "schema_contract",
        "contract",
        "schema",
        "artifact_contract"
      ])
    )
    |> put_new_present(
      "trust_boundary",
      first_present_cadence_import_value(cadence_import, ["trust_boundary"])
    )
  end

  defp first_present_cadence_import_value(cadence_import, keys) do
    Enum.find_value(keys, fn key ->
      case Map.get(cadence_import, key) do
        value when value in [nil, ""] -> nil
        value -> value
      end
    end)
  end

  defp cadence_import_alias_keys do
    ~w(
      external_id
      id
      cadence_id
      external_ref
      external_reference
      activity_type
      type
      import_type
      cadence_import_type
      schema_contract
      contract
      schema
      artifact_contract
      trust_boundary
    )
  end

  defp normalize_station_calendar_status_fields(activity) do
    activity
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_list_field("station_calendar_overlap_availabilities")
    |> normalize_status_list_field("station_calendar_reservation_statuses")
    |> normalize_source_station_calendar_field("source_station_calendar_entry")
    |> normalize_source_station_calendar_field("source_station_calendar_overlaps")
  end

  defp normalize_status_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, value} when value in [nil, ""] ->
        activity

      {:ok, value} ->
        Map.put(activity, field, normalize_status_token(value))

      :error ->
        activity
    end
  end

  defp normalize_status_list_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalize_status_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(activity, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(activity, field, [normalize_status_token(value)])

      _missing_or_empty ->
        activity
    end
  end

  defp normalize_source_station_calendar_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        Map.put(activity, field, Enum.map(values, &normalize_source_station_calendar/1))

      {:ok, value} ->
        Map.put(activity, field, normalize_source_station_calendar(value))

      :error ->
        activity
    end
  end

  defp normalize_source_station_calendar(%{} = source) do
    source
    |> normalize_status_field("availability")
    |> normalize_status_field("status")
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("reservation_status")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("reservation_match_status")
    |> normalize_status_field("station_reservation_match_status")
  end

  defp normalize_source_station_calendar(value), do: value

  defp normalize_spacecraft_id(%{"spacecraft_id" => spacecraft_id} = activity)
       when not is_nil(spacecraft_id),
       do: activity

  defp normalize_spacecraft_id(%{"satellite_id" => spacecraft_id} = activity)
       when not is_nil(spacecraft_id),
       do: Map.put(activity, "spacecraft_id", spacecraft_id)

  defp normalize_spacecraft_id(%{} = activity) do
    case first_nested_identity(activity, ["spacecraft", "satellite"], [
           "spacecraft_id",
           "satellite_id",
           "id"
         ]) do
      nil -> activity
      spacecraft_id -> Map.put(activity, "spacecraft_id", spacecraft_id)
    end
  end

  defp normalize_status_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_status_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_status_token()
  end

  defp normalize_status_token(value), do: value

  defp normalize_station_id(%{"ground_station_id" => station_id} = activity)
       when not is_nil(station_id),
       do: activity

  defp normalize_station_id(%{"station_id" => station_id} = activity) when not is_nil(station_id),
    do: Map.put(activity, "ground_station_id", station_id)

  defp normalize_station_id(%{} = activity) do
    case first_nested_identity(activity, ["ground_station", "station"], [
           "ground_station_id",
           "station_id",
           "id"
         ]) do
      nil -> activity
      station_id -> Map.put(activity, "ground_station_id", station_id)
    end
  end

  defp normalize_target_id(%{"target_id" => target_id} = activity) when not is_nil(target_id),
    do: activity

  defp normalize_target_id(%{} = activity) do
    case first_nested_identity(activity, ["target"], ["target_id", "id"]) do
      nil -> activity
      target_id -> Map.put(activity, "target_id", target_id)
    end
  end

  defp first_nested_identity(activity, object_keys, identity_keys) do
    Enum.find_value(object_keys, fn object_key ->
      case Map.get(activity, object_key) do
        %{} = object -> Enum.find_value(identity_keys, &present_identity(Map.get(object, &1)))
        _value -> nil
      end
    end)
  end

  defp present_identity(value) when value in [nil, ""], do: nil
  defp present_identity(value), do: value

  defp normalize_activity_time(activity, canonical_key, alternate_key) do
    canonical_value = numeric_value(Map.get(activity, canonical_key))
    alternate_value = numeric_value(Map.get(activity, alternate_key))

    cond do
      is_number(canonical_value) -> Map.put(activity, canonical_key, canonical_value)
      is_number(alternate_value) -> Map.put(activity, canonical_key, alternate_value)
      true -> activity
    end
  end

  defp normalize_activity_direction(%{"direction" => direction} = activity) do
    case normalize_contact_direction(direction) do
      nil -> Map.delete(activity, "direction")
      normalized -> Map.put(activity, "direction", normalized)
    end
  end

  defp normalize_activity_direction(activity), do: activity

  @doc """
  Normalizes provider-shaped contact direction labels into canonical timeline directions.

  Accepts atoms or strings with case, whitespace, and hyphen variants. Unknown
  non-empty values are returned as normalized snake-case strings so review
  artifacts can preserve provider evidence without accepting it as a known
  contact direction.
  """
  def normalize_contact_direction(direction) when direction in [nil, ""], do: nil

  def normalize_contact_direction(direction) do
    normalized_direction = normalize_contact_direction_token(direction)

    cond do
      normalized_direction in [nil, "", "nil"] ->
        nil

      aliased_direction = Map.get(provider_direction_aliases(), normalized_direction) ->
        aliased_direction

      normalized_direction in contact_direction_values() ->
        normalized_direction

      normalized_direction == "contact" ->
        normalized_direction

      true ->
        normalized_direction
    end
  end

  defp normalize_contact_direction_token(direction) do
    direction
    |> encode_value()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_numeric_activity_fields(activity) do
    Enum.reduce(@numeric_activity_fields, activity, fn field, acc ->
      normalize_optional_number_field(acc, field)
    end)
  end

  defp normalize_optional_number_field(%{} = activity, field) do
    case Map.fetch(activity, field) do
      {:ok, value} ->
        case numeric_value(value) do
          nil -> Map.delete(activity, field)
          number -> Map.put(activity, field, number)
        end

      :error ->
        activity
    end
  end

  defp normalize_provider_downlink_activity(activity) do
    if provider_downlink_activity?(activity) do
      activity
      |> Map.put_new("type", "downlink")
      |> Map.put_new("direction", "downlink")
    else
      activity
    end
  end

  defp normalize_direction_contact_activity(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = Map.get(activity, "direction")

    cond do
      typed_contact_window?(type, direction, activity) and direction == "health_check" ->
        Map.put_new(activity, "type", "health_check")

      typed_contact_window?(type, direction, activity) ->
        Map.put_new(activity, "type", "planned_contact")

      true ->
        activity
    end
  end

  defp typed_contact_window?(type, direction, activity) do
    type in [nil, "contact", "planned_contact"] and
      direction in ["tracking", "uplink", "command", "health_check"] and
      is_binary(Map.get(activity, "ground_station_id")) and
      Map.get(activity, "ground_station_id") != "" and
      is_number(Map.get(activity, "starts_at_s")) and
      is_number(Map.get(activity, "ends_at_s"))
  end

  defp normalize_activity_type_alias(%{"type" => type} = activity) when not is_nil(type),
    do: activity

  defp normalize_activity_type_alias(%{"activity_type" => type} = activity)
       when is_binary(type) and type != "",
       do: Map.put(activity, "type", type)

  defp normalize_activity_type_alias(activity), do: activity

  defp provider_downlink_activity?(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = Map.get(activity, "direction")

    type in [nil, "contact", "planned_contact"] and
      direction in [nil, "downlink"] and
      not command_feedback_activity?(activity) and
      is_binary(Map.get(activity, "ground_station_id")) and
      Map.get(activity, "ground_station_id") != "" and
      is_number(Map.get(activity, "starts_at_s")) and
      is_number(Map.get(activity, "ends_at_s"))
  end

  defp command_feedback_activity?(activity) do
    Map.has_key?(activity, "command_success") or Map.has_key?(activity, "command_result")
  end

  defp optional_activity_to_map(nil), do: nil
  defp optional_activity_to_map(activity), do: activity_to_map(activity)

  defp provider_direction_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().contact_direction_aliases
    |> Map.new(fn {alias_value, direction} -> {alias_value, Atom.to_string(direction)} end)
  end

  defp contact_direction_values do
    OrbitalDynamics.MissionPlan.Activity.capabilities().contact_directions
    |> Enum.map(&Atom.to_string/1)
  end

  defp timeline_lifecycle_event!(event) do
    normalized = normalize_lifecycle_value(event)

    cond do
      aliased_event = Map.get(lifecycle_event_aliases(), normalized) ->
        aliased_event

      normalized in @lifecycle_events ->
        normalized

      true ->
        raise ArgumentError, "lifecycle event must be one of #{inspect(@lifecycle_events)}"
    end
  end

  defp lifecycle_event_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().lifecycle_event_aliases
    |> Map.new(fn {alias_value, event} -> {alias_value, Atom.to_string(event)} end)
  end

  defp maybe_put_lifecycle_status_unless_preserved(activity, status) do
    if activity_status(activity) in (@executed_statuses ++ @terminal_exception_statuses) do
      activity
    else
      Map.put(activity, "status", status)
    end
  end

  defp activity_status(activity) do
    activity
    |> Map.get("status", get_in(activity, ["metadata", "status"]) || "planned")
    |> normalize_activity_status_value()
  end

  defp activity_approval_status(activity) do
    activity
    |> Map.get(
      "approval_status",
      get_in(activity, ["metadata", "approval_status"]) || "not_evaluated"
    )
    |> normalize_approval_status_value()
  end

  defp normalize_lifecycle_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_lifecycle_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_lifecycle_value()
  end

  defp normalize_lifecycle_value(value), do: encode_value(value)

  defp normalize_activity_status_value(value) do
    normalized = normalize_lifecycle_value(value)
    Map.get(activity_status_aliases(), normalized, normalized)
  end

  defp activity_status_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().activity_status_aliases
    |> Map.new(fn {alias_value, status} -> {alias_value, Atom.to_string(status)} end)
  end

  defp normalize_approval_status_value(value) do
    normalized = normalize_lifecycle_value(value)
    Map.get(approval_status_aliases(), normalized, normalized)
  end

  defp approval_status_aliases do
    OrbitalDynamics.MissionPlan.Activity.capabilities().approval_status_aliases
    |> Map.new(fn {alias_value, status} -> {alias_value, Atom.to_string(status)} end)
  end

  defp activity_locked?(activity) do
    truthy?(activity["locked"]) || truthy?(get_in(activity, ["metadata", "locked"]))
  end

  defp activity_allow_overlap(activity) do
    activity
    |> first_present_boolean_value(["allow_overlap", "allow_overlap?"])
    |> boolean_value()
  end

  defp first_present_boolean_value(activity, keys) do
    Enum.find_value(keys, fn key ->
      cond do
        Map.has_key?(activity, key) ->
          {:value, Map.get(activity, key)}

        is_map(Map.get(activity, "metadata")) and Map.has_key?(activity["metadata"], key) ->
          {:value, get_in(activity, ["metadata", key])}

        true ->
          nil
      end
    end)
    |> case do
      {:value, value} -> value
      nil -> nil
    end
  end

  defp activity_approved?(activity) do
    approval_status = activity_approval_status(activity)

    truthy?(activity["approved"]) ||
      truthy?(get_in(activity, ["metadata", "approved"])) ||
      approval_status in @protected_approval_statuses
  end

  defp protected_by_lock_or_approval?(activity),
    do: activity_locked?(activity) or activity_approved?(activity)

  defp preservation_sensitive_source?(%{"status" => status}) when status in @executed_statuses,
    do: true

  defp preservation_sensitive_source?(source),
    do: source["locked"] || approval_protected?(source)

  defp approval_protected?(source),
    do: source["approval_status"] in @protected_approval_statuses

  defp executed_status?(status), do: status in @executed_statuses

  defp repairable_status?(status),
    do: status in ["missed", "failed", "delayed", "canceled", "cancelled", "rejected"]

  defp activity_schedule_conflict_status(activity) do
    activity["schedule_conflict_status"] ||
      get_in(activity, ["metadata", "schedule_conflict_status"])
  end

  defp approved_timeline_row?(row), do: row["approval_status"] in ["approved", "auto_approvable"]
  defp executed_timeline_row?(row), do: row["status"] in @executed_statuses

  defp terminal_exception_timeline_row?(row) do
    row["status"] in @terminal_exception_statuses or
      row["operator_action_reason"] in [
        "contact_success_false_requires_review",
        "command_success_false_requires_review"
      ] or
      provider_result_failure?(Map.get(row, "contact_result")) or
      provider_result_failure?(Map.get(row, "command_result"))
  end

  defp changed_fields(source, replacement) do
    @diff_compare_fields
    |> Enum.filter(&(diff_compare_value(source, &1) != diff_compare_value(replacement, &1)))
  end

  defp diff_compare_value(row, field) when field in @diff_activity_context_compare_fields do
    case Map.fetch(row, field) do
      {:ok, nil} -> get_in(row, ["activity_context", field])
      {:ok, value} -> value
      :error -> get_in(row, ["activity_context", field])
    end
  end

  defp diff_compare_value(row, field), do: Map.get(row, field)

  defp review_significant_change?(changed_fields) do
    Enum.any?(changed_fields, &(&1 in @diff_compare_fields))
  end

  defp timeline_row_has_dependencies?(row) do
    non_empty_list?(row["dependency_activity_ids"]) or
      non_empty_list?(row["dependency_timeline_ids"])
  end

  defp timeline_row_has_exclusivity?(row) do
    non_empty_list?(row["exclusive_with_activity_ids"]) or
      non_empty_list?(row["exclusive_with_timeline_ids"])
  end

  defp timeline_integrity_review?(row), do: row["timeline_integrity_status"] == "review_required"

  defp timeline_integrity_issue_count(rows) do
    Enum.reduce(rows, 0, &(&2 + Map.get(&1, "timeline_integrity_issue_count", 0)))
  end

  defp timeline_integrity_issue_types(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issue_types"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp timeline_integrity_issue_type_counts(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issues"))
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map()
  end

  defp timeline_row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_uniq()
  end

  defp timeline_integrity_scope_ids(rows, issue_type_fragment, field) do
    rows
    |> Enum.filter(fn row ->
      row
      |> list_value("timeline_integrity_issue_types")
      |> Enum.any?(&String.contains?(&1, issue_type_fragment))
    end)
    |> timeline_row_ids(field)
  end

  defp timeline_integrity_ids_by_issue_type(rows, id_field) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> list_value("timeline_integrity_issue_types")
      |> Enum.map(&{&1, row[id_field]})
    end)
    |> grouped_sorted_ids()
  end

  defp timeline_integrity_ids_by_field(rows, group_field, id_field) do
    rows
    |> Enum.map(&{&1[group_field], &1[id_field]})
    |> grouped_sorted_ids()
  end

  defp grouped_sorted_ids(pairs) do
    pairs
    |> Enum.reject(fn {group, id} -> is_nil(group) or is_nil(id) end)
    |> Enum.group_by(fn {group, _id} -> group end, fn {_group, id} -> id end)
    |> Enum.sort_by(fn {group, _ids} -> group end)
    |> Map.new(fn {group, ids} -> {group, sorted_uniq(ids)} end)
  end

  defp timeline_integrity_row_list_ids(rows, field) do
    rows
    |> Enum.flat_map(&list_value(&1, field))
    |> sorted_uniq()
  end

  defp timeline_diff_status_ids(rows, status) do
    rows
    |> Enum.filter(&(&1["diff_status"] == status))
    |> timeline_row_ids("timeline_id")
  end

  defp dependency_issue_count(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issues"))
    |> Enum.count(fn issue ->
      is_map(issue) and
        issue
        |> Map.get("type")
        |> dependency_issue_type?()
    end)
  end

  defp exclusivity_issue_count(rows) do
    rows
    |> Enum.flat_map(&list_value(&1, "timeline_integrity_issues"))
    |> Enum.count(fn issue ->
      is_map(issue) and
        issue
        |> Map.get("type")
        |> exclusivity_issue_type?()
    end)
  end

  defp dependency_issue_type?(type) when is_binary(type), do: String.contains?(type, "dependency")
  defp dependency_issue_type?(_type), do: false

  defp exclusivity_issue_type?(type) when is_binary(type),
    do: String.contains?(type, "exclusivity")

  defp exclusivity_issue_type?(_type), do: false

  defp non_empty_list?(value), do: is_list(value) and value != []
  defp list_value(value, key), do: Map.get(value, key) || []

  defp diff_dependency_context(prefix, row) do
    %{
      "#{prefix}_dependency_activity_ids" => row["dependency_activity_ids"],
      "#{prefix}_dependency_timeline_ids" => row["dependency_timeline_ids"],
      "#{prefix}_timeline_integrity_status" => row["timeline_integrity_status"],
      "#{prefix}_timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
      "#{prefix}_timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
      "#{prefix}_timeline_integrity_issues" => row["timeline_integrity_issues"],
      "#{prefix}_missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
      "#{prefix}_missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
      "#{prefix}_self_dependency_activity_ids" => row["self_dependency_activity_ids"],
      "#{prefix}_self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
      "#{prefix}_dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
      "#{prefix}_dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
      "#{prefix}_dependency_order_violation_activity_ids" =>
        row["dependency_order_violation_activity_ids"],
      "#{prefix}_dependency_order_violation_timeline_ids" =>
        row["dependency_order_violation_timeline_ids"],
      "#{prefix}_exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "#{prefix}_exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "#{prefix}_exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
      "#{prefix}_exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
      "#{prefix}_exclusivity_violation_group" => row["exclusivity_violation_group"]
    }
  end

  defp diff_schedule_context(prefix, row) do
    %{
      "#{prefix}_allow_overlap" => row["allow_overlap"]
    }
  end

  defp diff_protection_context(_prefix, nil), do: %{}
  defp diff_protection_context(_prefix, row) when row == %{}, do: %{}

  defp diff_protection_context(prefix, row) do
    decision =
      row
      |> Map.put("id", row["activity_id"])
      |> protection_decision()

    %{
      "#{prefix}_protection_decision" => decision,
      "#{prefix}_protection_category" => decision["protection_category"],
      "#{prefix}_protection_reason" => decision["reason"]
    }
  end

  defp diff_invalid_activity_input_context(_prefix, row) when row == %{}, do: %{}

  defp diff_invalid_activity_input_context(prefix, %{"invalid_activity_input" => true} = row) do
    %{
      "#{prefix}_invalid_activity_input" => true,
      "#{prefix}_invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "#{prefix}_activity" => row["source_activity"]
    }
  end

  defp diff_invalid_activity_input_context(_prefix, _row), do: %{}

  defp diff_required_operator_action("unchanged", _requires_review), do: "none"
  defp diff_required_operator_action("changed", true), do: "review_timeline_change"
  defp diff_required_operator_action("changed", false), do: "record_timeline_change"

  defp diff_reason("unchanged", source, _replacement, _changed_fields),
    do: "timeline activity #{source["activity_id"]} is unchanged"

  defp diff_reason("changed", source, replacement, changed_fields) do
    "timeline activity #{source["activity_id"]} changes to #{replacement["activity_id"]}: #{Enum.join(changed_fields, ",")}"
  end

  defp lifecycle_transition(_field, value, value), do: nil

  defp lifecycle_transition(field, nil, to),
    do:
      %{"field" => field, "transition_type" => "added", "to" => to}
      |> Map.merge(transition_semantics(field, nil, to))

  defp lifecycle_transition(field, from, nil),
    do:
      %{"field" => field, "transition_type" => "removed", "from" => from}
      |> Map.merge(transition_semantics(field, from, nil))

  defp lifecycle_transition(field, from, to),
    do:
      %{"field" => field, "transition_type" => "changed", "from" => from, "to" => to}
      |> Map.merge(transition_semantics(field, from, to))

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

  defp transition_semantics("status", from, to) do
    %{
      "from_category" => status_lifecycle_category(from),
      "to_category" => status_lifecycle_category(to)
    }
    |> Map.merge(status_transition_review(from, to))
    |> compact_map()
  end

  defp transition_semantics("approval_status", from, to) do
    %{
      "from_category" => approval_lifecycle_category(from),
      "to_category" => approval_lifecycle_category(to)
    }
    |> Map.merge(approval_transition_review(from, to))
    |> compact_map()
  end

  defp transition_semantics(_field, _from, _to), do: %{}

  defp status_transition_review(nil, to) do
    cond do
      unsupported_activity_status?(to) ->
        transition_review("unsupported_status", true, "unsupported_replacement_status")

      to in @terminal_exception_statuses ->
        transition_review("terminal_exception_recorded", true, "added_terminal_exception_status")

      to == "blocked_by_policy" ->
        transition_review("status_blocked", true, "activity_status_blocked_by_policy")

      true ->
        transition_review("status_added", false, "added_activity_status")
    end
  end

  defp status_transition_review(from, nil) do
    cond do
      unsupported_activity_status?(from) ->
        transition_review("unsupported_status", true, "unsupported_source_status")

      from in @executed_statuses ->
        transition_review("executed_activity_removed", true, "removed_executed_status")

      true ->
        transition_review("status_removed", false, "removed_activity_status")
    end
  end

  defp status_transition_review(from, to) do
    cond do
      unsupported_activity_status?(from) ->
        transition_review("unsupported_status", true, "unsupported_source_status")

      unsupported_activity_status?(to) ->
        transition_review("unsupported_status", true, "unsupported_replacement_status")

      to == "blocked_by_policy" ->
        transition_review("status_blocked", true, "activity_status_blocked_by_policy")

      from == "blocked_by_policy" and to != "blocked_by_policy" ->
        transition_review("status_block_cleared", true, "blocked_status_cleared")

      from in @executed_statuses ->
        transition_review("executed_activity_changed", true, "executed_status_changed")

      to in @executed_statuses ->
        transition_review("execution_recorded", false, "activity_execution_recorded")

      from in @terminal_exception_statuses and to not in @terminal_exception_statuses ->
        transition_review("terminal_exception_reopened", true, "terminal_exception_reopened")

      to in @terminal_exception_statuses ->
        transition_review("terminal_exception_recorded", true, "terminal_exception_recorded")

      repairable_status?(to) ->
        transition_review("repair_status_recorded", true, "repair_status_recorded")

      true ->
        transition_review("status_changed", false, "status_changed")
    end
  end

  defp approval_transition_review(nil, to) do
    cond do
      unsupported_approval_status?(to) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_replacement_approval_status"
        )

      to == "rejected" ->
        transition_review("approval_rejected", true, "approval_rejected")

      to == "blocked_by_policy" ->
        transition_review("approval_blocked", true, "approval_blocked_by_policy")

      to in @review_approval_statuses ->
        transition_review("approval_review_required", true, "approval_requires_review")

      true ->
        transition_review("approval_added", false, "approval_status_added")
    end
  end

  defp approval_transition_review(from, nil) do
    cond do
      unsupported_approval_status?(from) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_source_approval_status"
        )

      from in @protected_approval_statuses ->
        transition_review("protected_approval_removed", true, "protected_approval_removed")

      true ->
        transition_review("approval_removed", false, "approval_status_removed")
    end
  end

  defp approval_transition_review(from, to) do
    cond do
      unsupported_approval_status?(from) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_source_approval_status"
        )

      unsupported_approval_status?(to) ->
        transition_review(
          "unsupported_approval_status",
          true,
          "unsupported_replacement_approval_status"
        )

      to == "blocked_by_policy" ->
        transition_review("approval_blocked", true, "approval_blocked_by_policy")

      from in @protected_approval_statuses and to not in @protected_approval_statuses ->
        transition_review("approval_regressed", true, "protected_approval_regressed")

      to == "rejected" ->
        transition_review("approval_rejected", true, "approval_rejected")

      to in @review_approval_statuses ->
        transition_review("approval_review_required", true, "approval_requires_review")

      to in @protected_approval_statuses ->
        transition_review("approval_granted", true, "approval_grant_requires_operator_authority")

      true ->
        transition_review("approval_changed", false, "approval_status_changed")
    end
  end

  defp transition_review(category, requires_review?, reason) do
    %{
      "transition_category" => category,
      "requires_operator_review" => requires_review?,
      "operator_action_reason" => reason
    }
  end

  defp transition_requires_operator_review?(nil), do: false

  defp transition_requires_operator_review?(%{"requires_operator_review" => requires_review?}),
    do: requires_review?

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

  defp unsupported_approval_status?(nil), do: false
  defp unsupported_approval_status?(status), do: status not in @approval_statuses

  defp unsupported_activity_status?(nil), do: false
  defp unsupported_activity_status?(status), do: status not in @activity_statuses

  defp optional_activity_state_input(nil, _sequence), do: nil

  defp optional_activity_state_input(%{"invalid_activity_input" => true} = activity, _sequence),
    do: activity_to_map(activity)

  defp optional_activity_state_input(%{invalid_activity_input: true} = activity, _sequence),
    do: activity_to_map(activity)

  defp optional_activity_state_input(activity, sequence) do
    case activity_input_to_map(activity, sequence) do
      {:ok, activity} -> activity
      {:error, row} -> row
    end
  end

  defp invalid_activity_state_row?(%{"invalid_activity_input" => true}), do: true
  defp invalid_activity_state_row?(%{invalid_activity_input: true}), do: true
  defp invalid_activity_state_row?(_activity), do: false

  defp invalid_activity_state?(planned_activity, realized_activity) do
    planned_activity
    |> invalid_activity_state_rows(realized_activity)
    |> Enum.any?()
  end

  defp invalid_activity_state_count(planned_activity, realized_activity) do
    planned_activity
    |> invalid_activity_state_rows(realized_activity)
    |> length()
    |> case do
      0 -> nil
      count -> count
    end
  end

  defp invalid_activity_state_reasons(planned_activity, realized_activity) do
    reasons =
      planned_activity
      |> invalid_activity_state_rows(realized_activity)
      |> Enum.map(& &1["invalid_activity_input_reason"])
      |> sorted_uniq()

    if reasons == [], do: nil, else: reasons
  end

  defp invalid_activity_state_rows(planned_activity, realized_activity) do
    [planned_activity, realized_activity]
    |> Enum.filter(fn
      %{"invalid_activity_input" => true} -> true
      _activity -> false
    end)
  end

  defp state_activity_id(%{"invalid_activity_input" => true, "activity_id" => activity_id}),
    do: activity_id

  defp state_activity_id(activity), do: activity_id(activity)

  defp state_timeline_id(%{"invalid_activity_input" => true, "timeline_id" => timeline_id}),
    do: timeline_id

  defp state_timeline_id(activity), do: activity_timeline_id(activity)

  defp status_state_activity_id(planned_activity, realized_activity) do
    (planned_activity && state_activity_id(planned_activity)) ||
      (realized_activity && state_activity_id(realized_activity))
  end

  defp status_state_timeline_id(planned_activity, realized_activity) do
    (planned_activity && state_timeline_id(planned_activity)) ||
      (realized_activity && state_timeline_id(realized_activity))
  end

  defp status_state_transition_decision(nil), do: "none"

  defp status_state_transition_decision(%{"requires_operator_review" => true}), do: "review"

  defp status_state_transition_decision(%{}), do: "record"

  defp status_state_review_required?(%{"requires_operator_review" => review_required?}),
    do: review_required?

  defp status_state_review_required?(_status_transition), do: false

  defp status_state_required_operator_action("none"), do: "none"
  defp status_state_required_operator_action("review"), do: "review_activity_transition"
  defp status_state_required_operator_action("record"), do: "record_timeline_change"

  defp status_state_operator_action_reason(nil), do: "no_status_change"

  defp status_state_operator_action_reason(%{"operator_action_reason" => reason}), do: reason

  defp status_state_import_action("none"), do: "record_preserved_activity"
  defp status_state_import_action("review"), do: "review_timeline_diff"
  defp status_state_import_action("record"), do: "import_replacement_activity"

  defp approval_state_required_operator_action("none"), do: "none"
  defp approval_state_required_operator_action("review"), do: "review_activity_approval"
  defp approval_state_required_operator_action("record"), do: "record_timeline_change"

  defp approval_state_operator_action_reason(nil), do: "no_approval_status_change"

  defp approval_state_operator_action_reason(%{"operator_action_reason" => reason}), do: reason

  defp lifecycle_state_transition_decision(status_state, approval_state, protections) do
    cond do
      Map.get(status_state, "review_required") or Map.get(approval_state, "review_required") or
          lifecycle_state_protection_review_required?(protections) ->
        "review"

      Map.get(status_state, "transition_decision") == "record" or
          Map.get(approval_state, "transition_decision") == "record" ->
        "record"

      true ->
        "none"
    end
  end

  defp lifecycle_state_protection_review_required?(protections) do
    Enum.any?(protections, fn
      %{"protection_decision" => "review_change"} -> true
      _protection -> false
    end)
  end

  defp lifecycle_state_required_operator_actions(
         status_state,
         approval_state,
         protections,
         transition_decision
       ) do
    actions =
      [
        Map.get(status_state, "required_operator_action"),
        Map.get(approval_state, "required_operator_action")
      ] ++ lifecycle_state_protection_actions(protections)

    actions =
      actions
      |> Enum.reject(&(&1 in [nil, "none"]))
      |> sorted_uniq()

    case {transition_decision, actions} do
      {"none", []} -> ["none"]
      {"record", []} -> ["record_timeline_change"]
      {_decision, actions} -> actions
    end
  end

  defp lifecycle_state_required_operator_action(actions, "review") do
    cond do
      "review_activity_transition" in actions -> "review_activity_transition"
      "review_activity_approval" in actions -> "review_activity_approval"
      "review_timeline_change" in actions -> "review_timeline_change"
      true -> List.first(actions) || "review_activity_transition"
    end
  end

  defp lifecycle_state_required_operator_action(_actions, "record"), do: "record_timeline_change"
  defp lifecycle_state_required_operator_action(_actions, "none"), do: "none"

  defp lifecycle_state_protection_actions(protections) do
    Enum.flat_map(protections, fn
      %{"protection_decision" => "review_change"} -> ["review_timeline_change"]
      _protection -> []
    end)
  end

  defp lifecycle_state_operator_action_reasons(status_state, approval_state, protections) do
    [
      Map.get(status_state, "operator_action_reason"),
      Map.get(approval_state, "operator_action_reason")
    ]
    |> Kernel.++(lifecycle_state_protection_reasons(protections))
    |> Enum.reject(&(&1 in [nil, "no_status_change", "no_approval_status_change"]))
    |> sorted_uniq()
    |> case do
      [] -> nil
      reasons -> reasons
    end
  end

  defp lifecycle_state_protection_reasons(protections) do
    protections
    |> Enum.filter(&(Map.get(&1 || %{}, "protection_decision") == "review_change"))
    |> Enum.map(&Map.get(&1, "reason"))
  end

  defp delta(replacement, source) when is_number(replacement) and is_number(source),
    do: replacement - source

  defp delta(_replacement, _source), do: nil

  defp completion_fraction(actual, planned)
       when is_number(actual) and is_number(planned) and planned > 0.0 do
    actual / planned
  end

  defp completion_fraction(_actual, _planned), do: nil

  defp activity_timeline_id(activity) do
    activity["timeline_id"] ||
      activity["persistent_id"] ||
      get_in(activity, ["metadata", "timeline_id"]) ||
      get_in(activity, ["metadata", "persistent_id"]) ||
      derived_timeline_id(activity)
  end

  defp derived_timeline_id(activity) do
    [
      "timeline",
      activity["scenario_id"],
      activity["type"],
      activity_subject_id(activity),
      activity_source_window_id(activity) || activity_start(activity)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp activity_subject_id(activity) do
    activity["target_id"] ||
      activity["ground_station_id"] ||
      activity["maneuver_id"] ||
      activity["spacecraft_id"] ||
      activity["resource_id"]
  end

  defp activity_source_window_id(activity) do
    activity["source_window_id"] ||
      get_in(activity, ["source_window", "id"]) ||
      get_in(activity, ["source_window", "window_id"]) ||
      get_in(activity, ["metadata", "source_window_id"]) ||
      get_in(activity, ["metadata", "source_window", "id"]) ||
      get_in(activity, ["metadata", "source_window", "window_id"])
  end

  defp activity_source_window_type(activity) do
    activity["source_window_type"] ||
      activity["source_window_kind"] ||
      get_in(activity, ["source_window", "type"]) ||
      get_in(activity, ["source_window", "kind"]) ||
      get_in(activity, ["source_window", "window_type"]) ||
      get_in(activity, ["metadata", "source_window_type"]) ||
      get_in(activity, ["metadata", "source_window_kind"]) ||
      get_in(activity, ["metadata", "source_window", "type"]) ||
      get_in(activity, ["metadata", "source_window", "kind"]) ||
      get_in(activity, ["metadata", "source_window", "window_type"])
  end

  defp dependency_activity_ids(activity) do
    activity
    |> first_value([
      "dependency_activity_ids",
      "depends_on_activity_ids",
      "depends_on",
      "dependencies"
    ])
    |> normalize_id_list(["activity_id", "id"])
  end

  defp duplicate_dependency_activity_ids(activity) do
    activity
    |> first_value([
      "dependency_activity_ids",
      "depends_on_activity_ids",
      "depends_on",
      "dependencies"
    ])
    |> duplicate_id_list(["activity_id", "id"])
  end

  defp dependency_timeline_ids(activity) do
    case first_value(activity, ["dependency_timeline_ids", "depends_on_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value(["dependencies"])
        |> normalize_map_id_list(["timeline_id", "persistent_id"])

      values ->
        normalize_id_list(values, ["timeline_id", "persistent_id"])
    end
  end

  defp duplicate_dependency_timeline_ids(activity) do
    case first_value(activity, ["dependency_timeline_ids", "depends_on_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value(["dependencies"])
        |> duplicate_map_id_list(["timeline_id", "persistent_id"])

      values ->
        duplicate_id_list(values, ["timeline_id", "persistent_id"])
    end
  end

  defp exclusive_with_activity_ids(activity) do
    explicit =
      activity
      |> first_value(["exclusive_with_activity_ids"])
      |> normalize_id_list(["activity_id", "id"])

    case explicit do
      values when is_list(values) and values != [] ->
        values

      _empty ->
        activity
        |> first_value(["exclusive_with", "exclusions"])
        |> normalize_id_list(["activity_id", "id"])
    end
  end

  defp duplicate_exclusivity_activity_ids(activity) do
    explicit =
      activity
      |> first_value(["exclusive_with_activity_ids"])
      |> duplicate_id_list(["activity_id", "id"])

    case explicit do
      values when is_list(values) and values != [] ->
        values

      _empty ->
        activity
        |> first_value(["exclusive_with", "exclusions"])
        |> duplicate_id_list(["activity_id", "id"])
    end
  end

  defp exclusive_with_timeline_ids(activity) do
    case first_value(activity, ["exclusive_with_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value(["exclusive_with", "exclusions"])
        |> normalize_map_id_list(["timeline_id", "persistent_id"])

      values ->
        normalize_id_list(values, ["timeline_id", "persistent_id"])
    end
  end

  defp duplicate_exclusivity_timeline_ids(activity) do
    case first_value(activity, ["exclusive_with_timeline_ids"]) do
      value when value in [nil, []] ->
        activity
        |> first_value(["exclusive_with", "exclusions"])
        |> duplicate_map_id_list(["timeline_id", "persistent_id"])

      values ->
        duplicate_id_list(values, ["timeline_id", "persistent_id"])
    end
  end

  defp first_present_value(activity, keys) do
    Enum.find_value(keys, :error, fn key ->
      metadata = Map.get(activity, "metadata") || Map.get(activity, :metadata) || %{}

      case fetch_key_or_atom(activity, key) do
        {:ok, value} ->
          {:ok, value}

        :error ->
          case fetch_key_or_atom(metadata, key) do
            {:ok, value} -> {:ok, value}
            :error -> false
          end
      end
    end)
  end

  defp first_value(activity, keys) do
    Enum.find_value(keys, fn key ->
      metadata = Map.get(activity, "metadata") || Map.get(activity, :metadata) || %{}

      case fetch_key_or_atom(activity, key) do
        {:ok, value} when not is_nil(value) ->
          value

        _value ->
          case fetch_key_or_atom(metadata, key) do
            {:ok, value} -> value
            :error -> nil
          end
      end
    end)
  end

  defp fetch_key_or_atom(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error when is_binary(key) -> fetch_existing_atom_key(map, key)
      :error -> :error
    end
  end

  defp fetch_key_or_atom(_map, _key), do: :error

  defp fetch_existing_atom_key(map, key) do
    atom_key = String.to_existing_atom(key)
    Map.fetch(map, atom_key)
  rescue
    ArgumentError -> :error
  end

  defp first_number(activity, keys) do
    Enum.find_value(keys, fn key ->
      value = first_value(activity, [key])
      numeric_value(value)
    end)
  end

  defp first_number_or_scalar(activity, keys) do
    Enum.find_value(keys, fn key ->
      case first_value(activity, [key]) do
        value when is_number(value) -> value
        value when is_binary(value) and value != "" -> numeric_value(value) || value
        value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
        _value -> nil
      end
    end)
  end

  defp first_scalar_string(activity, keys) do
    Enum.find_value(keys, fn key ->
      case first_value(activity, [key]) do
        value when is_binary(value) and value != "" -> value
        value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
        _value -> nil
      end
    end)
  end

  defp first_provider_result_string(activity, keys) do
    Enum.find_value(keys, fn key ->
      activity
      |> first_value([key])
      |> provider_result_artifact_value()
    end)
  end

  defp first_stable_identifier(activity, keys) do
    Enum.find_value(keys, fn key ->
      case first_value(activity, [key]) do
        value when is_binary(value) and value != "" ->
          if Regex.match?(@stable_id_pattern, value), do: value

        value when is_atom(value) and not is_nil(value) ->
          value = Atom.to_string(value)
          if Regex.match?(@stable_id_pattern, value), do: value

        _value ->
          nil
      end
    end)
  end

  defp first_boolean(activity, keys) do
    Enum.reduce_while(keys, nil, fn key, _acc ->
      cond do
        Map.has_key?(activity, key) and is_boolean(boolean_value(Map.get(activity, key))) ->
          {:halt, boolean_value(Map.get(activity, key))}

        is_map(Map.get(activity, "metadata")) and
          Map.has_key?(Map.get(activity, "metadata"), key) and
            is_boolean(boolean_value(get_in(activity, ["metadata", key]))) ->
          {:halt, boolean_value(get_in(activity, ["metadata", key]))}

        true ->
          {:cont, nil}
      end
    end)
  end

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp normalize_id_list(nil, _map_keys), do: nil

  defp normalize_id_list(values, map_keys) when is_list(values) do
    values
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> normalize_scalar_ids()
  end

  defp normalize_id_list(value, map_keys) do
    value
    |> id_values(map_keys)
    |> normalize_scalar_ids()
  end

  defp normalize_map_id_list(nil, _map_keys), do: nil

  defp normalize_map_id_list(values, map_keys) when is_list(values) do
    values
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> normalize_scalar_ids()
  end

  defp normalize_map_id_list(%{} = value, map_keys) do
    value
    |> id_values(map_keys)
    |> normalize_scalar_ids()
  end

  defp normalize_map_id_list(_value, _map_keys), do: nil

  defp duplicate_id_list(nil, _map_keys), do: nil

  defp duplicate_id_list(values, map_keys) when is_list(values) do
    values
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> duplicate_scalar_ids()
  end

  defp duplicate_id_list(value, map_keys) do
    value
    |> id_values(map_keys)
    |> duplicate_scalar_ids()
  end

  defp duplicate_map_id_list(nil, _map_keys), do: nil

  defp duplicate_map_id_list(values, map_keys) when is_list(values) do
    values
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(&id_values(&1, map_keys))
    |> duplicate_scalar_ids()
  end

  defp duplicate_map_id_list(%{} = value, map_keys) do
    value
    |> id_values(map_keys)
    |> duplicate_scalar_ids()
  end

  defp duplicate_map_id_list(_value, _map_keys), do: nil

  defp id_values(%{} = value, map_keys) do
    Enum.flat_map(map_keys, fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value, _map_keys), do: [value]

  defp normalize_scalar_ids(values) do
    values
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp duplicate_scalar_ids(values) do
    values
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.frequencies()
    |> Enum.filter(fn {_id, count} -> count > 1 end)
    |> Enum.map(fn {id, _count} -> id end)
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> stable_id_value()
  end

  defp stable_id_value(value) when is_binary(value) do
    value
    |> String.split(",", trim: false)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn value ->
      value != "" and value != "nil" and stable_activity_id?(value)
    end)
  end

  defp stable_id_value(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> stable_id_value()
  end

  defp stable_id_value(_value), do: []

  defp activity_start(activity) do
    Map.get(activity, "starts_at_s") || Map.get(activity, "start_s")
  end

  defp activity_end(activity) do
    Map.get(activity, "ends_at_s") || Map.get(activity, "end_s")
  end

  defp activity_duration_s(%{"duration_s" => duration_s}) when is_number(duration_s),
    do: duration_s

  defp activity_duration_s(activity) do
    start_s = activity_start(activity)
    end_s = activity_end(activity)

    if is_number(start_s) and is_number(end_s), do: end_s - start_s, else: nil
  end

  defp activity_id(%{"id" => id}), do: encode_value(id)

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp truthy?(value) when is_boolean(value), do: value
  defp truthy?(value) when is_number(value), do: value == 1

  defp truthy?(value) when is_binary(value) do
    String.downcase(String.trim(value)) in ["true", "1"]
  end

  defp truthy?(_value), do: false

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
