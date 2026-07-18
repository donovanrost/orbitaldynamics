defmodule OrbitalDynamics.Timeline.LifecycleStatePolicy do
  @moduledoc false

  def status_state_transition_decision(nil), do: "none"

  def status_state_transition_decision(%{"requires_operator_review" => true}), do: "review"

  def status_state_transition_decision(%{}), do: "record"

  def status_state_review_required?(%{"requires_operator_review" => review_required?}),
    do: review_required?

  def status_state_review_required?(_status_transition), do: false

  def status_state_required_operator_action("none"), do: "none"
  def status_state_required_operator_action("review"), do: "review_activity_transition"
  def status_state_required_operator_action("record"), do: "record_timeline_change"

  def status_state_operator_action_reason(nil), do: "no_status_change"

  def status_state_operator_action_reason(%{"operator_action_reason" => reason}), do: reason

  def status_state_import_action("none"), do: "record_preserved_activity"
  def status_state_import_action("review"), do: "review_timeline_diff"
  def status_state_import_action("record"), do: "import_replacement_activity"

  def approval_state_required_operator_action("none"), do: "none"
  def approval_state_required_operator_action("review"), do: "review_activity_approval"
  def approval_state_required_operator_action("record"), do: "record_timeline_change"

  def approval_state_operator_action_reason(nil), do: "no_approval_status_change"

  def approval_state_operator_action_reason(%{"operator_action_reason" => reason}), do: reason

  def lifecycle_state_transition_decision(status_state, approval_state, protections) do
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

  def lifecycle_state_required_operator_actions(
        status_state,
        approval_state,
        protections,
        transition_decision,
        sorted_uniq
      ) do
    actions =
      [
        Map.get(status_state, "required_operator_action"),
        Map.get(approval_state, "required_operator_action")
      ] ++ lifecycle_state_protection_actions(protections)

    actions =
      actions
      |> Enum.reject(&(&1 in [nil, "none"]))
      |> sorted_uniq.()

    case {transition_decision, actions} do
      {"none", []} -> ["none"]
      {"record", []} -> ["record_timeline_change"]
      {_decision, actions} -> actions
    end
  end

  def lifecycle_state_required_operator_action(actions, "review") do
    cond do
      "review_activity_transition" in actions -> "review_activity_transition"
      "review_activity_approval" in actions -> "review_activity_approval"
      "review_timeline_change" in actions -> "review_timeline_change"
      true -> List.first(actions) || "review_activity_transition"
    end
  end

  def lifecycle_state_required_operator_action(_actions, "record"),
    do: "record_timeline_change"

  def lifecycle_state_required_operator_action(_actions, "none"), do: "none"

  def lifecycle_state_operator_action_reasons(
        status_state,
        approval_state,
        protections,
        sorted_uniq
      ) do
    [
      Map.get(status_state, "operator_action_reason"),
      Map.get(approval_state, "operator_action_reason")
    ]
    |> Kernel.++(lifecycle_state_protection_reasons(protections))
    |> Enum.reject(&(&1 in [nil, "no_status_change", "no_approval_status_change"]))
    |> sorted_uniq.()
    |> case do
      [] -> nil
      reasons -> reasons
    end
  end

  defp lifecycle_state_protection_review_required?(protections) do
    Enum.any?(protections, fn
      %{"protection_decision" => "review_change"} -> true
      _protection -> false
    end)
  end

  defp lifecycle_state_protection_actions(protections) do
    Enum.flat_map(protections, fn
      %{"protection_decision" => "review_change"} -> ["review_timeline_change"]
      _protection -> []
    end)
  end

  defp lifecycle_state_protection_reasons(protections) do
    protections
    |> Enum.filter(&(Map.get(&1 || %{}, "protection_decision") == "review_change"))
    |> Enum.map(&Map.get(&1, "reason"))
  end
end
