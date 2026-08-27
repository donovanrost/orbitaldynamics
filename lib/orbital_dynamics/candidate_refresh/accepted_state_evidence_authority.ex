defmodule OrbitalDynamics.CandidateRefresh.AcceptedStateEvidenceAuthority do
  @moduledoc false

  @schema_contract "accepted_state_evidence_authority.v1"
  @warning_message "accepted-state OrbitData evidence requires operator review but has no CandidateRefresh decision authority"

  @max_scan_depth 8
  @max_scan_nodes 512
  @max_map_entries 64
  @max_list_entries 128
  @max_binary_bytes 256
  @max_abs_integer 9_007_199_254_740_991
  @max_abs_float 1.7976931348623157e308
  @max_spacecraft_states 128
  @max_issues 50
  @max_review_reasons 64
  @max_encoding_projection_paths 512
  @max_encoding_projection_actions 512
  @max_encoding_projection_segments 16
  @max_encoding_projection_segment_bytes 256

  @accepted_state_encoding_redaction %{
    "spacecraft_states" => [],
    "maneuver_execution_deltas" => []
  }

  @refresh_encoding_redaction %{
    "accepted_planning_state" => @accepted_state_encoding_redaction
  }

  @covariance_fields ~w(
    covariance_reference_frame
    covariance_epoch
    covariance_status
    covariance_component_order
    covariance_matrix_6x6
    covariance_unit_contract
    covariance_frame_binding
    covariance_epoch_binding
    covariance_numerical_check
    covariance_propagation_status
  )

  @complete_quality_fields ~w(
    covariance_matrix_6x6
    covariance_unit_contract
    covariance_frame_binding
    covariance_epoch_binding
    covariance_numerical_check
    covariance_propagation_status
    covariance_status
  )

  @allowed_covariance_statuses ~w(
    matrix_imported_metadata_only_no_propagation
    matrix_exported_metadata_only_no_propagation
    metadata_only_no_propagation
    metadata_only_not_propagated
    not_present
  )
  @component_order ~w(
    x_km
    y_km
    z_km
    x_dot_km_s
    y_dot_km_s
    z_dot_km_s
  )
  @supported_ref_frames ~w(EME2000 J2000 ICRF)
  @supported_unit_declarations ~w(implicit_ccsds_units explicit_ccsds_units)
  @supported_time_scales ~w(utc tai tdb)
  @covariance_numerical_check_name "normalized_principal_minors_nonnegative_relative_symmetric_6x6_bounded_float"
  @covariance_numerical_check_claim "deterministic_normalized_principal_minor_support_check_not_external_validation"

  @identity_keys ~w(content_identity source_identity covariance_source_identity)
  @auth_claim_keys ~w(
    authority
    authentication
    authenticated
    signature
    signed
    verified
    verified_authority
    trusted_authority
    source_authority
  )

  @direct_report_projection_fields ~w(
    cadence_import_manifest
    candidate_diff_report
    candidate_rejection_report
    candidate_refresh_request_source_report_summary
    command_window_report
    constraint_report
    contact_allocation_capacity_pack_summary
    contact_allocation_provider_reservation_request_summary
    contact_allocation_report
    contact_allocation_reservation_conflict_summary
    contact_allocation_station_pressure_summary
    contact_allocation_summary
    contact_contention_report
    contact_contention_resolution_report
    contact_contention_resolution_summary
    contact_filter_report
    contact_intent
    contact_intent_summary
    contact_intents
    link_capacity_report
    link_capacity_summary
    maneuver_review_report
    model_acceptance_report
    objective_satisfaction_report
    objective_tradeoff_report
    operational_execution_boundary_summary
    operational_import_eligibility_summary
    operational_quality_gate_import_readiness_summary
    operational_quality_gate_operator_training_summary
    operational_quality_gate_schema_validation_summary
    operational_quality_gate_summary
    operational_quality_gate_unavailable_resource_summary
    operational_readiness_gate_summary
    operational_readiness_report
    operational_timeline_report
    operator_review_package
    provider_counteroffer_import_readiness_summary
    provider_counteroffer_plan_impact_summary
    provider_counteroffer_report
    provider_counteroffer_review_summary
    quality_gate_report
    realized_activities
    realized_activity
    realized_state
    realized_state_snapshot
    refresh_budget_report
    relay_data_path_summary
    resource_filter_report
    resource_filter_summary
    resource_projection_flow_summary
    resource_projection_report
    result_artifact
    schema_validation_batch_report
    schema_validation_report
    score_term_report
    source_cadence_import_manifest
    source_candidate_diff_report
    source_candidate_rejection_report
    source_command_window_report
    source_constraint_report
    source_contact_allocation_capacity_pack_summary
    source_contact_allocation_provider_reservation_request_summary
    source_contact_allocation_report
    source_contact_allocation_reservation_conflict_summary
    source_contact_allocation_station_pressure_summary
    source_contact_allocation_summary
    source_contact_contention_report
    source_contact_contention_resolution_report
    source_contact_contention_resolution_summary
    source_contact_filter_report
    source_contact_intent
    source_contact_intent_summary
    source_contact_intents
    source_link_capacity_report
    source_link_capacity_summary
    source_maneuver_review_report
    source_model_acceptance_report
    source_objective_satisfaction_report
    source_objective_tradeoff_report
    source_operational_execution_boundary_summary
    source_operational_import_eligibility_summary
    source_operational_quality_gate_import_readiness_summary
    source_operational_quality_gate_operator_training_summary
    source_operational_quality_gate_schema_validation_summary
    source_operational_quality_gate_summary
    source_operational_quality_gate_unavailable_resource_summary
    source_operational_readiness_gate_summary
    source_operational_readiness_report
    source_operational_timeline_report
    source_operator_review_package
    source_provider_counteroffer_import_readiness_summary
    source_provider_counteroffer_plan_impact_summary
    source_provider_counteroffer_report
    source_provider_counteroffer_review_summary
    source_quality_gate_report
    source_realized_activities
    source_realized_activity
    source_realized_state
    source_realized_state_snapshot
    source_refresh_budget_report
    source_relay_data_path_summary
    source_resource_filter_report
    source_resource_filter_summary
    source_resource_projection_flow_summary
    source_resource_projection_report
    source_result_artifact
    source_schema_validation_batch_report
    source_schema_validation_report
    source_score_term_report
    source_station_calendar_precedence_summary
    source_station_calendar_report
    source_station_reservation_hold_import_readiness_summary
    source_station_reservation_hold_summary
    source_station_reservation_report
    source_station_reservation_review_summary
    source_timeline_activity_approval_state
    source_timeline_activity_lifecycle_state
    source_timeline_activity_precondition_summary
    source_timeline_activity_state
    source_timeline_activity_status_state
    source_timeline_dependency_impact_summary
    source_timeline_diff_report
    source_timeline_diff_summary
    source_timeline_feedback_report
    source_timeline_integrity_report
    source_timeline_lifecycle_state_summary
    source_timeline_publication_summary
    source_timeline_transition_application_report
    source_timeline_transition_application_summary
    source_validation_safety_case_summary
    station_calendar_precedence_summary
    station_calendar_report
    station_reservation_hold_import_readiness_summary
    station_reservation_hold_summary
    station_reservation_report
    station_reservation_review_summary
    timeline_activity_approval_state
    timeline_activity_lifecycle_state
    timeline_activity_precondition_summary
    timeline_activity_state
    timeline_activity_status_state
    timeline_dependency_impact_summary
    timeline_diff_report
    timeline_diff_summary
    timeline_feedback_report
    timeline_integrity_report
    timeline_lifecycle_state_summary
    timeline_publication_summary
    timeline_transition_application_report
    timeline_transition_application_summary
    validation_safety_case_summary
  )

  @source_report_collection_projection_fields ~w(
	    source_candidate_diff_reports
	    source_candidate_rejection_reports
	    source_command_window_reports
	    source_constraint_reports
	    source_contact_allocation_reports
	    source_contact_contention_reports
	    source_contact_contention_resolution_reports
	    source_contact_filter_reports
	    source_contact_intents
	    source_freshness_reports
	    source_link_capacity_reports
	    source_maneuver_review_reports
	    source_model_acceptance_reports
	    source_objective_satisfaction_reports
	    source_objective_tradeoff_reports
	    source_operational_readiness_reports
	    source_operational_timeline_reports
	    source_provider_counteroffer_reports
	    source_quality_gate_reports
	    source_refresh_budget_reports
	    source_resource_filter_reports
	    source_resource_projection_reports
	    source_schema_validation_reports
	    source_score_term_reports
	    source_station_calendar_reports
	    source_station_reservation_reports
	    source_timeline_activity_lifecycle_states
	    source_timeline_activity_precondition_summaries
	    source_timeline_activity_states
	    source_timeline_dependency_impact_summaries
	    source_timeline_diff_reports
	    source_timeline_feedback_reports
	    source_timeline_integrity_reports
	    source_timeline_lifecycle_state_summaries
	    source_timeline_publication_summaries
	    source_timeline_transition_application_reports
	    source_validation_safety_case_summaries
	  )

  @accepted_state_core_projection_fields ~w(
    accepted_at
    current_epoch
    current_epoch_s
    ground_network
    maneuver_execution_deltas
    objectives
    operational_feedback
    provenance
    quality
    remaining_horizon
    resource_summaries
    schema_contract
    snapshot_id
    source
    spacecraft_states
    station_calendar
    station_calendar_provider
    targets
  )

  @refresh_core_projection_fields ~w(
	    accepted_planning_state
	    approval_policy
    candidate_limit_policy
    campaign_environment
    constraints
    contact_allocation_policy
    current_epoch
    current_epoch_s
    freshness_policy
    ground_network
    mission_state
    model_assumptions
    objectives
    operational_feedback
    prior_candidate_activities
    remaining_horizon
    resource_filter_policy
    resource_summaries
    run_input_sources
    schema_contract
    scoring_policy
    source_reports
    station_calendar
    station_calendar_provider
	    targets
	  )

  @candidate_refresh_nested_consumer_fields ~w(
	    _source_report_trust_boundary
	    access
	    access_windows
	    activity_context
	    activity_id
	    activity_type
	    actual_downlink_mb
	    actual_latency_s
	    allocation_reason
	    allow_overlap
	    allowed_state_quality_levels
	    altitude_km
	    approval_policy
	    assumptions
	    availability
	    availability_overrides
	    available
	    available_capacity_fraction
	    avoid_eclipse
	    blocked_candidate_id
	    blocked_contact_ids_by_spacecraft_id
	    blur_score
	    body
	    candidate_activities
	    candidate_activity_id
	    candidate_limit_policy
	    capacity_bps
	    capacity_fraction
	    capacity_model
	    capacity_pack_capacity_fraction
	    center_name
	    cloud_cover_fraction
	    collection_ids
	    contact
	    contact_allocation
	    contact_allocation_policy
	    contact_candidate
	    contact_candidates
	    contact_id
	    contact_ids
	    contact_success_rate
	    contact_type
	    contacts
	    contract
	    count
	    coverage
	    data_path_id
	    default
	    dependency_timeline_ids
	    direction
	    directions
	    downlink_activity_id
	    downlink_demand_mb
	    downlink_mb
	    downlink_rate_mb_s
	    drag_area_m2
	    drag_coefficient
	    dropped_candidate_count
	    dry_mass_kg
	    duration_s
	    eclipse
	    eclipse_intervals
	    eclipse_overlap_s
	    effective_allocation_status
	    end_s
	    ends_at_s
	    environment
	    epoch_s
	    evidence
	    executable_beam_digests
	    expires_at
	    expires_at_s
	    filters
	    frame
	    freshness_policy
	    fuel_margin
	    generated_at
	    ground_network
	    ground_station
	    ground_station_id
	    hold_expires_at_s
	    id
	    image_quality_score
	    image_quality_status
	    initial_state
	    invalid_candidate_limit_policy
	    invalid_candidate_limit_policy_reason
	    invalid_resource_summary_input_count
	    j2
	    latency_limit_s
	    latency_s
	    latitude_deg
	    lifecycle_state
	    longitude_deg
	    maneuver_execution_deltas
	    maneuvers
	    max_candidate_activities
	    max_candidates
	    max_horizon_start_offset_s
	    max_snapshot_age_s
	    metadata
	    min_activity_duration_s
	    minimum_elevation_deg
	    mission_state
	    mode
	    model_assumptions
	    mu_km3_s2
	    network_access
	    objective_id
	    objectives
	    observation_success_rate
	    operational_readiness
	    overlap_ends_at_s
	    overlap_starts_at_s
	    output_step_s
	    path
	    paths
	    planned_ground_station_id
	    planned_target_id
	    position_km
	    precondition_status
	    priority
	    product_ids
	    propagation
	    propellant_mass_kg
	    provenance
	    provider_entry_id
	    provider_id
	    publication_id
	    quality
	    quality_gate
	    reason
	    refresh_id
	    relay_chain_spacecraft_ids
	    relay_path
	    remaining_horizon
	    report_id
	    required_downlink_mb
	    required_observations
	    reservation_expires_at_s
	    reservation_hold_expires_at_s
	    reservation_id
	    reservation_match_status
	    reservation_status
	    reserved_by
	    resource_availability_overrides
	    resource_blocked_contact_ids_by_spacecraft_id
	    resource_blocking_dimension
	    resource_filter_policy
	    resource_id
	    resource_margin_overrides
	    resource_name
	    resource_pressure_rows
	    resource_provenance
	    resource_scope
	    resource_summaries
	    resource_trust_boundary
	    review_required
	    root_max_iterations
	    root_tolerance_s
	    route_id
	    row_count
	    run_input_sources
	    satellite
	    satellite_id
	    scenario_id
	    scenario_snapshot_id
	    score
	    scoring_policy
	    selection_scope
	    selected_contact_id
	    source
	    source_activity_context
	    source_activity_id
	    source_artifact_id
	    source_artifact_type
	    source_candidate_limit_policy
	    source_contact
	    source_contact_allocation
	    source_contact_candidate
	    source_contact_candidates
	    source_contacts
	    source_contention_recommendation
	    source_family
	    source_quality_gate_report_id
	    source_readiness_report_id
	    source_reports
	    source_resource_suppression
	    source_revision
	    source_station_calendar_entry
	    source_station_calendar_overlaps
	    source_station_calendar_provider_contention
	    source_summary_model
	    source_summary_schema_contract
	    source_summary_validation_status
	    source_window
	    source_window_id
	    spacecraft
	    spacecraft_availability
	    spacecraft_available
	    spacecraft_id
	    spacecraft_states
	    start_s
	    starts_at_s
	    state
	    state_vector
	    station_availability
	    station_calendar
	    station_calendar_ambiguous_entry_count
	    station_calendar_ambiguous_entry_ids
	    station_calendar_directions
	    station_calendar_entry_ambiguous
	    station_calendar_entry_id
	    station_calendar_overlap_availabilities
	    station_calendar_overlap_count
	    station_calendar_overlap_entry_ids
	    station_calendar_precedence_availability
	    station_calendar_provider
	    station_calendar_provider_entry_id
	    station_calendar_provider_id
	    station_calendar_reservation_expires_at_s
	    station_calendar_reservation_ids
	    station_calendar_reservation_overlap_count
	    station_calendar_reservation_statuses
	    station_calendar_reserved_by
	    station_calendar_status
	    station_calendar_trust_boundary
	    station_calendar_trust_boundary_status
	    station_capacity_fraction
	    station_contention_status
	    station_id
	    station_reservation_expires_at_s
	    station_reservation_id
	    station_reservation_match_status
	    station_reservation_status
	    station_reserved_by
	    status
	    storage_capacity_mb
	    storage_used_mb
	    study_id
	    summary
	    supersedes_artifact_ids
	    suppressed_candidate_count
	    suppressed_reason
	    target
	    target_id
	    targets
	    threshold
	    timeline_id
	    timeline_identity
	    time_scale
	    trust_boundaries
	    trust_boundary
	    trust_boundary_status
	    type
	    velocity_km_s
	    window_id
	    window_type
	  )

  @accepted_state_projection_fields Enum.sort(
                                      Enum.uniq(
                                        @accepted_state_core_projection_fields ++
                                          @direct_report_projection_fields ++
                                          @source_report_collection_projection_fields
                                      )
                                    )

  @refresh_projection_fields Enum.sort(
                               Enum.uniq(
                                 @refresh_core_projection_fields ++
                                   @direct_report_projection_fields ++
                                   @source_report_collection_projection_fields
                               )
                             )

  @evidence_authority_contract_fields ~w(
    accepted_state_encoding_projection_paths
    accepted_state_encoding_projection_required
    action
    artifact_type
    authenticated
    authentication
    authority
    build_encoding_projection_actions
    carry_through_surfaces
    claim
    component_order
    content_identity
    content_identity_authority
    conversion_applied
    covariance_authority
    covariance_component_order
    covariance_epoch
    covariance_epoch_binding
    covariance_frame_binding
    covariance_matrix_6x6
    covariance_numerical_check
    covariance_propagation_status
    covariance_ref_frame
    covariance_reference_frame
    covariance_source_identity
    covariance_status
    covariance_unit_contract
    created_by
    decision_authority
    declaration
    detail
    epoch
    evidence_authority
    frame
    generated_at
    handoff_status
    input_format
    issue_count
    issues
    known_limits
    l6_exclusions
    level
    matched
    metadata
    mixed_unit_declarations
    name
    omitted_issue_count
    position_km
    position_position
    position_velocity
    provenance
    quality
    reason
    review_reasons
    review_required
    scenario_id
    schema_contract
    schema_version
    scope
    seconds_since_j2000
    segments
    sha256
    signature
    signed
    source
    source_authority
    source_identity
    source_ref_frame
    source_revision
    spacecraft_id
    spacecraft_state_count
    state_evidence_scope
    state_epoch
    state_vector
    states_missing_covariance_evidence_count
    states_with_covariance_evidence_count
    status
    system
    time_scale
    trusted_authority
    velocity_km_s
    velocity_velocity
    verified
    verified_authority
  )

  @encoding_projection_fields Enum.sort(
                                Enum.uniq(
                                  @accepted_state_projection_fields ++
                                    @refresh_projection_fields ++
                                    @candidate_refresh_nested_consumer_fields ++
                                    @covariance_fields ++
                                    @complete_quality_fields ++
                                    @identity_keys ++
                                    @auth_claim_keys ++
                                    @evidence_authority_contract_fields
                                )
                              )

  @encoding_projection_atom_by_key Map.new(@encoding_projection_fields, fn key ->
                                     {key, String.to_atom(key)}
                                   end)

  @encoding_projection_key_by_atom Map.new(@encoding_projection_fields, fn key ->
                                     {String.to_atom(key), key}
                                   end)

  @negative_authority_values ~w(
    false
    no
    none
    not_applicable
    not_authenticated
    unauthenticated
    not_authority
    no_authority
    not_provided
    not_provided_by_byte_identity
    byte_identity_not_authority
    byte_identity_only
  )

  @build_encoding_unsafe_reasons ~w(
    accepted_state_evidence_binary_oversize
    accepted_state_evidence_improper_list_shape
    accepted_state_evidence_integer_oversize
    accepted_state_evidence_invalid_utf8
    accepted_state_evidence_node_budget_exceeded
    accepted_state_evidence_shape_deep
    accepted_state_evidence_shape_oversize
    accepted_state_maneuver_execution_deltas_oversize
    accepted_state_spacecraft_states_oversize
    atom_string_alias_collision
    invalid_accepted_state_shape
    invalid_maneuver_execution_deltas_shape
    invalid_spacecraft_states_shape
    unsupported_accepted_state_evidence_atom
    unsupported_accepted_state_evidence_atom_key
    unsupported_accepted_state_evidence_key
    unsupported_accepted_state_evidence_value
  )

  @handoff_surfaces [
    "accepted_planning_state.evidence_authority",
    "provenance.accepted_planning_state.evidence_authority"
  ]

  def schema_contract, do: @schema_contract
  def warning_message, do: @warning_message
  def accepted_state_projection_fields, do: @accepted_state_projection_fields
  def refresh_projection_fields, do: @refresh_projection_fields
  def encoding_projection_fields, do: @encoding_projection_fields
  def max_encoding_projection_nodes, do: @max_scan_nodes
  def max_encoding_projection_depth, do: @max_scan_depth
  def max_encoding_projection_map_entries, do: @max_map_entries
  def max_encoding_projection_list_entries, do: @max_list_entries
  def max_encoding_projection_binary_bytes, do: @max_binary_bytes
  def max_encoding_projection_segment_bytes, do: @max_encoding_projection_segment_bytes
  def refresh_encoding_redaction, do: @refresh_encoding_redaction

  def encoding_projection_atom_for_key(key) when is_binary(key),
    do: Map.get(@encoding_projection_atom_by_key, key)

  def encoding_projection_atom_for_key(_key), do: nil

  def encoding_projection_atom_key_token(key) when is_atom(key),
    do: Map.get(@encoding_projection_key_by_atom, key)

  def encoding_projection_atom_key_token(_key), do: nil

  def review_required?(value), do: Map.get(build(value), "review_required") == true

  def build(%{"schema_contract" => @schema_contract} = summary),
    do: normalize_existing_summary(summary)

  def build(%{} = value) do
    cond do
      candidate_refresh_artifact?(value) ->
        candidate_refresh_handoff_summary(value)

      refresh_wrapper?(value) ->
        from_refresh_wrapper(value)

      true ->
        from_accepted_state(value)
    end
  end

  def build(value), do: from_accepted_state(value)

  def analyze_refresh_wrapper(%{} = refresh) do
    {summary, refresh, outcome, cursor} = analyze_refresh_wrapper_transaction(refresh)

    %{
      refresh: refresh,
      evidence_authority: summary,
      build_encoding_outcome: outcome,
      analysis_cursor: cursor
    }
  end

  def analyze_refresh_wrapper(refresh) do
    summary =
      base_summary(0, 0)
      |> Map.put("state_evidence_scope", "accepted_planning_state.spacecraft_states")
      |> put_issue_summary([
        issue(
          "invalid_candidate_refresh_shape",
          "$.candidate_refresh",
          nil,
          safe_project_action("candidate_refresh")
        )
      ])

    %{
      refresh: @refresh_encoding_redaction,
      evidence_authority: summary,
      build_encoding_outcome: :whole_refresh_redaction,
      analysis_cursor: %{nodes: 0, overflow: true}
    }
  end

  defp analyze_refresh_wrapper_transaction(%{} = refresh) do
    {summary, projected, cursor} = transaction_refresh_wrapper(refresh)

    cond do
      Map.fetch!(cursor, :overflow) ->
        {summary, @refresh_encoding_redaction, :whole_refresh_redaction, cursor}

      field(summary, "accepted_state_encoding_projection_required") == true ->
        {summary, projected, :complete_projected_refresh, cursor}

      true ->
        {summary, refresh, :byte_preserve_raw_refresh, cursor}
    end
  end

  defp transaction_refresh_wrapper(%{} = refresh) do
    stats = transaction_initial_stats()

    case transaction_known_map(
           refresh,
           @refresh_projection_fields,
           "$.candidate_refresh",
           "candidate_refresh",
           [],
           0,
           0,
           stats
         ) do
      {:ok, projected, nodes, issues, stats} ->
        {transaction_summary(stats, issues), projected, %{nodes: nodes, overflow: false}}

      {:overflow, nodes, issues, stats} ->
        {transaction_summary(stats, issues), nil, %{nodes: nodes, overflow: true}}
    end
  end

  defp transaction_summary(stats, issues) do
    semantic_issues = transaction_semantic_issues(stats)
    states_with_evidence = transaction_states_with_covariance_evidence_count(stats)

    base_summary(
      Map.fetch!(stats, :spacecraft_state_count),
      states_with_evidence
    )
    |> Map.put("state_evidence_scope", "accepted_planning_state.spacecraft_states")
    |> put_issue_summary(issues ++ semantic_issues)
  end

  defp transaction_initial_stats do
    %{
      spacecraft_state_count: 0,
      states: %{},
      top_level_covariance: %{}
    }
  end

  defp transaction_semantic_issues(stats) do
    states_with_evidence = transaction_states_with_covariance_evidence_count(stats)

    transaction_state_accumulator_issues(Map.get(stats, :states, %{})) ++
      transaction_top_level_accumulator_issues(
        Map.get(stats, :top_level_covariance, %{}),
        states_with_evidence > 0
      )
  end

  defp transaction_states_with_covariance_evidence_count(stats) do
    stats
    |> Map.get(:states, %{})
    |> Enum.count(fn {_index, state} -> transaction_state_covariance_evidence_present?(state) end)
  end

  defp transaction_state_covariance_evidence_present?(state) do
    state
    |> Map.get(:containers, %{})
    |> Map.take(["quality", "metadata", "provenance"])
    |> Enum.any?(fn {_name, container} -> Map.get(container, :evidence_present?, false) end)
  end

  defp transaction_state_accumulator_issues(states) do
    states
    |> Enum.sort_by(fn {index, _state} -> index end)
    |> Enum.flat_map(fn {index, state} -> transaction_state_accumulator_issues(index, state) end)
  end

  defp transaction_state_accumulator_issues(index, state) do
    path = "$.accepted_planning_state.spacecraft_states[#{index}]"
    containers = transaction_state_covariance_containers(state)
    covariance_present? = transaction_state_covariance_evidence_present?(state)

    partial_issues =
      if covariance_present? and
           not transaction_quality_complete?(transaction_named_container(containers, "quality")) do
        [issue("partial_covariance_evidence", path <> ".quality")]
      else
        []
      end

    container_issues =
      containers
      |> Enum.flat_map(fn {name, container} ->
        transaction_covariance_container_accumulator_issues(state, container, path <> "." <> name)
      end)

    conflict_issues =
      ~w(
        covariance_reference_frame
        covariance_epoch
        covariance_unit_contract
        covariance_frame_binding
        covariance_epoch_binding
      )
      |> Enum.flat_map(fn field ->
        transaction_covariance_signature_conflict_issues(containers, path, field)
      end)

    partial_issues ++ container_issues ++ conflict_issues
  end

  defp transaction_state_covariance_containers(state) do
    stored_containers = Map.get(state, :containers, %{})

    ~w(quality metadata provenance)
    |> Enum.map(fn name ->
      {name, Map.get(stored_containers, name, transaction_empty_covariance_container())}
    end)
  end

  defp transaction_named_container(containers, name) do
    case Enum.find(containers, fn {container_name, _container} -> container_name == name end) do
      {_name, container} -> container
      nil -> transaction_empty_covariance_container()
    end
  end

  defp transaction_top_level_accumulator_issues(top_level_containers, states_have_evidence?) do
    containers =
      ~w(quality provenance source)
      |> Enum.map(fn name ->
        {name, Map.get(top_level_containers, name, transaction_empty_covariance_container())}
      end)

    top_level_has_covariance? =
      Enum.any?(containers, fn {_name, container} ->
        Map.get(container, :evidence_present?, false)
      end)

    partial_issues =
      if top_level_has_covariance? and not states_have_evidence? do
        [issue("partial_covariance_evidence", "$.accepted_planning_state.provenance")]
      else
        []
      end

    container_issues =
      containers
      |> Enum.flat_map(fn {name, container} ->
        transaction_covariance_container_accumulator_issues(
          transaction_default_state(),
          container,
          "$.accepted_planning_state." <> name
        )
      end)

    conflict_issues =
      ~w(
        covariance_reference_frame
        covariance_epoch
        covariance_unit_contract
        covariance_frame_binding
        covariance_epoch_binding
      )
      |> Enum.flat_map(fn field ->
        transaction_covariance_signature_conflict_issues(
          containers,
          "$.accepted_planning_state",
          field
        )
      end)

    partial_issues ++ container_issues ++ conflict_issues
  end

  defp transaction_covariance_container_accumulator_issues(state, container, path) do
    transaction_reference_frame_accumulator_issues(container, path) ++
      transaction_status_accumulator_issues(container, path) ++
      transaction_component_order_accumulator_issues(container, path) ++
      transaction_matrix_accumulator_issues(container, path) ++
      transaction_unit_contract_accumulator_issues(container, path) ++
      transaction_frame_binding_accumulator_issues(state, container, path) ++
      transaction_direct_epoch_accumulator_issues(container, path) ++
      transaction_epoch_binding_accumulator_issues(state, container, path) ++
      transaction_numerical_check_accumulator_issues(container, path) ++
      transaction_propagation_accumulator_issues(container, path)
  end

  defp transaction_reference_frame_accumulator_issues(container, path) do
    case transaction_field_record(container, "covariance_reference_frame") do
      %{present?: true, empty?: true} ->
        []

      %{present?: true, text: frame, detail: detail} ->
        if frame in @supported_ref_frames do
          []
        else
          [
            issue(
              "unsupported_covariance_reference_frame",
              path <> ".covariance_reference_frame",
              detail
            )
          ]
        end

      _record ->
        []
    end
  end

  defp transaction_status_accumulator_issues(container, path) do
    case transaction_field_record(container, "covariance_status") do
      %{present?: true, empty?: true} ->
        []

      %{present?: true, normalized: status, detail: detail} ->
        if status in @allowed_covariance_statuses do
          []
        else
          [issue("unsupported_covariance_status", path <> ".covariance_status", detail)]
        end

      _record ->
        []
    end
  end

  defp transaction_component_order_accumulator_issues(container, path) do
    case Map.get(container, :component_order) do
      %{present?: true} = order ->
        if transaction_component_order_supported?(order) do
          []
        else
          [
            issue(
              "unsupported_covariance_component_order",
              path <> ".covariance_component_order",
              transaction_order_detail(order)
            )
          ]
        end

      _order ->
        []
    end
  end

  defp transaction_matrix_accumulator_issues(container, path) do
    case Map.get(container, :matrix) do
      %{present?: true} = matrix ->
        case transaction_matrix_shape(matrix) do
          :ok ->
            []

          {:error, detail} ->
            [issue("invalid_covariance_matrix_shape", path <> ".covariance_matrix_6x6", detail)]
        end

      _matrix ->
        []
    end
  end

  defp transaction_unit_contract_accumulator_issues(container, path) do
    contract = Map.get(container, :unit_contract, %{})

    if Map.get(contract, :present?, false) do
      contract_path = path <> ".covariance_unit_contract"

      transaction_required_member_issues(
        contract,
        "declaration",
        @supported_unit_declarations,
        contract_path,
        "unsupported_covariance_unit_contract"
      ) ++
        transaction_required_exact_text_issues(
          contract,
          "position_position",
          "km**2",
          contract_path
        ) ++
        transaction_required_exact_text_issues(
          contract,
          "position_velocity",
          "km**2/s",
          contract_path
        ) ++
        transaction_required_exact_text_issues(
          contract,
          "velocity_velocity",
          "km**2/s**2",
          contract_path
        ) ++
        transaction_required_false_issues(
          contract,
          "mixed_unit_declarations",
          contract_path,
          "invalid_covariance_unit_contract_shape",
          "unsupported_covariance_unit_contract"
        ) ++
        transaction_unit_component_order_issues(contract, contract_path)
    else
      []
    end
  end

  defp transaction_frame_binding_accumulator_issues(state, container, path) do
    binding = Map.get(container, :frame_binding, %{})

    if Map.get(binding, :present?, false) do
      binding_path = path <> ".covariance_frame_binding"
      state_frame = Map.get(state, :frame)

      source_frame =
        transaction_required_text_member(binding, "source_ref_frame", @supported_ref_frames)

      covariance_frame =
        transaction_required_text_member(binding, "covariance_ref_frame", @supported_ref_frames)

      accepted_state_frame =
        transaction_required_text_member(binding, "accepted_state_frame", ["earth_inertial_j2000"])

      transaction_required_member_issues(
        binding,
        "source_ref_frame",
        @supported_ref_frames,
        binding_path,
        "invalid_covariance_frame_binding_shape"
      ) ++
        transaction_required_member_issues(
          binding,
          "covariance_ref_frame",
          @supported_ref_frames,
          binding_path,
          "invalid_covariance_frame_binding_shape"
        ) ++
        transaction_required_member_issues(
          binding,
          "accepted_state_frame",
          ["earth_inertial_j2000"],
          binding_path,
          "invalid_covariance_frame_binding_shape"
        ) ++
        transaction_required_false_issues(
          binding,
          "conversion_applied",
          binding_path,
          "invalid_covariance_frame_binding_shape",
          "covariance_frame_conversion_claimed"
        ) ++
        transaction_optional_true_issues(
          binding,
          "matched",
          binding_path,
          "covariance_frame_mismatch"
        ) ++
        transaction_maybe_mismatch_issue(
          is_binary(Map.get(state_frame || %{}, :text)) and is_binary(accepted_state_frame) and
            Map.get(state_frame, :text) != accepted_state_frame,
          "covariance_frame_mismatch",
          binding_path <> ".accepted_state_frame"
        ) ++
        transaction_maybe_mismatch_issue(
          is_binary(source_frame) and is_binary(covariance_frame) and
            source_frame != covariance_frame,
          "covariance_frame_mismatch",
          binding_path <> ".covariance_ref_frame"
        ) ++
        transaction_direct_reference_binding_issues(container, covariance_frame, path)
    else
      []
    end
  end

  defp transaction_direct_epoch_accumulator_issues(container, path) do
    direct_epoch = transaction_direct_epoch_text(container)
    binding = Map.get(container, :epoch_binding, %{})

    cond do
      is_nil(direct_epoch) ->
        []

      not Map.get(binding, :present?, false) ->
        [
          issue(
            "covariance_epoch_mismatch",
            path <> ".covariance_epoch",
            "missing_covariance_epoch_binding"
          )
        ]

      is_nil(transaction_epoch_binding_text(binding, "covariance_epoch")) ->
        [
          issue(
            "covariance_epoch_mismatch",
            path <> ".covariance_epoch",
            "missing_covariance_epoch_binding"
          )
        ]

      true ->
        []
    end
  end

  defp transaction_epoch_binding_accumulator_issues(state, container, path) do
    binding = Map.get(container, :epoch_binding, %{})

    if Map.get(binding, :present?, false) do
      binding_path = path <> ".covariance_epoch_binding"
      state_epoch_text = transaction_epoch_binding_text(binding, "state_epoch")
      covariance_epoch_text = transaction_epoch_binding_text(binding, "covariance_epoch")
      direct_epoch = transaction_direct_epoch_text(container)

      transaction_required_binary_text_issues(
        binding,
        "state_epoch",
        binding_path,
        "invalid_covariance_epoch_binding_shape"
      ) ++
        transaction_required_binary_text_issues(
          binding,
          "covariance_epoch",
          binding_path,
          "invalid_covariance_epoch_binding_shape"
        ) ++
        transaction_required_member_issues(
          binding,
          "time_scale",
          @supported_time_scales,
          binding_path,
          "invalid_covariance_epoch_binding_shape"
        ) ++
        transaction_required_true_issues(
          binding,
          "matched",
          binding_path,
          "covariance_epoch_mismatch"
        ) ++
        transaction_epoch_seconds_consistency_issues(
          binding,
          Map.get(state, :epoch_seconds, %{status: :missing}),
          binding_path
        ) ++
        transaction_maybe_mismatch_issue(
          is_binary(state_epoch_text) and is_binary(covariance_epoch_text) and
            state_epoch_text != covariance_epoch_text,
          "covariance_epoch_mismatch",
          binding_path <> ".covariance_epoch"
        ) ++
        transaction_maybe_mismatch_issue(
          is_binary(covariance_epoch_text) and is_binary(direct_epoch) and
            covariance_epoch_text != direct_epoch,
          "covariance_epoch_mismatch",
          binding_path <> ".covariance_epoch"
        )
    else
      []
    end
  end

  defp transaction_numerical_check_accumulator_issues(container, path) do
    check = Map.get(container, :numerical_check, %{})

    if Map.get(check, :present?, false) do
      check_path = path <> ".covariance_numerical_check"
      status = transaction_member_record(check, "status")

      status_issues =
        if Map.get(status || %{}, :normalized) == "passed" do
          []
        else
          [
            issue(
              "unsupported_covariance_numerical_status",
              check_path <> ".status",
              transaction_status_detail(status)
            )
          ]
        end

      status_issues ++
        transaction_required_supported_text_issues(
          check,
          "name",
          @covariance_numerical_check_name,
          check_path
        ) ++
        transaction_required_supported_text_issues(
          check,
          "claim",
          @covariance_numerical_check_claim,
          check_path
        )
    else
      []
    end
  end

  defp transaction_propagation_accumulator_issues(container, path) do
    case transaction_field_record(container, "covariance_propagation_status") do
      %{present?: true, empty?: true} ->
        []

      %{present?: true, normalized: "metadata_only_not_propagated"} ->
        []

      %{present?: true, detail: detail} ->
        [
          issue(
            "covariance_propagation_or_filtering_claimed",
            path <> ".covariance_propagation_status",
            detail
          )
        ]

      _record ->
        []
    end
  end

  defp transaction_quality_complete?(quality) do
    transaction_complete_covariance_status?(
      transaction_field_record(quality, "covariance_status")
    ) and
      transaction_component_order_supported?(Map.get(quality, :component_order)) and
      transaction_matrix_shape(Map.get(quality, :matrix)) == :ok and
      transaction_unit_contract_supported?(Map.get(quality, :unit_contract)) and
      transaction_frame_binding_supported?(Map.get(quality, :frame_binding)) and
      transaction_epoch_binding_supported?(Map.get(quality, :epoch_binding)) and
      transaction_numerical_check_supported?(Map.get(quality, :numerical_check)) and
      transaction_propagation_supported?(
        transaction_field_record(quality, "covariance_propagation_status")
      )
  end

  defp transaction_complete_covariance_status?(%{present?: true, normalized: status}),
    do: status in @allowed_covariance_statuses and status != "not_present"

  defp transaction_complete_covariance_status?(_record), do: false

  defp transaction_propagation_supported?(%{
         present?: true,
         normalized: "metadata_only_not_propagated"
       }),
       do: true

  defp transaction_propagation_supported?(_record), do: false

  defp transaction_unit_contract_supported?(%{present?: true} = contract),
    do: match?({:ok, _signature}, transaction_unit_contract_signature(contract))

  defp transaction_unit_contract_supported?(_contract), do: false

  defp transaction_frame_binding_supported?(%{present?: true} = binding),
    do: match?({:ok, _signature}, transaction_frame_binding_signature(binding))

  defp transaction_frame_binding_supported?(_binding), do: false

  defp transaction_epoch_binding_supported?(%{present?: true} = binding),
    do: match?({:ok, _signature}, transaction_epoch_binding_signature(binding))

  defp transaction_epoch_binding_supported?(_binding), do: false

  defp transaction_numerical_check_supported?(%{present?: true} = check) do
    Map.get(transaction_member_record(check, "status") || %{}, :normalized) == "passed" and
      transaction_member_exact_text?(check, "name", @covariance_numerical_check_name) and
      transaction_member_exact_text?(check, "claim", @covariance_numerical_check_claim)
  end

  defp transaction_numerical_check_supported?(_check), do: false

  defp transaction_required_member_issues(record, key, allowed, path, reason) do
    field_path = path <> "." <> key

    case transaction_member_record(record, key) do
      nil ->
        [issue(reason, field_path)]

      %{text: text, detail: detail} ->
        cond do
          is_binary(text) and text in allowed -> []
          is_binary(text) -> [issue(reason, field_path, detail)]
          true -> [issue(reason, field_path, detail)]
        end
    end
  end

  defp transaction_required_exact_text_issues(record, key, expected, path) do
    field_path = path <> "." <> key

    case transaction_member_record(record, key) do
      nil ->
        [issue("invalid_covariance_unit_contract_shape", field_path)]

      %{text: ^expected} ->
        []

      %{text: nil, detail: detail} ->
        [issue("invalid_covariance_unit_contract_shape", field_path, detail)]

      %{detail: detail} ->
        [issue("unsupported_covariance_unit_contract", field_path, detail)]
    end
  end

  defp transaction_required_binary_text_issues(record, key, path, reason) do
    field_path = path <> "." <> key

    case transaction_member_record(record, key) do
      nil -> [issue(reason, field_path)]
      %{binary_text: text} when is_binary(text) -> []
      %{invalid_text_detail: detail} -> [issue(reason, field_path, detail)]
      %{detail: detail} -> [issue(reason, field_path, detail)]
    end
  end

  defp transaction_required_false_issues(record, key, path, invalid_reason, true_reason) do
    field_path = path <> "." <> key

    case transaction_member_record(record, key) do
      %{boolean: false} -> []
      %{boolean: true} -> [issue(true_reason, field_path)]
      %{detail: detail} -> [issue(invalid_reason, field_path, detail)]
      nil -> [issue(invalid_reason, field_path)]
    end
  end

  defp transaction_required_true_issues(record, key, path, false_reason) do
    field_path = path <> "." <> key

    case transaction_member_record(record, key) do
      %{boolean: true} -> []
      %{boolean: false} -> [issue(false_reason, field_path)]
      %{detail: detail} -> [issue("invalid_covariance_epoch_binding_shape", field_path, detail)]
      nil -> [issue("invalid_covariance_epoch_binding_shape", field_path)]
    end
  end

  defp transaction_optional_true_issues(record, key, path, false_reason) do
    field_path = path <> "." <> key

    case transaction_member_record(record, key) do
      nil -> []
      %{boolean: true} -> []
      %{boolean: false} -> [issue(false_reason, field_path)]
      %{detail: detail} -> [issue("invalid_covariance_frame_binding_shape", field_path, detail)]
    end
  end

  defp transaction_unit_component_order_issues(contract, path) do
    case Map.get(contract, :component_order) do
      %{present?: true} = order ->
        if transaction_component_order_supported?(order) do
          []
        else
          [
            issue(
              "unsupported_covariance_component_order",
              path <> ".component_order",
              transaction_order_detail(order)
            )
          ]
        end

      _order ->
        [issue("unsupported_covariance_component_order", path <> ".component_order", "missing")]
    end
  end

  defp transaction_epoch_seconds_consistency_issues(binding, state_epoch_s, path) do
    field_path = path <> ".seconds_since_j2000"

    case transaction_member_record(binding, "seconds_since_j2000") do
      nil ->
        []

      %{number: value} when is_number(value) ->
        transaction_state_epoch_seconds_consistency_issues(value, state_epoch_s, field_path)

      %{detail: detail} ->
        [issue("invalid_covariance_epoch_binding_shape", field_path, detail)]
    end
  end

  defp transaction_state_epoch_seconds_consistency_issues(
         value,
         %{status: :present, value: state_value},
         path
       ) do
    if state_value == value do
      []
    else
      [issue("covariance_epoch_mismatch", path)]
    end
  end

  defp transaction_state_epoch_seconds_consistency_issues(_value, %{status: :invalid}, path),
    do: [issue("covariance_epoch_mismatch", path, "state_epoch_seconds_invalid")]

  defp transaction_state_epoch_seconds_consistency_issues(_value, _state_epoch_s, path),
    do: [issue("covariance_epoch_mismatch", path, "state_epoch_seconds_missing")]

  defp transaction_required_supported_text_issues(record, key, expected, path) do
    field_path = path <> "." <> key

    case transaction_member_record(record, key) do
      nil ->
        [issue("unsupported_covariance_numerical_check", field_path, "missing")]

      %{text: ^expected} ->
        []

      %{detail: detail} ->
        [issue("unsupported_covariance_numerical_check", field_path, detail)]
    end
  end

  defp transaction_direct_reference_binding_issues(container, covariance_frame, path) do
    reference_frame = transaction_field_text(container, "covariance_reference_frame")

    if is_binary(reference_frame) and is_binary(covariance_frame) and
         reference_frame != covariance_frame do
      [issue("covariance_frame_mismatch", path <> ".covariance_reference_frame")]
    else
      []
    end
  end

  defp transaction_maybe_mismatch_issue(true, reason, path), do: [issue(reason, path)]
  defp transaction_maybe_mismatch_issue(false, _reason, _path), do: []

  defp transaction_component_order_supported?(%{present?: true, count: 6, items: items}) do
    Enum.all?(0..5, fn index -> Map.get(items, index) == Enum.at(@component_order, index) end)
  end

  defp transaction_component_order_supported?(_order), do: false

  defp transaction_order_detail(%{shape: :improper}), do: "expected_proper_component_order"
  defp transaction_order_detail(%{shape: :oversize}), do: "expected_six_component_order"
  defp transaction_order_detail(_order), do: "unsupported_component_order"

  defp transaction_matrix_shape(%{present?: true, shape: :improper}),
    do: {:error, "expected_proper_6x6_numeric_matrix"}

  defp transaction_matrix_shape(%{present?: true, shape: :oversize}),
    do: {:error, "expected_6x6_numeric_matrix"}

  defp transaction_matrix_shape(%{present?: true, outer_count: 6, rows: rows}) do
    if Enum.all?(0..5, fn row_index ->
         transaction_matrix_row_supported?(Map.get(rows, row_index))
       end) do
      :ok
    else
      {:error, "expected_six_numeric_rows_with_six_numeric_values_each"}
    end
  end

  defp transaction_matrix_shape(%{present?: true}), do: {:error, "expected_6x6_numeric_matrix"}
  defp transaction_matrix_shape(_matrix), do: {:error, "expected_6x6_numeric_matrix"}

  defp transaction_matrix_row_supported?(%{shape: :ok, count: 6, values: values}) do
    Enum.all?(0..5, fn column_index -> Map.get(values, column_index) == :number end)
  end

  defp transaction_matrix_row_supported?(_row), do: false

  defp transaction_unit_contract_signature(contract) do
    with {:ok, declaration} <-
           transaction_signature_text_member(
             contract,
             "declaration",
             @supported_unit_declarations
           ),
         {:ok, position_position} <- transaction_signature_text(contract, "position_position"),
         {:ok, position_velocity} <- transaction_signature_text(contract, "position_velocity"),
         {:ok, velocity_velocity} <- transaction_signature_text(contract, "velocity_velocity"),
         {:ok, false} <- transaction_signature_false(contract, "mixed_unit_declarations"),
         true <- transaction_component_order_supported?(Map.get(contract, :component_order)),
         true <- position_position == "km**2",
         true <- position_velocity == "km**2/s",
         true <- velocity_velocity == "km**2/s**2" do
      {:ok, {:unit_contract, declaration, @component_order}}
    else
      _error -> :error
    end
  end

  defp transaction_frame_binding_signature(binding) do
    with {:ok, source_frame} <-
           transaction_signature_text_member(binding, "source_ref_frame", @supported_ref_frames),
         {:ok, covariance_frame} <-
           transaction_signature_text_member(
             binding,
             "covariance_ref_frame",
             @supported_ref_frames
           ),
         {:ok, accepted_state_frame} <-
           transaction_signature_text_member(binding, "accepted_state_frame", [
             "earth_inertial_j2000"
           ]),
         {:ok, false} <- transaction_signature_false(binding, "conversion_applied"),
         :ok <- transaction_signature_optional_true(binding, "matched"),
         true <- source_frame == covariance_frame do
      {:ok, {:frame_binding, source_frame, covariance_frame, accepted_state_frame}}
    else
      _error -> :error
    end
  end

  defp transaction_epoch_binding_signature(binding) do
    with {:ok, state_epoch} <- transaction_signature_binary_text(binding, "state_epoch"),
         {:ok, covariance_epoch} <- transaction_signature_binary_text(binding, "covariance_epoch"),
         {:ok, time_scale} <-
           transaction_signature_text_member(binding, "time_scale", @supported_time_scales),
         {:ok, true} <- transaction_signature_true(binding, "matched"),
         :ok <- transaction_signature_optional_number(binding, "seconds_since_j2000"),
         true <- state_epoch == covariance_epoch do
      {:ok, {:epoch_binding, state_epoch, covariance_epoch, time_scale}}
    else
      _error -> :error
    end
  end

  defp transaction_signature_text_member(record, key, allowed) do
    case transaction_signature_text(record, key) do
      {:ok, value} -> if value in allowed, do: {:ok, value}, else: :error
      _result -> :error
    end
  end

  defp transaction_signature_text(record, key) do
    case transaction_member_record(record, key) do
      %{text: text} when is_binary(text) -> {:ok, text}
      _record -> :error
    end
  end

  defp transaction_signature_binary_text(record, key) do
    case transaction_member_record(record, key) do
      %{binary_text: text} when is_binary(text) -> {:ok, text}
      _record -> :error
    end
  end

  defp transaction_signature_false(record, key) do
    case transaction_member_record(record, key) do
      %{boolean: false} -> {:ok, false}
      _record -> :error
    end
  end

  defp transaction_signature_true(record, key) do
    case transaction_member_record(record, key) do
      %{boolean: true} -> {:ok, true}
      _record -> :error
    end
  end

  defp transaction_signature_optional_true(record, key) do
    case transaction_member_record(record, key) do
      %{boolean: true} -> :ok
      nil -> :ok
      _record -> :error
    end
  end

  defp transaction_signature_optional_number(record, key) do
    case transaction_member_record(record, key) do
      %{number: value} when is_number(value) -> :ok
      nil -> :ok
      _record -> :error
    end
  end

  defp transaction_member_exact_text?(record, key, expected) do
    case transaction_member_record(record, key) do
      %{text: ^expected} -> true
      _record -> false
    end
  end

  defp transaction_required_text_member(record, key, allowed) do
    case transaction_member_record(record, key) do
      %{text: text} when is_binary(text) -> if text in allowed, do: text, else: nil
      _record -> nil
    end
  end

  defp transaction_field_text(container, key) do
    case transaction_field_record(container, key) do
      %{text: text} when is_binary(text) -> text
      _record -> nil
    end
  end

  defp transaction_direct_epoch_text(container) do
    case transaction_field_record(container, "covariance_epoch") do
      %{binary_text: text} when is_binary(text) -> text
      _record -> nil
    end
  end

  defp transaction_epoch_binding_text(binding, key) do
    case transaction_member_record(binding, key) do
      %{binary_text: text} when is_binary(text) -> text
      _record -> nil
    end
  end

  defp transaction_status_detail(nil), do: "unsupported_or_missing"

  defp transaction_status_detail(%{normalized: nil}), do: "unsupported_or_missing"

  defp transaction_status_detail(%{normalized: status}) when is_binary(status), do: status

  defp transaction_status_detail(%{detail: detail}), do: detail

  defp transaction_covariance_signature_conflict_issues(containers, path, field) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {{name, container}, index} ->
      case transaction_covariance_signature(container, field) do
        {:ok, signature} -> [{index, name, signature}]
        :error -> []
      end
    end)
    |> transaction_signature_conflict_issues(path, field)
  end

  defp transaction_signature_conflict_issues([], _path, _field), do: []

  defp transaction_signature_conflict_issues(
         [{source_index, _source_name, source_signature} | signatures],
         path,
         field
       ) do
    Enum.flat_map(signatures, fn {index, name, signature} ->
      if signature == source_signature do
        []
      else
        [
          issue(
            covariance_signature_conflict_reason(field),
            path <> "." <> name <> "." <> field,
            "conflicts_with_" <> covariance_container_name(source_index)
          )
        ]
      end
    end)
  end

  defp transaction_covariance_signature(container, "covariance_reference_frame") do
    case transaction_field_record(container, "covariance_reference_frame") do
      %{text: text} when is_binary(text) ->
        if text in @supported_ref_frames do
          {:ok, {:reference_frame, text}}
        else
          :error
        end

      _record ->
        :error
    end
  end

  defp transaction_covariance_signature(container, "covariance_epoch") do
    case transaction_field_record(container, "covariance_epoch") do
      %{binary_text: text} when is_binary(text) -> {:ok, {:epoch, text}}
      _record -> :error
    end
  end

  defp transaction_covariance_signature(container, "covariance_unit_contract") do
    transaction_unit_contract_signature(Map.get(container, :unit_contract, %{}))
  end

  defp transaction_covariance_signature(container, "covariance_frame_binding") do
    transaction_frame_binding_signature(Map.get(container, :frame_binding, %{}))
  end

  defp transaction_covariance_signature(container, "covariance_epoch_binding") do
    transaction_epoch_binding_signature(Map.get(container, :epoch_binding, %{}))
  end

  defp transaction_covariance_signature(_container, _field), do: :error

  defp transaction_accumulate_map_semantics(stats, _map, scope, segments),
    do: transaction_accumulate_semantic(stats, {:map, :present}, scope, segments)

  defp transaction_accumulate_list_semantics(stats, {:ok, items}, scope, segments),
    do:
      transaction_accumulate_semantic(stats, {:list, :ok, length_bounded(items)}, scope, segments)

  defp transaction_accumulate_list_semantics(stats, {:oversize, items}, scope, segments),
    do:
      transaction_accumulate_semantic(
        stats,
        {:list, :oversize, length_bounded(items)},
        scope,
        segments
      )

  defp transaction_accumulate_list_semantics(stats, {:improper, items}, scope, segments),
    do:
      transaction_accumulate_semantic(
        stats,
        {:list, :improper, length_bounded(items)},
        scope,
        segments
      )

  defp transaction_accumulate_scalar_semantics(stats, value, scope, segments),
    do: transaction_accumulate_semantic(stats, {:scalar, value}, scope, segments)

  defp transaction_accumulate_semantic(stats, event, "accepted_planning_state", segments) do
    stats
    |> transaction_record_state_scalar(event, segments)
    |> transaction_record_covariance_event(event, segments)
  end

  defp transaction_accumulate_semantic(stats, _event, _scope, _segments), do: stats

  defp transaction_record_state_scalar(stats, event, ["spacecraft_states", index, "frame"])
       when is_integer(index) do
    transaction_update_state(stats, index, fn state ->
      case event do
        {:scalar, value} -> Map.put(state, :frame, transaction_scalar_record(value))
        _event -> state
      end
    end)
  end

  defp transaction_record_state_scalar(
         stats,
         event,
         ["spacecraft_states", index, "epoch", "seconds_since_j2000"]
       )
       when is_integer(index) do
    transaction_update_state(stats, index, fn state ->
      Map.put(state, :epoch_seconds, transaction_epoch_seconds_record(event))
    end)
  end

  defp transaction_record_state_scalar(stats, _event, _segments), do: stats

  defp transaction_record_covariance_event(stats, event, segments) do
    case transaction_covariance_context(segments) do
      {:state, index, container_name, rest} ->
        transaction_update_state_container(stats, index, container_name, fn container ->
          transaction_update_covariance_container(container, rest, event)
        end)

      {:top_level, container_name, rest} ->
        transaction_update_top_level_container(stats, container_name, fn container ->
          transaction_update_covariance_container(container, rest, event)
        end)

      nil ->
        stats
    end
  end

  defp transaction_covariance_context(["spacecraft_states", index, container | rest])
       when is_integer(index) and container in ["quality", "metadata", "provenance"],
       do: {:state, index, container, rest}

  defp transaction_covariance_context([container | rest])
       when container in ["quality", "provenance", "source"],
       do: {:top_level, container, rest}

  defp transaction_covariance_context(_segments), do: nil

  defp transaction_update_covariance_container(container, [], _event), do: container

  defp transaction_update_covariance_container(container, [field], event) do
    container = transaction_mark_covariance_evidence(container, field, event)

    case field do
      "covariance_reference_frame" ->
        transaction_put_field_record(container, field, event)

      "covariance_epoch" ->
        transaction_put_field_record(container, field, event)

      "covariance_status" ->
        transaction_put_field_record(container, field, event)

      "covariance_component_order" ->
        transaction_put_component_order(container, event)

      "covariance_matrix_6x6" ->
        transaction_put_matrix(container, event)

      "covariance_unit_contract" ->
        transaction_put_nested_record(container, :unit_contract, event)

      "covariance_frame_binding" ->
        transaction_put_nested_record(container, :frame_binding, event)

      "covariance_epoch_binding" ->
        transaction_put_nested_record(container, :epoch_binding, event)

      "covariance_numerical_check" ->
        transaction_put_nested_record(container, :numerical_check, event)

      "covariance_propagation_status" ->
        transaction_put_field_record(container, field, event)

      _field ->
        container
    end
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_component_order", index],
         {:scalar, value}
       )
       when is_integer(index) do
    transaction_update_component_order(container, [:component_order], index, value)
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_matrix_6x6", row_index],
         event
       )
       when is_integer(row_index) do
    transaction_update_matrix_row(container, row_index, event)
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_matrix_6x6", row_index, column_index],
         {:scalar, value}
       )
       when is_integer(row_index) and is_integer(column_index) do
    transaction_update_matrix_value(container, row_index, column_index, value)
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_unit_contract", "component_order"],
         event
       ) do
    transaction_update_nested_component_order(container, :unit_contract, event)
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_unit_contract", "component_order", index],
         {:scalar, value}
       )
       when is_integer(index) do
    transaction_update_nested_component_order_item(container, :unit_contract, index, value)
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_unit_contract", field],
         {:scalar, value}
       ) do
    transaction_put_nested_member(
      container,
      :unit_contract,
      field,
      transaction_scalar_record(value)
    )
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_frame_binding", field],
         {:scalar, value}
       ) do
    transaction_put_nested_member(
      container,
      :frame_binding,
      field,
      transaction_scalar_record(value)
    )
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_epoch_binding", field],
         {:scalar, value}
       ) do
    transaction_put_nested_member(
      container,
      :epoch_binding,
      field,
      transaction_scalar_record(value)
    )
  end

  defp transaction_update_covariance_container(
         container,
         ["covariance_numerical_check", field],
         {:scalar, value}
       ) do
    transaction_put_nested_member(
      container,
      :numerical_check,
      field,
      transaction_scalar_record(value)
    )
  end

  defp transaction_update_covariance_container(container, _rest, _event), do: container

  defp transaction_mark_covariance_evidence(container, field, event) do
    if field in @covariance_fields and transaction_covariance_evidence_present?(field, event) do
      Map.put(container, :evidence_present?, true)
    else
      container
    end
  end

  defp transaction_covariance_evidence_present?("covariance_status", {:scalar, value}) do
    normalized_value(value) not in [nil, "", "not_present"]
  end

  defp transaction_covariance_evidence_present?(_field, {:scalar, value})
       when value in [nil, ""],
       do: false

  defp transaction_covariance_evidence_present?(_field, {:scalar, _value}), do: true
  defp transaction_covariance_evidence_present?(_field, {:map, :present}), do: true
  defp transaction_covariance_evidence_present?(_field, {:list, _shape, _count}), do: true

  defp transaction_put_field_record(container, field, {:scalar, value}) do
    fields = Map.put(Map.get(container, :fields, %{}), field, transaction_scalar_record(value))
    Map.put(container, :fields, fields)
  end

  defp transaction_put_field_record(container, field, event) do
    fields = Map.put(Map.get(container, :fields, %{}), field, transaction_event_record(event))
    Map.put(container, :fields, fields)
  end

  defp transaction_put_component_order(container, {:list, shape, count}) do
    Map.put(container, :component_order, %{present?: true, shape: shape, count: count, items: %{}})
  end

  defp transaction_put_component_order(container, event) do
    Map.put(container, :component_order, transaction_event_record(event))
  end

  defp transaction_update_component_order(container, [order_key], index, value) do
    order =
      container
      |> Map.get(order_key, %{present?: true, shape: :ok, count: nil, items: %{}})
      |> Map.update(:items, %{index => exact_bounded_text(value)}, fn items ->
        Map.put(items, index, exact_bounded_text(value))
      end)

    Map.put(container, order_key, order)
  end

  defp transaction_put_matrix(container, {:list, shape, count}) do
    Map.put(container, :matrix, %{present?: true, shape: shape, outer_count: count, rows: %{}})
  end

  defp transaction_put_matrix(container, event) do
    Map.put(container, :matrix, transaction_event_record(event))
  end

  defp transaction_update_matrix_row(container, row_index, {:list, shape, count}) do
    matrix =
      Map.get(container, :matrix, %{present?: true, shape: :ok, outer_count: nil, rows: %{}})

    rows = Map.get(matrix, :rows, %{})
    row = Map.merge(Map.get(rows, row_index, %{}), %{shape: shape, count: count})

    matrix =
      matrix
      |> Map.put(:present?, true)
      |> Map.put(:rows, Map.put(rows, row_index, row))

    Map.put(container, :matrix, matrix)
  end

  defp transaction_update_matrix_row(container, row_index, event) do
    matrix =
      Map.get(container, :matrix, %{present?: true, shape: :ok, outer_count: nil, rows: %{}})

    rows = Map.get(matrix, :rows, %{})
    row = Map.merge(Map.get(rows, row_index, %{}), transaction_event_record(event))

    matrix =
      matrix
      |> Map.put(:present?, true)
      |> Map.put(:rows, Map.put(rows, row_index, row))

    Map.put(container, :matrix, matrix)
  end

  defp transaction_update_matrix_value(container, row_index, column_index, value) do
    matrix =
      Map.get(container, :matrix, %{present?: true, shape: :ok, outer_count: nil, rows: %{}})

    rows = Map.get(matrix, :rows, %{})
    row = Map.get(rows, row_index, %{values: %{}})

    marker =
      if is_number(value) and bounded_number?(value) do
        :number
      else
        :invalid
      end

    row = Map.update(row, :values, %{column_index => marker}, &Map.put(&1, column_index, marker))
    matrix = matrix |> Map.put(:present?, true) |> Map.put(:rows, Map.put(rows, row_index, row))
    Map.put(container, :matrix, matrix)
  end

  defp transaction_put_nested_record(container, nested_key, {:map, :present}) do
    Map.put(container, nested_key, Map.put(Map.get(container, nested_key, %{}), :present?, true))
  end

  defp transaction_put_nested_record(container, nested_key, {:scalar, nil})
       when nested_key in [:unit_contract, :frame_binding, :epoch_binding] do
    container
  end

  defp transaction_put_nested_record(container, nested_key, event) do
    Map.put(container, nested_key, transaction_event_record(event))
  end

  defp transaction_put_nested_member(container, nested_key, field, record) do
    nested =
      container
      |> Map.get(nested_key, %{present?: true, members: %{}})
      |> Map.put(:present?, true)
      |> Map.update(:members, %{field => record}, fn members ->
        Map.put(members, field, record)
      end)

    Map.put(container, nested_key, nested)
  end

  defp transaction_update_nested_component_order(container, nested_key, {:list, shape, count}) do
    nested =
      container
      |> Map.get(nested_key, %{present?: true, members: %{}})
      |> Map.put(:present?, true)
      |> Map.put(:component_order, %{present?: true, shape: shape, count: count, items: %{}})

    Map.put(container, nested_key, nested)
  end

  defp transaction_update_nested_component_order(container, nested_key, event) do
    nested =
      container
      |> Map.get(nested_key, %{present?: true, members: %{}})
      |> Map.put(:present?, true)
      |> Map.put(:component_order, transaction_event_record(event))

    Map.put(container, nested_key, nested)
  end

  defp transaction_update_nested_component_order_item(container, nested_key, index, value) do
    nested =
      container
      |> Map.get(nested_key, %{present?: true, members: %{}})
      |> Map.put(:present?, true)

    order =
      nested
      |> Map.get(:component_order, %{present?: true, shape: :ok, count: nil, items: %{}})
      |> Map.update(:items, %{index => exact_bounded_text(value)}, fn items ->
        Map.put(items, index, exact_bounded_text(value))
      end)

    Map.put(container, nested_key, Map.put(nested, :component_order, order))
  end

  defp transaction_event_record({:map, :present}), do: %{present?: true, kind: :map}

  defp transaction_event_record({:list, shape, count}),
    do: %{present?: true, kind: :list, shape: shape, count: count}

  defp transaction_event_record({:scalar, value}), do: transaction_scalar_record(value)

  defp transaction_scalar_record(value) do
    %{
      present?: true,
      kind: :scalar,
      text: exact_bounded_text(value),
      binary_text: nonempty_binary_text(value),
      invalid_text_detail: invalid_text_detail(value),
      normalized: normalized_value(value),
      boolean: if(is_boolean(value), do: value, else: nil),
      number: transaction_number_value(value),
      empty?: value in [nil, ""],
      detail: encoded_value(value)
    }
  end

  defp transaction_number_value(value) when is_number(value) do
    if bounded_number?(value), do: value, else: nil
  end

  defp transaction_number_value(_value), do: nil

  defp transaction_epoch_seconds_record({:scalar, value}) when is_integer(value) do
    if bounded_integer?(value), do: %{status: :present, value: value}, else: %{status: :invalid}
  end

  defp transaction_epoch_seconds_record({:scalar, value}) when is_float(value) do
    if bounded_number?(value), do: %{status: :present, value: value}, else: %{status: :invalid}
  end

  defp transaction_epoch_seconds_record({_kind, _shape, _count}), do: %{status: :invalid}
  defp transaction_epoch_seconds_record(_event), do: %{status: :invalid}

  defp transaction_field_record(%{} = container, key),
    do: container |> Map.get(:fields, %{}) |> Map.get(key)

  defp transaction_field_record(_container, _key), do: nil

  defp transaction_member_record(%{} = record, key),
    do: record |> Map.get(:members, %{}) |> Map.get(key)

  defp transaction_member_record(_record, _key), do: nil

  defp transaction_empty_covariance_container do
    %{
      evidence_present?: false,
      fields: %{},
      matrix: %{},
      component_order: %{},
      unit_contract: %{},
      frame_binding: %{},
      epoch_binding: %{},
      numerical_check: %{}
    }
  end

  defp transaction_default_state do
    %{
      frame: nil,
      epoch_seconds: %{status: :missing},
      containers: %{}
    }
  end

  defp transaction_update_state(stats, index, fun) do
    states = Map.get(stats, :states, %{})
    state = fun.(Map.get(states, index, transaction_default_state()))
    Map.put(stats, :states, Map.put(states, index, state))
  end

  defp transaction_update_state_container(stats, index, container_name, fun) do
    transaction_update_state(stats, index, fn state ->
      containers = Map.get(state, :containers, %{})

      container =
        fun.(Map.get(containers, container_name, transaction_empty_covariance_container()))

      Map.put(state, :containers, Map.put(containers, container_name, container))
    end)
  end

  defp transaction_update_top_level_container(stats, container_name, fun) do
    containers = Map.get(stats, :top_level_covariance, %{})

    container =
      fun.(Map.get(containers, container_name, transaction_empty_covariance_container()))

    Map.put(stats, :top_level_covariance, Map.put(containers, container_name, container))
  end

  defp transaction_known_map(%{} = map, fields, path, scope, segments, depth, nodes, stats) do
    case transaction_enter_node(path, scope, segments, depth, nodes) do
      {:ok, nodes} ->
        entries = bounded_entries(map)
        collision_tokens = projection_alias_collision_tokens(entries)

        own_issues =
          map_size_issue(map, path, safe_project_action(scope)) ++
            key_shape_issues(entries, path, sanitize_map_action(scope, segments)) ++
            projection_field_alias_issues(map, path, scope, segments) ++
            alias_collision_issues(entries, path, sanitize_map_action(scope, segments))

        with {:ok, projection, nodes, issues, stats} <-
               transaction_known_fields(
                 fields,
                 map,
                 path,
                 scope,
                 segments,
                 depth + 1,
                 nodes,
                 own_issues,
                 stats,
                 collision_tokens,
                 %{}
               ),
             {:ok, nodes, issues, stats} <-
               transaction_scan_unretained_entries(
                 map,
                 entries,
                 fields,
                 path,
                 scope,
                 segments,
                 depth + 1,
                 nodes,
                 issues,
                 stats
               ) do
          {:ok, projection, nodes, issues, stats}
        else
          {:overflow, nodes, issues, stats} -> {:overflow, nodes, issues, stats}
        end

      {:drop, nodes, issues} ->
        {:ok, :drop, nodes, issues, stats}

      {:overflow, nodes, issues} ->
        {:overflow, nodes, issues, stats}
    end
  end

  defp transaction_known_fields(
         [],
         _map,
         _path,
         _scope,
         _segments,
         _depth,
         nodes,
         issues,
         stats,
         _collision_tokens,
         projection
       ) do
    {:ok, projection, nodes, issues, stats}
  end

  defp transaction_known_fields(
         [field | rest],
         map,
         path,
         scope,
         segments,
         depth,
         nodes,
         issues,
         stats,
         collision_tokens,
         projection
       ) do
    cond do
      MapSet.member?(collision_tokens, field) ->
        transaction_known_fields(
          rest,
          map,
          path,
          scope,
          segments,
          depth,
          nodes,
          issues,
          stats,
          collision_tokens,
          projection
        )

      true ->
        case fetch_known_public_field(map, field) do
          {:ok, value} ->
            child_scope = transaction_child_scope(scope, field)
            child_segments = transaction_child_segments(scope, segments, field)
            child_path = transaction_child_path(path, scope, field)

            if nodes >= @max_scan_nodes do
              {:overflow, nodes,
               [
                 issue(
                   "accepted_state_evidence_node_budget_exceeded",
                   child_path,
                   "max_scan_nodes_exceeded",
                   delete_action(child_scope, child_segments)
                 )
                 | issues
               ], stats}
            else
              case transaction_known_field(
                     field,
                     value,
                     child_path,
                     child_scope,
                     child_segments,
                     depth,
                     nodes,
                     stats
                   ) do
                {:ok, :drop, nodes, child_issues, stats} ->
                  transaction_known_fields(
                    rest,
                    map,
                    path,
                    scope,
                    segments,
                    depth,
                    nodes,
                    issues ++ child_issues,
                    stats,
                    collision_tokens,
                    projection
                  )

                {:ok, projected_value, nodes, child_issues, stats} ->
                  transaction_known_fields(
                    rest,
                    map,
                    path,
                    scope,
                    segments,
                    depth,
                    nodes,
                    issues ++ child_issues,
                    stats,
                    collision_tokens,
                    Map.put(projection, field, projected_value)
                  )

                {:overflow, nodes, child_issues, stats} ->
                  {:overflow, nodes, issues ++ child_issues, stats}
              end
            end

          _result ->
            transaction_known_fields(
              rest,
              map,
              path,
              scope,
              segments,
              depth,
              nodes,
              issues,
              stats,
              collision_tokens,
              projection
            )
        end
    end
  end

  defp transaction_known_field(
         "accepted_planning_state",
         %{} = accepted_state,
         _path,
         _scope,
         _segments,
         depth,
         nodes,
         stats
       ) do
    case transaction_known_map(
           accepted_state,
           @accepted_state_projection_fields,
           "$.accepted_planning_state",
           "accepted_planning_state",
           [],
           depth,
           nodes,
           stats
         ) do
      {:ok, projection, nodes, issues, stats} ->
        {:ok, projection, nodes, issues, stats}

      {:overflow, nodes, issues, stats} ->
        {:overflow, nodes, issues, stats}
    end
  end

  defp transaction_known_field(
         "accepted_planning_state",
         _accepted_state,
         _path,
         _scope,
         _segments,
         depth,
         nodes,
         stats
       ) do
    transaction_drop(
      "invalid_accepted_state_shape",
      "$.candidate_refresh.accepted_planning_state",
      nil,
      projection_action("candidate_refresh", "delete", ["accepted_planning_state"]),
      depth,
      nodes,
      stats
    )
  end

  defp transaction_known_field(
         "spacecraft_states",
         values,
         path,
         "accepted_planning_state",
         segments,
         depth,
         nodes,
         stats
       ) do
    transaction_spacecraft_states(values, path, segments, depth, nodes, stats)
  end

  defp transaction_known_field(
         "maneuver_execution_deltas",
         values,
         path,
         "accepted_planning_state",
         segments,
         depth,
         nodes,
         stats
       ) do
    transaction_maneuver_execution_deltas(values, path, segments, depth, nodes, stats)
  end

  defp transaction_known_field(_field, value, path, scope, segments, depth, nodes, stats),
    do: transaction_value(value, path, scope, segments, depth, nodes, stats)

  defp transaction_spacecraft_states(values, path, segments, depth, nodes, stats)
       when is_list(values) do
    case transaction_enter_node(path, "accepted_planning_state", segments, depth, nodes) do
      {:ok, nodes} ->
        case bounded_list_items(values, @max_spacecraft_states) do
          {:ok, items} ->
            transaction_spacecraft_state_items(items, depth + 1, nodes, [], [], stats, 0)

          {:oversize, _items} ->
            {:ok, :drop, nodes,
             [
               issue(
                 "accepted_state_spacecraft_states_oversize",
                 path,
                 "max_spacecraft_states_exceeded",
                 delete_action("accepted_planning_state", ["spacecraft_states"])
               )
             ], stats}

          {:improper, _items} ->
            {:ok, :drop, nodes,
             [
               issue(
                 "invalid_spacecraft_states_shape",
                 path,
                 nil,
                 delete_action("accepted_planning_state", ["spacecraft_states"])
               )
             ], stats}
        end

      {:drop, nodes, issues} ->
        {:ok, :drop, nodes, issues, stats}

      {:overflow, nodes, issues} ->
        {:overflow, nodes, issues, stats}
    end
  end

  defp transaction_spacecraft_states(nil, path, _segments, depth, nodes, stats) do
    transaction_drop(
      "invalid_spacecraft_states_shape",
      path,
      "nil",
      delete_action("accepted_planning_state", ["spacecraft_states"]),
      depth,
      nodes,
      stats
    )
  end

  defp transaction_spacecraft_states(values, path, _segments, depth, nodes, stats) do
    transaction_drop(
      "invalid_spacecraft_states_shape",
      path,
      encoded_value(values),
      delete_action("accepted_planning_state", ["spacecraft_states"]),
      depth,
      nodes,
      stats
    )
  end

  defp transaction_spacecraft_state_items(
         [],
         _depth,
         nodes,
         projected_items,
         issues,
         stats,
         _index
       ) do
    {:ok, Enum.reverse(projected_items), nodes, issues, stats}
  end

  defp transaction_spacecraft_state_items(
         [state | rest],
         depth,
         nodes,
         projected_items,
         issues,
         stats,
         index
       ) do
    state_path = "$.accepted_planning_state.spacecraft_states[#{index}]"
    state_segments = ["spacecraft_states", index]

    stats = Map.update!(stats, :spacecraft_state_count, &(&1 + 1))

    case transaction_value(
           state,
           state_path,
           "accepted_planning_state",
           state_segments,
           depth,
           nodes,
           stats
         ) do
      {:ok, %{} = projected_state, nodes, projection_issues, stats} ->
        transaction_spacecraft_state_items(
          rest,
          depth,
          nodes,
          [projected_state | projected_items],
          issues ++ projection_issues,
          stats,
          index + 1
        )

      {:ok, _projected_state, nodes, projection_issues, stats} ->
        transaction_spacecraft_state_items(
          rest,
          depth,
          nodes,
          projected_items,
          issues ++
            projection_issues ++
            [issue("invalid_spacecraft_state_shape", state_path)],
          stats,
          index + 1
        )

      {:overflow, nodes, projection_issues, stats} ->
        {:overflow, nodes, issues ++ projection_issues, stats}
    end
  end

  defp transaction_maneuver_execution_deltas(values, path, segments, depth, nodes, stats)
       when is_list(values) do
    case transaction_enter_node(path, "accepted_planning_state", segments, depth, nodes) do
      {:ok, nodes} ->
        case bounded_list_items(values, @max_list_entries) do
          {:ok, items} ->
            transaction_project_list_items(
              items,
              path,
              "accepted_planning_state",
              segments,
              depth + 1,
              nodes,
              [],
              [],
              stats,
              0
            )

          {:oversize, _items} ->
            {:ok, :drop, nodes,
             [
               issue(
                 "accepted_state_maneuver_execution_deltas_oversize",
                 path,
                 "max_maneuver_execution_deltas_exceeded",
                 delete_action("accepted_planning_state", ["maneuver_execution_deltas"])
               )
             ], stats}

          {:improper, _items} ->
            {:ok, :drop, nodes,
             [
               issue(
                 "invalid_maneuver_execution_deltas_shape",
                 path,
                 nil,
                 delete_action("accepted_planning_state", ["maneuver_execution_deltas"])
               )
             ], stats}
        end

      {:drop, nodes, issues} ->
        {:ok, :drop, nodes, issues, stats}

      {:overflow, nodes, issues} ->
        {:overflow, nodes, issues, stats}
    end
  end

  defp transaction_maneuver_execution_deltas(nil, path, _segments, depth, nodes, stats) do
    transaction_drop(
      "invalid_maneuver_execution_deltas_shape",
      path,
      "nil",
      delete_action("accepted_planning_state", ["maneuver_execution_deltas"]),
      depth,
      nodes,
      stats
    )
  end

  defp transaction_maneuver_execution_deltas(values, path, _segments, depth, nodes, stats) do
    transaction_drop(
      "invalid_maneuver_execution_deltas_shape",
      path,
      encoded_value(values),
      delete_action("accepted_planning_state", ["maneuver_execution_deltas"]),
      depth,
      nodes,
      stats
    )
  end

  defp transaction_value(value, path, scope, segments, depth, nodes, stats) do
    cond do
      nodes >= @max_scan_nodes ->
        {:overflow, nodes,
         [
           issue(
             "accepted_state_evidence_node_budget_exceeded",
             path,
             "max_scan_nodes_exceeded",
             delete_action(scope, segments)
           )
         ], stats}

      depth > @max_scan_depth ->
        {:ok, :drop, nodes + 1,
         [
           issue(
             "accepted_state_evidence_shape_deep",
             path,
             "max_scan_depth_exceeded",
             delete_action(scope, segments)
           )
         ], stats}

      is_map(value) ->
        transaction_map_value(value, path, scope, segments, depth, nodes, stats)

      is_list(value) ->
        transaction_list_value(value, path, scope, segments, depth, nodes, stats)

      true ->
        transaction_scalar_value(value, path, scope, segments, nodes, stats)
    end
  end

  defp transaction_map_value(%{} = map, path, scope, segments, depth, nodes, stats) do
    case transaction_enter_node(path, scope, segments, depth, nodes) do
      {:ok, nodes} ->
        entries = bounded_entries(map)
        collision_tokens = projection_alias_collision_tokens(entries)
        semantic_issues = transaction_path_semantic_issues(map, path, scope, segments)
        stats = transaction_accumulate_map_semantics(stats, map, scope, segments)

        own_issues =
          semantic_issues ++
            map_size_issue(map, path, safe_project_action(scope)) ++
            key_shape_issues(entries, path, sanitize_map_action(scope, segments)) ++
            projection_field_alias_issues(map, path, scope, segments) ++
            alias_collision_issues(entries, path, sanitize_map_action(scope, segments))

        if map_size(map) > @max_map_entries do
          case transaction_scan_entry_values(
                 entries,
                 path,
                 scope,
                 segments,
                 depth + 1,
                 nodes,
                 own_issues,
                 stats
               ) do
            {:ok, nodes, issues, stats} -> {:ok, :drop, nodes, issues, stats}
            {:overflow, nodes, issues, stats} -> {:overflow, nodes, issues, stats}
          end
        else
          transaction_project_entries(
            entries,
            collision_tokens,
            path,
            scope,
            segments,
            depth + 1,
            nodes,
            own_issues,
            stats,
            %{}
          )
          |> transaction_maybe_drop_semantic_projection(semantic_issues)
        end

      {:drop, nodes, issues} ->
        {:ok, :drop, nodes, issues, stats}

      {:overflow, nodes, issues} ->
        {:overflow, nodes, issues, stats}
    end
  end

  defp transaction_list_value(values, path, scope, segments, depth, nodes, stats) do
    case transaction_enter_node(path, scope, segments, depth, nodes) do
      {:ok, nodes} ->
        semantic_issues = transaction_path_semantic_issues(values, path, scope, segments)

        case bounded_list_items(values, @max_list_entries) do
          {:ok, items} ->
            stats = transaction_accumulate_list_semantics(stats, {:ok, items}, scope, segments)

            transaction_project_list_items(
              items,
              path,
              scope,
              segments,
              depth + 1,
              nodes,
              [],
              semantic_issues,
              stats,
              0
            )
            |> transaction_maybe_drop_semantic_projection(semantic_issues)

          {:oversize, items} ->
            stats =
              transaction_accumulate_list_semantics(stats, {:oversize, items}, scope, segments)

            issues =
              semantic_issues ++
                [
                  issue(
                    "accepted_state_evidence_shape_oversize",
                    path,
                    "max_list_entries_exceeded",
                    delete_action(scope, segments)
                  )
                ]

            case transaction_scan_list_values(
                   items,
                   path,
                   scope,
                   segments,
                   depth + 1,
                   nodes,
                   issues,
                   stats,
                   0
                 ) do
              {:ok, nodes, issues, stats} -> {:ok, :drop, nodes, issues, stats}
              {:overflow, nodes, issues, stats} -> {:overflow, nodes, issues, stats}
            end

          {:improper, items} ->
            stats =
              transaction_accumulate_list_semantics(stats, {:improper, items}, scope, segments)

            issues =
              semantic_issues ++
                [
                  issue(
                    "accepted_state_evidence_improper_list_shape",
                    path,
                    nil,
                    delete_action(scope, segments)
                  )
                ]

            case transaction_scan_list_values(
                   items,
                   path,
                   scope,
                   segments,
                   depth + 1,
                   nodes,
                   issues,
                   stats,
                   0
                 ) do
              {:ok, nodes, issues, stats} -> {:ok, :drop, nodes, issues, stats}
              {:overflow, nodes, issues, stats} -> {:overflow, nodes, issues, stats}
            end
        end

      {:drop, nodes, issues} ->
        {:ok, :drop, nodes, issues, stats}

      {:overflow, nodes, issues} ->
        {:overflow, nodes, issues, stats}
    end
  end

  defp transaction_scalar_value(value, path, scope, segments, nodes, stats) do
    issues =
      scalar_shape_issues(value, path, delete_action(scope, segments)) ++
        transaction_path_semantic_issues(value, path, scope, segments)

    stats = transaction_accumulate_scalar_semantics(stats, value, scope, segments)

    case transaction_scalar_projection(value, issues) do
      {:ok, projected} -> {:ok, projected, nodes + 1, issues, stats}
      :drop -> {:ok, :drop, nodes + 1, issues, stats}
    end
  end

  defp transaction_scalar_projection(value, []) when is_binary(value) do
    case bounded_binary(value) do
      {:ok, value} -> {:ok, value}
      {:error, _reason} -> :drop
    end
  end

  defp transaction_scalar_projection(value, []) when is_integer(value) do
    if bounded_integer?(value), do: {:ok, value}, else: :drop
  end

  defp transaction_scalar_projection(value, []) when is_float(value) do
    if bounded_number?(value), do: {:ok, value}, else: :drop
  end

  defp transaction_scalar_projection(value, []) when is_boolean(value) or is_nil(value),
    do: {:ok, value}

  defp transaction_scalar_projection(value, []) when is_atom(value) do
    case atom_value_token(value) do
      nil -> :drop
      token -> {:ok, token}
    end
  end

  defp transaction_scalar_projection(_value, _issues), do: :drop

  defp transaction_maybe_drop_semantic_projection({:ok, _projection, nodes, issues, stats}, [
         _issue | _rest
       ]),
       do: {:ok, :drop, nodes, issues, stats}

  defp transaction_maybe_drop_semantic_projection(result, _semantic_issues), do: result

  defp transaction_path_semantic_issues(value, path, scope, segments) do
    cond do
      accepted_state_evidence_container_segments?(segments) ->
        transaction_state_evidence_container_issues(value, path, scope, segments)

      state_evidence_container_segments?(segments) ->
        transaction_state_evidence_container_issues(value, path, scope, segments)

      state_epoch_seconds_segments?(segments) ->
        transaction_state_epoch_seconds_issues(value, path, scope, segments)

      covariance_matrix_row_segments?(segments) ->
        transaction_covariance_matrix_row_issues(value, path, scope, segments)

      covariance_matrix_segments?(segments) ->
        transaction_covariance_matrix_issues(value, path, scope, segments)

      covariance_component_order_segments?(segments) ->
        transaction_component_order_issues(value, path, scope, segments)

      covariance_status_segments?(segments) ->
        transaction_covariance_status_issues(value, path, scope, segments)

      covariance_reference_frame_segments?(segments) ->
        transaction_covariance_reference_frame_issues(value, path, scope, segments)

      covariance_propagation_status_segments?(segments) ->
        transaction_covariance_propagation_status_issues(value, path, scope, segments)

      direct_covariance_epoch_segments?(segments) ->
        transaction_direct_covariance_epoch_issues(value, path, scope, segments)

      covariance_unit_contract_segments?(segments) ->
        transaction_container_shape_issues(
          value,
          path,
          scope,
          segments,
          "invalid_covariance_unit_contract_shape"
        )

      covariance_frame_binding_segments?(segments) ->
        transaction_container_shape_issues(
          value,
          path,
          scope,
          segments,
          "invalid_covariance_frame_binding_shape"
        )

      covariance_epoch_binding_segments?(segments) ->
        transaction_container_shape_issues(
          value,
          path,
          scope,
          segments,
          "invalid_covariance_epoch_binding_shape"
        )

      covariance_numerical_check_segments?(segments) ->
        transaction_container_shape_issues(
          value,
          path,
          scope,
          segments,
          "invalid_covariance_numerical_check_shape"
        )

      covariance_epoch_binding_text_segments?(segments) ->
        transaction_covariance_epoch_binding_text_issues(value, path, scope, segments)

      covariance_epoch_binding_seconds_segments?(segments) ->
        transaction_covariance_epoch_binding_seconds_issues(value, path, scope, segments)

      identity_container_segments?(segments) ->
        transaction_source_identity_issues(value, path, scope, segments)

      identity_authority_claim_segments?(segments) ->
        transaction_identity_authority_claim_issues(value, path, segments)

      authority_claim_segments?(segments) ->
        transaction_authority_claim_issues(value, path)

      true ->
        []
    end
  end

  defp transaction_state_evidence_container_issues(nil, _path, _scope, _segments), do: []

  defp transaction_state_evidence_container_issues(%{}, _path, _scope, _segments), do: []

  defp transaction_state_evidence_container_issues(value, path, scope, segments),
    do: [
      issue(
        "invalid_accepted_state_evidence_container_shape",
        path,
        encoded_value(value),
        delete_action(scope, segments)
      )
    ]

  defp transaction_state_epoch_seconds_issues(value, path, scope, segments)
       when is_integer(value) do
    if bounded_integer?(value) do
      []
    else
      [
        issue(
          "invalid_state_epoch_seconds_shape",
          path,
          "oversize_integer",
          delete_action(scope, segments)
        )
      ]
    end
  end

  defp transaction_state_epoch_seconds_issues(value, path, scope, segments)
       when is_float(value) do
    if bounded_number?(value) do
      []
    else
      [
        issue(
          "invalid_state_epoch_seconds_shape",
          path,
          "invalid_float",
          delete_action(scope, segments)
        )
      ]
    end
  end

  defp transaction_state_epoch_seconds_issues(nil, path, scope, segments),
    do: [
      issue("invalid_state_epoch_seconds_shape", path, "nil", delete_action(scope, segments))
    ]

  defp transaction_state_epoch_seconds_issues("", path, scope, segments),
    do: [
      issue("invalid_state_epoch_seconds_shape", path, "empty", delete_action(scope, segments))
    ]

  defp transaction_state_epoch_seconds_issues(value, path, scope, segments),
    do: [
      issue(
        "invalid_state_epoch_seconds_shape",
        path,
        encoded_value(value),
        delete_action(scope, segments)
      )
    ]

  defp transaction_covariance_matrix_row_issues(value, _path, _scope, _segments)
       when is_list(value),
       do: []

  defp transaction_covariance_matrix_row_issues(value, path, scope, segments),
    do: [
      issue(
        "invalid_covariance_matrix_shape",
        path,
        encoded_value(value),
        delete_action(scope, segments)
      )
    ]

  defp transaction_covariance_matrix_issues(value, _path, _scope, _segments)
       when is_list(value),
       do: []

  defp transaction_covariance_matrix_issues(value, path, scope, segments),
    do: [
      issue(
        "invalid_covariance_matrix_shape",
        path,
        encoded_value(value),
        delete_action(scope, segments)
      )
    ]

  defp transaction_component_order_issues(value, _path, _scope, _segments)
       when value in [nil, ""],
       do: []

  defp transaction_component_order_issues(value, _path, _scope, _segments)
       when is_list(value),
       do: []

  defp transaction_component_order_issues(value, path, scope, segments),
    do: [
      issue(
        "unsupported_covariance_component_order",
        path,
        encoded_value(value),
        delete_action(scope, segments)
      )
    ]

  defp transaction_covariance_status_issues(value, _path, _scope, _segments)
       when value in [nil, ""] do
    []
  end

  defp transaction_covariance_status_issues(value, path, scope, segments) do
    if covariance_status_supported?(value) do
      []
    else
      [
        issue(
          "unsupported_covariance_status",
          path,
          encoded_value(value),
          delete_action(scope, segments)
        )
      ]
    end
  end

  defp transaction_covariance_reference_frame_issues(value, _path, _scope, _segments)
       when value in [nil, ""],
       do: []

  defp transaction_covariance_reference_frame_issues(value, path, scope, segments) do
    if reference_frame_supported?(value) do
      []
    else
      [
        issue(
          "unsupported_covariance_reference_frame",
          path,
          encoded_value(value),
          delete_action(scope, segments)
        )
      ]
    end
  end

  defp transaction_covariance_propagation_status_issues(value, _path, _scope, _segments)
       when value in [nil, ""],
       do: []

  defp transaction_covariance_propagation_status_issues(value, path, scope, segments) do
    if propagation_status_supported?(value) do
      []
    else
      [
        issue(
          "covariance_propagation_or_filtering_claimed",
          path,
          encoded_value(value),
          delete_action(scope, segments)
        )
      ]
    end
  end

  defp transaction_direct_covariance_epoch_issues(value, path, scope, segments) do
    case nonempty_binary_text(value) do
      nil ->
        [
          issue(
            "invalid_covariance_epoch_shape",
            path,
            invalid_text_detail(value),
            delete_action(scope, segments)
          )
        ]

      _text ->
        []
    end
  end

  defp transaction_container_shape_issues(%{}, _path, _scope, _segments, _reason), do: []

  defp transaction_container_shape_issues(nil, _path, _scope, _segments, _reason), do: []

  defp transaction_container_shape_issues(value, path, scope, segments, reason),
    do: [issue(reason, path, encoded_value(value), delete_action(scope, segments))]

  defp transaction_covariance_epoch_binding_text_issues(value, path, scope, segments) do
    case nonempty_binary_text(value) do
      nil ->
        [
          issue(
            "invalid_covariance_epoch_binding_shape",
            path,
            invalid_text_detail(value),
            delete_action(scope, segments)
          )
        ]

      _text ->
        []
    end
  end

  defp transaction_covariance_epoch_binding_seconds_issues(value, path, scope, segments)
       when is_number(value) do
    if bounded_number?(value) do
      []
    else
      [
        issue(
          "invalid_covariance_epoch_binding_shape",
          path,
          encoded_value(value),
          delete_action(scope, segments)
        )
      ]
    end
  end

  defp transaction_covariance_epoch_binding_seconds_issues(value, path, scope, segments),
    do: [
      issue(
        "invalid_covariance_epoch_binding_shape",
        path,
        encoded_value(value),
        delete_action(scope, segments)
      )
    ]

  defp transaction_source_identity_issues(%{}, _path, _scope, _segments), do: []

  defp transaction_source_identity_issues(value, path, scope, segments),
    do: [
      issue(
        "invalid_source_identity_shape",
        path,
        encoded_value(value),
        delete_action(scope, segments)
      )
    ]

  defp transaction_identity_authority_claim_issues(value, path, segments) do
    if affirmative_authority_claim?(value) do
      reason =
        case List.last(segments) do
          "authority" -> "claimed_content_identity_authority"
          _field -> "authenticated_source_identity_claim"
        end

      [issue(reason, path, encoded_value(value))]
    else
      []
    end
  end

  defp transaction_authority_claim_issues(value, path) do
    if affirmative_authority_claim?(value) do
      [issue("claimed_content_identity_authority", path, encoded_value(value))]
    else
      []
    end
  end

  defp state_epoch_seconds_segments?([
         "spacecraft_states",
         index,
         "epoch",
         "seconds_since_j2000"
       ])
       when is_integer(index),
       do: true

  defp state_epoch_seconds_segments?(_segments), do: false

  defp accepted_state_evidence_container_segments?([container])
       when container in ["quality", "provenance", "source"],
       do: true

  defp accepted_state_evidence_container_segments?(_segments), do: false

  defp state_evidence_container_segments?([
         "spacecraft_states",
         index,
         container
       ])
       when is_integer(index) and container in ["quality", "metadata", "provenance", "source"],
       do: true

  defp state_evidence_container_segments?(_segments), do: false

  defp covariance_matrix_row_segments?([
         "spacecraft_states",
         index,
         container,
         "covariance_matrix_6x6",
         row_index
       ])
       when is_integer(index) and is_integer(row_index) and
              container in ["quality", "metadata", "provenance"],
       do: true

  defp covariance_matrix_row_segments?([container, "covariance_matrix_6x6", row_index])
       when is_integer(row_index) and container in ["quality", "provenance", "source"],
       do: true

  defp covariance_matrix_row_segments?(_segments), do: false

  defp covariance_matrix_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_matrix_6x6")

  defp covariance_component_order_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_component_order")

  defp covariance_status_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_status")

  defp covariance_reference_frame_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_reference_frame")

  defp covariance_propagation_status_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_propagation_status")

  defp direct_covariance_epoch_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_epoch")

  defp covariance_unit_contract_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_unit_contract")

  defp covariance_frame_binding_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_frame_binding")

  defp covariance_epoch_binding_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_epoch_binding")

  defp covariance_numerical_check_segments?(segments),
    do: covariance_field_segments?(segments, "covariance_numerical_check")

  defp covariance_epoch_binding_text_segments?([
         "spacecraft_states",
         index,
         container,
         "covariance_epoch_binding",
         field
       ])
       when is_integer(index) and container in ["quality", "metadata", "provenance"] and
              field in ["state_epoch", "covariance_epoch"],
       do: true

  defp covariance_epoch_binding_text_segments?([container, "covariance_epoch_binding", field])
       when container in ["quality", "provenance", "source"] and
              field in ["state_epoch", "covariance_epoch"],
       do: true

  defp covariance_epoch_binding_text_segments?(_segments), do: false

  defp covariance_epoch_binding_seconds_segments?([
         "spacecraft_states",
         index,
         container,
         "covariance_epoch_binding",
         "seconds_since_j2000"
       ])
       when is_integer(index) and container in ["quality", "metadata", "provenance"],
       do: true

  defp covariance_epoch_binding_seconds_segments?([
         container,
         "covariance_epoch_binding",
         "seconds_since_j2000"
       ])
       when container in ["quality", "provenance", "source"],
       do: true

  defp covariance_epoch_binding_seconds_segments?(_segments), do: false

  defp covariance_field_segments?(
         [
           "spacecraft_states",
           index,
           container,
           actual_field
         ],
         expected_field
       )
       when is_integer(index) and container in ["quality", "metadata", "provenance"] do
    actual_field == expected_field
  end

  defp covariance_field_segments?([container, actual_field], expected_field)
       when container in ["quality", "provenance", "source"] do
    actual_field == expected_field
  end

  defp covariance_field_segments?(_segments, _field), do: false

  defp identity_container_segments?(segments) do
    case List.last(segments) do
      key when key in @identity_keys -> true
      _key -> false
    end
  end

  defp identity_authority_claim_segments?(segments) do
    case Enum.reverse(segments) do
      [key, identity | _rest] when key in @auth_claim_keys and identity in @identity_keys -> true
      _segments -> false
    end
  end

  defp authority_claim_segments?(segments) do
    case List.last(segments) do
      key when key in @auth_claim_keys -> true
      _key -> false
    end
  end

  defp transaction_enter_node(path, scope, segments, depth, nodes) do
    cond do
      nodes >= @max_scan_nodes ->
        {:overflow, nodes,
         [
           issue(
             "accepted_state_evidence_node_budget_exceeded",
             path,
             "max_scan_nodes_exceeded",
             delete_action(scope, segments)
           )
         ]}

      depth > @max_scan_depth ->
        {:drop, nodes + 1,
         [
           issue(
             "accepted_state_evidence_shape_deep",
             path,
             "max_scan_depth_exceeded",
             delete_action(scope, segments)
           )
         ]}

      true ->
        {:ok, nodes + 1}
    end
  end

  defp transaction_drop(reason, path, detail, projection_action, _depth, nodes, stats) do
    if nodes >= @max_scan_nodes do
      {:overflow, nodes,
       [
         issue(
           "accepted_state_evidence_node_budget_exceeded",
           path,
           "max_scan_nodes_exceeded",
           projection_action
         )
       ], stats}
    else
      {:ok, :drop, nodes + 1, [issue(reason, path, detail, projection_action)], stats}
    end
  end

  defp transaction_project_entries(
         [],
         _collision_tokens,
         _path,
         _scope,
         _segments,
         _depth,
         nodes,
         issues,
         stats,
         projection
       ) do
    {:ok, projection, nodes, issues, stats}
  end

  defp transaction_project_entries(
         [{key, value} | rest],
         collision_tokens,
         path,
         scope,
         segments,
         depth,
         nodes,
         issues,
         stats,
         projection
       ) do
    case key_token(key) do
      {:ok, token} ->
        if MapSet.member?(collision_tokens, token) do
          transaction_project_entries(
            rest,
            collision_tokens,
            path,
            scope,
            segments,
            depth,
            nodes,
            issues,
            stats,
            projection
          )
        else
          child_segments = segments ++ [token]

          case transaction_value(
                 value,
                 path <> "." <> token,
                 scope,
                 child_segments,
                 depth,
                 nodes,
                 stats
               ) do
            {:ok, :drop, nodes, child_issues, stats} ->
              transaction_project_entries(
                rest,
                collision_tokens,
                path,
                scope,
                segments,
                depth,
                nodes,
                issues ++ child_issues,
                stats,
                projection
              )

            {:ok, projected_value, nodes, child_issues, stats} ->
              transaction_project_entries(
                rest,
                collision_tokens,
                path,
                scope,
                segments,
                depth,
                nodes,
                issues ++ child_issues,
                stats,
                Map.put(projection, token, projected_value)
              )

            {:overflow, nodes, child_issues, stats} ->
              {:overflow, nodes, issues ++ child_issues, stats}
          end
        end

      {:error, _reason} ->
        transaction_project_entries(
          rest,
          collision_tokens,
          path,
          scope,
          segments,
          depth,
          nodes,
          issues,
          stats,
          projection
        )
    end
  end

  defp transaction_project_list_items(
         [],
         _path,
         _scope,
         _segments,
         _depth,
         nodes,
         projected_items,
         issues,
         stats,
         _index
       ) do
    {:ok, Enum.reverse(projected_items), nodes, issues, stats}
  end

  defp transaction_project_list_items(
         [value | rest],
         path,
         scope,
         segments,
         depth,
         nodes,
         projected_items,
         issues,
         stats,
         index
       ) do
    case transaction_value(
           value,
           path <> "[#{index}]",
           scope,
           segments ++ [index],
           depth,
           nodes,
           stats
         ) do
      {:ok, :drop, nodes, child_issues, stats} ->
        transaction_project_list_items(
          rest,
          path,
          scope,
          segments,
          depth,
          nodes,
          projected_items,
          issues ++ child_issues,
          stats,
          index + 1
        )

      {:ok, projected_value, nodes, child_issues, stats} ->
        transaction_project_list_items(
          rest,
          path,
          scope,
          segments,
          depth,
          nodes,
          [projected_value | projected_items],
          issues ++ child_issues,
          stats,
          index + 1
        )

      {:overflow, nodes, child_issues, stats} ->
        {:overflow, nodes, issues ++ child_issues, stats}
    end
  end

  defp transaction_scan_unretained_entries(
         map,
         entries,
         fields,
         path,
         scope,
         segments,
         depth,
         nodes,
         issues,
         stats
       ) do
    if map_size(map) > @max_map_entries do
      {:ok, nodes, issues, stats}
    else
      retained_fields = MapSet.new(fields)

      entries =
        Enum.reject(entries, fn {key, _value} ->
          case key_token(key) do
            {:ok, key_name} -> MapSet.member?(retained_fields, key_name)
            {:error, _reason} -> true
          end
        end)

      transaction_scan_entry_values(entries, path, scope, segments, depth, nodes, issues, stats)
    end
  end

  defp transaction_scan_entry_values([], _path, _scope, _segments, _depth, nodes, issues, stats),
    do: {:ok, nodes, issues, stats}

  defp transaction_scan_entry_values(
         [{key, value} | rest],
         path,
         scope,
         segments,
         depth,
         nodes,
         issues,
         stats
       ) do
    case key_token(key) do
      {:ok, key_name} ->
        case transaction_value(
               value,
               path <> "." <> key_name,
               scope,
               segments ++ [key_name],
               depth,
               nodes,
               stats
             ) do
          {:ok, _projection, nodes, child_issues, stats} ->
            transaction_scan_entry_values(
              rest,
              path,
              scope,
              segments,
              depth,
              nodes,
              issues ++ child_issues,
              stats
            )

          {:overflow, nodes, child_issues, stats} ->
            {:overflow, nodes, issues ++ child_issues, stats}
        end

      {:error, _reason} ->
        transaction_scan_entry_values(rest, path, scope, segments, depth, nodes, issues, stats)
    end
  end

  defp transaction_scan_list_values(
         [],
         _path,
         _scope,
         _segments,
         _depth,
         nodes,
         issues,
         stats,
         _index
       ),
       do: {:ok, nodes, issues, stats}

  defp transaction_scan_list_values(
         [value | rest],
         path,
         scope,
         segments,
         depth,
         nodes,
         issues,
         stats,
         index
       ) do
    case transaction_value(
           value,
           path <> "[#{index}]",
           scope,
           segments ++ [index],
           depth,
           nodes,
           stats
         ) do
      {:ok, _projection, nodes, child_issues, stats} ->
        transaction_scan_list_values(
          rest,
          path,
          scope,
          segments,
          depth,
          nodes,
          issues ++ child_issues,
          stats,
          index + 1
        )

      {:overflow, nodes, child_issues, stats} ->
        {:overflow, nodes, issues ++ child_issues, stats}
    end
  end

  defp transaction_child_scope("candidate_refresh", "accepted_planning_state"),
    do: "accepted_planning_state"

  defp transaction_child_scope(scope, _field), do: scope

  defp transaction_child_segments("candidate_refresh", _segments, "accepted_planning_state"),
    do: []

  defp transaction_child_segments(_scope, segments, field), do: segments ++ [field]

  defp transaction_child_path(_path, "candidate_refresh", "accepted_planning_state"),
    do: "$.accepted_planning_state"

  defp transaction_child_path(path, _scope, field), do: path <> "." <> field

  defp projection_alias_collision_tokens(entries) do
    entries
    |> Enum.reduce(%{}, fn {key, _value}, acc ->
      case alias_key_token(key) do
        {:ok, token} -> Map.update(acc, token, [key_form(key)], &[key_form(key) | &1])
        {:error, _reason} -> acc
      end
    end)
    |> Enum.reduce(MapSet.new(), fn {token, forms}, acc ->
      if :atom in forms and :string in forms do
        MapSet.put(acc, token)
      else
        acc
      end
    end)
  end

  def from_refresh_wrapper(%{} = refresh) do
    {wrapper_issues, _nodes} = refresh_wrapper_preflight_result(refresh)

    case fetch_known_public_field(refresh, "accepted_planning_state") do
      {:ok, %{} = accepted_state} ->
        from_accepted_state(accepted_state, wrapper_issues)

      {:ok, _accepted_state} ->
        from_accepted_state(
          %{"spacecraft_states" => []},
          [
            issue(
              "invalid_accepted_state_shape",
              "$.candidate_refresh.accepted_planning_state",
              nil,
              projection_action("candidate_refresh", "delete", ["accepted_planning_state"])
            )
            | wrapper_issues
          ]
        )

      {:alias_collision, _key} ->
        from_accepted_state(
          %{"spacecraft_states" => []},
          [
            issue(
              "atom_string_alias_collision",
              "$.candidate_refresh.accepted_planning_state",
              nil,
              sanitize_map_action("candidate_refresh", [])
            )
            | wrapper_issues
          ]
        )

      _result ->
        from_accepted_state(%{}, wrapper_issues)
    end
  end

  def from_refresh_wrapper(_refresh) do
    from_accepted_state(%{"spacecraft_states" => []}, [
      issue(
        "invalid_candidate_refresh_shape",
        "$.candidate_refresh",
        nil,
        safe_project_action("candidate_refresh")
      )
    ])
  end

  def from_accepted_state(%{} = accepted_state),
    do:
      from_accepted_state(accepted_state, accepted_state_public_preflight_issues(accepted_state))

  def from_accepted_state(accepted_state), do: from_accepted_state(accepted_state, [])

  def from_accepted_state(%{} = accepted_state, boundary_issues) do
    boundary_issues = normalize_boundary_issues(boundary_issues)
    {state_shape_issues, states} = spacecraft_states_result(accepted_state)
    maneuver_execution_delta_issues = maneuver_execution_delta_shape_issues(accepted_state)

    state_summaries =
      states
      |> Enum.with_index()
      |> Enum.map(fn {state, index} -> state_summary(state, index) end)

    states_with_evidence =
      Enum.count(state_summaries, &Map.get(&1, :covariance_evidence_present?))

    issues =
      boundary_issues ++
        state_shape_issues ++
        maneuver_execution_delta_issues ++
        top_level_covariance_issues(
          accepted_state,
          states_with_evidence > 0,
          "$.accepted_planning_state"
        ) ++ Enum.flat_map(state_summaries, &Map.fetch!(&1, :issues))

    base_summary(length_bounded(states), states_with_evidence)
    |> Map.put("state_evidence_scope", "accepted_planning_state.spacecraft_states")
    |> put_issue_summary(issues)
  end

  def from_accepted_state(_accepted_state, boundary_issues) do
    boundary_issues = normalize_boundary_issues(boundary_issues)

    base_summary(0, 0)
    |> Map.put("state_evidence_scope", "accepted_planning_state.spacecraft_states")
    |> put_issue_summary(
      boundary_issues ++
        [
          issue(
            "invalid_accepted_state_shape",
            "$.accepted_planning_state",
            nil,
            safe_project_action("accepted_planning_state")
          )
        ]
    )
  end

  def candidate_refresh_handoff_summary(%{} = artifact) do
    ref_summary = get_in_fields(artifact, ["accepted_planning_state", "evidence_authority"])

    provenance_summary =
      get_in_fields(artifact, ["provenance", "accepted_planning_state", "evidence_authority"])

    normalized_ref_summary = normalize_handoff_summary(ref_summary)
    normalized_provenance_summary = normalize_handoff_summary(provenance_summary)

    embedded_review_reasons =
      handoff_review_reasons(normalized_ref_summary, normalized_provenance_summary)

    embedded_projection_paths =
      handoff_encoding_projection_paths(normalized_ref_summary, normalized_provenance_summary)

    embedded_projection_actions =
      handoff_encoding_projection_actions(normalized_ref_summary, normalized_provenance_summary)

    embedded_projection_required? =
      handoff_encoding_projection_required?(
        normalized_ref_summary,
        normalized_provenance_summary,
        embedded_projection_paths,
        embedded_projection_actions
      )

    embedded_summary =
      cond do
        is_map(normalized_ref_summary) -> normalized_ref_summary
        is_map(normalized_provenance_summary) -> normalized_provenance_summary
        true -> base_summary(0, 0)
      end

    issues =
      embedded_issues(embedded_summary) ++
        candidate_refresh_handoff_preflight_issues(artifact) ++
        handoff_surface_issues(normalized_ref_summary, normalized_provenance_summary)

    embedded_summary
    |> Map.put_new("schema_contract", @schema_contract)
    |> Map.put_new("decision_authority", "no_decision_authority")
    |> Map.put_new("covariance_authority", "metadata_only_not_consumed")
    |> Map.put_new("content_identity_authority", "byte_identity_not_authenticated")
    |> Map.put("carry_through_surfaces", @handoff_surfaces)
    |> Map.put(
      "handoff_status",
      if(issues == [] and embedded_review_reasons == [],
        do: "candidate_refresh_evidence_authority_carried",
        else: "review_required"
      )
    )
    |> put_issue_summary(
      issues,
      embedded_review_reasons,
      embedded_projection_required?,
      embedded_projection_paths,
      embedded_projection_actions
    )
  end

  def candidate_refresh_handoff_summary(_artifact) do
    base_summary(0, 0)
    |> Map.put("handoff_status", "review_required")
    |> put_issue_summary([issue("invalid_candidate_refresh_shape", "$.candidate_refresh")])
  end

  defp base_summary(state_count, states_with_evidence) do
    %{
      "schema_contract" => @schema_contract,
      "decision_authority" => "no_decision_authority",
      "covariance_authority" => "metadata_only_not_consumed",
      "content_identity_authority" => "byte_identity_not_authenticated",
      "spacecraft_state_count" => state_count,
      "states_with_covariance_evidence_count" => states_with_evidence,
      "states_missing_covariance_evidence_count" => state_count - states_with_evidence,
      "l6_exclusions" => [
        "no_signature_or_declared_authority_authentication",
        "no_external_covariance_truth_validation",
        "no_covariance_filtering_or_propagation",
        "no_cadence_authorization"
      ],
      "carry_through_surfaces" => @handoff_surfaces
    }
  end

  defp normalize_existing_summary(%{} = summary) do
    state_count = summary_count(field(summary, "spacecraft_state_count"))

    states_with_evidence =
      summary
      |> field("states_with_covariance_evidence_count")
      |> summary_count()
      |> min(state_count)

    {incoming_review_reasons, review_reason_issues} = embedded_review_reasons(summary)
    {incoming_projection_paths, projection_path_issues} = embedded_projection_paths(summary)
    {incoming_projection_actions, projection_action_issues} = embedded_projection_actions(summary)

    {incoming_projection_required, projection_required_issues} =
      embedded_projection_required(summary, incoming_projection_paths)

    summary_issues =
      summary
      |> embedded_issues()
      |> maybe_review_without_issues(summary, incoming_review_reasons)

    projection_invariant_issues =
      projection_summary_invariant_issues(
        incoming_review_reasons,
        incoming_projection_paths,
        incoming_projection_required,
        incoming_projection_actions,
        review_reason_issues ++
          projection_path_issues ++
          projection_action_issues ++
          projection_required_issues
      )

    base_summary(state_count, states_with_evidence)
    |> maybe_put_summary_text("state_evidence_scope", field(summary, "state_evidence_scope"))
    |> maybe_put_summary_text("handoff_status", field(summary, "handoff_status"))
    |> put_issue_summary(
      summary_issues ++
        review_reason_issues ++
        projection_path_issues ++
        projection_required_issues ++
        projection_action_issues ++
        projection_invariant_issues ++
        public_preflight_issues(summary, "$.evidence_authority"),
      incoming_review_reasons,
      incoming_projection_required,
      incoming_projection_paths,
      incoming_projection_actions
    )
  end

  defp normalize_handoff_summary(%{} = summary), do: normalize_existing_summary(summary)
  defp normalize_handoff_summary(_summary), do: nil

  defp handoff_review_reasons(ref_summary, provenance_summary) do
    [ref_summary, provenance_summary]
    |> Enum.flat_map(&normalized_handoff_review_reasons/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalized_handoff_review_reasons(%{} = summary) do
    case fetch_public_field(summary, "review_reasons") do
      {:ok, reasons} when is_list(reasons) ->
        case bounded_list_items(reasons, @max_review_reasons) do
          {:ok, items} -> Enum.filter(items, &is_binary/1)
          {:oversize, items} -> Enum.filter(items, &is_binary/1)
          {:improper, items} -> Enum.filter(items, &is_binary/1)
        end

      _result ->
        []
    end
  end

  defp normalized_handoff_review_reasons(_summary), do: []

  defp handoff_encoding_projection_paths(ref_summary, provenance_summary) do
    [ref_summary, provenance_summary]
    |> Enum.flat_map(&normalized_handoff_encoding_projection_paths/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalized_handoff_encoding_projection_paths(%{} = summary) do
    case fetch_public_field(summary, "accepted_state_encoding_projection_paths") do
      {:ok, paths} when is_list(paths) ->
        case bounded_list_items(paths, @max_encoding_projection_paths) do
          {:ok, items} -> Enum.filter(items, &accepted_state_encoding_path?/1)
          {:oversize, _items} -> ["$.accepted_planning_state"]
          {:improper, _items} -> ["$.accepted_planning_state"]
        end

      _result ->
        []
    end
  end

  defp normalized_handoff_encoding_projection_paths(_summary), do: []

  defp handoff_encoding_projection_actions(ref_summary, provenance_summary) do
    [ref_summary, provenance_summary]
    |> Enum.flat_map(&normalized_handoff_encoding_projection_actions/1)
    |> Enum.uniq()
    |> Enum.sort_by(&projection_action_sort_key/1)
  end

  defp normalized_handoff_encoding_projection_actions(%{} = summary) do
    case fetch_public_field(summary, "build_encoding_projection_actions") do
      {:ok, actions} ->
        case projection_actions_value(actions) do
          {valid_actions, []} -> valid_actions
          {_valid_actions, _issues} -> [safe_project_action("accepted_planning_state")]
        end

      _result ->
        []
    end
  end

  defp normalized_handoff_encoding_projection_actions(_summary), do: []

  defp handoff_encoding_projection_required?(
         ref_summary,
         provenance_summary,
         projection_paths,
         projection_actions
       ) do
    projection_paths != [] or projection_actions != [] or
      Enum.any?([ref_summary, provenance_summary], fn
        %{} = summary -> field(summary, "accepted_state_encoding_projection_required") == true
        _summary -> false
      end)
  end

  defp summary_count(value) when is_integer(value) and value >= 0 and value <= @max_abs_integer,
    do: value

  defp summary_count(_value), do: 0

  defp maybe_review_without_issues([], summary, []) do
    if field(summary, "review_required") == true or
         normalized_value(field(summary, "status")) == "review_required" do
      [issue("embedded_evidence_authority_review_without_issues", "$.evidence_authority")]
    else
      []
    end
  end

  defp maybe_review_without_issues(issues, _summary, _review_reasons), do: issues

  defp maybe_put_summary_text(summary, key, value) do
    case summary_text(value) do
      nil -> summary
      text -> Map.put(summary, key, text)
    end
  end

  defp summary_text(value) when is_binary(value) do
    case bounded_binary(value) do
      {:ok, value} -> value
      {:error, _reason} -> nil
    end
  end

  defp summary_text(value) when is_atom(value), do: atom_value_token(value)
  defp summary_text(_value), do: nil

  defp spacecraft_states_result(%{} = accepted_state) do
    field_path = "$.accepted_planning_state.spacecraft_states"

    case fetch_public_field(accepted_state, "spacecraft_states") do
      :missing ->
        {[], []}

      {:ok, states} ->
        bounded_spacecraft_states(states, field_path)

      {:alias_collision, _key} ->
        {[
           issue(
             "atom_string_alias_collision",
             field_path,
             nil,
             sanitize_map_action("accepted_planning_state", [])
           )
         ], []}
    end
  end

  defp bounded_spacecraft_states(states, path) when is_list(states) do
    case bounded_list_items(states, @max_spacecraft_states) do
      {:ok, items} ->
        {[], items}

      {:oversize, _items} ->
        {[
           issue(
             "accepted_state_spacecraft_states_oversize",
             path,
             "max_spacecraft_states_exceeded",
             delete_action("accepted_planning_state", ["spacecraft_states"])
           )
         ], []}

      {:improper, _items} ->
        {[
           issue(
             "invalid_spacecraft_states_shape",
             path,
             nil,
             delete_action("accepted_planning_state", ["spacecraft_states"])
           )
         ], []}
    end
  end

  defp bounded_spacecraft_states(nil, path) do
    {[
       issue(
         "invalid_spacecraft_states_shape",
         path,
         "nil",
         delete_action("accepted_planning_state", ["spacecraft_states"])
       )
     ], []}
  end

  defp bounded_spacecraft_states(states, path),
    do:
      {[
         issue(
           "invalid_spacecraft_states_shape",
           path,
           encoded_value(states),
           delete_action("accepted_planning_state", ["spacecraft_states"])
         )
       ], []}

  defp maneuver_execution_delta_shape_issues(%{} = accepted_state) do
    field_path = "$.accepted_planning_state.maneuver_execution_deltas"

    case fetch_public_field(accepted_state, "maneuver_execution_deltas") do
      :missing ->
        []

      {:ok, values} when is_list(values) ->
        case bounded_list_items(values, @max_list_entries) do
          {:ok, _items} ->
            []

          {:oversize, _items} ->
            [
              issue(
                "accepted_state_maneuver_execution_deltas_oversize",
                field_path,
                "max_maneuver_execution_deltas_exceeded",
                delete_action("accepted_planning_state", ["maneuver_execution_deltas"])
              )
            ]

          {:improper, _items} ->
            [
              issue(
                "invalid_maneuver_execution_deltas_shape",
                field_path,
                nil,
                delete_action("accepted_planning_state", ["maneuver_execution_deltas"])
              )
            ]
        end

      {:ok, nil} ->
        [
          issue(
            "invalid_maneuver_execution_deltas_shape",
            field_path,
            "nil",
            delete_action("accepted_planning_state", ["maneuver_execution_deltas"])
          )
        ]

      {:ok, value} ->
        [
          issue(
            "invalid_maneuver_execution_deltas_shape",
            field_path,
            encoded_value(value),
            delete_action("accepted_planning_state", ["maneuver_execution_deltas"])
          )
        ]

      {:alias_collision, _key} ->
        [
          issue(
            "atom_string_alias_collision",
            field_path,
            nil,
            sanitize_map_action("accepted_planning_state", [])
          )
        ]
    end
  end

  defp state_summary(%{} = state, index) do
    path = "$.accepted_planning_state.spacecraft_states[#{index}]"
    quality = map_field(state, "quality")
    metadata = map_field(state, "metadata")
    provenance = map_field(state, "provenance")

    covariance_evidence_present? =
      covariance_evidence_present?(quality) or covariance_evidence_present?(metadata) or
        covariance_evidence_present?(provenance)

    issues =
      state_container_shape_issues(state, path) ++
        state_epoch_seconds_issues(state, path, index) ++
        state_covariance_partial_issues(state, path, covariance_evidence_present?) ++
        state_covariance_reference_frame_issues([quality, metadata, provenance], path) ++
        state_covariance_status_issues([quality, metadata, provenance], path) ++
        state_covariance_component_order_issues([quality, metadata, provenance], path) ++
        state_covariance_matrix_issues([quality, metadata, provenance], path) ++
        state_covariance_unit_issues([quality, metadata, provenance], path) ++
        state_covariance_binding_issues(state, [quality, metadata, provenance], path) ++
        state_covariance_numerical_issues([quality, metadata, provenance], path) ++
        state_covariance_propagation_issues([quality, metadata, provenance], path)

    %{
      covariance_evidence_present?: covariance_evidence_present?,
      issues: issues
    }
  end

  defp state_summary(_state, index) do
    %{
      covariance_evidence_present?: false,
      issues: [
        issue(
          "invalid_spacecraft_state_shape",
          "$.accepted_planning_state.spacecraft_states[#{index}]"
        )
      ]
    }
  end

  defp state_container_shape_issues(state, path) do
    Enum.flat_map(~w(quality metadata provenance source), fn key ->
      case fetch_public_field(state, key) do
        {:ok, nil} ->
          []

        {:ok, value} when is_map(value) ->
          []

        {:ok, _value} ->
          [issue("invalid_accepted_state_evidence_container_shape", path <> "." <> key)]

        _result ->
          []
      end
    end)
  end

  defp state_covariance_partial_issues(_state, _path, false), do: []

  defp state_covariance_partial_issues(state, path, true) do
    quality = map_field(state, "quality")

    if complete_quality_covariance?(quality) do
      []
    else
      [issue("partial_covariance_evidence", path <> ".quality")]
    end
  end

  defp state_epoch_seconds_issues(state, path, index) do
    {_status, _value, issues} =
      state_epoch_seconds_result(state, path, [
        "spacecraft_states",
        index,
        "epoch",
        "seconds_since_j2000"
      ])

    issues
  end

  defp state_covariance_reference_frame_issues(containers, path) do
    frame_issues =
      containers
      |> Enum.with_index()
      |> Enum.flat_map(fn {container, index} ->
        container_path = covariance_container_path(path, index)

        field_issues(
          container,
          "covariance_reference_frame",
          container_path <> ".covariance_reference_frame",
          "unsupported_covariance_reference_frame",
          &reference_frame_supported?/1
        ) ++ direct_reference_binding_issues(container, container_path)
      end)

    frame_issues ++
      covariance_signature_conflict_issues(containers, path, "covariance_reference_frame")
  end

  defp state_covariance_status_issues(containers, path) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      case fetch_public_field(container, "covariance_status") do
        {:ok, status} when status in [nil, ""] ->
          []

        {:ok, status} ->
          if covariance_status_supported?(status) do
            []
          else
            [
              issue(
                "unsupported_covariance_status",
                covariance_container_path(path, index) <> ".covariance_status",
                encoded_value(status)
              )
            ]
          end

        _result ->
          []
      end
    end)
  end

  defp state_covariance_component_order_issues(containers, path) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      field_issues(
        container,
        "covariance_component_order",
        covariance_container_path(path, index) <> ".covariance_component_order",
        "unsupported_covariance_component_order",
        &component_order_supported?/1
      )
    end)
  end

  defp state_covariance_matrix_issues(containers, path) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      case fetch_public_field(container, "covariance_matrix_6x6") do
        {:ok, matrix} ->
          case covariance_matrix_shape(matrix) do
            :ok ->
              []

            {:error, detail} ->
              [
                issue(
                  "invalid_covariance_matrix_shape",
                  covariance_container_path(path, index) <> ".covariance_matrix_6x6",
                  detail
                )
              ]
          end

        _result ->
          []
      end
    end)
  end

  defp state_covariance_unit_issues(containers, path) do
    unit_issues =
      containers
      |> Enum.with_index()
      |> Enum.flat_map(fn {container, index} ->
        unit_contract_field_issues(container, covariance_container_path(path, index))
      end)

    unit_issues ++
      covariance_signature_conflict_issues(containers, path, "covariance_unit_contract")
  end

  defp state_covariance_binding_issues(state, containers, path) do
    binding_issues =
      containers
      |> Enum.with_index()
      |> Enum.flat_map(fn {container, index} ->
        container_path = covariance_container_path(path, index)

        frame_binding_field_issues(state, container, container_path) ++
          epoch_field_issues(state, container, container_path) ++
          epoch_binding_field_issues(state, container, container_path, path)
      end)

    binding_issues ++
      covariance_signature_conflict_issues(containers, path, "covariance_epoch") ++
      covariance_signature_conflict_issues(containers, path, "covariance_frame_binding") ++
      covariance_signature_conflict_issues(containers, path, "covariance_epoch_binding")
  end

  defp direct_reference_binding_issues(container, container_path) do
    reference_frame = exact_bounded_text(field(container, "covariance_reference_frame"))
    field_path = container_path <> ".covariance_reference_frame"

    case fetch_public_field(container, "covariance_frame_binding") do
      {:ok, %{} = binding} ->
        binding_frame = exact_bounded_text(field(binding, "covariance_ref_frame"))

        if is_binary(reference_frame) and is_binary(binding_frame) and
             reference_frame != binding_frame do
          [issue("covariance_frame_mismatch", field_path)]
        else
          []
        end

      _result ->
        []
    end
  end

  defp unit_contract_field_issues(container, container_path) do
    field_path = container_path <> ".covariance_unit_contract"

    case fetch_public_field(container, "covariance_unit_contract") do
      {:ok, nil} ->
        []

      {:ok, %{} = contract} ->
        unit_contract_issues(contract, field_path)

      {:ok, _contract} ->
        [issue("invalid_covariance_unit_contract_shape", field_path)]

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        []
    end
  end

  defp unit_contract_issues(contract, path) do
    []
    |> Kernel.++(
      required_text_member_issues(
        contract,
        "declaration",
        @supported_unit_declarations,
        path,
        "unsupported_covariance_unit_contract"
      )
    )
    |> Kernel.++(required_text_value_issues(contract, "position_position", "km**2", path))
    |> Kernel.++(required_text_value_issues(contract, "position_velocity", "km**2/s", path))
    |> Kernel.++(required_text_value_issues(contract, "velocity_velocity", "km**2/s**2", path))
    |> Kernel.++(required_false_value_issues(contract, "mixed_unit_declarations", path))
    |> Kernel.++(required_component_order_issues(contract, path))
  end

  defp frame_binding_field_issues(state, container, container_path) do
    field_path = container_path <> ".covariance_frame_binding"

    case fetch_public_field(container, "covariance_frame_binding") do
      {:ok, nil} ->
        []

      {:ok, %{} = binding} ->
        frame_binding_issues(state, binding, field_path)

      {:ok, _binding} ->
        [issue("invalid_covariance_frame_binding_shape", field_path)]

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        []
    end
  end

  defp frame_binding_issues(state, binding, path) do
    {source_frame, source_frame_issues} =
      required_frame_token(binding, "source_ref_frame", path)

    {covariance_frame, covariance_frame_issues} =
      required_frame_token(binding, "covariance_ref_frame", path)

    {accepted_state_frame, accepted_state_frame_issues} =
      required_accepted_state_frame_token(binding, "accepted_state_frame", path)

    state_frame = exact_bounded_text(field(state, "frame"))

    []
    |> Kernel.++(source_frame_issues)
    |> Kernel.++(covariance_frame_issues)
    |> Kernel.++(accepted_state_frame_issues)
    |> Kernel.++(required_false_value_issues(binding, "conversion_applied", path))
    |> Kernel.++(
      optional_true_value_issues(binding, "matched", path, "covariance_frame_mismatch")
    )
    |> maybe_issue(
      is_binary(state_frame) and is_binary(accepted_state_frame) and
        state_frame != accepted_state_frame,
      "covariance_frame_mismatch",
      path <> ".accepted_state_frame"
    )
    |> maybe_issue(
      is_binary(source_frame) and is_binary(covariance_frame) and source_frame != covariance_frame,
      "covariance_frame_mismatch",
      path <> ".covariance_ref_frame"
    )
  end

  defp epoch_field_issues(_state, container, container_path) do
    field_path = container_path <> ".covariance_epoch"

    case fetch_public_field(container, "covariance_epoch") do
      {:ok, covariance_epoch} ->
        case nonempty_binary_text(covariance_epoch) do
          nil ->
            [
              issue(
                "invalid_covariance_epoch_shape",
                field_path,
                invalid_text_detail(covariance_epoch)
              )
            ]

          epoch ->
            direct_epoch_binding_issues(container, container_path, field_path, epoch)
        end

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        []
    end
  end

  defp direct_epoch_binding_issues(container, container_path, field_path, direct_epoch) do
    binding_path = container_path <> ".covariance_epoch_binding"
    binding_epoch_path = binding_path <> ".covariance_epoch"

    case fetch_public_field(container, "covariance_epoch_binding") do
      {:ok, %{} = binding} ->
        case fetch_public_field(binding, "covariance_epoch") do
          {:ok, binding_epoch} ->
            case nonempty_binary_text(binding_epoch) do
              ^direct_epoch ->
                []

              nil ->
                [
                  issue(
                    "invalid_covariance_epoch_binding_shape",
                    binding_epoch_path,
                    invalid_text_detail(binding_epoch)
                  )
                ]

              _epoch ->
                [issue("covariance_epoch_mismatch", field_path)]
            end

          {:alias_collision, _key} ->
            [issue("atom_string_alias_collision", binding_epoch_path)]

          _result ->
            [issue("covariance_epoch_mismatch", field_path, "missing_covariance_epoch_binding")]
        end

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", binding_path)]

      _result ->
        [issue("covariance_epoch_mismatch", field_path, "missing_covariance_epoch_binding")]
    end
  end

  defp epoch_binding_field_issues(state, container, container_path, state_path) do
    field_path = container_path <> ".covariance_epoch_binding"

    case fetch_public_field(container, "covariance_epoch_binding") do
      {:ok, nil} ->
        []

      {:ok, %{} = binding} ->
        epoch_binding_issues(state, container, binding, field_path, state_path)

      {:ok, _binding} ->
        [issue("invalid_covariance_epoch_binding_shape", field_path)]

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        []
    end
  end

  defp epoch_binding_issues(state, container, binding, path, state_path) do
    state_epoch_s = state_epoch_seconds_result(state, state_path)

    {state_epoch_text, state_epoch_issues} =
      required_binary_text(binding, "state_epoch", path, "invalid_covariance_epoch_binding_shape")

    {covariance_epoch_text, covariance_epoch_issues} =
      required_binary_text(
        binding,
        "covariance_epoch",
        path,
        "invalid_covariance_epoch_binding_shape"
      )

    {_time_scale, time_scale_issues} =
      required_text_member(
        binding,
        "time_scale",
        @supported_time_scales,
        path,
        "invalid_covariance_epoch_binding_shape"
      )

    covariance_epoch = field(container, "covariance_epoch") |> nonempty_binary_text()

    []
    |> Kernel.++(state_epoch_issues)
    |> Kernel.++(covariance_epoch_issues)
    |> Kernel.++(time_scale_issues)
    |> Kernel.++(
      required_true_value_issues(binding, "matched", path, "covariance_epoch_mismatch")
    )
    |> Kernel.++(optional_numeric_epoch_issues(binding, state_epoch_s, path))
    |> maybe_issue(
      is_binary(state_epoch_text) and is_binary(covariance_epoch_text) and
        state_epoch_text != covariance_epoch_text,
      "covariance_epoch_mismatch",
      path <> ".covariance_epoch"
    )
    |> maybe_issue(
      is_binary(covariance_epoch_text) and is_binary(covariance_epoch) and
        covariance_epoch_text != covariance_epoch,
      "covariance_epoch_mismatch",
      path <> ".covariance_epoch"
    )
  end

  defp state_covariance_numerical_issues(containers, path) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      case fetch_public_field(container, "covariance_numerical_check") do
        {:ok, %{} = check} ->
          numerical_check_issues(
            check,
            covariance_container_path(path, index) <> ".covariance_numerical_check"
          )

        {:ok, _check} ->
          [
            issue(
              "invalid_covariance_numerical_check_shape",
              covariance_container_path(path, index) <> ".covariance_numerical_check"
            )
          ]

        _result ->
          []
      end
    end)
  end

  defp numerical_check_issues(check, path) do
    status = normalized_value(field(check, "status"))

    status_issues =
      if status == "passed" do
        []
      else
        detail =
          case status do
            nil -> "unsupported_or_missing"
            value -> value
          end

        [issue("unsupported_covariance_numerical_status", path <> ".status", detail)]
      end

    status_issues ++
      required_supported_text_issues(check, "name", @covariance_numerical_check_name, path) ++
      required_supported_text_issues(check, "claim", @covariance_numerical_check_claim, path)
  end

  defp required_supported_text_issues(map, key, expected, path) do
    field_path = path <> "." <> key

    case fetch_public_field(map, key) do
      {:ok, nil} ->
        [issue("unsupported_covariance_numerical_check", field_path, "missing")]

      {:ok, value} ->
        if exact_bounded_text(value) == expected do
          []
        else
          [issue("unsupported_covariance_numerical_check", field_path, encoded_value(value))]
        end

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        [issue("unsupported_covariance_numerical_check", field_path, "missing")]
    end
  end

  defp state_covariance_propagation_issues(containers, path) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      case fetch_public_field(container, "covariance_propagation_status") do
        {:ok, status} when status in [nil, ""] ->
          []

        {:ok, status} ->
          if propagation_status_supported?(status) do
            []
          else
            [
              issue(
                "covariance_propagation_or_filtering_claimed",
                covariance_container_path(path, index) <> ".covariance_propagation_status",
                encoded_value(status)
              )
            ]
          end

        _result ->
          []
      end
    end)
  end

  defp top_level_covariance_issues(accepted_state, states_have_evidence?, path) do
    containers = [
      map_field(accepted_state, "quality"),
      map_field(accepted_state, "provenance"),
      map_field(accepted_state, "source")
    ]

    has_top_level_covariance? = Enum.any?(containers, &covariance_evidence_present?/1)

    if has_top_level_covariance? and not states_have_evidence? do
      [issue("partial_covariance_evidence", path <> ".provenance")]
    else
      []
    end
  end

  defp complete_quality_covariance?(quality) when is_map(quality) do
    Enum.all?(@complete_quality_fields, &field_present?(quality, &1)) and
      complete_covariance_status_supported?(field(quality, "covariance_status")) and
      component_order_supported?(field(quality, "covariance_component_order")) and
      covariance_matrix_shape(field(quality, "covariance_matrix_6x6")) == :ok and
      unit_contract_supported?(field(quality, "covariance_unit_contract")) and
      frame_binding_supported?(field(quality, "covariance_frame_binding")) and
      epoch_binding_supported?(field(quality, "covariance_epoch_binding")) and
      numerical_check_supported?(field(quality, "covariance_numerical_check")) and
      propagation_status_supported?(field(quality, "covariance_propagation_status"))
  end

  defp complete_quality_covariance?(_quality), do: false

  defp covariance_status_supported?(status),
    do: normalized_value(status) in @allowed_covariance_statuses

  defp reference_frame_supported?(frame),
    do: exact_bounded_text(frame) in @supported_ref_frames

  defp complete_covariance_status_supported?(status) do
    normalized_status = normalized_value(status)
    normalized_status in @allowed_covariance_statuses and normalized_status != "not_present"
  end

  defp propagation_status_supported?(status),
    do: normalized_value(status) == "metadata_only_not_propagated"

  defp component_order_supported?(value) when is_list(value) do
    case bounded_list_items(value, 6) do
      {:ok, items} ->
        if length_bounded(items) == 6 do
          component_order_items_supported?(items, @component_order)
        else
          false
        end

      _items ->
        false
    end
  end

  defp component_order_supported?(_value), do: false

  defp component_order_items_supported?([], []), do: true

  defp component_order_items_supported?([value | values], [expected | expected_values]) do
    exact_bounded_text(value) == expected and
      component_order_items_supported?(values, expected_values)
  end

  defp component_order_items_supported?(_values, _expected_values), do: false

  defp unit_contract_supported?(%{} = contract) do
    match?({:ok, _signature}, unit_contract_signature(contract))
  end

  defp unit_contract_supported?(_contract), do: false

  defp frame_binding_supported?(%{} = binding) do
    match?({:ok, _signature}, frame_binding_signature(binding))
  end

  defp frame_binding_supported?(_binding), do: false

  defp epoch_binding_supported?(%{} = binding) do
    match?({:ok, _signature}, epoch_binding_signature(binding))
  end

  defp epoch_binding_supported?(_binding), do: false

  defp numerical_check_supported?(%{} = check) do
    normalized_value(field(check, "status")) == "passed" and
      required_supported_text?(check, "name", @covariance_numerical_check_name) and
      required_supported_text?(check, "claim", @covariance_numerical_check_claim)
  end

  defp numerical_check_supported?(_check), do: false

  defp field_issues(container, key, path, reason, supported?) do
    case fetch_public_field(container, key) do
      {:ok, nil} ->
        []

      {:ok, ""} ->
        []

      {:ok, value} ->
        if supported?.(value), do: [], else: [issue(reason, path, encoded_value(value))]

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", path)]

      _result ->
        []
    end
  end

  defp required_text_member_issues(contract, key, allowed, path, reason) do
    {_value, issues} = required_text_member(contract, key, allowed, path, reason)
    issues
  end

  defp required_text_value_issues(contract, key, expected, path) do
    field_path = path <> "." <> key

    case fetch_public_field(contract, key) do
      {:ok, value} ->
        case exact_bounded_text(value) do
          ^expected ->
            []

          nil ->
            [issue("invalid_covariance_unit_contract_shape", field_path, encoded_value(value))]

          _value ->
            [issue("unsupported_covariance_unit_contract", field_path, encoded_value(value))]
        end

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        [issue("invalid_covariance_unit_contract_shape", field_path)]
    end
  end

  defp required_component_order_issues(contract, path) do
    field_path = path <> ".component_order"

    case fetch_public_field(contract, "component_order") do
      {:ok, value} ->
        if component_order_supported?(value) do
          []
        else
          [issue("unsupported_covariance_component_order", field_path, encoded_value(value))]
        end

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        [issue("unsupported_covariance_component_order", field_path, "missing")]
    end
  end

  defp required_false_value_issues(map, "mixed_unit_declarations", path) do
    required_false_value_issues(
      map,
      "mixed_unit_declarations",
      path,
      "invalid_covariance_unit_contract_shape",
      "unsupported_covariance_unit_contract"
    )
  end

  defp required_false_value_issues(map, "conversion_applied", path) do
    required_false_value_issues(
      map,
      "conversion_applied",
      path,
      "invalid_covariance_frame_binding_shape",
      "covariance_frame_conversion_claimed"
    )
  end

  defp required_false_value_issues(map, key, path, invalid_reason, true_reason) do
    field_path = path <> "." <> key

    case fetch_public_field(map, key) do
      {:ok, false} -> []
      {:ok, true} -> [issue(true_reason, field_path)]
      {:ok, value} -> [issue(invalid_reason, field_path, encoded_value(value))]
      {:alias_collision, _key} -> [issue("atom_string_alias_collision", field_path)]
      _result -> [issue(invalid_reason, field_path)]
    end
  end

  defp required_true_value_issues(map, key, path, false_reason) do
    field_path = path <> "." <> key

    case fetch_public_field(map, key) do
      {:ok, true} ->
        []

      {:ok, false} ->
        [issue(false_reason, field_path)]

      {:ok, value} ->
        [issue("invalid_covariance_epoch_binding_shape", field_path, encoded_value(value))]

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        [issue("invalid_covariance_epoch_binding_shape", field_path)]
    end
  end

  defp optional_true_value_issues(map, key, path, false_reason) do
    field_path = path <> "." <> key

    case fetch_public_field(map, key) do
      {:ok, nil} ->
        [issue("invalid_covariance_frame_binding_shape", field_path)]

      {:ok, true} ->
        []

      {:ok, false} ->
        [issue(false_reason, field_path)]

      {:ok, value} ->
        [issue("invalid_covariance_frame_binding_shape", field_path, encoded_value(value))]

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        []
    end
  end

  defp optional_numeric_epoch_issues(binding, state_epoch_s, path) do
    field_path = path <> ".seconds_since_j2000"

    case fetch_public_field(binding, "seconds_since_j2000") do
      {:ok, value} when is_number(value) ->
        cond do
          not bounded_number?(value) ->
            [issue("invalid_covariance_epoch_binding_shape", field_path, encoded_value(value))]

          true ->
            state_epoch_seconds_consistency_issues(value, state_epoch_s, field_path)
        end

      {:ok, value} ->
        [issue("invalid_covariance_epoch_binding_shape", field_path, encoded_value(value))]

      {:alias_collision, _key} ->
        [issue("atom_string_alias_collision", field_path)]

      _result ->
        []
    end
  end

  defp state_epoch_seconds_consistency_issues(value, {:present, state_value, _issues}, path) do
    if state_value == value do
      []
    else
      [issue("covariance_epoch_mismatch", path)]
    end
  end

  defp state_epoch_seconds_consistency_issues(_value, {:invalid, _state_value, _issues}, path),
    do: [issue("covariance_epoch_mismatch", path, "state_epoch_seconds_invalid")]

  defp state_epoch_seconds_consistency_issues(_value, {:missing, _state_value, _issues}, path),
    do: [issue("covariance_epoch_mismatch", path, "state_epoch_seconds_missing")]

  defp required_frame_token(binding, key, path) do
    required_text_member(
      binding,
      key,
      @supported_ref_frames,
      path,
      "invalid_covariance_frame_binding_shape"
    )
  end

  defp required_accepted_state_frame_token(binding, key, path) do
    required_text_member(
      binding,
      key,
      ["earth_inertial_j2000"],
      path,
      "invalid_covariance_frame_binding_shape"
    )
  end

  defp required_text_member(map, key, allowed, path, reason) do
    field_path = path <> "." <> key

    case fetch_public_field(map, key) do
      {:ok, value} ->
        case exact_bounded_text(value) do
          nil ->
            {nil, [issue(reason, field_path, encoded_value(value))]}

          text ->
            if text in allowed do
              {text, []}
            else
              {nil, [issue(reason, field_path, encoded_value(value))]}
            end
        end

      {:alias_collision, _key} ->
        {nil, [issue("atom_string_alias_collision", field_path)]}

      _result ->
        {nil, [issue(reason, field_path)]}
    end
  end

  defp required_binary_text(map, key, path, reason) do
    field_path = path <> "." <> key

    case fetch_public_field(map, key) do
      {:ok, value} ->
        case nonempty_binary_text(value) do
          nil -> {nil, [issue(reason, field_path, invalid_text_detail(value))]}
          text -> {text, []}
        end

      {:alias_collision, _key} ->
        {nil, [issue("atom_string_alias_collision", field_path)]}

      _result ->
        {nil, [issue(reason, field_path)]}
    end
  end

  defp required_supported_text?(map, key, expected) do
    case fetch_public_field(map, key) do
      {:ok, value} -> exact_bounded_text(value) == expected
      _result -> false
    end
  end

  defp covariance_signature_conflict_issues(containers, path, field) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      case covariance_signature(container, field) do
        {:ok, signature} -> [{index, signature}]
        :error -> []
      end
    end)
    |> signature_conflict_issues(path, field)
  end

  defp signature_conflict_issues([], _path, _field), do: []

  defp signature_conflict_issues([{source_index, source_signature} | signatures], path, field) do
    Enum.flat_map(signatures, fn {index, signature} ->
      if signature == source_signature do
        []
      else
        [
          issue(
            covariance_signature_conflict_reason(field),
            covariance_container_path(path, index) <> "." <> field,
            "conflicts_with_" <> covariance_container_name(source_index)
          )
        ]
      end
    end)
  end

  defp covariance_signature(container, field) do
    case fetch_public_field(container, field) do
      {:ok, value} -> covariance_signature_value(field, value)
      _result -> :error
    end
  end

  defp covariance_signature_value("covariance_reference_frame", value),
    do: exact_text_signature(:reference_frame, value, @supported_ref_frames)

  defp covariance_signature_value("covariance_epoch", value),
    do: binary_text_signature(:epoch, value)

  defp covariance_signature_value("covariance_unit_contract", value),
    do: unit_contract_signature(value)

  defp covariance_signature_value("covariance_frame_binding", value),
    do: frame_binding_signature(value)

  defp covariance_signature_value("covariance_epoch_binding", value),
    do: epoch_binding_signature(value)

  defp covariance_signature_value(_field, _value), do: :error

  defp exact_text_signature(tag, value, allowed) do
    case nonempty_exact_text(value) do
      nil ->
        :error

      text ->
        if is_nil(allowed) or text in allowed do
          {:ok, {tag, text}}
        else
          :error
        end
    end
  end

  defp binary_text_signature(tag, value) do
    case nonempty_binary_text(value) do
      nil -> :error
      text -> {:ok, {tag, text}}
    end
  end

  defp unit_contract_signature(contract) do
    with {:ok, declaration} <-
           signature_text_member(contract, "declaration", @supported_unit_declarations),
         {:ok, position_position} <- signature_text(contract, "position_position"),
         {:ok, position_velocity} <- signature_text(contract, "position_velocity"),
         {:ok, velocity_velocity} <- signature_text(contract, "velocity_velocity"),
         {:ok, false} <- signature_false(contract, "mixed_unit_declarations"),
         {:ok, component_order} <- signature_component_order(contract),
         true <- position_position == "km**2",
         true <- position_velocity == "km**2/s",
         true <- velocity_velocity == "km**2/s**2" do
      {:ok, {:unit_contract, declaration, component_order}}
    else
      _error -> :error
    end
  end

  defp frame_binding_signature(binding) do
    with {:ok, source_frame} <-
           signature_text_member(binding, "source_ref_frame", @supported_ref_frames),
         {:ok, covariance_frame} <-
           signature_text_member(binding, "covariance_ref_frame", @supported_ref_frames),
         {:ok, accepted_state_frame} <-
           signature_text_member(binding, "accepted_state_frame", ["earth_inertial_j2000"]),
         {:ok, false} <- signature_false(binding, "conversion_applied"),
         :ok <- signature_optional_true(binding, "matched"),
         true <- source_frame == covariance_frame do
      {:ok, {:frame_binding, source_frame, covariance_frame, accepted_state_frame}}
    else
      _error -> :error
    end
  end

  defp epoch_binding_signature(binding) do
    with {:ok, state_epoch} <- signature_binary_text(binding, "state_epoch"),
         {:ok, covariance_epoch} <- signature_binary_text(binding, "covariance_epoch"),
         {:ok, time_scale} <- signature_text_member(binding, "time_scale", @supported_time_scales),
         {:ok, true} <- signature_true(binding, "matched"),
         :ok <- signature_optional_number(binding, "seconds_since_j2000"),
         true <- state_epoch == covariance_epoch do
      {:ok, {:epoch_binding, state_epoch, covariance_epoch, time_scale}}
    else
      _error -> :error
    end
  end

  defp signature_text_member(map, key, allowed) do
    case signature_text(map, key) do
      {:ok, value} ->
        if value in allowed, do: {:ok, value}, else: :error

      _result ->
        :error
    end
  end

  defp signature_text(map, key) do
    case fetch_public_field(map, key) do
      {:ok, value} ->
        case nonempty_exact_text(value) do
          nil -> :error
          text -> {:ok, text}
        end

      _result ->
        :error
    end
  end

  defp signature_binary_text(map, key) do
    case fetch_public_field(map, key) do
      {:ok, value} ->
        case nonempty_binary_text(value) do
          nil -> :error
          text -> {:ok, text}
        end

      _result ->
        :error
    end
  end

  defp signature_false(map, key) do
    case fetch_public_field(map, key) do
      {:ok, false} -> {:ok, false}
      _result -> :error
    end
  end

  defp signature_true(map, key) do
    case fetch_public_field(map, key) do
      {:ok, true} -> {:ok, true}
      _result -> :error
    end
  end

  defp signature_optional_true(map, key) do
    case fetch_public_field(map, key) do
      {:ok, nil} -> :error
      {:ok, true} -> :ok
      :missing -> :ok
      _result -> :error
    end
  end

  defp signature_optional_number(map, key) do
    case fetch_public_field(map, key) do
      {:ok, value} when is_number(value) -> if(bounded_number?(value), do: :ok, else: :error)
      :missing -> :ok
      _result -> :error
    end
  end

  defp signature_component_order(map) do
    case fetch_public_field(map, "component_order") do
      {:ok, value} ->
        if component_order_supported?(value), do: {:ok, @component_order}, else: :error

      _result ->
        :error
    end
  end

  defp covariance_signature_conflict_reason("covariance_unit_contract"),
    do: "covariance_unit_contract_conflict"

  defp covariance_signature_conflict_reason("covariance_reference_frame"),
    do: "covariance_reference_frame_conflict"

  defp covariance_signature_conflict_reason("covariance_epoch"), do: "covariance_epoch_conflict"

  defp covariance_signature_conflict_reason("covariance_frame_binding"),
    do: "covariance_frame_binding_conflict"

  defp covariance_signature_conflict_reason("covariance_epoch_binding"),
    do: "covariance_epoch_binding_conflict"

  defp covariance_container_name(0), do: "quality"
  defp covariance_container_name(1), do: "metadata"
  defp covariance_container_name(2), do: "provenance"
  defp covariance_container_name(_index), do: "evidence_container"

  defp covariance_evidence_present?(container) when is_map(container) do
    Enum.any?(@covariance_fields, fn key ->
      case fetch_public_field(container, key) do
        {:ok, nil} ->
          false

        {:ok, ""} ->
          false

        {:ok, "not_present"} ->
          key != "covariance_status"

        {:ok, value} when is_atom(value) ->
          normalized_value(value) != "not_present" or key != "covariance_status"

        {:ok, _value} ->
          true

        _result ->
          false
      end
    end)
  end

  defp covariance_evidence_present?(_container), do: false

  defp covariance_matrix_shape(matrix) when is_list(matrix) do
    case bounded_list_items(matrix, 6) do
      {:ok, rows} ->
        covariance_matrix_rows_shape(rows)

      {:oversize, _rows} ->
        {:error, "expected_6x6_numeric_matrix"}

      {:improper, _rows} ->
        {:error, "expected_proper_6x6_numeric_matrix"}
    end
  end

  defp covariance_matrix_shape(_matrix), do: {:error, "expected_6x6_numeric_matrix"}

  defp covariance_matrix_rows_shape(rows) do
    cond do
      length_bounded(rows) != 6 ->
        {:error, "expected_6x6_numeric_matrix"}

      Enum.all?(rows, &covariance_matrix_row?/1) ->
        :ok

      true ->
        {:error, "expected_six_numeric_rows_with_six_numeric_values_each"}
    end
  end

  defp covariance_matrix_row?(row) when is_list(row) do
    case bounded_list_items(row, 6) do
      {:ok, values} ->
        length_bounded(values) == 6 and Enum.all?(values, &is_number/1)

      _items ->
        false
    end
  end

  defp covariance_matrix_row?(_row), do: false

  defp handoff_surface_issues(ref_summary, provenance_summary) do
    []
    |> maybe_issue(
      not is_map(ref_summary),
      "candidate_refresh_evidence_authority_summary_missing",
      "$.candidate_refresh.accepted_planning_state.evidence_authority"
    )
    |> maybe_issue(
      not is_map(provenance_summary),
      "candidate_refresh_evidence_authority_summary_missing",
      "$.candidate_refresh.provenance.accepted_planning_state.evidence_authority"
    )
    |> maybe_issue(
      is_map(ref_summary) and is_map(provenance_summary) and ref_summary != provenance_summary,
      "candidate_refresh_evidence_authority_summary_mismatch",
      "$.candidate_refresh.provenance.accepted_planning_state.evidence_authority"
    )
  end

  defp embedded_issues(%{} = summary) do
    case fetch_public_field(summary, "issues") do
      {:ok, issues} ->
        case bounded_list_items(issues, @max_issues) do
          {:ok, items} ->
            Enum.flat_map(items, &embedded_issue/1)

          {:oversize, items} ->
            [
              issue(
                "invalid_embedded_evidence_authority_issues_shape",
                "$.issues",
                "max_issues_exceeded",
                safe_project_action("accepted_planning_state")
              )
              | Enum.flat_map(items, &embedded_issue/1)
            ]

          {:improper, _items} ->
            [
              issue(
                "invalid_embedded_evidence_authority_issues_shape",
                "$.issues",
                nil,
                safe_project_action("accepted_planning_state")
              )
            ]
        end

      _result ->
        []
    end
  end

  defp embedded_issues(_summary), do: []

  defp embedded_review_reasons(%{} = summary) do
    case fetch_public_field(summary, "review_reasons") do
      {:ok, reasons} ->
        review_reasons_value(reasons)

      {:alias_collision, _key} ->
        {[],
         [
           issue(
             "atom_string_alias_collision",
             "$.evidence_authority.review_reasons",
             nil,
             safe_project_action("accepted_planning_state")
           )
         ]}

      _result ->
        {[], []}
    end
  end

  defp embedded_review_reasons(_summary), do: {[], []}

  defp embedded_projection_paths(%{} = summary) do
    case fetch_public_field(summary, "accepted_state_encoding_projection_paths") do
      {:ok, paths} ->
        projection_paths_value(paths)

      {:alias_collision, _key} ->
        {[],
         [
           issue(
             "atom_string_alias_collision",
             "$.evidence_authority.accepted_state_encoding_projection_paths",
             nil,
             safe_project_action("accepted_planning_state")
           )
         ]}

      _result ->
        {[], []}
    end
  end

  defp embedded_projection_paths(_summary), do: {[], []}

  defp embedded_projection_actions(%{} = summary) do
    case fetch_public_field(summary, "build_encoding_projection_actions") do
      {:ok, actions} ->
        projection_actions_value(actions)

      {:alias_collision, _key} ->
        {[],
         [
           issue(
             "atom_string_alias_collision",
             "$.evidence_authority.build_encoding_projection_actions",
             nil,
             safe_project_action("accepted_planning_state")
           )
         ]}

      _result ->
        {[], []}
    end
  end

  defp embedded_projection_actions(_summary), do: {[], []}

  defp embedded_projection_required(%{} = summary, incoming_projection_paths) do
    field_path = "$.evidence_authority.accepted_state_encoding_projection_required"

    case fetch_public_field(summary, "accepted_state_encoding_projection_required") do
      {:ok, true} ->
        {true, []}

      {:ok, false} ->
        {incoming_projection_paths != [], []}

      {:ok, value} ->
        {true,
         [
           issue(
             "invalid_evidence_authority_projection_required_shape",
             field_path,
             encoded_value(value),
             safe_project_action("accepted_planning_state")
           )
         ]}

      {:alias_collision, _key} ->
        {true,
         [
           issue(
             "atom_string_alias_collision",
             field_path,
             nil,
             safe_project_action("accepted_planning_state")
           )
         ]}

      _result ->
        {incoming_projection_paths != [], []}
    end
  end

  defp embedded_projection_required(_summary, incoming_projection_paths),
    do: {incoming_projection_paths != [], []}

  defp projection_summary_invariant_issues(
         review_reasons,
         projection_paths,
         projection_required?,
         projection_actions,
         shape_issues
       ) do
    []
    |> maybe_issue(
      shape_issues != [] and projection_actions == [],
      "invalid_evidence_authority_projection_summary",
      "$.evidence_authority",
      "malformed_summary_requires_projection",
      safe_project_action("accepted_planning_state")
    )
    |> maybe_issue(
      projection_required? == true and projection_actions == [],
      "invalid_evidence_authority_projection_summary",
      "$.evidence_authority.accepted_state_encoding_projection_required",
      "projection_required_without_actions",
      safe_project_action("accepted_planning_state")
    )
    |> maybe_issue(
      projection_paths != [] and projection_actions == [],
      "invalid_evidence_authority_projection_summary",
      "$.evidence_authority.accepted_state_encoding_projection_paths",
      "projection_paths_without_actions",
      safe_project_action("accepted_planning_state")
    )
    |> maybe_issue(
      Enum.any?(review_reasons, &(&1 in @build_encoding_unsafe_reasons)) and
        projection_actions == [],
      "invalid_evidence_authority_projection_summary",
      "$.evidence_authority.review_reasons",
      "unsafe_review_reason_without_actions",
      safe_project_action("accepted_planning_state")
    )
  end

  defp review_reasons_value(reasons) when is_list(reasons) do
    case bounded_list_items(reasons, @max_review_reasons) do
      {:ok, items} ->
        review_reason_items(items)

      {:oversize, items} ->
        {valid_reasons, issues} = review_reason_items(items)

        {valid_reasons,
         [
           issue(
             "invalid_evidence_authority_review_reasons_shape",
             "$.evidence_authority.review_reasons",
             "max_review_reasons_exceeded",
             safe_project_action("accepted_planning_state")
           )
           | issues
         ]}

      {:improper, items} ->
        {valid_reasons, issues} = review_reason_items(items)

        {valid_reasons,
         [
           issue(
             "invalid_evidence_authority_review_reasons_shape",
             "$.evidence_authority.review_reasons",
             "improper_review_reasons",
             safe_project_action("accepted_planning_state")
           )
           | issues
         ]}
    end
  end

  defp review_reasons_value(_reasons) do
    {[],
     [
       issue(
         "invalid_evidence_authority_review_reasons_shape",
         "$.evidence_authority.review_reasons",
         nil,
         safe_project_action("accepted_planning_state")
       )
     ]}
  end

  defp review_reason_items(items) do
    Enum.reduce(items, {[], []}, fn reason, {reasons, issues} ->
      case review_reason_value(reason) do
        {:ok, reason} ->
          {[reason | reasons], issues}

        {:error, detail} ->
          {reasons,
           [
             issue(
               "invalid_evidence_authority_review_reasons_shape",
               "$.evidence_authority.review_reasons",
               detail,
               safe_project_action("accepted_planning_state")
             )
             | issues
           ]}
      end
    end)
    |> then(fn {reasons, issues} ->
      {reasons |> Enum.uniq() |> Enum.sort(), Enum.reverse(issues)}
    end)
  end

  defp review_reason_value(reason) when is_binary(reason) do
    case bounded_binary(reason) do
      {:ok, ""} -> {:error, "empty_review_reason"}
      {:ok, reason} -> {:ok, reason}
      {:error, detail} -> {:error, detail}
    end
  end

  defp review_reason_value(_reason), do: {:error, "invalid_review_reason"}

  defp projection_paths_value(paths) when is_list(paths) do
    case bounded_list_items(paths, @max_encoding_projection_paths) do
      {:ok, items} ->
        projection_path_items(items)

      {:oversize, items} ->
        {_valid_paths, issues} = projection_path_items(items)

        {["$.accepted_planning_state"],
         [
           issue(
             "invalid_evidence_authority_projection_paths_shape",
             "$.evidence_authority.accepted_state_encoding_projection_paths",
             "max_projection_paths_exceeded",
             safe_project_action("accepted_planning_state")
           )
           | issues
         ]}

      {:improper, items} ->
        {_valid_paths, issues} = projection_path_items(items)

        {["$.accepted_planning_state"],
         [
           issue(
             "invalid_evidence_authority_projection_paths_shape",
             "$.evidence_authority.accepted_state_encoding_projection_paths",
             "improper_projection_paths",
             safe_project_action("accepted_planning_state")
           )
           | issues
         ]}
    end
  end

  defp projection_paths_value(_paths) do
    {[],
     [
       issue(
         "invalid_evidence_authority_projection_paths_shape",
         "$.evidence_authority.accepted_state_encoding_projection_paths",
         nil,
         safe_project_action("accepted_planning_state")
       )
     ]}
  end

  defp projection_path_items(items) do
    Enum.reduce(items, {[], []}, fn path, {paths, issues} ->
      case projection_path_value(path) do
        {:ok, path} ->
          {[path | paths], issues}

        {:error, detail} ->
          {paths,
           [
             issue(
               "invalid_evidence_authority_projection_paths_shape",
               "$.evidence_authority.accepted_state_encoding_projection_paths",
               detail,
               safe_project_action("accepted_planning_state")
             )
             | issues
           ]}
      end
    end)
    |> then(fn {paths, issues} ->
      {paths |> Enum.uniq() |> Enum.sort(), Enum.reverse(issues)}
    end)
  end

  defp projection_path_value(path) when is_binary(path) do
    case bounded_binary(path) do
      {:ok, path} ->
        if accepted_state_encoding_path?(path) do
          {:ok, path}
        else
          {:error, "invalid_projection_path"}
        end

      {:error, detail} ->
        {:error, detail}
    end
  end

  defp projection_path_value(_path), do: {:error, "invalid_projection_path"}

  defp projection_actions_value(actions) when is_list(actions) do
    case bounded_list_items(actions, @max_encoding_projection_actions) do
      {:ok, items} ->
        projection_action_items(items)

      {:oversize, items} ->
        {_valid_actions, issues} = projection_action_items(items)

        {[safe_project_action("accepted_planning_state")],
         [
           issue(
             "invalid_evidence_authority_projection_actions_shape",
             "$.evidence_authority.build_encoding_projection_actions",
             "max_projection_actions_exceeded",
             safe_project_action("accepted_planning_state")
           )
           | issues
         ]}

      {:improper, items} ->
        {_valid_actions, issues} = projection_action_items(items)

        {[safe_project_action("accepted_planning_state")],
         [
           issue(
             "invalid_evidence_authority_projection_actions_shape",
             "$.evidence_authority.build_encoding_projection_actions",
             "improper_projection_actions",
             safe_project_action("accepted_planning_state")
           )
           | issues
         ]}
    end
  end

  defp projection_actions_value(_actions) do
    {[safe_project_action("accepted_planning_state")],
     [
       issue(
         "invalid_evidence_authority_projection_actions_shape",
         "$.evidence_authority.build_encoding_projection_actions",
         nil,
         safe_project_action("accepted_planning_state")
       )
     ]}
  end

  defp projection_action_items(items) do
    Enum.reduce(items, {[], []}, fn action, {actions, issues} ->
      case projection_action_value(action) do
        {:ok, action} ->
          {[action | actions], issues}

        {:error, detail} ->
          {actions,
           [
             issue(
               "invalid_evidence_authority_projection_actions_shape",
               "$.evidence_authority.build_encoding_projection_actions",
               detail,
               safe_project_action("accepted_planning_state")
             )
             | issues
           ]}
      end
    end)
    |> then(fn {actions, issues} ->
      {actions |> Enum.uniq() |> Enum.sort_by(&projection_action_sort_key/1),
       Enum.reverse(issues)}
    end)
  end

  defp projection_action_value(%{} = action) do
    with {:ok, scope} <-
           projection_action_text(action, "scope", [
             "accepted_planning_state",
             "candidate_refresh"
           ]),
         {:ok, action_name} <-
           projection_action_text(action, "action", ["delete", "sanitize_map", "safe_project"]),
         {:ok, segments} <- projection_action_segments(action),
         true <- projection_action_allowed?(action_name, segments) do
      {:ok, %{"scope" => scope, "action" => action_name, "segments" => segments}}
    else
      _result -> {:error, "invalid_projection_action"}
    end
  end

  defp projection_action_value(_action), do: {:error, "invalid_projection_action"}

  defp projection_action_text(action, key, allowed) do
    case fetch_public_field(action, key) do
      {:ok, value} when is_binary(value) ->
        case bounded_binary(value) do
          {:ok, value} -> if value in allowed, do: {:ok, value}, else: :error
          {:error, _reason} -> :error
        end

      _result ->
        :error
    end
  end

  defp projection_action_segments(action) do
    case fetch_public_field(action, "segments") do
      {:ok, segments} when is_list(segments) ->
        case bounded_list_items(segments, @max_encoding_projection_segments) do
          {:ok, items} -> projection_segment_items(items, [])
          _result -> :error
        end

      _result ->
        :error
    end
  end

  defp projection_segment_items([], acc), do: {:ok, Enum.reverse(acc)}

  defp projection_segment_items([segment | rest], acc) when is_binary(segment) do
    if byte_size(segment) <= @max_encoding_projection_segment_bytes and String.valid?(segment) do
      projection_segment_items(rest, [segment | acc])
    else
      :error
    end
  end

  defp projection_segment_items([segment | rest], acc) when is_integer(segment) do
    if segment >= 0 and segment < @max_list_entries do
      projection_segment_items(rest, [segment | acc])
    else
      :error
    end
  end

  defp projection_segment_items(_segments, _acc), do: :error

  defp projection_action_allowed?("safe_project", []), do: true
  defp projection_action_allowed?("safe_project", _segments), do: false
  defp projection_action_allowed?("delete", []), do: false
  defp projection_action_allowed?(_action, _segments), do: true

  defp embedded_issue(%{} = row) do
    reason = embedded_issue_reason(field(row, "reason"))
    path = embedded_issue_path(field(row, "path"))

    projection_action =
      if reason in @build_encoding_unsafe_reasons and accepted_state_encoding_path?(path) do
        safe_project_action("accepted_planning_state")
      end

    [
      issue(
        reason,
        path,
        embedded_issue_detail(field(row, "detail")),
        projection_action
      )
    ]
  end

  defp embedded_issue(_row),
    do: [
      issue(
        "invalid_embedded_evidence_authority_issue_shape",
        "$.issues",
        nil,
        safe_project_action("accepted_planning_state")
      )
    ]

  defp embedded_issue_reason(value) do
    case summary_text(value) do
      nil -> "invalid_embedded_evidence_authority_issue_reason"
      reason -> reason
    end
  end

  defp embedded_issue_path(value) do
    case summary_text(value) do
      "$" <> _rest = path -> path
      _value -> "$.issues"
    end
  end

  defp embedded_issue_detail(nil), do: nil
  defp embedded_issue_detail(value), do: encoded_value(value)

  defp candidate_refresh_artifact?(%{} = value) do
    field(value, "schema_contract") == "candidate_refresh.v1" or
      field(value, "artifact_type") == "candidate_refresh"
  end

  defp refresh_wrapper?(%{} = value) do
    Map.has_key?(value, "accepted_planning_state") or
      Map.has_key?(value, :accepted_planning_state)
  end

  defp refresh_wrapper_preflight_result(refresh) do
    entries = bounded_entries(refresh)

    root_issues =
      map_size_issue(refresh, "$.candidate_refresh", safe_project_action("candidate_refresh")) ++
        key_shape_issues(
          entries,
          "$.candidate_refresh",
          sanitize_map_action("candidate_refresh", [])
        ) ++
        projection_field_alias_issues(refresh, "$.candidate_refresh", "candidate_refresh", []) ++
        alias_collision_issues(
          entries,
          "$.candidate_refresh",
          sanitize_map_action("candidate_refresh", [])
        )

    {accepted_state_issues, nodes} =
      case fetch_known_public_field(refresh, "accepted_planning_state") do
        {:ok, %{} = accepted_state} ->
          accepted_state_public_preflight_result(accepted_state, 1)

        {:ok, value} ->
          scan_public(
            value,
            "$.accepted_planning_state",
            "accepted_planning_state",
            [],
            0,
            1
          )

        _result ->
          {[], 1}
      end

    entries =
      Enum.reject(entries, fn {key, _value} ->
        match?({:ok, "accepted_planning_state"}, key_token(key))
      end)

    {subtree_issues, nodes} = scan_refresh_wrapper_entries(entries, nodes, [])

    {root_issues ++ accepted_state_issues ++ subtree_issues, nodes}
  end

  defp scan_refresh_wrapper_entries(entries, nodes, issues) do
    Enum.reduce_while(entries, {issues, nodes}, fn {key, value}, {acc_issues, acc_nodes} ->
      if acc_nodes >= @max_scan_nodes do
        {:halt,
         {[
            issue(
              "accepted_state_evidence_node_budget_exceeded",
              "$.candidate_refresh",
              "max_scan_nodes_exceeded",
              safe_project_action("candidate_refresh")
            )
            | acc_issues
          ], acc_nodes}}
      else
        case key_token(key) do
          {:ok, key_name} ->
            {child_issues, child_nodes} =
              scan_public(
                value,
                "$.candidate_refresh." <> key_name,
                "candidate_refresh",
                [key_name],
                1,
                acc_nodes
              )

            {:cont, {acc_issues ++ child_issues, child_nodes}}

          {:error, _reason} ->
            {:cont, {acc_issues, acc_nodes}}
        end
      end
    end)
  end

  defp candidate_refresh_handoff_preflight_issues(artifact) do
    top_entries = bounded_entries(artifact)

    top_level_issues =
      map_size_issue(artifact, "$.candidate_refresh", safe_project_action("candidate_refresh")) ++
        key_shape_issues(
          top_entries,
          "$.candidate_refresh",
          sanitize_map_action("candidate_refresh", [])
        ) ++
        projection_field_alias_issues(artifact, "$.candidate_refresh", "candidate_refresh", []) ++
        alias_collision_issues(
          top_entries,
          "$.candidate_refresh",
          sanitize_map_action("candidate_refresh", [])
        )

    accepted_state_issues =
      case fetch_known_public_field(artifact, "accepted_planning_state") do
        {:ok, value} ->
          public_preflight_issues(value, "$.candidate_refresh.accepted_planning_state")

        {:alias_collision, _key} ->
          [
            issue(
              "atom_string_alias_collision",
              "$.candidate_refresh.accepted_planning_state",
              nil,
              sanitize_map_action("candidate_refresh", [])
            )
          ]

        _result ->
          []
      end

    provenance_issues =
      case fetch_public_field(artifact, "provenance") do
        {:ok, %{} = provenance} ->
          case fetch_known_public_field(provenance, "accepted_planning_state") do
            {:ok, value} ->
              public_preflight_issues(
                value,
                "$.candidate_refresh.provenance.accepted_planning_state"
              )

            {:alias_collision, _key} ->
              [
                issue(
                  "atom_string_alias_collision",
                  "$.candidate_refresh.provenance.accepted_planning_state",
                  nil,
                  sanitize_map_action("candidate_refresh", ["provenance"])
                )
              ]

            _result ->
              []
          end

        {:alias_collision, _key} ->
          [
            issue(
              "atom_string_alias_collision",
              "$.candidate_refresh.provenance",
              nil,
              sanitize_map_action("candidate_refresh", [])
            )
          ]

        _result ->
          []
      end

    top_level_issues ++ accepted_state_issues ++ provenance_issues
  end

  defp normalize_boundary_issues(issues) when is_list(issues) do
    case bounded_list_items(issues, @max_issues) do
      {:ok, items} ->
        Enum.filter(items, &is_map/1)

      {:oversize, items} ->
        [
          issue("accepted_state_evidence_boundary_issues_oversize", "$.boundary_issues")
          | Enum.filter(items, &is_map/1)
        ]

      {:improper, items} ->
        [
          issue("accepted_state_evidence_boundary_issues_improper", "$.boundary_issues")
          | Enum.filter(items, &is_map/1)
        ]
    end
  end

  defp normalize_boundary_issues(_issues),
    do: [issue("accepted_state_evidence_boundary_issues_invalid", "$.boundary_issues")]

  defp accepted_state_public_preflight_issues(%{} = accepted_state) do
    accepted_state
    |> accepted_state_public_preflight_result(0)
    |> elem(0)
  end

  defp accepted_state_public_preflight_issues(_accepted_state), do: []

  defp accepted_state_public_preflight_result(%{} = accepted_state, nodes) do
    {root_issues, nodes} = accepted_state_root_public_preflight_result(accepted_state, nodes)

    {container_issues, nodes} =
      accepted_state_container_public_preflight_result(accepted_state, nodes)

    {root_issues ++ container_issues, nodes}
  end

  defp accepted_state_root_public_preflight_result(%{} = accepted_state, nodes) do
    path = "$.accepted_planning_state"
    scope = "accepted_planning_state"
    entries = bounded_entries(accepted_state)

    own_issues =
      map_size_issue(accepted_state, path, safe_project_action(scope)) ++
        key_shape_issues(entries, path, sanitize_map_action(scope, [])) ++
        projection_field_alias_issues(accepted_state, path, scope, []) ++
        alias_collision_issues(entries, path, sanitize_map_action(scope, [])) ++
        identity_claim_issues(entries, path)

    entries =
      Enum.reject(entries, fn {key, _value} ->
        case key_token(key) do
          {:ok, key_name} -> key_name in ["spacecraft_states", "maneuver_execution_deltas"]
          {:error, _reason} -> false
        end
      end)

    if nodes >= @max_scan_nodes do
      {[
         issue(
           "accepted_state_evidence_node_budget_exceeded",
           path,
           "max_scan_nodes_exceeded",
           safe_project_action(scope)
         )
         | own_issues
       ], nodes}
    else
      scan_entries(entries, path, scope, [], 0, nodes + 1, own_issues)
    end
  end

  defp accepted_state_container_public_preflight_result(%{} = accepted_state, nodes) do
    case fetch_public_field(accepted_state, "spacecraft_states") do
      {:ok, states} when is_list(states) ->
        case bounded_list_items(states, @max_spacecraft_states) do
          {:ok, items} -> state_container_public_preflight_result(items, nodes)
          _result -> {[], nodes}
        end

      _result ->
        {[], nodes}
    end
  end

  defp state_container_public_preflight_result(states, nodes) do
    states
    |> Enum.with_index()
    |> Enum.reduce_while({[], nodes}, fn {state, index}, {issues, nodes} ->
      if nodes >= @max_scan_nodes do
        {:halt,
         {[
            issue(
              "accepted_state_evidence_node_budget_exceeded",
              "$.accepted_planning_state.spacecraft_states",
              "max_scan_nodes_exceeded",
              safe_project_action("accepted_planning_state")
            )
            | issues
          ], nodes}}
      else
        {state_issues, nodes} = state_container_public_preflight_issues(state, index, nodes)
        {:cont, {issues ++ state_issues, nodes}}
      end
    end)
  end

  defp state_container_public_preflight_issues(%{} = state, index, nodes) do
    state_path = "$.accepted_planning_state.spacecraft_states[#{index}]"

    ~w(quality metadata provenance source)
    |> Enum.reduce_while({[], nodes}, fn key, {issues, nodes} ->
      if nodes >= @max_scan_nodes do
        {:halt,
         {[
            issue(
              "accepted_state_evidence_node_budget_exceeded",
              state_path,
              "max_scan_nodes_exceeded",
              safe_project_action("accepted_planning_state")
            )
            | issues
          ], nodes}}
      else
        case fetch_public_field(state, key) do
          {:ok, %{} = container} ->
            {container_issues, nodes} =
              scan_public(
                container,
                state_path <> "." <> key,
                "accepted_planning_state",
                ["spacecraft_states", index, key],
                1,
                nodes
              )

            {:cont, {issues ++ container_issues, nodes}}

          _result ->
            {:cont, {issues, nodes}}
        end
      end
    end)
  end

  defp state_container_public_preflight_issues(_state, _index, nodes), do: {[], nodes}

  defp public_preflight_issues(term, path) do
    {issues, _nodes} = scan_public(term, path, projection_scope(path), [], 0, 0)
    issues
  end

  defp projection_scope("$.accepted_planning_state"), do: "accepted_planning_state"

  defp projection_scope("$.candidate_refresh.accepted_planning_state"),
    do: "accepted_planning_state"

  defp projection_scope("$.candidate_refresh.provenance.accepted_planning_state"),
    do: "accepted_planning_state"

  defp projection_scope("$.candidate_refresh"), do: "candidate_refresh"
  defp projection_scope(_path), do: nil

  defp scan_public(_term, path, scope, segments, _depth, nodes) when nodes >= @max_scan_nodes do
    {[
       issue(
         "accepted_state_evidence_node_budget_exceeded",
         path,
         "max_scan_nodes_exceeded",
         delete_action(scope, segments)
       )
     ], nodes}
  end

  defp scan_public(_term, path, scope, segments, depth, nodes) when depth > @max_scan_depth do
    {[
       issue(
         "accepted_state_evidence_shape_deep",
         path,
         "max_scan_depth_exceeded",
         delete_action(scope, segments)
       )
     ], nodes + 1}
  end

  defp scan_public(%{} = map, path, scope, segments, depth, nodes) do
    entries = bounded_entries(map)

    own_issues =
      map_size_issue(map, path, safe_project_action(scope)) ++
        key_shape_issues(entries, path, sanitize_map_action(scope, segments)) ++
        projection_field_alias_issues(map, path, scope, segments) ++
        alias_collision_issues(entries, path, sanitize_map_action(scope, segments)) ++
        identity_claim_issues(entries, path)

    scan_entries(entries, path, scope, segments, depth, nodes + 1, own_issues)
  end

  defp scan_public(values, path, scope, segments, depth, nodes) when is_list(values) do
    case bounded_list_items(values, @max_list_entries) do
      {:ok, items} ->
        scan_list_items(items, path, scope, segments, depth, nodes + 1, [])

      {:oversize, items} ->
        scan_list_items(
          items,
          path,
          scope,
          segments,
          depth,
          nodes + 1,
          [
            issue(
              "accepted_state_evidence_shape_oversize",
              path,
              "max_list_entries_exceeded",
              delete_action(scope, segments)
            )
          ]
        )

      {:improper, items} ->
        scan_list_items(
          items,
          path,
          scope,
          segments,
          depth,
          nodes + 1,
          [
            issue(
              "accepted_state_evidence_improper_list_shape",
              path,
              nil,
              delete_action(scope, segments)
            )
          ]
        )
    end
  end

  defp scan_public(value, path, scope, segments, _depth, nodes),
    do: {scalar_shape_issues(value, path, delete_action(scope, segments)), nodes + 1}

  defp scan_entries(entries, path, scope, segments, depth, nodes, issues) do
    Enum.reduce_while(entries, {issues, nodes}, fn {key, value}, {acc_issues, acc_nodes} ->
      if acc_nodes >= @max_scan_nodes do
        {:halt,
         {[
            issue(
              "accepted_state_evidence_node_budget_exceeded",
              path,
              "max_scan_nodes_exceeded",
              delete_action(scope, segments)
            )
            | acc_issues
          ], acc_nodes}}
      else
        child_segments = segments_for(segments, key)

        {child_issues, child_nodes} =
          scan_public(value, path_for(path, key), scope, child_segments, depth + 1, acc_nodes)

        {:cont, {acc_issues ++ child_issues, child_nodes}}
      end
    end)
  end

  defp scan_list_items(items, path, scope, segments, depth, nodes, issues) do
    items
    |> Enum.with_index()
    |> Enum.reduce_while({issues, nodes}, fn {value, index}, {acc_issues, acc_nodes} ->
      if acc_nodes >= @max_scan_nodes do
        {:halt,
         {[
            issue(
              "accepted_state_evidence_node_budget_exceeded",
              path,
              "max_scan_nodes_exceeded",
              delete_action(scope, segments)
            )
            | acc_issues
          ], acc_nodes}}
      else
        {child_issues, child_nodes} =
          scan_public(
            value,
            path <> "[#{index}]",
            scope,
            segments ++ [index],
            depth + 1,
            acc_nodes
          )

        {:cont, {acc_issues ++ child_issues, child_nodes}}
      end
    end)
  end

  defp segments_for(segments, key) do
    case key_token(key) do
      {:ok, key_name} -> segments ++ [key_name]
      {:error, _reason} -> segments
    end
  end

  defp map_size_issue(map, path, projection_action \\ nil) do
    if map_size(map) > @max_map_entries do
      [
        issue(
          "accepted_state_evidence_shape_oversize",
          path,
          "max_map_entries_exceeded",
          projection_action
        )
      ]
    else
      []
    end
  end

  defp key_shape_issues(entries, path, projection_action \\ nil) do
    Enum.flat_map(entries, fn {key, _value} ->
      case key_token(key) do
        {:ok, _key} -> []
        {:error, reason} -> [issue(reason, path <> ".unsupported_key", nil, projection_action)]
      end
    end)
  end

  defp alias_collision_issues(entries, path, projection_action \\ nil) do
    entries
    |> Enum.flat_map(fn {key, _value} ->
      case alias_key_token(key) do
        {:ok, name} -> [{name, key_form(key)}]
        {:error, _reason} -> []
      end
    end)
    |> Enum.group_by(fn {name, _form} -> name end, fn {_name, form} -> form end)
    |> Enum.flat_map(fn {name, forms} ->
      unique_forms = Enum.uniq(forms)

      if :atom in unique_forms and :string in unique_forms do
        [issue("atom_string_alias_collision", path <> "." <> name, nil, projection_action)]
      else
        []
      end
    end)
  end

  defp projection_field_alias_issues(%{} = map, path, "candidate_refresh", segments) do
    projection_field_alias_issues(
      map,
      path,
      encoding_projection_fields(),
      "candidate_refresh",
      segments
    )
  end

  defp projection_field_alias_issues(%{} = map, path, "accepted_planning_state", segments) do
    projection_field_alias_issues(
      map,
      path,
      encoding_projection_fields(),
      "accepted_planning_state",
      segments
    )
  end

  defp projection_field_alias_issues(_map, _path, _scope, _segments), do: []

  defp projection_field_alias_issues(map, path, fields, scope, segments) do
    Enum.flat_map(fields, fn field ->
      atom_key = encoding_projection_atom_for_key(field)

      if is_atom(atom_key) and Map.has_key?(map, field) and Map.has_key?(map, atom_key) do
        [
          issue(
            "atom_string_alias_collision",
            path <> "." <> field,
            nil,
            sanitize_map_action(scope, segments)
          )
        ]
      else
        []
      end
    end)
  end

  defp identity_claim_issues(entries, path) do
    Enum.flat_map(entries, fn {key, value} ->
      case key_token(key) do
        {:ok, key_name} ->
          child_path = path <> "." <> key_name

          identity_container_issues =
            if key_name in @identity_keys do
              source_identity_issues(value, child_path)
            else
              []
            end

          auth_claim_issues =
            if key_name in @auth_claim_keys and affirmative_authority_claim?(value) do
              [issue("claimed_content_identity_authority", child_path, encoded_value(value))]
            else
              []
            end

          identity_container_issues ++ auth_claim_issues

        {:error, _reason} ->
          []
      end
    end)
  end

  defp scalar_shape_issues(nil, _path, _projection_action), do: []
  defp scalar_shape_issues(value, _path, _projection_action) when is_boolean(value), do: []

  defp scalar_shape_issues(value, path, projection_action) when is_float(value) do
    if bounded_number?(value) do
      []
    else
      [
        issue(
          "unsupported_accepted_state_evidence_value",
          path,
          "invalid_float",
          projection_action
        )
      ]
    end
  end

  defp scalar_shape_issues(value, path, projection_action) when is_integer(value) do
    if bounded_integer?(value) do
      []
    else
      [
        issue(
          "accepted_state_evidence_integer_oversize",
          path,
          "max_safe_integer_exceeded",
          projection_action
        )
      ]
    end
  end

  defp scalar_shape_issues(value, path, projection_action) when is_binary(value) do
    case bounded_binary(value) do
      {:ok, _value} -> []
      {:error, reason} -> [issue(reason, path, nil, projection_action)]
    end
  end

  defp scalar_shape_issues(value, path, projection_action) when is_atom(value) do
    if atom_value_token(value) do
      []
    else
      [issue("unsupported_accepted_state_evidence_atom", path, nil, projection_action)]
    end
  end

  defp scalar_shape_issues(value, path, projection_action) when is_pid(value),
    do: [issue("unsupported_accepted_state_evidence_value", path, "pid", projection_action)]

  defp scalar_shape_issues(value, path, projection_action) when is_reference(value),
    do: [issue("unsupported_accepted_state_evidence_value", path, "reference", projection_action)]

  defp scalar_shape_issues(value, path, projection_action) when is_function(value),
    do: [issue("unsupported_accepted_state_evidence_value", path, "function", projection_action)]

  defp scalar_shape_issues(_value, path, projection_action),
    do: [
      issue(
        "unsupported_accepted_state_evidence_value",
        path,
        "unsupported_term",
        projection_action
      )
    ]

  defp source_identity_issues(%{} = identity, path) do
    authority = field(identity, "authority")

    authority_issues =
      if affirmative_authority_claim?(authority) do
        [
          issue(
            "claimed_content_identity_authority",
            path <> ".authority",
            encoded_value(authority)
          )
        ]
      else
        []
      end

    auth_field_issues =
      @auth_claim_keys
      |> Enum.reject(&(&1 == "authority"))
      |> Enum.flat_map(fn key ->
        case fetch_public_field(identity, key) do
          {:ok, value} ->
            if affirmative_authority_claim?(value) do
              [
                issue(
                  "authenticated_source_identity_claim",
                  path <> "." <> key,
                  encoded_value(value)
                )
              ]
            else
              []
            end

          _result ->
            []
        end
      end)

    authority_issues ++ auth_field_issues
  end

  defp source_identity_issues(_identity, path),
    do: [issue("invalid_source_identity_shape", path)]

  defp affirmative_authority_claim?(value) when value in [nil, false], do: false
  defp affirmative_authority_claim?(true), do: true

  defp affirmative_authority_claim?(value) do
    case normalized_value(value) do
      nil -> false
      "" -> false
      value -> value not in @negative_authority_values
    end
  end

  defp put_issue_summary(
         summary,
         issues,
         incoming_review_reasons \\ [],
         encoding_projection_required \\ nil,
         incoming_encoding_projection_paths \\ [],
         incoming_encoding_projection_actions \\ []
       ) do
    issues =
      issues
      |> Enum.filter(&is_map/1)
      |> Enum.uniq()
      |> Enum.sort_by(&{Map.get(&1, "reason"), Map.get(&1, "path"), Map.get(&1, "detail", "")})

    displayed_issues =
      issues
      |> Enum.map(&display_issue/1)
      |> Enum.uniq()
      |> Enum.sort_by(&{Map.get(&1, "reason"), Map.get(&1, "path"), Map.get(&1, "detail", "")})

    review_reasons =
      (Enum.map(issues, &Map.get(&1, "reason")) ++ incoming_review_reasons)
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    review_required? = issues != [] or review_reasons != []
    issue_count = length_bounded(displayed_issues)

    encoding_projection_actions =
      issues
      |> build_encoding_projection_actions(incoming_encoding_projection_actions)

    encoding_projection_paths =
      issues
      |> accepted_state_encoding_projection_paths(incoming_encoding_projection_paths)

    encoding_projection_required =
      case encoding_projection_required do
        true -> true
        false -> encoding_projection_paths != [] or encoding_projection_actions != []
        _value -> encoding_projection_paths != [] or encoding_projection_actions != []
      end

    summary
    |> Map.put("status", if(review_required?, do: "review_required", else: "clean"))
    |> Map.put("review_required", review_required?)
    |> Map.put("review_reasons", review_reasons)
    |> Map.put("issue_count", issue_count)
    |> Map.put("issues", Enum.take(displayed_issues, @max_issues))
    |> Map.put("omitted_issue_count", max(issue_count - @max_issues, 0))
    |> Map.put("accepted_state_encoding_projection_required", encoding_projection_required)
    |> Map.put("accepted_state_encoding_projection_paths", encoding_projection_paths)
    |> Map.put("build_encoding_projection_actions", encoding_projection_actions)
  end

  defp display_issue(issue), do: Map.delete(issue, "_encoding_projection_action")

  defp build_encoding_projection_actions(issues, incoming_actions) do
    issue_actions =
      Enum.flat_map(issues, fn
        %{"_encoding_projection_action" => action} when is_map(action) -> [action]
        _issue -> []
      end)

    actions =
      (issue_actions ++ incoming_actions)
      |> Enum.filter(&is_map/1)
      |> Enum.uniq()
      |> Enum.sort_by(&projection_action_sort_key/1)

    if length_bounded(actions) > @max_encoding_projection_actions do
      actions
      |> Enum.map(&Map.get(&1, "scope"))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.map(&safe_project_action/1)
    else
      actions
    end
  end

  defp projection_action_sort_key(%{} = action) do
    {Map.get(action, "scope"), Map.get(action, "action"), Map.get(action, "segments", [])}
  end

  defp accepted_state_encoding_projection_paths(issues, incoming_paths) do
    paths =
      issues
      |> Enum.flat_map(fn
        %{"reason" => reason, "path" => path} ->
          if reason in @build_encoding_unsafe_reasons and accepted_state_encoding_path?(path) do
            [path]
          else
            []
          end

        _issue ->
          []
      end)
      |> Kernel.++(incoming_paths)
      |> Enum.uniq()
      |> Enum.sort()

    if length_bounded(paths) > @max_encoding_projection_paths do
      ["$.accepted_planning_state"]
    else
      paths
    end
  end

  defp accepted_state_encoding_path?(path) when is_binary(path) do
    path == "$.accepted_planning_state" or
      String.starts_with?(path, "$.accepted_planning_state.") or
      path == "$.candidate_refresh.accepted_planning_state" or
      String.starts_with?(path, "$.candidate_refresh.accepted_planning_state.")
  end

  defp accepted_state_encoding_path?(_path), do: false

  defp maybe_issue(issues, true, reason, path), do: [issue(reason, path) | issues]
  defp maybe_issue(issues, false, _reason, _path), do: issues

  defp maybe_issue(issues, true, reason, path, detail, projection_action),
    do: [issue(reason, path, detail, projection_action) | issues]

  defp maybe_issue(issues, false, _reason, _path, _detail, _projection_action), do: issues

  defp issue(reason, path, detail \\ nil, projection_action \\ nil) do
    %{"reason" => reason, "path" => path}
    |> maybe_put("detail", detail)
    |> maybe_put("_encoding_projection_action", projection_action)
  end

  defp issue_matches?(%{"reason" => actual_reason, "path" => actual_path}, reason, path),
    do: actual_reason == reason and actual_path == path

  defp issue_matches?(_issue, _reason, _path), do: false

  defp covariance_epoch_binding_seconds_path?(path) when is_binary(path) do
    String.starts_with?(path, "$.accepted_planning_state.spacecraft_states[") and
      String.ends_with?(path, ".covariance_epoch_binding.seconds_since_j2000")
  end

  defp covariance_epoch_binding_seconds_path?(_path), do: false

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp delete_action(nil, _segments), do: nil
  defp delete_action(scope, []), do: safe_project_action(scope)
  defp delete_action(scope, segments), do: projection_action(scope, "delete", segments)

  defp sanitize_map_action(nil, _segments), do: nil

  defp sanitize_map_action(scope, segments),
    do: projection_action(scope, "sanitize_map", segments)

  defp safe_project_action(nil), do: nil
  defp safe_project_action(scope), do: projection_action(scope, "safe_project", [])

  defp projection_action(scope, action, segments)
       when scope in ["accepted_planning_state", "candidate_refresh"] and is_list(segments) do
    %{"scope" => scope, "action" => action, "segments" => segments}
  end

  defp projection_action(_scope, _action, _segments), do: nil

  defp covariance_container_path(path, 0), do: path <> ".quality"
  defp covariance_container_path(path, 1), do: path <> ".metadata"
  defp covariance_container_path(path, 2), do: path <> ".provenance"
  defp covariance_container_path(path, _index), do: path <> ".evidence_container"

  defp get_in_fields(value, []), do: value

  defp get_in_fields(%{} = map, [key | rest]) do
    case fetch_public_field(map, key) do
      {:ok, value} -> get_in_fields(value, rest)
      _result -> nil
    end
  end

  defp get_in_fields(_value, _keys), do: nil

  defp map_field(map, key) do
    case fetch_public_field(map, key) do
      {:ok, %{} = value} -> value
      _value -> %{}
    end
  end

  defp state_epoch_seconds_result(state, path, projection_segments \\ nil) do
    epoch_path = path <> ".epoch"

    case fetch_public_field(state, "epoch") do
      {:ok, %{} = epoch} ->
        state_epoch_seconds_field_result(epoch, epoch_path, projection_segments)

      {:ok, nil} ->
        {:invalid, nil, [issue("invalid_state_epoch_shape", epoch_path, "nil")]}

      {:ok, value} ->
        {:invalid, nil, [issue("invalid_state_epoch_shape", epoch_path, encoded_value(value))]}

      {:alias_collision, _key} ->
        {:invalid, nil, [issue("atom_string_alias_collision", epoch_path)]}

      _result ->
        {:missing, nil, []}
    end
  end

  defp state_epoch_seconds_field_result(epoch, epoch_path, projection_segments) do
    field_path = epoch_path <> ".seconds_since_j2000"

    case fetch_public_field(epoch, "seconds_since_j2000") do
      {:ok, value} ->
        state_epoch_seconds_value_result(value, field_path, projection_segments)

      {:alias_collision, _key} ->
        {:invalid, nil, [issue("atom_string_alias_collision", field_path)]}

      _result ->
        {:missing, nil, []}
    end
  end

  defp state_epoch_seconds_value_result(value, path, _projection_segments)
       when is_integer(value) do
    if bounded_integer?(value) do
      {:present, value, []}
    else
      {:invalid, nil, [issue("invalid_state_epoch_seconds_shape", path, "oversize_integer")]}
    end
  end

  defp state_epoch_seconds_value_result(value, path, _projection_segments) when is_float(value) do
    if bounded_number?(value) do
      {:present, value, []}
    else
      {:invalid, nil, [issue("invalid_state_epoch_seconds_shape", path, "invalid_float")]}
    end
  end

  defp state_epoch_seconds_value_result(nil, path, _projection_segments),
    do: {:invalid, nil, [issue("invalid_state_epoch_seconds_shape", path, "nil")]}

  defp state_epoch_seconds_value_result("", path, _projection_segments),
    do: {:invalid, nil, [issue("invalid_state_epoch_seconds_shape", path, "empty")]}

  defp state_epoch_seconds_value_result(value, path, projection_segments) do
    issues =
      [issue("invalid_state_epoch_seconds_shape", path, encoded_value(value))] ++
        state_epoch_seconds_encoding_issues(value, path, projection_segments)

    {:invalid, nil, issues}
  end

  defp state_epoch_seconds_encoding_issues(value, path, projection_segments)
       when is_list(value) do
    projection_action = delete_action("accepted_planning_state", projection_segments || [])

    case bounded_list_items(value, @max_list_entries) do
      {:ok, _items} ->
        []

      {:oversize, _items} ->
        [
          issue(
            "accepted_state_evidence_shape_oversize",
            path,
            "max_list_entries_exceeded",
            projection_action
          )
        ]

      {:improper, _items} ->
        [
          issue(
            "accepted_state_evidence_improper_list_shape",
            path,
            nil,
            projection_action
          )
        ]
    end
  end

  defp state_epoch_seconds_encoding_issues(value, path, projection_segments) do
    projection_action = delete_action("accepted_planning_state", projection_segments || [])

    case scalar_shape_issues(value, path, projection_action) do
      [] -> []
      issues -> issues
    end
  end

  defp field(map, key, default \\ nil)

  defp field(%{} = map, key, default) do
    case fetch_public_field(map, key) do
      {:ok, value} -> value
      _result -> default
    end
  end

  defp field(_map, _key, default), do: default

  defp field_present?(%{} = map, key), do: match?({:ok, _value}, fetch_public_field(map, key))
  defp field_present?(_map, _key), do: false

  defp fetch_public_field(%{} = map, key) do
    matches =
      map
      |> bounded_entries()
      |> Enum.filter(fn {map_key, _value} -> key_matches?(map_key, key) end)

    case matches do
      [] -> :missing
      [{_key, value}] -> {:ok, value}
      _matches -> {:alias_collision, key}
    end
  end

  defp fetch_public_field(_map, _key), do: :missing

  defp fetch_known_public_field(%{} = map, key) do
    atom_key = encoding_projection_atom_for_key(key)
    string_present? = Map.has_key?(map, key)
    atom_present? = not is_nil(atom_key) and Map.has_key?(map, atom_key)

    case {string_present?, atom_present?} do
      {false, false} -> :missing
      {true, false} -> Map.fetch(map, key)
      {false, true} -> Map.fetch(map, atom_key)
      {true, true} -> {:alias_collision, key}
    end
  end

  defp fetch_known_public_field(_map, _key), do: :missing

  defp key_matches?(map_key, target) when is_binary(map_key), do: map_key == target

  defp key_matches?(map_key, target) when is_atom(map_key) do
    case atom_key_token(map_key) do
      ^target -> true
      _token -> false
    end
  end

  defp key_matches?(_map_key, _target), do: false

  defp bounded_entries(%{} = map) do
    entries =
      if map_size(map) > @max_map_entries do
        deterministic_known_entries(map)
      else
        Map.to_list(map)
      end

    Enum.sort_by(entries, fn {key, _value} -> key_sort_token(key) end)
  end

  defp deterministic_known_entries(%{} = map) do
    Enum.flat_map(@encoding_projection_fields, fn field ->
      atom_key = encoding_projection_atom_for_key(field)

      string_entries =
        if Map.has_key?(map, field) do
          [{field, Map.fetch!(map, field)}]
        else
          []
        end

      atom_entries =
        if is_atom(atom_key) and Map.has_key?(map, atom_key) do
          [{atom_key, Map.fetch!(map, atom_key)}]
        else
          []
        end

      string_entries ++ atom_entries
    end)
  end

  defp bounded_list_items(values, max_items) when is_list(values),
    do: bounded_list_items(values, max_items, [])

  defp bounded_list_items(_values, _max_items), do: {:improper, []}

  defp bounded_list_items([], _remaining, acc), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items(_values, 0, acc), do: {:oversize, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], remaining, acc),
    do: bounded_list_items(tail, remaining - 1, [head | acc])

  defp bounded_list_items(_improper_tail, _remaining, acc), do: {:improper, Enum.reverse(acc)}

  defp length_bounded(values), do: length_bounded(values, 0)
  defp length_bounded([], count), do: count
  defp length_bounded([_head | tail], count), do: length_bounded(tail, count + 1)

  defp path_for(path, key) do
    case key_token(key) do
      {:ok, key_name} -> path <> "." <> key_name
      {:error, _reason} -> path <> ".unsupported_key"
    end
  end

  defp key_shape_token(key) do
    case key_token(key) do
      {:ok, key_name} -> key_name
      {:error, reason} -> reason
    end
  end

  defp key_sort_token(key), do: {key_form(key), key_shape_token(key)}

  defp key_token(key) when is_binary(key) do
    case bounded_binary(key) do
      {:ok, key} -> {:ok, key}
      {:error, reason} -> {:error, reason}
    end
  end

  defp key_token(key) when is_atom(key) do
    case atom_key_token(key) do
      nil -> {:error, "unsupported_accepted_state_evidence_atom_key"}
      key_name -> {:ok, key_name}
    end
  end

  defp key_token(_key), do: {:error, "unsupported_accepted_state_evidence_key"}

  defp alias_key_token(key) when is_binary(key) do
    case bounded_binary(key) do
      {:ok, key} -> {:ok, key}
      {:error, reason} -> {:error, reason}
    end
  end

  defp alias_key_token(key) when is_atom(key) do
    case atom_key_token(key) do
      nil -> {:error, "unsupported_accepted_state_evidence_atom_key"}
      key_name -> {:ok, key_name}
    end
  end

  defp alias_key_token(_key), do: {:error, "unsupported_accepted_state_evidence_key"}

  defp key_form(key) when is_binary(key), do: :string
  defp key_form(key) when is_atom(key), do: :atom
  defp key_form(_key), do: :other

  defp bounded_binary(value) when byte_size(value) > @max_binary_bytes,
    do: {:error, "accepted_state_evidence_binary_oversize"}

  defp bounded_binary(value) do
    if String.valid?(value) do
      {:ok, value}
    else
      {:error, "accepted_state_evidence_invalid_utf8"}
    end
  end

  defp bounded_integer?(value) when is_integer(value),
    do: value >= -@max_abs_integer and value <= @max_abs_integer

  defp bounded_number?(value) when is_integer(value), do: bounded_integer?(value)

  defp bounded_number?(value) when is_float(value),
    do: value == value and value <= @max_abs_float and value >= -@max_abs_float

  defp bounded_number?(_value), do: false

  defp exact_bounded_text(value) when is_binary(value) do
    case bounded_binary(value) do
      {:ok, value} -> value
      {:error, _reason} -> nil
    end
  end

  defp exact_bounded_text(value) when is_atom(value), do: atom_value_token(value)
  defp exact_bounded_text(_value), do: nil

  defp nonempty_exact_text(value) do
    case exact_bounded_text(value) do
      "" -> nil
      text when is_binary(text) -> text
      nil -> nil
    end
  end

  defp nonempty_binary_text(value) when is_binary(value) do
    case bounded_binary(value) do
      {:ok, ""} -> nil
      {:ok, value} -> value
      {:error, _reason} -> nil
    end
  end

  defp nonempty_binary_text(_value), do: nil

  defp invalid_text_detail(nil), do: "nil"
  defp invalid_text_detail(""), do: "empty"
  defp invalid_text_detail(value) when is_atom(value), do: "unsupported_atom"
  defp invalid_text_detail(value), do: encoded_value(value)

  defp normalized_value(nil), do: nil
  defp normalized_value(false), do: "false"
  defp normalized_value(true), do: "true"

  defp normalized_value(value) when is_binary(value) do
    case bounded_binary(value) do
      {:ok, value} ->
        value
        |> String.trim()
        |> String.downcase()

      {:error, _reason} ->
        nil
    end
  end

  defp normalized_value(value) when is_atom(value), do: atom_value_token(value)
  defp normalized_value(_value), do: nil

  defp encoded_value(value) when is_binary(value) do
    case bounded_binary(value) do
      {:ok, value} -> value
      {:error, reason} -> reason
    end
  end

  defp encoded_value(value) when is_atom(value) do
    case atom_value_token(value) do
      nil -> "unsupported_atom"
      token -> token
    end
  end

  defp encoded_value(false), do: "false"
  defp encoded_value(true), do: "true"

  defp encoded_value(value) when is_integer(value),
    do: if(bounded_integer?(value), do: "integer", else: "oversize_integer")

  defp encoded_value(value) when is_float(value),
    do: if(bounded_number?(value), do: "float", else: "invalid_float")

  defp encoded_value(value) when is_pid(value), do: "pid"
  defp encoded_value(value) when is_reference(value), do: "reference"
  defp encoded_value(value) when is_function(value), do: "function"
  defp encoded_value(_value), do: "unsupported_term"

  defp atom_key_token(key), do: encoding_projection_atom_key_token(key)

  defp atom_value_token(:accepted), do: "accepted"
  defp atom_value_token(:authenticated), do: "authenticated"
  defp atom_value_token(:byte_identity_not_authenticated), do: "byte_identity_not_authenticated"

  defp atom_value_token(:candidate_refresh_evidence_authority_carried),
    do: "candidate_refresh_evidence_authority_carried"

  defp atom_value_token(:clean), do: "clean"
  defp atom_value_token(:earth_inertial_j2000), do: "earth_inertial_j2000"
  defp atom_value_token(:EME2000), do: "EME2000"
  defp atom_value_token(:explicit_ccsds_units), do: "explicit_ccsds_units"
  defp atom_value_token(:failed), do: "failed"
  defp atom_value_token(:ICRF), do: "ICRF"
  defp atom_value_token(:implicit_ccsds_units), do: "implicit_ccsds_units"
  defp atom_value_token(:km), do: "km"
  defp atom_value_token(:"km**2"), do: "km**2"
  defp atom_value_token(:"km**2/s"), do: "km**2/s"
  defp atom_value_token(:"km**2/s**2"), do: "km**2/s**2"

  defp atom_value_token(:matrix_exported_metadata_only_no_propagation),
    do: "matrix_exported_metadata_only_no_propagation"

  defp atom_value_token(:matrix_imported_metadata_only_no_propagation),
    do: "matrix_imported_metadata_only_no_propagation"

  defp atom_value_token(:metadata_only_not_consumed), do: "metadata_only_not_consumed"
  defp atom_value_token(:metadata_only_no_propagation), do: "metadata_only_no_propagation"
  defp atom_value_token(:metadata_only_not_propagated), do: "metadata_only_not_propagated"
  defp atom_value_token(:no_cadence_authorization), do: "no_cadence_authorization"

  defp atom_value_token(:no_covariance_filtering_or_propagation),
    do: "no_covariance_filtering_or_propagation"

  defp atom_value_token(:no_decision_authority), do: "no_decision_authority"

  defp atom_value_token(:no_external_covariance_truth_validation),
    do: "no_external_covariance_truth_validation"

  defp atom_value_token(:no_signature_or_declared_authority_authentication),
    do: "no_signature_or_declared_authority_authentication"

  defp atom_value_token(:not_authenticated), do: "not_authenticated"
  defp atom_value_token(:not_present), do: "not_present"
  defp atom_value_token(:passed), do: "passed"
  defp atom_value_token(:planning_accepted), do: "planning_accepted"
  defp atom_value_token(:review_required), do: "review_required"
  defp atom_value_token(:tai), do: "tai"
  defp atom_value_token(:tdb), do: "tdb"
  defp atom_value_token(:unsupported), do: "unsupported"
  defp atom_value_token(:utc), do: "utc"
  defp atom_value_token(:x_dot_km_s), do: "x_dot_km_s"
  defp atom_value_token(:x_km), do: "x_km"
  defp atom_value_token(:y_dot_km_s), do: "y_dot_km_s"
  defp atom_value_token(:y_km), do: "y_km"
  defp atom_value_token(:z_dot_km_s), do: "z_dot_km_s"
  defp atom_value_token(:z_km), do: "z_km"
  defp atom_value_token(_value), do: nil
end
