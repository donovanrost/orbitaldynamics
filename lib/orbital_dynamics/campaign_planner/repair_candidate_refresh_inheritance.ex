defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshInheritance do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshAcceptedState,
    BranchRefreshGroundNetwork,
    BranchRefreshTargets,
    ValueEncoding
  }

  def inherit(request, approval_policy, mission_state, prior_plan) do
    request
    |> inherit_approval_policy(approval_policy)
    |> inherit_mission_state(mission_state, prior_plan)
  end

  defp inherit_approval_policy(nil, _approval_policy), do: nil
  defp inherit_approval_policy(request, nil), do: request

  defp inherit_approval_policy(
         %{"candidate_refresh" => %{} = refresh} = request,
         approval_policy
       ) do
    Map.put(
      request,
      "candidate_refresh",
      Map.put_new(refresh, "approval_policy", ValueEncoding.stringify_keys(approval_policy))
    )
  end

  defp inherit_approval_policy(%{} = request, approval_policy) do
    Map.put_new(request, "approval_policy", ValueEncoding.stringify_keys(approval_policy))
  end

  defp inherit_mission_state(nil, _mission_state, _prior_plan), do: nil
  defp inherit_mission_state(request, nil, _prior_plan), do: request

  defp inherit_mission_state(
         request,
         %{"objectives" => []} = mission_state,
         _prior_plan
       )
       when map_size(mission_state) == 1,
       do: request

  defp inherit_mission_state(
         %{"candidate_refresh" => %{} = refresh} = request,
         mission_state,
         prior_plan
       ) do
    refresh =
      refresh
      |> Map.put_new("mission_state", mission_state)
      |> inherit_mission_state_inputs(mission_state, prior_plan)

    request
    |> Map.put("candidate_refresh", refresh)
    |> inherit_manifest_inputs(mission_state)
  end

  defp inherit_mission_state(%{} = request, mission_state, prior_plan) do
    request
    |> Map.put_new("mission_state", mission_state)
    |> inherit_mission_state_inputs(mission_state, prior_plan)
    |> inherit_manifest_inputs(mission_state)
  end

  defp inherit_mission_state_inputs(refresh, mission_state, prior_plan) do
    operational_feedback = Map.get(refresh, "operational_feedback", %{})

    refresh
    |> put_if_absent(
      "accepted_planning_state",
      BranchRefreshAcceptedState.from_mission_state(mission_state, prior_plan)
    )
    |> put_if_absent(
      "targets",
      BranchRefreshTargets.build(%{"events" => []}, mission_state, operational_feedback)
    )
  end

  defp inherit_manifest_inputs(request, mission_state) do
    put_if_absent(
      request,
      "ground_stations",
      BranchRefreshGroundNetwork.ground_stations(mission_state)
    )
  end

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    case Map.get(map, key) do
      existing when existing in [nil, "", [], %{}] -> Map.put(map, key, value)
      _existing -> map
    end
  end
end
