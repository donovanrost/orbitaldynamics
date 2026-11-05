defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Replacement do
  @moduledoc """
  First-improvement neighborhood: defer every opportunity of one tentative served
  request, then rebuild. A deferred request can still fit after other work.
  Exact commitments are never deferred; the controller owns feasibility and value acceptance.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Scheduling.Strategy
  @impl true
  def propose(problem, incumbent, history, state) do
    {:ok, activities, _, _, _} = incumbent.result

    activities
    |> Enum.reject(&MapSet.member?(problem.protected_request_ids, &1["request_id"]))
    |> Enum.sort_by(&{-&1["value"], &1["request_id"]})
    |> Stream.map(fn a ->
      {last, first} = Enum.split_with(incumbent.order, &(&1["request_id"] == a["request_id"]))

      {first ++ last,
       %{"deferred_request_id" => a["request_id"], "previous_asset_id" => a["asset_id"]}}
    end)
    |> Enum.find(fn {order, _} ->
      not MapSet.member?(history.tried_orders, Enum.map(order, & &1["id"]))
    end)
    |> case do
      nil -> :done
      {order, description} -> {:candidate, order, description, state}
    end
  end
end
