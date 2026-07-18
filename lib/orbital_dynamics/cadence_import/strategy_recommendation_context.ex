defmodule OrbitalDynamics.CadenceImport.StrategyRecommendationContext do
  @moduledoc false

  def resource_pressure(%{"explanation" => explanation}, callbacks)
      when is_list(explanation) and is_list(callbacks) do
    rows =
      explanation
      |> Enum.map(&stringify_keys(callbacks, &1))
      |> Enum.filter(&(&1["type"] == "resource_pressure"))

    %{
      "activity_ids" =>
        risk_context_values(rows, ["activity_id", "first_resource_pressure_activity_id"]),
      "scenario_ids" => risk_context_values(rows, "scenario_id"),
      "ground_station_ids" =>
        risk_context_values(rows, [
          "ground_station_id",
          "first_resource_pressure_ground_station_id"
        ]),
      "spacecraft_ids" => risk_context_values(rows, "spacecraft_id"),
      "directions" =>
        risk_context_values(rows, ["direction", "first_resource_pressure_direction"]),
      "station_calendar_entry_ids" =>
        risk_context_values(rows, [
          "station_calendar_entry_id",
          "first_resource_pressure_station_calendar_entry_id"
        ]),
      "station_calendar_provider_ids" =>
        risk_context_values(rows, [
          "station_calendar_provider_id",
          "first_resource_pressure_station_calendar_provider_id"
        ]),
      "station_calendar_provider_entry_ids" =>
        risk_context_values(rows, [
          "station_calendar_provider_entry_id",
          "first_resource_pressure_station_calendar_provider_entry_id"
        ]),
      "station_calendar_directions" =>
        risk_context_values(rows, [
          "station_calendar_directions",
          "first_resource_pressure_station_calendar_directions"
        ]),
      "source_window_ids" =>
        risk_context_values(rows, [
          "source_window_id",
          "first_resource_pressure_source_window_id"
        ]),
      "source_window_types" =>
        risk_context_values(rows, [
          "source_window_type",
          "first_resource_pressure_source_window_type"
        ]),
      "resource_pressure_statuses" => risk_context_values(rows, "resource_pressure_status"),
      "resource_pressure_types" => risk_context_values(rows, ["resource_pressure_types"]),
      "first_resource_pressure_kinds" =>
        risk_context_values(rows, ["pressure_kind", "first_resource_pressure_kind"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def resource_pressure(_recommendation, callbacks) when is_list(callbacks), do: %{}

  def readiness_quality_gate(%{"explanation" => explanation}, callbacks)
      when is_list(explanation) and is_list(callbacks) do
    rows = Enum.map(explanation, &stringify_keys(callbacks, &1))

    readiness_rows =
      Enum.filter(rows, &(&1["type"] == "operational_readiness_pressure"))

    quality_gate_rows =
      Enum.filter(rows, &(&1["type"] == "quality_gate_pressure"))

    %{
      "operational_readiness_report_ids" => risk_context_values(readiness_rows, "report_id"),
      "operational_readiness_source_artifact_types" =>
        risk_context_values(readiness_rows, "source_artifact_type"),
      "operational_readiness_source_artifact_ids" =>
        risk_context_values(readiness_rows, "source_artifact_id"),
      "operational_readiness_levels" => risk_context_values(readiness_rows, "readiness_level"),
      "operational_readiness_import_classifications" =>
        risk_context_values(readiness_rows, "import_classification"),
      "operational_readiness_statuses" =>
        risk_context_values(readiness_rows, "operational_readiness_status"),
      "operational_readiness_gate_ids" =>
        risk_context_values(readiness_rows, "readiness_gate_id"),
      "operational_readiness_gate_statuses" =>
        risk_context_values(readiness_rows, "readiness_gate_status"),
      "operational_readiness_gate_classifications" =>
        risk_context_values(readiness_rows, "readiness_gate_classification"),
      "operational_readiness_required_operator_actions" =>
        risk_context_values(readiness_rows, "required_operator_action"),
      "operational_readiness_feedback_sources" =>
        risk_context_values(readiness_rows, "feedback_source"),
      "operational_readiness_feedback_scopes" =>
        risk_context_values(readiness_rows, "feedback_scope"),
      "operational_readiness_feedback_keys" =>
        risk_context_values(readiness_rows, "feedback_key"),
      "operational_readiness_trust_boundaries" =>
        risk_context_values(readiness_rows, "trust_boundary"),
      "quality_gate_report_ids" => risk_context_values(quality_gate_rows, "report_id"),
      "quality_gate_source_artifact_types" =>
        risk_context_values(quality_gate_rows, "source_artifact_type"),
      "quality_gate_source_artifact_ids" =>
        risk_context_values(quality_gate_rows, "source_artifact_id"),
      "quality_gate_source_readiness_report_ids" =>
        risk_context_values(quality_gate_rows, "source_readiness_report_id"),
      "quality_gate_readiness_levels" =>
        risk_context_values(quality_gate_rows, "readiness_level"),
      "quality_gate_import_classifications" =>
        risk_context_values(quality_gate_rows, "import_classification"),
      "quality_gate_pressure_statuses" =>
        risk_context_values(quality_gate_rows, "quality_gate_status"),
      "quality_gate_ids" => risk_context_values(quality_gate_rows, "gate_id"),
      "quality_gate_statuses" => risk_context_values(quality_gate_rows, "gate_status"),
      "quality_gate_classifications" =>
        risk_context_values(quality_gate_rows, "gate_classification"),
      "quality_gate_required_operator_actions" =>
        risk_context_values(quality_gate_rows, "required_operator_action"),
      "quality_gate_feedback_sources" =>
        risk_context_values(quality_gate_rows, "feedback_source"),
      "quality_gate_feedback_scopes" => risk_context_values(quality_gate_rows, "feedback_scope"),
      "quality_gate_feedback_keys" => risk_context_values(quality_gate_rows, "feedback_key"),
      "quality_gate_trust_boundaries" => risk_context_values(quality_gate_rows, "trust_boundary"),
      "quality_gate_resource_availability_reason_ids" =>
        risk_context_values(quality_gate_rows, ["resource_availability_reason_ids"]),
      "quality_gate_unavailable_resource_reason_ids" =>
        risk_context_values(quality_gate_rows, ["unavailable_resource_reason_ids"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def readiness_quality_gate(_recommendation, callbacks) when is_list(callbacks), do: %{}

  def risk(%{"risks_remaining" => risks} = recommendation, callbacks)
      when is_list(risks) and is_list(callbacks) do
    risks = Enum.map(risks, &stringify_keys(callbacks, &1))
    resource_margin_rows = strategy_recommendation_resource_margin_rows(recommendation, callbacks)
    resource_margin_context_rows = risks ++ resource_margin_rows

    candidate_rejection_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "candidate_rejection" or
            Map.get(&1, "type") == "candidate_rejection_pressure")
      )

    provider_counteroffer_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "provider_counteroffer" or
            Map.get(&1, "type") == "provider_counteroffer_review" or
            Map.has_key?(&1, "provider_counteroffer_id"))
      )

    %{
      "risk_types" => risk_context_values(risks, "type"),
      "activity_ids" =>
        risk_context_values(risks, ["activity_id", "first_resource_pressure_activity_id"]),
      "scenario_ids" => risk_context_values(risks, "scenario_id"),
      "ground_station_ids" =>
        risk_context_values(risks, [
          "ground_station_id",
          "first_resource_pressure_ground_station_id"
        ]),
      "spacecraft_ids" => risk_context_values(risks, "spacecraft_id"),
      "target_ids" => risk_context_values(risks, "target_id"),
      "collection_ids" => risk_context_values(risks, "collection_id"),
      "product_ids" => risk_context_values(risks, ["product_id", "product_ids"]),
      "payload_ids" => risk_context_values(risks, "payload_id"),
      "instrument_ids" => risk_context_values(risks, "instrument_id"),
      "objective_ids" => risk_context_values(risks, "objective_id"),
      "objective_types" => risk_context_values(risks, "objective_type"),
      "feedback_sources" => risk_context_values(risks, "feedback_source"),
      "feedback_scopes" => risk_context_values(risks, "feedback_scope"),
      "source_activity_ids" =>
        risk_context_values(risks, ["source_activity_id", "source_activity_ids"]),
      "timeline_ids" => risk_context_values(risks, "timeline_id"),
      "maneuver_ids" => risk_context_values(risks, "maneuver_id"),
      "maneuver_execution_uncertainty_statuses" =>
        risk_context_values(risks, "execution_uncertainty_status"),
      "maneuver_execution_uncertainty_sources" =>
        risk_context_values(risks, "execution_uncertainty_source"),
      "maneuver_execution_uncertainty_timing_3sigma_s" =>
        risk_context_values(risks, "timing_3sigma_s"),
      "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_km_s" =>
        risk_context_values(risks, "delta_v_3sigma_magnitude_km_s"),
      "missing_dependency_activity_ids" =>
        risk_context_values(risks, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" =>
        risk_context_values(risks, "missing_dependency_timeline_ids"),
      "dependency_cycle_activity_ids" =>
        risk_context_values(risks, "dependency_cycle_activity_ids"),
      "dependency_cycle_timeline_ids" =>
        risk_context_values(risks, "dependency_cycle_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        risk_context_values(risks, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        risk_context_values(risks, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        risk_context_values(risks, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        risk_context_values(risks, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_groups" => risk_context_values(risks, "exclusivity_violation_group"),
      "missed_downlink_activity_ids" =>
        risk_context_values(risks, [
          "missed_downlink_activity_id",
          "missed_downlink_activity_ids"
        ]),
      "directions" =>
        risk_context_values(risks, ["direction", "first_resource_pressure_direction"]),
      "station_calendar_entry_ids" =>
        risk_context_values(risks, [
          "station_calendar_entry_id",
          "first_resource_pressure_station_calendar_entry_id"
        ]),
      "station_calendar_provider_ids" =>
        risk_context_values(risks, [
          "station_calendar_provider_id",
          "first_resource_pressure_station_calendar_provider_id"
        ]),
      "station_calendar_provider_entry_ids" =>
        risk_context_values(risks, [
          "station_calendar_provider_entry_id",
          "first_resource_pressure_station_calendar_provider_entry_id"
        ]),
      "station_calendar_directions" =>
        risk_context_values(risks, [
          "station_calendar_directions",
          "first_resource_pressure_station_calendar_directions"
        ]),
      "source_window_ids" =>
        risk_context_values(risks, [
          "source_window_id",
          "first_resource_pressure_source_window_id"
        ]),
      "source_window_types" =>
        risk_context_values(risks, [
          "source_window_type",
          "first_resource_pressure_source_window_type"
        ]),
      "resource_pressure_statuses" => risk_context_values(risks, "resource_pressure_status"),
      "resource_pressure_types" => risk_context_values(risks, ["resource_pressure_types"]),
      "first_resource_pressure_kinds" =>
        risk_context_values(risks, "first_resource_pressure_kind"),
      "candidate_rejection_candidate_ids" =>
        risk_context_values(candidate_rejection_risks, "candidate_id"),
      "candidate_rejection_activity_ids" =>
        risk_context_values(candidate_rejection_risks, "activity_id"),
      "candidate_rejection_activity_types" =>
        risk_context_values(candidate_rejection_risks, "activity_type"),
      "candidate_rejection_scenario_ids" =>
        risk_context_values(candidate_rejection_risks, "scenario_id"),
      "candidate_rejection_ground_station_ids" =>
        risk_context_values(candidate_rejection_risks, "ground_station_id"),
      "candidate_rejection_source_window_ids" =>
        risk_context_values(candidate_rejection_risks, "source_window_id"),
      "candidate_rejection_source_window_types" =>
        risk_context_values(candidate_rejection_risks, "source_window_type"),
      "candidate_rejection_statuses" =>
        risk_context_values(candidate_rejection_risks, "rejection_status"),
      "candidate_rejection_primary_reasons" =>
        risk_context_values(candidate_rejection_risks, "primary_rejection_reason"),
      "candidate_rejection_reason_ids" =>
        risk_context_values(candidate_rejection_risks, ["rejection_reasons"]),
      "candidate_rejection_violated_constraints" =>
        risk_context_values(candidate_rejection_risks, "violated_constraint"),
      "candidate_rejection_required_margin_values" =>
        risk_context_values(candidate_rejection_risks, "required_margin"),
      "candidate_rejection_actual_margin_values" =>
        risk_context_values(candidate_rejection_risks, "actual_margin"),
      "candidate_rejection_required_operator_actions" =>
        risk_context_values(candidate_rejection_risks, "required_operator_action"),
      "candidate_rejection_feedback_sources" =>
        risk_context_values(candidate_rejection_risks, "feedback_source"),
      "candidate_rejection_feedback_scopes" =>
        risk_context_values(candidate_rejection_risks, "feedback_scope"),
      "candidate_rejection_feedback_keys" =>
        risk_context_values(candidate_rejection_risks, "feedback_key"),
      "candidate_rejection_trust_boundaries" =>
        risk_context_values(candidate_rejection_risks, "trust_boundary"),
      "provider_counteroffer_ids" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_id"),
      "provider_counteroffer_statuses" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_status"),
      "provider_counteroffer_negotiation_states" =>
        risk_context_values(
          provider_counteroffer_risks,
          "provider_counteroffer_negotiation_state"
        ),
      "provider_counteroffer_reason_codes" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_reason_code"),
      "provider_counteroffer_cost_deltas" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_cost_delta"),
      "provider_counteroffer_lock_deadline_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_lock_deadline_s"),
      "provider_counteroffer_starts_at_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_starts_at_s"),
      "provider_counteroffer_ends_at_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_ends_at_s"),
      "provider_counteroffer_start_delta_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_start_delta_s"),
      "provider_counteroffer_end_delta_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_end_delta_s"),
      "provider_counteroffer_duration_delta_values_s" =>
        risk_context_values(provider_counteroffer_risks, "provider_counteroffer_duration_delta_s"),
      "provider_counteroffer_plan_impact_statuses" =>
        risk_context_values(provider_counteroffer_risks, "plan_impact_status"),
      "provider_counteroffer_affected_station_calendar_entry_ids" =>
        risk_context_values(provider_counteroffer_risks, ["affected_station_calendar_entry_ids"]),
      "provider_counteroffer_affected_provider_entry_ids" =>
        risk_context_values(provider_counteroffer_risks, ["affected_provider_entry_ids"]),
      "provider_counteroffer_impact_counteroffer_ids" =>
        risk_context_values(provider_counteroffer_risks, ["impact_counteroffer_ids"]),
      "provider_counteroffer_required_operator_actions" =>
        risk_context_values(provider_counteroffer_risks, "required_operator_action"),
      "provider_counteroffer_feedback_sources" =>
        risk_context_values(provider_counteroffer_risks, "feedback_source"),
      "provider_counteroffer_feedback_scopes" =>
        risk_context_values(provider_counteroffer_risks, "feedback_scope"),
      "provider_counteroffer_feedback_keys" =>
        risk_context_values(provider_counteroffer_risks, "feedback_key"),
      "provider_counteroffer_trust_boundaries" =>
        risk_context_values(provider_counteroffer_risks, "trust_boundary")
    }
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.validation_refresh_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.approval_boundary_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.provider_reservation_request_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.capacity_pack_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.contact_contention_resolution_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_contention_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.station_reservation_conflict_context(risks)
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.station_reservation_hold_import_readiness_context(
        risks
      )
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.relay_data_path_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.link_capacity_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_intent_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_allocation_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.contact_filter_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.resource_filter_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.resource_projection_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.station_calendar_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.score_term_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.objective_satisfaction_context(risks))
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.objective_tradeoff_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.resource_margin_context(
        resource_margin_context_rows
      )
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.maneuver_execution_uncertainty_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.timeline_integrity_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.execution_success_feedback_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.operational_feedback_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_activity_precondition_context(risks)
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_activity_lifecycle_state_context(risks)
    )
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_dependency_impact_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.timeline_publication_context(risks))
    |> Map.merge(
      OrbitalDynamics.RecommendationRiskContext.timeline_lifecycle_state_context(risks)
    )
    |> Map.merge(OrbitalDynamics.RecommendationRiskContext.timeline_preservation_context(risks))
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def risk(_recommendation, callbacks) when is_list(callbacks), do: %{}

  defp strategy_recommendation_resource_margin_rows(%{"explanation" => explanation}, callbacks)
       when is_list(explanation) and is_list(callbacks) do
    explanation
    |> Enum.map(&stringify_keys(callbacks, &1))
    |> Enum.filter(&(&1["type"] == "resource_margin_pressure"))
  end

  defp strategy_recommendation_resource_margin_rows(_recommendation, callbacks)
       when is_list(callbacks),
       do: []

  def merge(row, context) when is_map(context) do
    Enum.reduce(context, row, fn
      {key, values}, acc when is_list(values) ->
        merged =
          acc
          |> Map.get(key, [])
          |> List.wrap()
          |> Kernel.++(values)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()

        if merged == [] do
          acc
        else
          Map.put(acc, key, merged)
        end

      {_key, nil}, acc ->
        acc

      {key, value}, acc ->
        Map.put(acc, key, value)
    end)
  end

  def merge(row, _context), do: row

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(callbacks, value),
    do: apply(Keyword.fetch!(callbacks, :stringify_keys), [value])
end
