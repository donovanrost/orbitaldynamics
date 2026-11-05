defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.CheckerTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.IndependentPlanFixture, as: F
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}

  setup_all do
    {:ok, F.build()}
  end

  defp codes(r), do: Enum.map(r["issues"], & &1["code"])

  defp fails(s, code) do
    result = s |> F.bind() |> Checker.snapshot()
    assert result["status"] == "failed"
    assert code in codes(result)
    refute "snapshot_content_identity" in codes(result)
    result
  end

  test "native artifacts pass independent snapshot and full-chain accounting", ctx do
    for {name, s} <- ctx.snapshots do
      if Map.has_key?(s, "checkpoint_id") do
        parent =
          Map.values(ctx.snapshots)
          |> Enum.find(&(&1["snapshot_id"] == s["payload"]["parent_snapshot_id"]))

        {issues, _} =
          OrbitalDynamics.MissionAnalysis.PlanValidation.ExecutionCheckpoint.check(
            s,
            parent,
            s["payload"]["state_update"],
            name
          )

        assert issues == []
      else
        assert Checker.snapshot(s)["status"] == "passed"
      end
    end

    r = Operations.validate(ctx.operations, F.load(ctx.snapshots))
    assert r["status"] == "passed" and r["issues"] == []
    assert r["independent_execution_summary"] == ctx.operations["execution_summary"]

    battery =
      Checker.snapshot(ctx.snapshots["baseline_snapshot.json"])["expected_battery"]["demo-3"][
        "battery"
      ]

    # Two 20 s services at 360 W, no generation or other loads: 10 - 2 - 2 Wh.
    assert_in_delta battery["energy_wh"], 6, 1.0e-10
  end

  test "rehashed placement corruptions detect windows, duration, overlap and exact commitments",
       ctx do
    s = ctx.snapshots["step-01-revised_snapshot.json"]

    fails(
      update_in(s, ["payload", "report", "activities", Access.at(0), "ends_at_s"], &(&1 + 1)),
      "activity_duration"
    )

    shifted =
      s
      |> update_in(["payload", "report", "activities", Access.at(0), "starts_at_s"], &(&1 + 1))
      |> update_in(["payload", "report", "activities", Access.at(0), "ends_at_s"], &(&1 + 1))

    fails(shifted, "protected_placement")

    outside =
      put_in(s, ["payload", "report", "activities", Access.at(0), "starts_at_s"], 820_497_000)

    fails(outside, "request_window")
    [first, _] = s["payload"]["report"]["activities"]

    overlap =
      s
      |> put_in(
        ["payload", "report", "activities", Access.at(1), "starts_at_s"],
        first["starts_at_s"]
      )
      |> put_in(
        ["payload", "report", "activities", Access.at(1), "ends_at_s"],
        first["ends_at_s"]
      )

    fails(overlap, "asset_overlap")
    duplicate = update_in(s, ["payload", "report", "activities"], fn xs -> xs ++ [hd(xs)] end)
    fails(duplicate, "duplicate_request_id")
  end

  test "rehashed completed work cannot reappear as active demand", ctx do
    s = ctx.snapshots["step-03-revised_snapshot.json"]

    closed =
      Enum.find(
        s["payload"]["inputs"]["execution"]["closed_requests"],
        &(&1["status"] == "completed")
      )

    q = closed["request"]

    bad =
      s
      |> update_in(["payload", "inputs", "mission", "requests"], &(&1 ++ [q]))
      |> update_in(
        ["payload", "report", "requests"],
        &(&1 ++
            [
              %{
                "request_id" => q["id"],
                "value" => q["value"],
                "status" => "unfulfilled",
                "reasons" => []
              }
            ])
      )

    fails(bad, "closed_request_reintroduced")
  end

  test "static overspend and falsified battery aggregates fail even with valid content identities",
       ctx do
    s = ctx.snapshots["baseline_snapshot.json"]

    fails(
      put_in(
        s,
        [
          "payload",
          "inputs",
          "mission",
          "assets",
          Access.at(0),
          "resource_budgets",
          "service_tokens"
        ],
        1
      ),
      "static_budget_overspend"
    )

    bad =
      update_in(
        s,
        [
          "payload",
          "report",
          "attitude_planning",
          "resource_feasibility",
          "assets",
          "demo-3",
          "models",
          Access.at(0),
          "levels",
          Access.at(0),
          "final_state",
          "energy_wh"
        ],
        &(&1 + 0.25)
      )

    fails(bad, "battery_final_state")

    fails(
      put_in(
        s,
        ["payload", "report", "remaining_resource_budgets", "demo-3", "service_tokens"],
        1
      ),
      "static_balance"
    )
  end

  test "a consistent-looking final snapshot still cannot reset balances across execution cycles",
       ctx do
    child = ctx.snapshots["step-03-revised_snapshot.json"]
    u = child["payload"]["inputs"]["execution"]["last_update"]
    actual = u["assets"]["demo-3"]["resource_budgets"]["service_tokens"]
    false_balance = if actual > 0, do: actual - 1, else: actual + 1
    u = put_in(u, ["assets", "demo-3", "resource_budgets", "service_tokens"], false_balance)

    child =
      child
      |> put_in(
        [
          "payload",
          "inputs",
          "mission",
          "assets",
          Access.at(0),
          "resource_budgets",
          "service_tokens"
        ],
        false_balance
      )
      |> put_in(["payload", "inputs", "execution", "last_update"], u)
      |> put_in(["payload", "inputs", "execution", "state_update_sha256"], Checker.digest(u))
      |> put_in(
        ["payload", "report", "remaining_resource_budgets", "demo-3", "service_tokens"],
        false_balance
      )
      |> F.bind()

    assert Checker.snapshot(child)["status"] == "passed"
    changed = F.replace_final(ctx, child)

    report =
      update_in(changed.operations, ["steps", Access.at(-1), "state_update"], fn _ -> u end)

    result = Operations.validate(report, F.load(changed.snapshots))
    assert result["status"] == "failed"
    assert "execution_static_balance" in codes(result)
  end

  test "analytic accounting handles capacity clipping, efficiency and unmet bus demand", ctx do
    s = ctx.snapshots["baseline_snapshot.json"]

    base = [
      "payload",
      "inputs",
      "study",
      "resources",
      "assets",
      "demo-3",
      Access.at(0),
      "configuration"
    ]

    charged =
      s
      |> put_in(base ++ ["initial_wh"], 5)
      |> put_in(base ++ ["capacity_wh"], 6)
      |> put_in(base ++ ["reserve_wh"], 0)
      |> put_in(base ++ ["charge_efficiency"], 0.5)
      |> put_in(base ++ ["discharge_efficiency"], 0.5)
      |> put_in(base ++ ["generation"], %{"kind" => "constant", "power_w" => 360})
      |> put_in(
        [
          "payload",
          "inputs",
          "study",
          "path_constraints",
          "assets",
          "demo-3",
          "modes",
          "reflecting",
          "power_load_w"
        ],
        720
      )
      |> F.bind()
      |> Checker.snapshot()

    b = charged["expected_battery"]["demo-3"]["battery"]
    assert_in_delta b["energy_wh"], 6, 1.0e-10
    assert_in_delta b["minimum_energy_wh"], 2, 1.0e-10
    assert_in_delta b["curtailed_wh"], 38, 1.0e-10
    assert b["unserved_wh"] == 0
    # Old production aggregates have deliberately not been changed to these new inputs.
    assert "battery_final_state" in codes(charged)

    depleted =
      s
      |> put_in(base ++ ["initial_wh"], 0)
      |> put_in(base ++ ["reserve_wh"], 0)
      |> F.bind()
      |> Checker.snapshot()

    assert_in_delta depleted["expected_battery"]["demo-3"]["battery"]["unserved_wh"], 4, 1.0e-10
    assert "battery_supply" in codes(depleted)
  end

  test "source geometry and incomplete phase loads remain partial; declared phase loads are checked",
       ctx do
    s = ctx.snapshots["baseline_snapshot.json"]

    base = [
      "payload",
      "inputs",
      "study",
      "resources",
      "assets",
      "demo-3",
      Access.at(0),
      "configuration"
    ]

    solar =
      put_in(s, base ++ ["generation"], %{"kind" => "solar_array"})
      |> F.bind()
      |> Checker.snapshot()

    assert solar["status"] == "partial" and "battery_model_unsupported" in codes(solar)
    dynamic = put_in(s, base ++ ["phase_load_w", "brake"], 10) |> F.bind() |> Checker.snapshot()
    assert dynamic["status"] == "failed"
    refute "battery_model_unsupported" in codes(dynamic)
    assert "battery_final_state" in codes(dynamic)

    missing_phase =
      update_in(s, base ++ ["phase_load_w"], &Map.delete(&1, "settle"))
      |> F.bind()
      |> Checker.snapshot()

    assert missing_phase["status"] == "partial"
  end

  test "a falsified chronological summary cannot borrow the runner's passed checks", ctx do
    report =
      update_in(
        ctx.operations,
        ["steps", Access.at(0), "accepted_plan", "scheduled_value"],
        &(&1 + 100)
      )

    result = Operations.validate(report, F.load(ctx.snapshots))
    assert result["status"] == "failed"
    assert "accepted_plan_summary" in codes(result)
  end

  test "expected stopped operations remain partial rather than an independent operating-plan pass",
       ctx do
    alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
    input = ctx.snapshots["baseline_snapshot.json"]["payload"]["inputs"]
    first = hd(ctx.operations["script"]["steps"])

    stop = %{
      "id" => "blocked",
      "kind" => "revise",
      "expected_status" => "commitment_conflict",
      "change" => %{
        "revision_id" => "blocked",
        "protect_request_ids" => [],
        "add_requests" => [],
        "unavailable_asset_ids" => ["demo-3"],
        "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
      }
    }

    script = %{ctx.operations["script"] | "steps" => [first, stop]}
    Process.put(:stopped_validation_artifacts, %{})

    report =
      Scenario.run!(input["mission"], input["study"], script, fn name, value ->
        Process.put(
          :stopped_validation_artifacts,
          Map.put(Process.get(:stopped_validation_artifacts), name, value)
        )
      end)

    assert report["verification_status"] == "passed"
    result = Operations.validate(report, F.load(Process.get(:stopped_validation_artifacts)))
    assert result["status"] == "partial"
    assert Enum.all?(result["issues"], &(&1["severity"] == "unsupported"))
    assert "stopped_operations" in codes(result)
  end

  test "checksum errors, missing chain files and malformed inputs cannot pass", ctx do
    s = ctx.snapshots["baseline_snapshot.json"]

    assert "snapshot_content_identity" in codes(
             Checker.snapshot(Map.put(s, "content_sha256", "wrong"))
           )

    for malformed <- [:null, %{}, put_in(s, ["payload", "report", "activities"], "bad")] do
      assert Checker.snapshot(malformed)["status"] == "failed"
    end

    missing = Map.delete(ctx.snapshots, "step-02-execution_snapshot.json")
    assert Operations.validate(ctx.operations, F.load(missing))["status"] == "failed"
  end
end
