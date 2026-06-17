defmodule OrbitalDynamics.CampaignPlanner.UrgentTargetAdditionFields do
  @moduledoc false

  def addition_reason(%{"type" => "observation_success_feedback"}),
    do: "observation_success_feedback_candidate_inserted"

  def addition_reason(%{"type" => "target_priority_feedback"}),
    do: "target_priority_feedback_candidate_inserted"

  def addition_reason(%{"objective_type" => "target_coverage"}),
    do: "target_coverage_candidate_inserted"

  def addition_reason(%{"objective_type" => "target_observation"}),
    do: "target_observation_candidate_inserted"

  def addition_reason(%{"objective_type" => "target_revisit"}),
    do: "target_revisit_candidate_inserted"

  def addition_reason(%{"objective_type" => "priority_commitment"}),
    do: "priority_commitment_candidate_inserted"

  def addition_reason(_event), do: "urgent_high_priority_target_inserted"

  def required_observations(event) do
    event
    |> Map.take(["required_observations", "required_revisits", "required_count"])
    |> Map.values()
    |> Enum.find(&is_number/1)
    |> case do
      nil -> 1
      count -> max(ceil_count(count), 1)
    end
  end

  def activity_id(event, branch, target_id, index, selected_count) do
    cond do
      is_binary(event["activity_id"]) and selected_count == 1 ->
        event["activity_id"]

      is_binary(event["activity_id"]) ->
        "#{event["activity_id"]}_#{index}"

      selected_count == 1 ->
        "#{branch["id"]}_urgent_observe_#{target_id}"

      true ->
        "#{branch["id"]}_urgent_observe_#{target_id}_#{index}"
    end
  end

  def metadata(event, priority, context, index) do
    %{
      "priority" => priority,
      "commitment_id" => event["commitment_id"],
      "what_if_event_id" => event["id"],
      "required_observations" => context["required_observations"],
      "planned_observations" => context["planned_observations"],
      "staged_observation_index" => index
    }
  end

  def warning(target_id, missing_count, reason) do
    "urgent target #{target_id} missing #{missing_count} observation(s): #{reason}"
  end

  defp ceil_count(value) when is_integer(value), do: max(value, 0)
  defp ceil_count(value) when is_float(value), do: value |> Float.ceil() |> trunc() |> max(0)
  defp ceil_count(_value), do: 0
end
