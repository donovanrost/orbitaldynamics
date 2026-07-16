defmodule OrbitalDynamics.CampaignPlanner.TargetPriorityFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{OperationalFeedbackSourceMetadata, ValueEncoding}

  def events(priorities, target_ids, threshold, horizon_end_s, trust_boundary)
      when is_map(priorities) do
    events(priorities, target_ids, threshold, horizon_end_s, trust_boundary, callbacks())
  end

  def events(priorities, target_ids, threshold, horizon_end_s, trust_boundary, callbacks)
      when is_map(priorities) do
    priorities
    |> Enum.flat_map(fn
      {"default", priority} ->
        if high_priority?(priority, threshold) do
          Enum.map(
            target_ids,
            &event(&1, priority, "default", horizon_end_s, trust_boundary, callbacks)
          )
        else
          []
        end

      {target_id, priority} ->
        if target_id in target_ids and high_priority?(priority, threshold) do
          [event(target_id, priority, "target", horizon_end_s, trust_boundary, callbacks)]
        else
          []
        end
    end)
    |> Enum.sort_by(&{&1["target_id"], -&1["priority"]})
  end

  def high_priority?(priority, threshold)
      when is_number(priority) and is_number(threshold),
      do: priority >= threshold

  def high_priority?(_priority, _threshold), do: false

  defp event(target_id, priority, source_scope, horizon_end_s, trust_boundary, callbacks) do
    %{
      "type" => "target_priority_feedback",
      "target_id" => target_id,
      "priority" => priority,
      "feedback_source" => "operational_feedback.target_priority_overrides",
      "feedback_scope" => source_scope,
      "required_observations" => 1,
      "allow_placeholder" => false,
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "target_priority_overrides",
          target_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
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
      feedback_event_trust_boundary: &feedback_event_trust_boundary/3
    ]
  end
end
