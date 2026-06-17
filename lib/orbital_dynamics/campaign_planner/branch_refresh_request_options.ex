defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshRequestOptions do
  @moduledoc false

  def outputs(targets, ground_stations) do
    ["eclipses"]
    |> maybe_append_output(ground_stations != [], "access_windows")
    |> maybe_append_output(targets != [], "target_visibility")
    |> Enum.reverse()
  end

  def horizon(request, defaults) do
    request.remaining_horizon
    |> Map.take(["starts_at_s", "ends_at_s", "duration_s"])
    |> Map.put("output_step_s", output_step_s(request, defaults))
  end

  def constraints(request, defaults) do
    source_constraints =
      get_in(request.prior_plan, ["assumptions", "constraints"]) || %{}

    source_constraints
    |> Map.merge(Map.get(defaults, "constraints", %{}))
    |> Map.put_new("avoid_eclipse", false)
    |> Map.put_new("min_activity_duration_s", 0.0)
  end

  def scoring_policy(request, defaults) do
    source_policy =
      get_in(request.prior_plan, ["ranking_explanation", "policy"]) || %{}

    source_policy
    |> Map.merge(Map.get(defaults, "scoring_policy", %{}))
    |> Map.put_new("downlink_rate_mb_s", 1.0)
  end

  def approval_policy(%{
        approval_policy_supplied?: true,
        approval_policy_source: policy
      }) do
    policy
  end

  def approval_policy(_request), do: nil

  defp output_step_s(request, defaults) do
    numeric_or_nil(Map.get(request.remaining_horizon, "output_step_s")) ||
      numeric_or_nil(get_in(request.prior_plan, ["planning_horizon", "output_step_s"])) ||
      numeric_or_nil(Map.get(defaults, "output_step_s")) ||
      60.0
  end

  defp maybe_append_output(outputs, true, output), do: [output | outputs]
  defp maybe_append_output(outputs, false, _output), do: outputs

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
