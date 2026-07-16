defmodule OrbitalDynamics.CampaignPlanner.ManeuverExecutionUncertaintyFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedbackPlanningContext,
    OperationalFeedbackSourceMetadata,
    ValueEncoding
  }

  def events(feedback, maneuver_activities, policy, horizon_end_s, trust_boundary)
      when is_map(feedback) do
    events(
      feedback,
      maneuver_activities,
      policy,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def events(feedback, maneuver_activities, policy, horizon_end_s, trust_boundary, callbacks)
      when is_map(feedback) do
    feedback
    |> Enum.flat_map(fn
      {"default", %{} = uncertainty} ->
        if relevant?(uncertainty, policy) do
          Enum.map(maneuver_activities, fn activity ->
            event(
              activity,
              uncertainty,
              "default",
              "default",
              policy,
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          end)
        else
          []
        end

      {feedback_key, %{} = uncertainty} ->
        if relevant?(uncertainty, policy) do
          maneuver_activities
          |> Enum.filter(&(feedback_key in maneuver_feedback_keys(&1, callbacks)))
          |> Enum.map(fn activity ->
            event(
              activity,
              uncertainty,
              maneuver_feedback_scope(activity, feedback_key, callbacks),
              feedback_key,
              policy,
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          end)
        else
          []
        end

      {_feedback_key, _uncertainty} ->
        []
    end)
    |> Enum.sort_by(&{&1["activity_id"], &1["feedback_key"]})
  end

  defp relevant?(%{} = uncertainty, policy) do
    uncertainty["execution_uncertainty_status"] == "missing" or
      over_threshold?(
        uncertainty["timing_3sigma_s"],
        policy["maneuver_execution_timing_3sigma_threshold_s"]
      ) or
      over_threshold?(
        uncertainty["delta_v_3sigma_magnitude_km_s"],
        policy["maneuver_execution_delta_v_3sigma_threshold_km_s"]
      )
  end

  defp over_threshold?(value, threshold)
       when is_number(value) and is_number(threshold),
       do: value > threshold

  defp over_threshold?(_value, _threshold), do: false

  defp event(
         activity,
         uncertainty,
         source_scope,
         feedback_key,
         policy,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "maneuver_execution_uncertainty_feedback",
      "activity_id" => Map.get(activity, "id") || Map.get(activity, "activity_id"),
      "scenario_id" => Map.get(activity, "scenario_id"),
      "execution_uncertainty_status" => uncertainty["execution_uncertainty_status"],
      "execution_uncertainty" => uncertainty["execution_uncertainty"],
      "timing_3sigma_s" => uncertainty["timing_3sigma_s"],
      "timing_3sigma_threshold_s" => policy["maneuver_execution_timing_3sigma_threshold_s"],
      "delta_v_3sigma_km_s" => uncertainty["delta_v_3sigma_km_s"],
      "delta_v_3sigma_magnitude_km_s" => uncertainty["delta_v_3sigma_magnitude_km_s"],
      "delta_v_3sigma_magnitude_threshold_km_s" =>
        policy["maneuver_execution_delta_v_3sigma_threshold_km_s"],
      "execution_uncertainty_source" => uncertainty["execution_uncertainty_source"],
      "feedback_source" => "operational_feedback.maneuver_execution_uncertainty",
      "feedback_scope" => source_scope,
      "feedback_key" => feedback_key,
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "maneuver_execution_uncertainty",
          feedback_key || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp maneuver_feedback_keys(activity, callbacks) do
    callbacks
    |> Keyword.fetch!(:maneuver_feedback_keys)
    |> then(& &1.(activity))
  end

  defp maneuver_feedback_scope(activity, feedback_key, callbacks) do
    callbacks
    |> Keyword.fetch!(:maneuver_feedback_scope)
    |> then(& &1.(activity, feedback_key))
  end

  defp compact_map(map, callbacks) do
    callbacks
    |> Keyword.fetch!(:compact_map)
    |> then(& &1.(map))
  end

  defp feedback_event_trust_boundary(trust_boundary, field, key, callbacks) do
    callbacks
    |> Keyword.fetch!(:feedback_event_trust_boundary)
    |> then(& &1.(trust_boundary, field, key))
  end

  defp feedback_event_trust_boundary(trust_boundary, field, key) do
    OperationalFeedbackSourceMetadata.feedback_event_trust_boundary(
      trust_boundary,
      field,
      key,
      []
    )
  end

  defp callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      feedback_event_trust_boundary: &feedback_event_trust_boundary/3,
      maneuver_feedback_keys: &OperationalFeedbackPlanningContext.maneuver_feedback_keys/1,
      maneuver_feedback_scope: &OperationalFeedbackPlanningContext.maneuver_feedback_scope/2
    ]
  end
end
