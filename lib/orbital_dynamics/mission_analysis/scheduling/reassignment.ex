defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Reassignment do
  @moduledoc """
  Deterministic first-improvement neighborhood: prefer an alternative asset's
  opportunity for one served request, preserving the order of other opportunities.
  Whole proposals are decoded again; placement and subsequent assignments can change.
  It cannot remove a served request, change request priority, or cross a value plateau.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Scheduling.Strategy

  @impl true
  def propose(problem, incumbent, history, state) do
    {:ok, activities, _, _, _} = incumbent.result

    activities
    |> Enum.reject(&MapSet.member?(problem.protected_request_ids, &1["request_id"]))
    |> Enum.sort_by(&{-&1["value"], &1["request_id"]})
    |> Stream.flat_map(fn a ->
      problem.opportunities
      |> Stream.filter(&(&1["request_id"] == a["request_id"] and &1["asset_id"] != a["asset_id"]))
      |> Stream.map(fn o ->
        order = prefer(incumbent.order, o)

        {order,
         %{
           "request_id" => a["request_id"],
           "from_asset_id" => a["asset_id"],
           "preferred_asset_id" => o["asset_id"],
           "preferred_opportunity_id" => o["id"]
         }}
      end)
    end)
    |> Enum.find(fn {order, _} ->
      not MapSet.member?(history.tried_orders, Enum.map(order, & &1["id"]))
    end)
    |> case do
      nil -> :done
      {order, move} -> {:candidate, order, move, state}
    end
  end

  defp prefer(order, preferred) do
    index = Enum.find_index(order, &(&1["request_id"] == preferred["request_id"]))
    order |> Enum.reject(&(&1["id"] == preferred["id"])) |> List.insert_at(index, preferred)
  end
end
