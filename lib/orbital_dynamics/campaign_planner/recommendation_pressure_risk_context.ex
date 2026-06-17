defmodule OrbitalDynamics.CampaignPlanner.RecommendationPressureRiskContext do
  @moduledoc false

  def context(%{"type" => "operational_readiness_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :operational_readiness)
  end

  def context(%{"type" => "quality_gate_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :quality_gate)
  end

  def context(%{"feedback_scope" => "approval_boundary"} = risk, fields_fun) do
    take(risk, fields_fun, :approval_boundary)
  end

  def context(%{"type" => "approval_boundary_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :approval_boundary)
  end

  def context(
        %{"feedback_scope" => "contact_allocation_provider_reservation_request"} = risk,
        fields_fun
      ) do
    take(risk, fields_fun, :provider_reservation_request)
  end

  def context(%{"type" => "provider_reservation_request_review"} = risk, fields_fun) do
    take(risk, fields_fun, :provider_reservation_request)
  end

  def context(%{"feedback_scope" => "contact_contention_resolution"} = risk, fields_fun) do
    take(risk, fields_fun, :capacity_pack)
  end

  def context(%{"capacity_pack_group_id" => _group_id} = risk, fields_fun) do
    take(risk, fields_fun, :capacity_pack)
  end

  def context(%{"station_reservation_hold_import_status" => _status} = risk, fields_fun) do
    take(risk, fields_fun, :station_reservation_hold_import_readiness)
  end

  def context(
        %{"station_reservation_hold_import_readiness_status" => _status} = risk,
        fields_fun
      ) do
    take(risk, fields_fun, :station_reservation_hold_import_readiness)
  end

  def context(
        %{"feedback_scope" => "contact_allocation", "station_reservation_match_status" => _} =
          risk,
        fields_fun
      ) do
    take(risk, fields_fun, :station_reservation_conflict)
  end

  def context(%{"type" => type} = risk, fields_fun)
      when type in [
             "contact_success_rate_low",
             "observation_success_rate_low",
             "station_throughput_factor_low"
           ] do
    take(risk, fields_fun, :operational_feedback)
  end

  def context(%{"feedback_scope" => "candidate_rejection"} = risk, fields_fun) do
    take(risk, fields_fun, :candidate_rejection)
  end

  def context(%{"type" => "candidate_rejection_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :candidate_rejection)
  end

  def context(%{"feedback_scope" => "model_acceptance"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"type" => "model_acceptance_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"feedback_scope" => "schema_validation"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"type" => "schema_validation_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"feedback_scope" => "validation_safety_case"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"type" => "validation_safety_case_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"feedback_scope" => "refresh_budget"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"type" => "refresh_budget_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"feedback_scope" => "refresh_freshness"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"type" => "refresh_freshness_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :validation_refresh)
  end

  def context(%{"feedback_scope" => "provider_counteroffer"} = risk, fields_fun) do
    take(risk, fields_fun, :provider_counteroffer)
  end

  def context(%{"type" => "provider_counteroffer_review"} = risk, fields_fun) do
    take(risk, fields_fun, :provider_counteroffer)
  end

  def context(%{"type" => "timeline_activity_precondition_review"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_activity_precondition)
  end

  def context(%{"feedback_scope" => "timeline_activity_precondition"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_activity_precondition)
  end

  def context(%{"type" => "timeline_activity_lifecycle_state_review"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_activity_lifecycle_state)
  end

  def context(%{"feedback_scope" => "timeline_activity_lifecycle_state"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_activity_lifecycle_state)
  end

  def context(%{"type" => "timeline_dependency_impact"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_dependency_impact)
  end

  def context(%{"feedback_scope" => "timeline_dependency_impact"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_dependency_impact)
  end

  def context(%{"resource_field" => field} = risk, fields_fun)
      when field in [
             "fuel_margin",
             "power_margin",
             "storage_margin",
             "downlink_margin",
             "thermal_margin_c"
           ] do
    take(risk, fields_fun, :resource_margin)
  end

  def context(%{"type" => type} = risk, fields_fun)
      when type in [
             "fuel_margin_low",
             "power_margin_low",
             "storage_margin_low",
             "downlink_margin_low",
             "thermal_margin_c_low"
           ] do
    take(risk, fields_fun, :resource_margin)
  end

  def context(%{"type" => "timeline_publication_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_publication)
  end

  def context(%{"feedback_scope" => "timeline_publication"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_publication)
  end

  def context(%{"type" => "command_window_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :command_window)
  end

  def context(%{"type" => "candidate_diff_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :candidate_diff)
  end

  def context(%{"type" => "timeline_diff_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_diff)
  end

  def context(%{"feedback_scope" => "command_window"} = risk, fields_fun) do
    take(risk, fields_fun, :command_window)
  end

  def context(%{"type" => "objective_gap_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :objective_gap)
  end

  def context(%{"type" => "timeline_feedback_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_feedback)
  end

  def context(%{"type" => "operational_timeline_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :operational_timeline)
  end

  def context(%{"type" => "maneuver_review_pressure"} = risk, fields_fun) do
    take(risk, fields_fun, :maneuver_review)
  end

  def context(%{"type" => "timeline_lifecycle_state_review"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_lifecycle_state)
  end

  def context(%{"feedback_scope" => "timeline_lifecycle_state"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_lifecycle_state)
  end

  def context(%{"type" => "timeline_preservation_review"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_preservation)
  end

  def context(%{"feedback_scope" => "timeline_preservation"} = risk, fields_fun) do
    take(risk, fields_fun, :timeline_preservation)
  end

  def context(_risk, _fields_fun), do: %{}

  defp take(risk, fields_fun, family) when is_function(fields_fun, 1) do
    Map.take(risk, fields_fun.(family))
  end
end
