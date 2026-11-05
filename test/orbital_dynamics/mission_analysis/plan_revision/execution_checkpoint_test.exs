defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.ExecutionCheckpointTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission, as: M

  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{
    Reference,
    Advance,
    Prediction,
    ExecutionCheckpoint,
    Snapshot
  }

  setup_all do
    root =
      Reference.create!(
        M.load!("studies/thermal_cooldown_reference.json"),
        M.load!("studies/thermal_cooldown_planning.json")
      )

    {:ok, root: root}
  end

  test "accepted checkpoint survives failed planning and retries without changing state or charging costs twice",
       c do
    u =
      Prediction.update!(c.root, 820_497_675)
      |> put_in(["scheduling", "work_budget"], %{"max_evaluations" => 1})

    accepted = Advance.accept!(c.root, u)
    cp = accepted.execution_checkpoint
    assert is_map(cp)
    assert cp == Advance.accept!(c.root, u).execution_checkpoint

    assert cp["payload"]["inputs"]["mission"]["assets"]
           |> hd()
           |> get_in(["resource_budgets", "service_tokens"]) == 0

    failed = Advance.plan!(c.root, cp)
    assert failed.review["status"] == "planning_failed"
    assert failed.review["plan_readiness"] == "stale_pending_replan"
    assert failed.revised_snapshot == :null
    assert failed.execution_checkpoint == cp

    retry =
      Advance.plan!(c.root, cp, %{
        "attempt_id" => "retry",
        "scheduling" => %{
          "strategy" => "greedy",
          "max_trials" => 1,
          "work_budget" => %{"max_evaluations" => 100_000}
        }
      })

    assert retry.review["status"] == "ready_for_review", inspect(retry.review)
    inputs = retry.revised_snapshot["payload"]["inputs"]
    assert inputs["execution"] == cp["payload"]["inputs"]["execution"]
    assert inputs["mission"]["assets"] == cp["payload"]["inputs"]["mission"]["assets"]
    assert inputs["study"]["saved_motion"] == cp["payload"]["inputs"]["study"]["saved_motion"]
    assert inputs["study"]["continuations"] == cp["payload"]["inputs"]["study"]["continuations"]
    assert inputs["execution_checkpoint_id"] == cp["checkpoint_id"]
    assert Reference.source!(retry.revised_snapshot) == inputs
    assert ExecutionCheckpoint.verify!(cp, c.root) == cp
  end

  test "coherent rehashing, wrong parent and attempts to alter state or constraints cannot bypass reconstruction",
       c do
    u = Prediction.update!(c.root, 820_497_660)
    cp = Advance.accept!(c.root, u).execution_checkpoint

    bad =
      put_in(
        cp,
        [
          "payload",
          "inputs",
          "mission",
          "assets",
          Access.at(0),
          "resource_budgets",
          "service_tokens"
        ],
        2
      )

    hash = Snapshot.digest(bad["payload"])

    bad =
      bad
      |> Map.put("content_sha256", hash)
      |> Map.put("checkpoint_id", "mission_execution_checkpoint:" <> hash)

    assert_raise ArgumentError, ~r/parent-derived/, fn -> Advance.plan!(c.root, bad) end

    another =
      Reference.revise!(c.root, %{
        "revision_id" => "new_parent",
        "protect_request_ids" => ["service"],
        "add_requests" => [],
        "unavailable_asset_ids" => [],
        "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
      }).revised_snapshot

    assert_raise ArgumentError, ~r/different parent/, fn -> Advance.plan!(another, cp) end

    for controls <- [
          %{"availability" => %{"time_scale" => "utc", "outages" => []}},
          %{"assets" => %{}},
          %{"protected_activities" => []}
        ] do
      assert_raise ArgumentError, fn ->
        Advance.plan!(c.root, cp, %{
          "attempt_id" => "bad",
          "scheduling" => Map.merge(%{"strategy" => "greedy", "max_trials" => 1}, controls)
        })
      end
    end
  end

  test "stale state is rejected without a checkpoint but physically out-of-limit state is retained",
       c do
    u = Prediction.update!(c.root, 820_497_660)
    stale = put_in(u, ["assets", "demo-3", "quality", "valid_until_s"], 820_497_659)
    assert Advance.accept!(c.root, stale).execution_checkpoint == :null
    low = put_in(u, ["assets", "demo-3", "battery_energy_wh", "battery"], 1)
    cp = Advance.accept!(c.root, low).execution_checkpoint
    assert is_map(cp)
    result = Advance.plan!(c.root, cp)
    assert result.revised_snapshot == :null
    assert result.execution_checkpoint == cp
  end
end
