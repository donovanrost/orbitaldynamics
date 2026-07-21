defmodule OrbitalDynamics.CampaignPlanner.RepairLinkCapacityPolicy do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    DownlinkObjectiveRequirements,
    ValueEncoding
  }

  def build(request) do
    policy = ValueEncoding.stringify_keys(request.scoring_policy || %{})

    request.mission_state
    |> required_downlink_mb()
    |> case do
      value when is_number(value) -> Map.put_new(policy, "required_downlink_mb", value)
      _value -> policy
    end
  end

  defp required_downlink_mb(mission_state) do
    mission_state
    |> DownlinkObjectiveRequirements.objectives()
    |> Enum.map(&objective_required_downlink_mb/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(objective)
  end

  defp objective_required_downlink_mb(_objective), do: nil
end
