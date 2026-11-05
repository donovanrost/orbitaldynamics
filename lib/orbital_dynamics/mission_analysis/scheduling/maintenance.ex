defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Maintenance do
  @moduledoc "Bounded joint service/maintenance trials over declared zero-value requests. No subsystem-specific synthesis."
  alias OrbitalDynamics.MissionAnalysis.{Input, Scheduling}
  alias Scheduling.Commitments

  def validate!(nil), do: nil

  def validate!(c) do
    fields = ~w(request_ids candidate_step_s max_candidates max_trials max_insertions)

    unless is_map(c) and Enum.sort(Map.keys(c)) == Enum.sort(fields),
      do: raise(ArgumentError, "maintenance requires exactly #{inspect(fields)}")

    ids = c["request_ids"]

    unless is_list(ids) and length(ids) in 1..32 and length(Enum.uniq(ids)) == length(ids),
      do: raise(ArgumentError, "maintenance requires 1..32 unique request IDs")

    Enum.each(ids, &Input.id!/1)
    Input.number!(c["candidate_step_s"], "maintenance candidate step", 0.001, 86_400)

    for {key, range} <- [
          {"max_candidates", 1..64},
          {"max_trials", 1..64},
          {"max_insertions", 1..3}
        ] do
      unless is_integer(c[key]) and c[key] in range,
        do: raise(ArgumentError, "invalid maintenance #{key}")
    end

    %{c | "request_ids" => Enum.sort(ids)}
  end

  def run(opportunities, requests, assets, separation, policy, evaluate, verify) do
    c = policy.maintenance
    ids = MapSet.new(c["request_ids"])
    requests_by_id = Map.new(requests, &{&1.id, &1})

    for id <- ids do
      unless requests_by_id[id] && requests_by_id[id].value == 0,
        do: raise(ArgumentError, "maintenance must name known zero-value requests")
    end

    user_pins = policy.protected_activities
    pinned = MapSet.new(user_pins, & &1["request_id"])
    ordinary = Enum.reject(opportunities, &MapSet.member?(ids, &1["request_id"]))
    {candidates, truncated} = candidates(opportunities, requests_by_id, ids, pinned, c)
    # Enumerate small sets lazily; a trial must see all maintenance reservations
    # before any service fit, otherwise full-horizon constraints can reject a
    # necessary maintenance prefix before a feasible joint plan is considered.
    proposals =
      Stream.concat([[]], Stream.flat_map(1..c["max_insertions"], &combinations(candidates, &1)))

    attempts = Enum.take(proposals, c["max_trials"] + 1)
    exhausted = length(attempts) <= c["max_trials"]

    {best, trials, fallback} =
      attempts
      |> Enum.take(c["max_trials"])
      |> Enum.with_index(1)
      |> Enum.reduce_while({nil, [], nil}, fn {pins, index}, {best, trials, fallback} ->
        before_work = Scheduling.Work.counts()

        result =
          trial(
            user_pins ++ pins,
            opportunities,
            ordinary,
            requests,
            assets,
            separation,
            policy,
            evaluate,
            verify
          )

        metrics = metrics(result, ids)
        {accepted, reason} = acceptance(best, result, metrics, policy, ids)
        reason = if index == 1 and accepted, do: "baseline", else: reason

        entry =
          Map.merge(metrics, %{
            "trial" => index,
            "reservations" => pins,
            "accepted" => accepted,
            "reason" => reason,
            "failure" => failure(result),
            "request_outcomes" => outcomes(result, requests),
            "enabled_service_request_ids" => difference(result, best, ids),
            "work_counts" =>
              Map.new(Scheduling.Work.counts(), fn {k, v} -> {k, v - before_work[k]} end)
          })

        best = if accepted, do: {result, pins}, else: best
        next = {best, trials ++ [entry], fallback || result}
        if Scheduling.Work.exhausted?(), do: {:halt, next}, else: {:cont, next}
      end)

    evidence = %{
      "encoding" => "declared_maintenance_reservation_sets.v1",
      "configuration" => c,
      "candidate_count" => length(candidates),
      "candidate_generation_truncated" => truncated,
      "trial_count" => length(trials),
      "trials" => trials,
      "status" =>
        cond do
          Scheduling.Work.exhausted?() -> "work_budget_exhausted"
          exhausted -> "candidate_sets_exhausted"
          true -> "trial_limit_reached"
        end,
      "selected_reservations" => if(best, do: elem(best, 1), else: []),
      "limits" => [
        "declared zero-value requests supply duration, pointing, mode and costs; no physical actuator availability inferred",
        "uniform start grid and bounded insertion sets, not exhaustive or globally optimal",
        "each reservation set runs the configured service strategy and all physical checks",
        "supported baseline is replaced only by greater service value; equal-value maintenance is not added"
      ]
    }

    # Keep the ordinary baseline's diagnostic result if every physical trial
    # fails. A violated result remains unusable by snapshots/execution.
    result = if best, do: elem(best, 0), else: fallback

    case result do
      {:ok, a, d, b, r, search} ->
        selected = MapSet.new(evidence["selected_reservations"], & &1["request_id"])

        a =
          Enum.map(a, fn activity ->
            if MapSet.member?(selected, activity["request_id"]) do
              activity |> Map.delete("protected") |> Map.put("automatic_maintenance", true)
            else
              activity
            end
          end)

        d =
          Enum.map(d, fn decision ->
            if MapSet.member?(selected, decision["request_id"]) and
                 decision["reason"] == "protected_selected",
               do: Map.put(decision, "reason", "automatic_maintenance_selected"),
               else: decision
          end)

        search =
          Map.put(search || %{}, "maintenance_search", evidence)
          |> Map.put("protected_activities", user_pins)

        {:ok, a, d, b, r, search}

      error ->
        error
    end
  end

  defp trial(
         pins,
         opportunities,
         ordinary,
         requests,
         assets,
         separation,
         policy,
         evaluate,
         verify
       ) do
    # Invalid generated reservations are search rejections, not fatal input errors.
    bound =
      try do
        pins = Commitments.normalize!(pins)
        bound = Commitments.bind!(pins, opportunities, requests, assets, separation)

        Commitments.reserve!(
          Map.new(assets, &{&1.id, &1.resource_budgets}),
          Enum.map(bound, fn p ->
            r = Enum.find(requests, &(&1.id == p["request_id"]))
            Commitments.activity(p, r)
          end)
        )

        {:ok, pins, bound}
      rescue
        e in ArgumentError ->
          {:error, {:maintenance_reservation_unavailable, Exception.message(e)}}
      end

    with {:ok, pins, bound} <- bound do
      p = %{policy | maintenance: nil, protected_activities: pins}
      Scheduling.run(ordinary, requests, &evaluate.(&1, bound), p, verify)
    end
  end

  defp candidates(opportunities, requests, ids, pinned, c) do
    values =
      opportunities
      |> Enum.filter(
        &(MapSet.member?(ids, &1["request_id"]) and not MapSet.member?(pinned, &1["request_id"]))
      )
      |> Enum.sort_by(&{&1["starts_at_s"], &1["asset_id"], &1["request_id"], &1["id"]})
      |> Stream.flat_map(fn o ->
        duration = requests[o["request_id"]].duration_s
        first = o["starts_at_s"] * 1.0
        last = (o["ends_at_s"] - duration) * 1.0

        Stream.iterate(0, &(&1 + 1))
        |> Stream.map(&(first + &1 * c["candidate_step_s"]))
        |> Stream.take_while(&(&1 <= last))
        |> Stream.concat(if(last >= first, do: [last], else: []))
        |> Stream.map(fn t ->
          %{
            "request_id" => o["request_id"],
            "asset_id" => o["asset_id"],
            "starts_at_s" => t,
            "ends_at_s" => t + duration
          }
        end)
      end)
      |> Stream.uniq()
      |> Enum.take(c["max_candidates"] + 1)

    {Enum.take(values, c["max_candidates"]), length(values) > c["max_candidates"]}
  end

  defp combinations(_, 0), do: [[]]
  defp combinations([], _), do: []

  defp combinations([head | tail], count) do
    Stream.concat(
      Stream.map(combinations(tail, count - 1), &[head | &1]),
      combinations(tail, count)
    )
    |> Stream.filter(fn pins ->
      length(Enum.uniq_by(pins, & &1["request_id"])) == length(pins)
    end)
  end

  defp metrics({:ok, a, _, _, r, _}, ids) do
    %{
      "planning_status" => r["planning_status"],
      "service_value" =>
        a
        |> Enum.reject(&MapSet.member?(ids, &1["request_id"]))
        |> Enum.map(& &1["value"])
        |> Enum.sum(),
      "service_request_ids" => service_ids(a, ids),
      "maintenance_costs" =>
        Enum.filter(a, &MapSet.member?(ids, &1["request_id"]))
        |> Enum.map(&Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s resource_costs)))
    }
  end

  defp metrics(_, _),
    do: %{
      "planning_status" => "rejected",
      "service_value" => 0,
      "service_request_ids" => [],
      "maintenance_costs" => []
    }

  defp acceptance(nil, {:ok, _, _, _, _, _}, m, _, _) do
    if m["planning_status"] == "supported",
      do: {true, "feasibility_restored"},
      else: {false, "unsupported_candidate"}
  end

  defp acceptance(_, {:error, _}, _, _, _), do: {false, "reservation_or_physical_check_rejected"}

  defp acceptance({before, _}, _result, m, policy, ids) do
    old = metrics(before, ids)

    cond do
      m["planning_status"] != "supported" ->
        {false, "unsupported_candidate"}

      policy.retention == :all_served and
          not Enum.all?(old["service_request_ids"], &(&1 in m["service_request_ids"])) ->
        {false, "lost_served_service"}

      old["planning_status"] != "supported" ->
        {true, "feasibility_restored"}

      m["service_value"] > old["service_value"] ->
        {true, "service_value_improved"}

      true ->
        {false, "no_service_value_improvement"}
    end
  end

  defp failure({:error, reason}), do: inspect(reason)
  defp failure(_), do: :null

  defp outcomes({:ok, a, d, b, r, _}, requests),
    do: Scheduling.Explanation.trial({:ok, a, d, b, r}, Enum.map(requests, & &1.id))

  defp outcomes(_, _), do: []

  defp service_ids(a, ids),
    do:
      a
      |> Enum.reject(&MapSet.member?(ids, &1["request_id"]))
      |> Enum.map(& &1["request_id"])
      |> Enum.sort()

  defp difference({:ok, a, _, _, _, _}, before, ids) do
    old =
      case before do
        {{:ok, a, _, _, _, _}, _} -> service_ids(a, ids)
        _ -> []
      end

    service_ids(a, ids) -- old
  end

  defp difference(_, _, _), do: []
end
