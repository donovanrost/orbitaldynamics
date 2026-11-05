defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Commitments do
  @moduledoc "Exact request/asset/time reservations, revalidated against current opportunities and constraints."
  alias OrbitalDynamics.MissionAnalysis.Input
  @fields ~w(request_id asset_id starts_at_s ends_at_s)

  def normalize!(values) do
    unless is_list(values) and length(values) <= 100,
      do: raise(ArgumentError, "at most 100 protected activities required")

    values =
      Enum.map(values, fn v ->
        unless is_map(v) and Enum.sort(Map.keys(v)) == Enum.sort(@fields),
          do: raise(ArgumentError, "protected activities require exactly #{inspect(@fields)}")

        start = Input.number!(v["starts_at_s"], "protected start", -1.0e12, 1.0e12)
        stop = Input.number!(v["ends_at_s"], "protected end", -1.0e12, 1.0e12)
        if stop <= start, do: raise(ArgumentError, "protected activity interval must be positive")

        %{
          v
          | "request_id" => Input.id!(v["request_id"]),
            "asset_id" => Input.id!(v["asset_id"]),
            "starts_at_s" => start,
            "ends_at_s" => stop
        }
      end)

    if length(Enum.uniq_by(values, & &1["request_id"])) != length(values),
      do: raise(ArgumentError, "a request may have only one protected activity")

    Enum.sort_by(values, &{&1["starts_at_s"], &1["asset_id"], &1["request_id"]})
  end

  def bind!(values, opportunities, requests, assets, separation) do
    requests = Map.new(requests, &{&1.id, &1})
    ids = MapSet.new(assets, & &1.id)

    Enum.map(values, fn v ->
      r = requests[v["request_id"]]

      unless r != nil and MapSet.member?(ids, v["asset_id"]) and
               v["ends_at_s"] == v["starts_at_s"] + r.duration_s,
             do:
               raise(
                 ArgumentError,
                 "protected activity must name a known asset/request and its exact duration"
               )

      opportunity =
        opportunities
        |> Enum.sort_by(& &1["id"])
        |> Enum.find(fn o ->
          o["request_id"] == v["request_id"] and o["asset_id"] == v["asset_id"] and
            o["starts_at_s"] <= v["starts_at_s"] and o["ends_at_s"] >= v["ends_at_s"]
        end)

      unless opportunity,
        do:
          raise(
            ArgumentError,
            "protected activity is outside currently supported opportunity bounds"
          )

      Map.put(v, "opportunity", opportunity)
    end)
    |> then(fn bound ->
      for {_, timeline} <- Enum.group_by(bound, & &1["asset_id"]),
          [a, b] <- Enum.chunk_every(Enum.sort_by(timeline, & &1["starts_at_s"]), 2, 1, :discard) do
        if a["ends_at_s"] + separation > b["starts_at_s"],
          do: raise(ArgumentError, "protected activities overlap or violate asset separation")
      end

      bound
    end)
  end

  def activity(v, request) do
    o = v["opportunity"]

    %{
      "id" => "activity:#{o["id"]}",
      "opportunity_id" => o["id"],
      "request_id" => request.id,
      "asset_id" => v["asset_id"],
      "starts_at_s" => v["starts_at_s"],
      "ends_at_s" => v["ends_at_s"],
      "type" => request.activity_type,
      "value" => request.value,
      "resource_costs" => request.resource_costs,
      "protected" => true
    }
  end

  def reserve!(balances, activities) do
    Enum.reduce(activities, balances, fn a, balances ->
      id = a["asset_id"]

      remaining =
        Enum.reduce(a["resource_costs"], balances[id], fn {key, cost}, budget ->
          if cost > Map.get(budget, key, 0),
            do: raise(ArgumentError, "protected activities exceed declared static budgets")

          if Map.has_key?(budget, key), do: Map.update!(budget, key, &(&1 - cost)), else: budget
        end)

      Map.put(balances, id, remaining)
    end)
  end

  def intact?(activities, protected) do
    Enum.all?(protected, fn p ->
      case Enum.filter(activities, &(&1["request_id"] == p["request_id"])) do
        [activity] -> Enum.all?(@fields, &(activity[&1] == p[&1]))
        _ -> false
      end
    end)
  end

  def decision(a),
    do: %{
      "opportunity_id" => a["opportunity_id"],
      "request_id" => a["request_id"],
      "asset_id" => a["asset_id"],
      "resource_ids" => [],
      "reason" => "protected_selected"
    }
end
