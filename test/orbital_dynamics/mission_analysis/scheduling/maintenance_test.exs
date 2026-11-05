defmodule OrbitalDynamics.MissionAnalysis.Scheduling.MaintenanceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Maintenance, Policy, Greedy}

  defp config,
    do: %{
      "request_ids" => ["m1", "m2"],
      "candidate_step_s" => 5,
      "max_candidates" => 8,
      "max_trials" => 4,
      "max_insertions" => 2
    }

  defp problem(budget \\ 2) do
    requests =
      for {id, value} <- [{"m1", 0}, {"m2", 0}, {"service", 10}],
          do: %{
            id: id,
            value: value,
            duration_s: 2,
            activity_type: "generic_task",
            resource_costs: if(value == 0, do: %{"tokens" => 1}, else: %{})
          }

    opportunities =
      for {r, i} <- Enum.with_index(requests),
          do: %{
            "id" => r.id,
            "request_id" => r.id,
            "asset_id" => "a",
            "starts_at_s" => i * 5,
            "ends_at_s" => i * 5 + 2
          }

    assets = [%{id: "a", resource_budgets: %{"tokens" => budget}}]

    evaluate = fn _, pins ->
      maintenance =
        Enum.map(pins, fn p ->
          r = Enum.find(requests, &(&1.id == p["request_id"]))
          OrbitalDynamics.MissionAnalysis.Scheduling.Commitments.activity(p, r)
        end)

      feasible = length(pins) == 2
      service = if feasible, do: [%{"request_id" => "service", "value" => 10}], else: []

      {:ok, maintenance ++ service, [], %{},
       %{
         "planning_status" => if(feasible, do: "supported", else: "violated"),
         "model_evaluation_count" => 0
       }}
    end

    {opportunities, requests, assets, evaluate}
  end

  test "evaluates maintenance sets jointly when neither single activity restores feasibility" do
    {o, r, a, evaluate} = problem()
    policy = Policy.new!(Greedy, max_trials: 1, maintenance: config())

    assert {:ok, activities, _, _, report, search} =
             Maintenance.run(o, r, a, 0, policy, evaluate, &{:ok, &1})

    assert report["planning_status"] == "supported"
    assert Enum.count(activities, & &1["automatic_maintenance"]) == 2
    evidence = search["maintenance_search"]
    assert evidence["trial_count"] == 4

    assert Enum.map(evidence["trials"], & &1["planning_status"]) == [
             "violated",
             "violated",
             "violated",
             "supported"
           ]

    assert List.last(evidence["trials"])["enabled_service_request_ids"] == ["service"]
  end

  test "joint maintenance cannot exceed static budgets and each proposal is evaluated at most once" do
    {o, r, a, evaluate} = problem(1)
    policy = Policy.new!(Greedy, max_trials: 1, maintenance: config())
    counter = :counters.new(1, [])

    count = fn order, pins ->
      :counters.add(counter, 1, 1)
      evaluate.(order, pins)
    end

    assert {:ok, [], _, _, report, search} =
             Maintenance.run(o, r, a, 0, policy, count, &{:ok, &1})

    assert report["planning_status"] == "violated"
    assert :counters.get(counter, 1) == 3
    assert List.last(search["maintenance_search"]["trials"])["planning_status"] == "rejected"
    assert search["maintenance_search"]["selected_reservations"] == []
  end

  test "includes the latest start once even with mixed integer and floating controls" do
    {o, r, a, evaluate} = problem()
    [first | tail] = o
    o = [Map.put(first, "ends_at_s", 5) | tail]
    c = %{config() | "request_ids" => ["m1"], "candidate_step_s" => 5.0, "max_insertions" => 1}
    policy = Policy.new!(Greedy, max_trials: 1, maintenance: c)
    {:ok, _, _, _, _, search} = Maintenance.run(o, r, a, 0, policy, evaluate, &{:ok, &1})
    evidence = search["maintenance_search"]
    assert evidence["candidate_count"] == 2
    assert Enum.map(tl(evidence["trials"]), &hd(&1["reservations"])["starts_at_s"]) == [0.0, 3.0]
    # Fixed windows used to produce duplicate start/end candidates when the
    # grid expression was a float but the explicit latest start was an integer.
    c = %{c | "request_ids" => ["m2"]}
    policy = Policy.new!(Greedy, max_trials: 1, maintenance: c)
    {:ok, _, _, _, _, search} = Maintenance.run(o, r, a, 0, policy, evaluate, &{:ok, &1})
    assert search["maintenance_search"]["candidate_count"] == 1
  end

  test "strict controls and known zero-value request identities are required" do
    for {key, value} <- [
          {"max_trials", 0},
          {"max_insertions", 4},
          {"max_candidates", 65},
          {"candidate_step_s", 0},
          {"request_ids", ["m1", "m1"]}
        ] do
      assert_raise ArgumentError, fn -> Maintenance.validate!(Map.put(config(), key, value)) end
    end

    assert_raise ArgumentError, fn ->
      Policy.new!(Greedy, max_trials: 64, maintenance: config())
    end

    {o, r, a, evaluate} = problem()

    for ids <- [["missing"], ["service"]] do
      policy = Policy.new!(Greedy, max_trials: 1, maintenance: %{config() | "request_ids" => ids})

      assert_raise ArgumentError, fn ->
        Maintenance.run(o, r, a, 0, policy, evaluate, &{:ok, &1})
      end
    end
  end
end
