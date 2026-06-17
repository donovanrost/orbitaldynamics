defmodule OrbitalDynamics.CandidateRefresh.FreshnessReport do
  @moduledoc false

  def build(context) when is_map(context) do
    refresh = Map.fetch!(context, :refresh)
    generated_at = Map.fetch!(context, :generated_at)
    accepted_state = Map.fetch!(context, :accepted_state)
    horizon = Map.fetch!(context, :horizon)
    current_epoch = Map.fetch!(context, :current_epoch_s)
    policy = freshness_policy(refresh)

    accepted_snapshot_age_s =
      accepted_snapshot_age_s(Map.get(accepted_state, "accepted_at"), generated_at)

    horizon_start_offset_s =
      horizon_start_offset_s(current_epoch, Map.get(horizon, "starts_at_s"))

    accepted_quality_level = accepted_quality_level(accepted_state)
    state_quality_status = state_quality_status(accepted_quality_level, policy)

    stale_reasons =
      []
      |> maybe_stale_reason(
        not is_nil(accepted_snapshot_age_s) and
          accepted_snapshot_age_s > policy["max_snapshot_age_s"],
        "accepted_snapshot_older_than_policy"
      )
      |> maybe_stale_reason(
        not is_nil(horizon_start_offset_s) and
          abs(horizon_start_offset_s) > policy["max_horizon_start_offset_s"],
        "remaining_horizon_does_not_start_at_current_epoch"
      )
      |> maybe_stale_reason(
        state_quality_status == "not_accepted",
        "accepted_state_quality_below_policy"
      )
      |> Enum.reverse()

    unknown_reasons =
      []
      |> maybe_unknown_reason(
        is_nil(accepted_snapshot_age_s),
        "accepted_snapshot_age_unknown"
      )
      |> maybe_unknown_reason(
        is_nil(horizon_start_offset_s),
        "horizon_alignment_unknown"
      )
      |> maybe_unknown_reason(
        state_quality_status == "unknown",
        "accepted_state_quality_unknown"
      )
      |> Enum.reverse()

    %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "model_limits" => Map.fetch!(context, :model_limits),
      "generated_at" => DateTime.to_iso8601(generated_at),
      "accepted_at" => Map.get(accepted_state, "accepted_at"),
      "accepted_state_quality_level" => accepted_quality_level,
      "allowed_state_quality_levels" => policy["allowed_state_quality_levels"],
      "state_quality_status" => state_quality_status,
      "current_epoch_s" => current_epoch,
      "horizon_starts_at_s" => Map.get(horizon, "starts_at_s"),
      "accepted_snapshot_age_s" => accepted_snapshot_age_s,
      "horizon_start_offset_s" => horizon_start_offset_s,
      "max_snapshot_age_s" => policy["max_snapshot_age_s"],
      "max_horizon_start_offset_s" => policy["max_horizon_start_offset_s"],
      "status" => freshness_status(stale_reasons, unknown_reasons),
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => unknown_reasons
    }
  end

  defp freshness_policy(refresh) do
    policy = Map.get(refresh, "freshness_policy", %{})

    %{
      "max_snapshot_age_s" => policy_number(policy, "max_snapshot_age_s", 86_400.0),
      "max_horizon_start_offset_s" => policy_number(policy, "max_horizon_start_offset_s", 1.0),
      "allowed_state_quality_levels" =>
        policy_list(policy, "allowed_state_quality_levels", ["accepted", "planning_accepted"])
    }
  end

  defp policy_number(policy, key, default) do
    case numeric_value(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp policy_list(policy, key, default) do
    case Map.get(policy, key) do
      values when is_list(values) ->
        accepted_values = Enum.filter(values, &is_binary/1)

        if accepted_values == [] do
          default
        else
          accepted_values
        end

      _value ->
        default
    end
  end

  defp accepted_quality_level(accepted_state) do
    accepted_state
    |> Map.get("quality", %{})
    |> Map.get("level")
  end

  defp state_quality_status(nil, _policy), do: "unknown"

  defp state_quality_status(level, policy) do
    if level in policy["allowed_state_quality_levels"] do
      "accepted"
    else
      "not_accepted"
    end
  end

  defp accepted_snapshot_age_s(nil, _generated_at), do: nil

  defp accepted_snapshot_age_s(accepted_at, generated_at) when is_binary(accepted_at) do
    with {:ok, accepted_at, _offset} <- DateTime.from_iso8601(accepted_at) do
      DateTime.diff(generated_at, accepted_at, :second) * 1.0
    else
      _error -> nil
    end
  end

  defp accepted_snapshot_age_s(_accepted_at, _generated_at), do: nil

  defp horizon_start_offset_s(current_epoch, horizon_starts_at_s)
       when is_number(current_epoch) and is_number(horizon_starts_at_s),
       do: horizon_starts_at_s - current_epoch

  defp horizon_start_offset_s(_current_epoch, _horizon_starts_at_s), do: nil

  defp freshness_status([_reason | _reasons], _unknown_reasons), do: "stale"
  defp freshness_status([], [_reason | _reasons]), do: "unknown"
  defp freshness_status([], []), do: "current"

  defp maybe_stale_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_stale_reason(reasons, false, _reason), do: reasons

  defp maybe_unknown_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_unknown_reason(reasons, false, _reason), do: reasons

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil
end
