defmodule OrbitalDynamics.CampaignPlanner.MissionStateNormalization do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    MissionState,
    ObjectivePressureRows,
    RepairRealizedState,
    ValueEncoding
  }

  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.CollectionLatencyObjectiveType

  def normalize(state), do: normalize(state, callbacks())

  def normalize(nil, callbacks),
    do: normalize(%{"snapshot_id" => "unspecified"}, callbacks)

  def normalize(%MissionState{} = state, callbacks) do
    state
    |> Map.from_struct()
    |> normalize(callbacks)
  end

  def normalize(state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    normalize_realized_feedback_status =
      Keyword.fetch!(callbacks, :normalize_realized_feedback_status)

    state = stringify_keys.(state || %{})

    %{
      "snapshot_id" => Map.get(state, "snapshot_id", "unspecified"),
      "captured_at" => Map.get(state, "captured_at"),
      "remaining_horizon" => Map.get(state, "remaining_horizon"),
      "spacecraft_states" => Map.get(state, "spacecraft_states", []),
      "ground_network" => ground_network_entries(state, callbacks),
      "ground_stations" => Map.get(state, "ground_stations", []),
      "targets" => Map.get(state, "targets", []),
      "accepted_planning_state" => Map.get(state, "accepted_planning_state"),
      "candidate_refresh_defaults" => Map.get(state, "candidate_refresh_defaults", %{}),
      "source_station_calendar_report" => Map.get(state, "source_station_calendar_report"),
      "station_calendar_report" => Map.get(state, "station_calendar_report"),
      "source_station_calendar_precedence_summary" =>
        Map.get(state, "source_station_calendar_precedence_summary"),
      "station_calendar_precedence_summary" =>
        Map.get(state, "station_calendar_precedence_summary"),
      "source_station_reservation_report" => Map.get(state, "source_station_reservation_report"),
      "station_reservation_report" => Map.get(state, "station_reservation_report"),
      "source_station_reservation_review_summary" =>
        Map.get(state, "source_station_reservation_review_summary"),
      "station_reservation_review_summary" =>
        Map.get(state, "station_reservation_review_summary"),
      "source_station_reservation_hold_summary" =>
        Map.get(state, "source_station_reservation_hold_summary"),
      "station_reservation_hold_summary" => Map.get(state, "station_reservation_hold_summary"),
      "source_station_reservation_hold_import_readiness_summary" =>
        Map.get(state, "source_station_reservation_hold_import_readiness_summary"),
      "station_reservation_hold_import_readiness_summary" =>
        Map.get(state, "station_reservation_hold_import_readiness_summary"),
      "source_planned_activity" => Map.get(state, "source_planned_activity"),
      "planned_activity" => Map.get(state, "planned_activity"),
      "source_planned_activities" => Map.get(state, "source_planned_activities"),
      "planned_activities" => Map.get(state, "planned_activities"),
      "source_proposed_contact" => Map.get(state, "source_proposed_contact"),
      "proposed_contact" => Map.get(state, "proposed_contact"),
      "source_proposed_contacts" => Map.get(state, "source_proposed_contacts"),
      "proposed_contacts" => Map.get(state, "proposed_contacts"),
      "resources" => Map.get(state, "resources", %{}),
      "resource_summaries" => Map.get(state, "resource_summaries", []),
      "degradations" => Map.get(state, "degradations", []),
      "realized_activities" =>
        state
        |> Map.get("realized_activities", get_in(state, ["realized_state", "activities"]) || [])
        |> Enum.map(normalize_realized_feedback_status),
      "source_realized_activity" => Map.get(state, "source_realized_activity"),
      "realized_activity" => Map.get(state, "realized_activity"),
      "source_realized_activities" => Map.get(state, "source_realized_activities"),
      "source_realized_state_snapshot" => Map.get(state, "source_realized_state_snapshot"),
      "realized_state_snapshot" => Map.get(state, "realized_state_snapshot"),
      "source_realized_state" => Map.get(state, "source_realized_state"),
      "objectives" =>
        state
        |> Map.get("objectives", [])
        |> Enum.map(&normalize_objective(&1, callbacks)),
      "source_timeline_feedback_report" => Map.get(state, "source_timeline_feedback_report"),
      "timeline_feedback_report" => Map.get(state, "timeline_feedback_report"),
      "source_operational_timeline_report" =>
        Map.get(state, "source_operational_timeline_report"),
      "operational_timeline_report" => Map.get(state, "operational_timeline_report"),
      "source_command_window_report" => Map.get(state, "source_command_window_report"),
      "command_window_report" => Map.get(state, "command_window_report"),
      "source_maneuver_review_report" => Map.get(state, "source_maneuver_review_report"),
      "maneuver_review_report" => Map.get(state, "maneuver_review_report"),
      "source_resource_projection_report" => Map.get(state, "source_resource_projection_report"),
      "resource_projection_report" => Map.get(state, "resource_projection_report"),
      "source_resource_projection_flow_summary" =>
        Map.get(state, "source_resource_projection_flow_summary"),
      "resource_projection_flow_summary" => Map.get(state, "resource_projection_flow_summary"),
      "source_resource_filter_report" => Map.get(state, "source_resource_filter_report"),
      "resource_filter_report" => Map.get(state, "resource_filter_report"),
      "source_resource_filter_summary" => Map.get(state, "source_resource_filter_summary"),
      "resource_filter_summary" => Map.get(state, "resource_filter_summary"),
      "source_contact_filter_report" => Map.get(state, "source_contact_filter_report"),
      "contact_filter_report" => Map.get(state, "contact_filter_report"),
      "source_contact_allocation_report" => Map.get(state, "source_contact_allocation_report"),
      "contact_allocation_report" => Map.get(state, "contact_allocation_report"),
      "source_contact_allocation_summary" => Map.get(state, "source_contact_allocation_summary"),
      "contact_allocation_summary" => Map.get(state, "contact_allocation_summary"),
      "source_contact_allocation_station_pressure_summary" =>
        Map.get(state, "source_contact_allocation_station_pressure_summary"),
      "contact_allocation_station_pressure_summary" =>
        Map.get(state, "contact_allocation_station_pressure_summary"),
      "source_contact_allocation_reservation_conflict_summary" =>
        Map.get(state, "source_contact_allocation_reservation_conflict_summary"),
      "contact_allocation_reservation_conflict_summary" =>
        Map.get(state, "contact_allocation_reservation_conflict_summary"),
      "source_contact_allocation_capacity_pack_summary" =>
        Map.get(state, "source_contact_allocation_capacity_pack_summary"),
      "contact_allocation_capacity_pack_summary" =>
        Map.get(state, "contact_allocation_capacity_pack_summary"),
      "source_contact_allocation_provider_reservation_request_summary" =>
        Map.get(state, "source_contact_allocation_provider_reservation_request_summary"),
      "contact_allocation_provider_reservation_request_summary" =>
        Map.get(state, "contact_allocation_provider_reservation_request_summary"),
      "source_contact_contention_report" => Map.get(state, "source_contact_contention_report"),
      "contact_contention_report" => Map.get(state, "contact_contention_report"),
      "source_contact_contention_resolution_report" =>
        Map.get(state, "source_contact_contention_resolution_report"),
      "contact_contention_resolution_report" =>
        Map.get(state, "contact_contention_resolution_report"),
      "source_contact_contention_resolution_summary" =>
        Map.get(state, "source_contact_contention_resolution_summary"),
      "contact_contention_resolution_summary" =>
        Map.get(state, "contact_contention_resolution_summary"),
      "source_contact_intent" => Map.get(state, "source_contact_intent"),
      "contact_intent" => Map.get(state, "contact_intent"),
      "source_contact_intents" => Map.get(state, "source_contact_intents"),
      "contact_intents" => Map.get(state, "contact_intents"),
      "source_contact_intent_summary" => Map.get(state, "source_contact_intent_summary"),
      "contact_intent_summary" => Map.get(state, "contact_intent_summary"),
      "source_candidate_diff_report" => Map.get(state, "source_candidate_diff_report"),
      "candidate_diff_report" => Map.get(state, "candidate_diff_report"),
      "source_candidate_rejection_report" => Map.get(state, "source_candidate_rejection_report"),
      "candidate_rejection_report" => Map.get(state, "candidate_rejection_report"),
      "source_provider_counteroffer_report" =>
        Map.get(state, "source_provider_counteroffer_report"),
      "provider_counteroffer_report" => Map.get(state, "provider_counteroffer_report"),
      "source_provider_counteroffer_import_readiness_summary" =>
        Map.get(state, "source_provider_counteroffer_import_readiness_summary"),
      "provider_counteroffer_import_readiness_summary" =>
        Map.get(state, "provider_counteroffer_import_readiness_summary"),
      "source_provider_counteroffer_plan_impact_summary" =>
        Map.get(state, "source_provider_counteroffer_plan_impact_summary"),
      "provider_counteroffer_plan_impact_summary" =>
        Map.get(state, "provider_counteroffer_plan_impact_summary"),
      "source_schema_validation_report" => Map.get(state, "source_schema_validation_report"),
      "schema_validation_report" => Map.get(state, "schema_validation_report"),
      "source_schema_validation_batch_report" =>
        Map.get(state, "source_schema_validation_batch_report"),
      "schema_validation_batch_report" => Map.get(state, "schema_validation_batch_report"),
      "source_operational_readiness_report" =>
        Map.get(state, "source_operational_readiness_report"),
      "operational_readiness_report" => Map.get(state, "operational_readiness_report"),
      "source_operational_readiness_gate_summary" =>
        Map.get(state, "source_operational_readiness_gate_summary"),
      "operational_readiness_gate_summary" =>
        Map.get(state, "operational_readiness_gate_summary"),
      "source_quality_gate_report" => Map.get(state, "source_quality_gate_report"),
      "quality_gate_report" => Map.get(state, "quality_gate_report"),
      "source_operational_quality_gate_summary" =>
        Map.get(state, "source_operational_quality_gate_summary"),
      "operational_quality_gate_summary" => Map.get(state, "operational_quality_gate_summary"),
      "source_operational_quality_gate_unavailable_resource_summary" =>
        Map.get(state, "source_operational_quality_gate_unavailable_resource_summary"),
      "operational_quality_gate_unavailable_resource_summary" =>
        Map.get(state, "operational_quality_gate_unavailable_resource_summary"),
      "source_operational_quality_gate_operator_training_summary" =>
        Map.get(state, "source_operational_quality_gate_operator_training_summary"),
      "operational_quality_gate_operator_training_summary" =>
        Map.get(state, "operational_quality_gate_operator_training_summary"),
      "source_operational_quality_gate_schema_validation_summary" =>
        Map.get(state, "source_operational_quality_gate_schema_validation_summary"),
      "operational_quality_gate_schema_validation_summary" =>
        Map.get(state, "operational_quality_gate_schema_validation_summary"),
      "source_operational_quality_gate_import_readiness_summary" =>
        Map.get(state, "source_operational_quality_gate_import_readiness_summary"),
      "operational_quality_gate_import_readiness_summary" =>
        Map.get(state, "operational_quality_gate_import_readiness_summary"),
      "source_model_acceptance_report" => Map.get(state, "source_model_acceptance_report"),
      "model_acceptance_report" => Map.get(state, "model_acceptance_report"),
      "source_validation_safety_case_summary" =>
        Map.get(state, "source_validation_safety_case_summary"),
      "validation_safety_case_summary" => Map.get(state, "validation_safety_case_summary"),
      "source_freshness_report" => Map.get(state, "source_freshness_report"),
      "freshness_report" => Map.get(state, "freshness_report"),
      "source_refresh_budget_report" => Map.get(state, "source_refresh_budget_report"),
      "refresh_budget_report" => Map.get(state, "refresh_budget_report"),
      "source_timeline_diff_report" => Map.get(state, "source_timeline_diff_report"),
      "timeline_diff_report" => Map.get(state, "timeline_diff_report"),
      "source_timeline_diff_summary" => Map.get(state, "source_timeline_diff_summary"),
      "timeline_diff_summary" => Map.get(state, "timeline_diff_summary"),
      "source_timeline_integrity_report" => Map.get(state, "source_timeline_integrity_report"),
      "timeline_integrity_report" => Map.get(state, "timeline_integrity_report"),
      "source_timeline_dependency_impact_summary" =>
        Map.get(state, "source_timeline_dependency_impact_summary"),
      "timeline_dependency_impact_summary" =>
        Map.get(state, "timeline_dependency_impact_summary"),
      "source_timeline_transition_application_summary" =>
        Map.get(state, "source_timeline_transition_application_summary"),
      "timeline_transition_application_summary" =>
        Map.get(state, "timeline_transition_application_summary"),
      "source_timeline_activity_state" => Map.get(state, "source_timeline_activity_state"),
      "timeline_activity_state" => Map.get(state, "timeline_activity_state"),
      "source_timeline_activity_status_state" =>
        Map.get(state, "source_timeline_activity_status_state"),
      "timeline_activity_status_state" => Map.get(state, "timeline_activity_status_state"),
      "source_timeline_activity_approval_state" =>
        Map.get(state, "source_timeline_activity_approval_state"),
      "timeline_activity_approval_state" => Map.get(state, "timeline_activity_approval_state"),
      "source_timeline_activity_precondition_summary" =>
        Map.get(state, "source_timeline_activity_precondition_summary"),
      "timeline_activity_precondition_summary" =>
        Map.get(state, "timeline_activity_precondition_summary"),
      "source_timeline_preservation_report" =>
        Map.get(state, "source_timeline_preservation_report"),
      "timeline_preservation_report" => Map.get(state, "timeline_preservation_report"),
      "source_timeline_preservation_status" =>
        Map.get(state, "source_timeline_preservation_status"),
      "timeline_preservation_status" => Map.get(state, "timeline_preservation_status"),
      "source_timeline_lifecycle_state_summary" =>
        Map.get(state, "source_timeline_lifecycle_state_summary"),
      "timeline_lifecycle_state_summary" => Map.get(state, "timeline_lifecycle_state_summary"),
      "source_timeline_activity_lifecycle_state" =>
        Map.get(state, "source_timeline_activity_lifecycle_state"),
      "timeline_activity_lifecycle_state" => Map.get(state, "timeline_activity_lifecycle_state"),
      "source_timeline_transition_application_report" =>
        Map.get(state, "source_timeline_transition_application_report"),
      "timeline_transition_application_report" =>
        Map.get(state, "timeline_transition_application_report"),
      "source_constraint_report" => Map.get(state, "source_constraint_report"),
      "constraint_report" => Map.get(state, "constraint_report"),
      "source_objective_satisfaction_report" =>
        Map.get(state, "source_objective_satisfaction_report"),
      "objective_satisfaction_report" => Map.get(state, "objective_satisfaction_report"),
      "source_objective_tradeoff_report" => Map.get(state, "source_objective_tradeoff_report"),
      "objective_tradeoff_report" => Map.get(state, "objective_tradeoff_report"),
      "source_score_term_report" => Map.get(state, "source_score_term_report"),
      "score_term_report" => Map.get(state, "score_term_report"),
      "source_link_capacity_report" => Map.get(state, "source_link_capacity_report"),
      "link_capacity_report" => Map.get(state, "link_capacity_report"),
      "source_link_capacity_summary" => Map.get(state, "source_link_capacity_summary"),
      "link_capacity_summary" => Map.get(state, "link_capacity_summary"),
      "source_relay_data_path_summary" => Map.get(state, "source_relay_data_path_summary"),
      "relay_data_path_summary" => Map.get(state, "relay_data_path_summary"),
      "source_operator_review_package" => Map.get(state, "source_operator_review_package"),
      "operator_review_package" => Map.get(state, "operator_review_package"),
      "source_cadence_import_manifest" => Map.get(state, "source_cadence_import_manifest"),
      "cadence_import_manifest" => Map.get(state, "cadence_import_manifest"),
      "source_result_artifact" => Map.get(state, "source_result_artifact"),
      "result_artifact" => Map.get(state, "result_artifact"),
      "operational_feedback" => Map.get(state, "operational_feedback", %{}),
      "prior_plan_history" => Map.get(state, "prior_plan_history", []),
      "operational_status" => Map.get(state, "operational_status", %{}),
      "assumptions" => Map.get(state, "assumptions", %{})
    }
  end

  def availability_token(value), do: availability_token(value, callbacks())

  def availability_token(value, _callbacks) when is_number(value) do
    if value < 1.0, do: "reduced_capacity", else: "available"
  end

  def availability_token(value, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    case encode_value.(value) do
      value when is_binary(value) ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> canonical_station_availability_token()

      value ->
        value
    end
  end

  defp ground_network_entries(state, callbacks) do
    normalize_ground_network(
      Map.get(state, "ground_network"),
      "mission_state.ground_network",
      callbacks
    ) ++
      normalize_ground_network(
        Map.get(state, "station_calendar"),
        "mission_state.station_calendar",
        callbacks
      ) ++
      normalize_ground_network(
        Map.get(state, "station_calendar_provider"),
        "mission_state.station_calendar_provider",
        callbacks
      )
  end

  defp normalize_ground_network(nil, _source, _callbacks), do: []

  defp normalize_ground_network(
         station_calendar_providers,
         "mission_state.station_calendar_provider",
         _callbacks
       )
       when is_list(station_calendar_providers) do
    station_calendar_providers
    |> Enum.flat_map(fn
      %{} = provider ->
        StationCalendar.to_ground_network(provider)

      _provider ->
        []
    end)
    |> Enum.map(&put_source_path(&1, "mission_state.station_calendar_provider"))
  end

  defp normalize_ground_network(ground_network, source, callbacks)
       when is_list(ground_network) do
    Enum.map(ground_network, fn entry ->
      entry
      |> normalize_ground_network_entry(callbacks)
      |> put_source_path(source)
    end)
  end

  defp normalize_ground_network(%{} = station_calendar_provider, _source, _callbacks) do
    station_calendar_provider
    |> StationCalendar.to_ground_network()
    |> Enum.map(&put_source_path(&1, "mission_state.station_calendar_provider"))
  end

  defp normalize_ground_network(_ground_network, source, _callbacks) do
    raise ArgumentError, "#{source} must be a list or station calendar provider object"
  end

  defp normalize_objective(objective, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    objective = stringify_keys.(objective)

    objective_type =
      objective["type"] || objective["objective_type"] || objective["objective"]

    case normalized_objective_type(objective_type, callbacks) do
      value when value in [nil, ""] ->
        objective

      value ->
        Map.put(objective, "type", value)
    end
  end

  defp normalized_objective_type(value, callbacks) do
    objective_pressure_label = Keyword.fetch!(callbacks, :objective_pressure_label)

    value
    |> objective_pressure_label.()
    |> canonical_objective_type()
  end

  defp canonical_objective_type(value) do
    CollectionLatencyObjectiveType.canonical(value) || canonical_non_latency_objective_type(value)
  end

  defp canonical_non_latency_objective_type("target_commitment"), do: "target_observation"

  defp canonical_non_latency_objective_type("required_downlink_completion"),
    do: "downlink_completion"

  defp canonical_non_latency_objective_type(value), do: value

  defp normalize_ground_network_entry(entry, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    entry
    |> stringify_keys.()
    |> normalize_station_availability_field("availability", callbacks)
    |> normalize_station_availability_field("status", callbacks)
    |> normalize_station_availability_field("station_contention_status", callbacks)
  end

  defp put_source_path(entry, source) do
    Map.put_new(entry, "mission_state_source_path", source)
  end

  defp normalize_station_availability_field(entry, field, callbacks) do
    case Map.get(entry, field) do
      value when value in [nil, ""] or is_number(value) ->
        entry

      value ->
        Map.put(entry, field, availability_token(value, callbacks))
    end
  end

  defp canonical_station_availability_token(value) when value in ["outage", "offline", "down"],
    do: "unavailable"

  defp canonical_station_availability_token(value), do: value

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      normalize_realized_feedback_status: &RepairRealizedState.normalize_feedback_status/1,
      objective_pressure_label: &ObjectivePressureRows.label/1,
      encode_value: &ValueEncoding.encode_value/1
    ]
  end
end
