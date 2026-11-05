defmodule OrbitalDynamics.MissionAnalysis.Scheduling.StaticEvaluator do
  @moduledoc "Decodes an ordered proposal with time conflicts, separation and static budgets only."
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Commitments

  def evaluate(assets, requests, opportunities, separation, protected \\ []) do
    request_map = Map.new(requests, &{&1.id, &1})
    balances = Map.new(assets, &{&1.id, &1.resource_budgets})

    seeded = Enum.map(protected, &Commitments.activity(&1, request_map[&1["request_id"]]))
    balances = Commitments.reserve!(balances, seeded)
    decisions = Enum.map(seeded, &Commitments.decision/1) |> Enum.reverse()

    opportunities
    |> Enum.reduce({Enum.reverse(seeded), decisions, balances}, fn opportunity,
                                                                   {activities, decisions,
                                                                    balances} ->
      r = request_map[opportunity["request_id"]]
      asset_id = opportunity["asset_id"]

      start =
        earliest_slot(
          opportunity["starts_at_s"],
          r.duration_s,
          Enum.filter(activities, &(&1["asset_id"] == asset_id)),
          separation
        )

      available = balances[asset_id]

      missing =
        for {key, cost} <- r.resource_costs,
            cost > 0 and not Map.has_key?(available, key),
            do: key

      insufficient =
        for {key, cost} <- r.resource_costs, cost > Map.get(available, key, 0), do: key

      reason =
        cond do
          Enum.any?(activities, &(&1["request_id"] == r.id)) -> "request_already_scheduled"
          start + r.duration_s > opportunity["ends_at_s"] -> "asset_conflict"
          missing != [] -> "undeclared_resource_budget"
          insufficient != [] -> "insufficient_resource_budget"
          true -> "selected"
        end

      decision = %{
        "opportunity_id" => opportunity["id"],
        "request_id" => r.id,
        "asset_id" => asset_id,
        "reason" => reason,
        "resource_ids" => Enum.sort(Enum.uniq(missing ++ insufficient))
      }

      if reason == "selected" do
        activity = %{
          "id" => "activity:#{opportunity["id"]}",
          "opportunity_id" => opportunity["id"],
          "request_id" => r.id,
          "asset_id" => asset_id,
          "type" => r.activity_type,
          "starts_at_s" => start,
          "ends_at_s" => start + r.duration_s,
          "value" => r.value,
          "resource_costs" => r.resource_costs
        }

        remaining =
          Enum.reduce(r.resource_costs, available, fn {key, cost}, acc ->
            Map.update(acc, key, 0.0, &(&1 - cost))
          end)

        {[activity | activities], [decision | decisions], Map.put(balances, asset_id, remaining)}
      else
        {activities, [decision | decisions], balances}
      end
    end)
    |> then(fn {a, d, b} ->
      {:ok, Enum.sort_by(a, &{&1["starts_at_s"], &1["id"]}), Enum.reverse(d), b, nil}
    end)
  end

  defp earliest_slot(start, duration, activities, separation) do
    activities
    |> Enum.sort_by(& &1["starts_at_s"])
    |> Enum.reduce(start, fn activity, candidate ->
      if candidate + duration + separation <= activity["starts_at_s"] or
           candidate >= activity["ends_at_s"] + separation,
         do: candidate,
         else: activity["ends_at_s"] + separation
    end)
  end
end
