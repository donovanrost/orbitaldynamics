defmodule OrbitalDynamics.MissionAnalysis.Scheduling.SearchTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.Scheduling
  alias OrbitalDynamics.MissionAnalysis.Scheduling.{Policy, Greedy, Reassignment, Reference}
  alias OrbitalDynamics.MissionAnalysis.AssignmentQualityCases

  defmodule Forged do
    @behaviour OrbitalDynamics.MissionAnalysis.Scheduling.Strategy
    def propose(p, _, _, _),
      do:
        {:candidate, [Map.put(hd(p.opportunities), "ends_at_s", 999) | tl(p.opportunities)], %{},
         nil}
  end

  defp problem do
    opportunities =
      for {id, r, asset} <- [{"ha", "high", "a"}, {"hb", "high", "b"}, {"la", "low", "a"}],
          do: %{
            "id" => id,
            "request_id" => r,
            "asset_id" => asset,
            "starts_at_s" => 0,
            "ends_at_s" => 10
          }

    {opportunities, [%{id: "high", value: 10}, %{id: "low", value: 9}]}
  end

  defp evaluate(order) do
    if hd(order)["asset_id"] == "a",
      do: {:ok, [%{"request_id" => "high", "asset_id" => "a", "value" => 10}], [], %{}, nil},
      else:
        {:ok,
         [
           %{"request_id" => "high", "asset_id" => "b", "value" => 10},
           %{"request_id" => "low", "asset_id" => "a", "value" => 9}
         ], [], %{}, nil}
  end

  test "bounded reassignment closes the exact 10/19 assignment gap" do
    policy = Policy.new!(Reassignment, max_trials: 4)
    cases = AssignmentQualityCases.run!(policy)
    assert cases == AssignmentQualityCases.run!(policy)
    assert Enum.all?(cases, &(&1["absolute_gap"] == 0))
    trap = Enum.find(cases, &(&1["id"] == "flexible_request_trap"))
    assert trap["planner_value"] == trap["optimal_value"]
    assert trap["planner_value"] == 19
  end

  test "trial cap includes baseline, returns incumbent and does not call another evaluator" do
    {os, rs} = problem()

    evaluate = fn order ->
      send(self(), :evaluated)
      evaluate(order)
    end

    assert {:ok, [_], _, _, _, report} =
             Scheduling.run(os, rs, evaluate, Policy.new!(Reassignment, max_trials: 1))

    assert report["trial_count"] == 1
    assert report["status"] == "trial_limit_reached"
    assert report["baseline_value"] == report["final_value"]
    assert_received :evaluated
    refute_received :evaluated
  end

  test "no-policy greedy output is unchanged; explicit greedy records only one trial" do
    {os, rs} = problem()
    assert {:ok, a, d, b, r, nil} = Scheduling.run(os, rs, &evaluate/1, nil)

    assert {:ok, ^a, ^d, ^b, ^r, report} =
             Scheduling.run(os, rs, &evaluate/1, Policy.new!(Greedy, max_trials: 4))

    assert report["trial_count"] == 1
    assert report["status"] == "greedy_complete"
  end

  test "an ineligible endpoint cannot replace the verified incumbent, and provider failures abort" do
    {os, rs} = problem()
    verify = fn a -> if length(a) == 2, do: {:invalid, :endpoint_ineligible}, else: {:ok, a} end

    assert {:ok, [_], _, _, _, report} =
             Scheduling.run(os, rs, &evaluate/1, Policy.new!(Reassignment, max_trials: 3), verify)

    assert report["final_value"] == 10
    assert List.last(report["trials"])["reason"] == "endpoint_ineligible"
    verify = fn a -> if length(a) == 2, do: {:error, :endpoint_provider_down}, else: {:ok, a} end

    assert {:error, :endpoint_provider_down} =
             Scheduling.run(os, rs, &evaluate/1, Policy.new!(Reassignment, max_trials: 3), verify)

    assert {:error, :bad_baseline} =
             Scheduling.run(os, rs, &evaluate/1, Policy.new!(Reassignment, max_trials: 3), fn _ ->
               {:invalid, :bad_baseline}
             end)
  end

  test "unknown or violated fleet evidence cannot win even with greater value" do
    {os, rs} = problem()

    for status <- ["unknown", "violated"] do
      evaluate = fn order ->
        {:ok, a, d, b, _} = evaluate(order)

        report = %{
          "planning_status" => if(length(a) == 2, do: status, else: "supported"),
          "model_evaluation_count" => 7,
          "resource_feasibility" => %{"model_evaluation_count" => 3}
        }

        {:ok, a, d, b, report}
      end

      assert {:ok, [_], _, _, _, report} =
               Scheduling.run(os, rs, evaluate, Policy.new!(Reassignment, max_trials: 3))

      assert report["final_value"] == 10
      assert List.last(report["trials"])["reason"] == "unsupported_candidate"
      assert report["total_model_evaluation_counts"]["attitude_model_evaluation_count"] == 14
      assert report["total_model_evaluation_counts"]["resource_model_evaluation_count"] == 6
    end
  end

  test "an improved value cannot sacrifice an incumbent served request" do
    {os, rs} = problem()

    evaluate = fn order ->
      if hd(order)["asset_id"] == "a",
        do: evaluate(order),
        else:
          {:ok, [%{"request_id" => "replacement", "asset_id" => "b", "value" => 100}], [], %{},
           nil}
    end

    assert {:ok, [_], _, _, _, report} =
             Scheduling.run(os, rs, evaluate, Policy.new!(Reassignment, max_trials: 3))

    assert report["final_value"] == 10
    assert List.last(report["trials"])["reason"] == "lost_served_request"
  end

  test "trial provider errors abort and forged opportunities never reach the evaluator" do
    {os, rs} = problem()

    evaluate = fn order ->
      if hd(order)["asset_id"] == "b", do: {:error, :source_down}, else: evaluate(order)
    end

    assert {:error, :source_down} =
             Scheduling.run(os, rs, evaluate, Policy.new!(Reassignment, max_trials: 3))

    assert_raise ArgumentError, ~r/permutation/, fn ->
      Scheduling.run(os, rs, &evaluate/1, Policy.new!(Forged, max_trials: 3))
    end
  end

  test "controls are bounded and JSON cannot name arbitrary modules" do
    for cap <- [0, 65, 1.5, :infinity],
        do: assert_raise(ArgumentError, fn -> Policy.new!(Reassignment, max_trials: cap) end)

    assert_raise ArgumentError, fn ->
      Reference.policy!(%{"strategy" => "System", "max_trials" => 2})
    end

    assert_raise ArgumentError, fn -> Policy.new!(Reassignment, max_trials: 2, max_trials: 3) end
  end
end
