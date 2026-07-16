defmodule OrbitalDynamics.CampaignPlanner.ActivitySuccessFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedbackPlanningContext,
    OperationalFeedbackSourceMetadata,
    ValueEncoding
  }

  def maneuver(factors, maneuver_activities, threshold, horizon_end_s, trust_boundary)
      when is_map(factors) do
    maneuver(
      factors,
      maneuver_activities,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def maneuver(factors, maneuver_activities, threshold, horizon_end_s, trust_boundary, callbacks)
      when is_map(factors) do
    factors
    |> Enum.flat_map(fn
      {"default", factor} ->
        if low_feedback_factor?(factor, threshold) do
          Enum.map(maneuver_activities, fn activity ->
            maneuver_success_event(
              activity,
              factor,
              "default",
              "default",
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          end)
        else
          []
        end

      {feedback_key, factor} ->
        if low_feedback_factor?(factor, threshold) do
          maneuver_activities
          |> Enum.filter(&(feedback_key in maneuver_feedback_keys(&1, callbacks)))
          |> Enum.map(fn activity ->
            maneuver_success_event(
              activity,
              factor,
              maneuver_feedback_scope(activity, feedback_key, callbacks),
              feedback_key,
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          end)
        else
          []
        end
    end)
    |> Enum.sort_by(&{&1["activity_id"], &1["feedback_key"], &1["maneuver_success_factor"]})
  end

  def command(factors, command_activities, threshold, horizon_end_s, trust_boundary)
      when is_map(factors) do
    command(
      factors,
      command_activities,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def command(factors, command_activities, threshold, horizon_end_s, trust_boundary, callbacks)
      when is_map(factors) do
    factors
    |> Enum.flat_map(fn
      {"default", factor} ->
        if low_feedback_factor?(factor, threshold) do
          Enum.map(command_activities, fn activity ->
            command_success_event(
              activity,
              factor,
              "default",
              "default",
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          end)
        else
          []
        end

      {feedback_key, factor} ->
        if low_feedback_factor?(factor, threshold) do
          command_activities
          |> Enum.filter(&(feedback_key in command_feedback_keys(&1, callbacks)))
          |> Enum.map(fn activity ->
            command_success_event(
              activity,
              factor,
              command_feedback_scope(activity, feedback_key, callbacks),
              feedback_key,
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          end)
        else
          []
        end
    end)
    |> Enum.sort_by(&{&1["activity_id"], &1["feedback_key"], &1["command_success_factor"]})
  end

  defp low_feedback_factor?(factor, threshold) when is_number(factor) and is_number(threshold),
    do: factor < threshold

  defp low_feedback_factor?(_factor, _threshold), do: false

  defp command_success_event(
         activity,
         factor,
         source_scope,
         feedback_key,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "command_success_feedback",
      "activity_id" => Map.get(activity, "id") || Map.get(activity, "activity_id"),
      "scenario_id" => Map.get(activity, "scenario_id"),
      "command_success_factor" => factor |> max(0.0) |> min(1.0),
      "feedback_source" => "operational_feedback.command_success_rate",
      "feedback_scope" => source_scope,
      "feedback_key" => feedback_key,
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "command_success_rate",
          feedback_key || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp maneuver_success_event(
         activity,
         factor,
         source_scope,
         feedback_key,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "maneuver_success_feedback",
      "activity_id" => Map.get(activity, "id") || Map.get(activity, "activity_id"),
      "scenario_id" => Map.get(activity, "scenario_id"),
      "maneuver_success_factor" => factor |> max(0.0) |> min(1.0),
      "feedback_source" => "operational_feedback.maneuver_success_rate",
      "feedback_scope" => source_scope,
      "feedback_key" => feedback_key,
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "maneuver_success_rate",
          feedback_key || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp command_feedback_keys(activity, callbacks) do
    callbacks
    |> Keyword.fetch!(:command_feedback_keys)
    |> then(& &1.(activity))
  end

  defp command_feedback_scope(activity, feedback_key, callbacks) do
    callbacks
    |> Keyword.fetch!(:command_feedback_scope)
    |> then(& &1.(activity, feedback_key))
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
      command_feedback_keys: &OperationalFeedbackPlanningContext.command_feedback_keys/1,
      command_feedback_scope: &OperationalFeedbackPlanningContext.command_feedback_scope/2,
      compact_map: &ValueEncoding.compact_map/1,
      feedback_event_trust_boundary: &feedback_event_trust_boundary/3,
      maneuver_feedback_keys: &OperationalFeedbackPlanningContext.maneuver_feedback_keys/1,
      maneuver_feedback_scope: &OperationalFeedbackPlanningContext.maneuver_feedback_scope/2
    ]
  end
end
