defmodule OrbitalDynamics.CampaignPlanner.RepairPolicySemantics do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchOperationalFeedback,
    RepairPolicy,
    ScalarValues,
    ValueEncoding
  }

  @command_health_activity_types ~w(command health_check)

  def to_map(%RepairPolicy{} = policy) do
    %{
      "preserve_approved" => policy.preserve_approved?,
      "preserve_executed" => policy.preserve_executed?,
      "allow_locked_changes" => policy.allow_locked_changes?,
      "schedule_churn_cost_weight" => policy.schedule_churn_cost_weight,
      "schedule_move_cost_weight" => policy.schedule_move_cost_weight,
      "degraded_payload_activity_types" => policy.degraded_payload_activity_types,
      "command_health_activity_types" => policy.command_health_activity_types
    }
  end

  def normalize(policy), do: normalize(policy, callbacks())

  def normalize(%RepairPolicy{} = policy, _callbacks), do: policy

  def normalize(policy, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    boolean_policy_value = Keyword.fetch!(callbacks, :boolean_policy_value)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)

    policy = stringify_keys.(policy || %{})

    %RepairPolicy{
      preserve_approved?: boolean_policy_value.(policy, "preserve_approved", true),
      preserve_executed?: boolean_policy_value.(policy, "preserve_executed", true),
      allow_locked_changes?: boolean_policy_value.(policy, "allow_locked_changes", false),
      schedule_churn_cost_weight:
        numeric_policy_value.(policy, "schedule_churn_cost_weight", 100.0),
      schedule_move_cost_weight: numeric_policy_value.(policy, "schedule_move_cost_weight", 0.01),
      degraded_payload_activity_types:
        Map.get(policy, "degraded_payload_activity_types", ["observe"]),
      command_health_activity_types:
        Map.get(policy, "command_health_activity_types", @command_health_activity_types)
    }
  end

  def degraded_modes_by_scenario(realized_state, repair_policy) do
    degraded_modes_by_scenario(realized_state, repair_policy, callbacks())
  end

  def degraded_modes_by_scenario(realized_state, repair_policy, callbacks) do
    truthy? = Keyword.fetch!(callbacks, :truthy?)

    normalize_incompatible_activity_types =
      Keyword.fetch!(callbacks, :normalize_incompatible_activity_types)

    realized_state
    |> Map.get("spacecraft_states", [])
    |> Enum.filter(fn state ->
      Map.get(state, "mode") in ["degraded", "degraded_mode"] or
        truthy?.(Map.get(state, "degraded"))
    end)
    |> Map.new(fn state ->
      scenario_id = Map.get(state, "scenario_id") || Map.get(state, "id")

      incompatible_types =
        (Map.get(state, "incompatible_activity_types") ||
           Map.get(state, "suppressed_activity_types") ||
           repair_policy.degraded_payload_activity_types)
        |> normalize_incompatible_activity_types.()

      {scenario_id, incompatible_types}
    end)
  end

  def degraded_incompatible?(activity, degraded_modes, repair_policy) do
    incompatible_types = Map.get(degraded_modes, activity["scenario_id"], [])

    exempt_activity_types =
      repair_policy.command_health_activity_types || @command_health_activity_types

    activity["type"] in incompatible_types and
      activity["type"] not in exempt_activity_types
  end

  def locked_or_approved?(activity), do: locked_or_approved?(activity, callbacks())

  def locked_or_approved?(activity, callbacks) do
    truthy? = Keyword.fetch!(callbacks, :truthy?)
    metadata = Map.get(activity, "metadata", %{})

    truthy?.(Map.get(activity, "locked")) or truthy?.(Map.get(activity, "approved")) or
      truthy?.(Map.get(metadata, "locked")) or truthy?.(Map.get(metadata, "approved")) or
      Map.get(activity, "approval_status") in ["approved", "locked"] or
      Map.get(metadata, "approval_status") in ["approved", "locked"]
  end

  defp callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      boolean_policy_value: &boolean_policy_value/3,
      numeric_policy_value: &numeric_policy_value/3,
      truthy?: &ScalarValues.truthy?/1,
      normalize_incompatible_activity_types:
        &BranchOperationalFeedback.normalize_incompatible_activity_types/1
    ]

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp boolean_policy_value(policy, key, default) do
    case ScalarValues.json_boolean_value(Map.get(policy, key, default)) do
      value when is_boolean(value) -> value
      _value -> default
    end
  end
end
