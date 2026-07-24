defmodule OrbitalDynamics.CampaignPlanner.RecommendationRiskDriver do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{risk_indicators: risk_indicators}, context_fun)
      when is_function(context_fun, 1) do
    Enum.map(risk_indicators, fn risk ->
      risk
      |> base_row()
      |> Map.merge(context_fun.(risk))
      |> compact_map()
    end)
  end

  def rows(_branch, _context_fun), do: []

  defp base_row(risk) do
    %{
      "type" => "risk_driver",
      "risk_type" => risk["type"],
      "severity" => risk["severity"],
      "reason" => risk["reason"],
      "value" => risk["value"],
      "activity_id" => risk["activity_id"],
      "ground_station_id" => risk["ground_station_id"],
      "scenario_id" => risk["scenario_id"],
      "spacecraft_id" => risk["spacecraft_id"],
      "target_id" => risk["target_id"],
      "collection_id" => risk["collection_id"],
      "collection_ids" => risk["collection_ids"],
      "product_id" => risk["product_id"],
      "product_ids" => risk["product_ids"],
      "payload_id" => risk["payload_id"],
      "payload_ids" => risk["payload_ids"],
      "instrument_id" => risk["instrument_id"],
      "instrument_ids" => risk["instrument_ids"],
      "objective_id" => risk["objective_id"],
      "objective_type" => risk["objective_type"],
      "objective_status" => risk["objective_status"],
      "source_objective_status" => risk["source_objective_status"],
      "latency_objective" => risk["latency_objective"],
      "max_latency_s" => risk["max_latency_s"],
      "planned_latency_s" => risk["planned_latency_s"],
      "required_contacts" => risk["required_contacts"],
      "planned_contacts" => risk["planned_contacts"],
      "required_downlink_mb" => risk["required_downlink_mb"],
      "planned_downlink_mb" => risk["planned_downlink_mb"],
      "contact_result" => risk["contact_result"],
      "command_result" => risk["command_result"],
      "maneuver_result" => risk["maneuver_result"],
      "realized_status" => risk["realized_status"],
      "command_success_factor" => risk["command_success_factor"],
      "maneuver_success_factor" => risk["maneuver_success_factor"],
      "ground_station_match_status" => risk["ground_station_match_status"],
      "planned_ground_station_id" => risk["planned_ground_station_id"],
      "realized_ground_station_id" => risk["realized_ground_station_id"],
      "planned_direction" => risk["planned_direction"],
      "realized_direction" => risk["realized_direction"],
      "direction_match_status" => risk["direction_match_status"],
      "source_window_id" => risk["source_window_id"],
      "planned_source_window_id" => risk["planned_source_window_id"],
      "realized_source_window_id" => risk["realized_source_window_id"],
      "source_window_match_status" => risk["source_window_match_status"],
      "command_identity_mismatch_fields" => risk["command_identity_mismatch_fields"],
      "starts_at_s" => risk["starts_at_s"],
      "ends_at_s" => risk["ends_at_s"],
      "source_activity_id" => risk["source_activity_id"],
      "replacement_activity_id" => risk["replacement_activity_id"],
      "source_activity_ids" => risk["source_activity_ids"],
      "timeline_id" => risk["timeline_id"],
      "maneuver_id" => risk["maneuver_id"],
      "execution_uncertainty_status" => risk["execution_uncertainty_status"],
      "execution_uncertainty_source" => risk["execution_uncertainty_source"],
      "execution_uncertainty" => risk["execution_uncertainty"],
      "timing_3sigma_s" => risk["timing_3sigma_s"],
      "timing_3sigma_threshold_s" => risk["timing_3sigma_threshold_s"],
      "delta_v_3sigma_km_s" => risk["delta_v_3sigma_km_s"],
      "delta_v_3sigma_magnitude_km_s" => risk["delta_v_3sigma_magnitude_km_s"],
      "delta_v_3sigma_magnitude_threshold_km_s" =>
        risk["delta_v_3sigma_magnitude_threshold_km_s"],
      "timeline_integrity_status" => risk["timeline_integrity_status"],
      "timeline_integrity_issue_count" => risk["timeline_integrity_issue_count"],
      "timeline_integrity_issue_types" => risk["timeline_integrity_issue_types"],
      "timeline_integrity_issues" => risk["timeline_integrity_issues"],
      "missing_dependency_activity_ids" => risk["missing_dependency_activity_ids"],
      "missing_dependency_timeline_ids" => risk["missing_dependency_timeline_ids"],
      "dependency_cycle_activity_ids" => risk["dependency_cycle_activity_ids"],
      "dependency_cycle_timeline_ids" => risk["dependency_cycle_timeline_ids"],
      "dependency_order_violation_activity_ids" =>
        risk["dependency_order_violation_activity_ids"],
      "dependency_order_violation_timeline_ids" =>
        risk["dependency_order_violation_timeline_ids"],
      "exclusivity_violation_activity_ids" => risk["exclusivity_violation_activity_ids"],
      "exclusivity_violation_timeline_ids" => risk["exclusivity_violation_timeline_ids"],
      "exclusivity_violation_group" => risk["exclusivity_violation_group"],
      "missed_downlink_activity_id" => risk["missed_downlink_activity_id"],
      "missed_downlink_activity_ids" => risk["missed_downlink_activity_ids"],
      "changed_fields" => risk["changed_fields"],
      "required_operator_action" => risk["required_operator_action"],
      "requires_operator_review" => risk["requires_operator_review"],
      "status_transition" => risk["status_transition"],
      "transition_type" => risk["transition_type"],
      "transition_category" => risk["transition_category"],
      "transition_reason" => risk["transition_reason"],
      "feedback_source" => risk["feedback_source"],
      "feedback_scope" => risk["feedback_scope"],
      "feedback_key" => risk["feedback_key"],
      "trust_boundary" => risk["trust_boundary"],
      "derivation_reasons" => risk["derivation_reasons"],
      "direction" => risk["direction"],
      "station_calendar_entry_id" => risk["station_calendar_entry_id"],
      "station_calendar_entry_status" => risk["station_calendar_entry_status"],
      "station_calendar_provider_id" => risk["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => risk["station_calendar_provider_entry_id"],
      "station_calendar_directions" => risk["station_calendar_directions"],
      "first_resource_pressure_activity_id" => risk["first_resource_pressure_activity_id"],
      "first_resource_pressure_activity_type" => risk["first_resource_pressure_activity_type"],
      "first_resource_pressure_kind" => risk["first_resource_pressure_kind"],
      "first_resource_pressure_starts_at_s" => risk["first_resource_pressure_starts_at_s"],
      "first_resource_pressure_direction" => risk["first_resource_pressure_direction"],
      "first_resource_pressure_ground_station_id" =>
        risk["first_resource_pressure_ground_station_id"],
      "first_resource_pressure_station_calendar_entry_id" =>
        risk["first_resource_pressure_station_calendar_entry_id"],
      "first_resource_pressure_station_calendar_provider_id" =>
        risk["first_resource_pressure_station_calendar_provider_id"],
      "first_resource_pressure_station_calendar_provider_entry_id" =>
        risk["first_resource_pressure_station_calendar_provider_entry_id"],
      "first_resource_pressure_station_calendar_directions" =>
        risk["first_resource_pressure_station_calendar_directions"],
      "resource_pressure_status" => risk["resource_pressure_status"],
      "resource_pressure_types" => risk["resource_pressure_types"]
    }
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
