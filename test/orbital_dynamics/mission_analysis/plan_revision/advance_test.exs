defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.AdvanceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Advance, Reference, Snapshot, Prediction}
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Commitments

  setup_all do
    mission = ReferenceMission.load!("studies/rolling_state_reference.json")
    study = ReferenceMission.load!("studies/rolling_state_planning.json")
    snapshot = Reference.create!(mission, study)
    [early, late] = snapshot["payload"]["report"]["activities"]
    update = Prediction.update!(snapshot, early["ends_at_s"])
    {:ok, snapshot: snapshot, update: update, early: early, late: late}
  end

  test "predicted state advances the boundary, archives completion and rechecks an exact future commitment",
       %{snapshot: s, update: u, late: late} do
    bytes = :json.encode(s)
    r = Advance.run!(s, %{u | "protect_request_ids" => ["late-1"]})
    assert r.review["status"] == "ready_for_review"
    child = r.revised_snapshot
    assert child["payload"]["parent_snapshot_id"] == s["snapshot_id"]
    inputs = child["payload"]["inputs"]
    assert inputs["mission"]["epoch_s"] == s["payload"]["inputs"]["mission"]["epoch_s"]
    assert inputs["study"]["horizon"]["starts_at_s"] == u["as_of_s"]

    assert inputs["study"]["horizon"]["ends_at_s"] ==
             s["payload"]["inputs"]["study"]["horizon"]["ends_at_s"]

    assert Enum.map(inputs["mission"]["requests"], & &1["id"]) == ["late-1"]

    assert inputs["mission"]["assets"] |> hd() |> Map.fetch!("resource_budgets") == %{
             "service_tokens" => 1.0
           }

    assert_in_delta get_in(inputs, ["study", "resources", "assets", "demo-3"])
                    |> hd()
                    |> get_in(["configuration", "initial_wh"]),
                    8.0,
                    1.0e-10

    assert [%{"status" => "completed", "request" => %{"id" => "early-3"}}] =
             inputs["execution"]["closed_requests"]

    assert Reference.source!(child) == inputs

    assert Commitments.intact?(r.candidate_report["activities"], [
             Map.take(late, ~w(request_id asset_id starts_at_s ends_at_s))
           ])

    assert r.review["diff"]["counts"]["unchanged"] == 1
    assert r.review["diff"]["counts"]["removed"] == 0
    assert r.review["diff"]["baseline_value"] == late["value"]
    assert :json.encode(s) == bytes
    assert Snapshot.verify!(child) == child
    # A later same-horizon revision keeps both the ledger and inherited commitment.
    change = %{
      "revision_id" => "same_boundary",
      "protect_request_ids" => [],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    next = Reference.revise!(child, change)
    assert next.review["status"] == "ready_for_review"
    assert next.revised_snapshot["payload"]["inputs"]["execution"] == inputs["execution"]

    assert Commitments.intact?(
             next.candidate_report["activities"],
             r.review["protected_activities"]
           )

    # Finish the remaining commitment: all requests close, but idle/path/resource coverage remains.
    done = Prediction.update!(next.revised_snapshot, late["ends_at_s"])
    final = Advance.run!(next.revised_snapshot, done)
    assert final.review["status"] == "ready_for_review"
    assert final.candidate_report["activities"] == [] and final.candidate_report["requests"] == []

    assert length(final.revised_snapshot["payload"]["inputs"]["execution"]["closed_requests"]) ==
             2

    assert final.candidate_report["attitude_planning"]["planning_status"] == "supported"
    assert Reference.source!(final.revised_snapshot)
    # Archived identities cannot be added again in a subsequent revision.
    early_request = hd(s["payload"]["inputs"]["mission"]["requests"])

    assert_raise ArgumentError, ~r/already exists/, fn ->
      Reference.revise!(final.revised_snapshot, %{
        change
        | "add_requests" => [
            %{"request" => early_request, "activity_modes" => %{"demo-3" => "reflecting"}}
          ]
      })
    end
  end

  test "lower battery changes tentative work, and cannot silently drop the same work when committed",
       %{snapshot: s, update: u} do
    low = put_in(u, ["assets", "demo-3", "battery_energy_wh", "battery"], 2.5)
    r = Advance.run!(s, low)
    assert r.review["status"] == "ready_for_review"
    assert r.candidate_report["activities"] == []
    [request] = r.candidate_report["requests"]
    assert request["request_id"] == "late-1" and request["status"] == "unfulfilled"
    assert request["scheduling_summary"]["attempt_reasons"]["resource_feasibility_violated"] > 0
    assert r.review["diff"]["counts"]["removed"] == 1
    assert r.review["diff"]["baseline_value"] == 22 and r.review["diff"]["revised_value"] == 0
    committed = Advance.run!(s, %{low | "protect_request_ids" => ["late-1"]})
    assert committed.review["status"] == "commitment_conflict"
    assert committed.revised_snapshot == :null
    assert hd(committed.review["conflicts"])["placement"]["request_id"] == "late-1"
  end

  test "inherited future commitments are rechecked from the updated state", %{
    snapshot: s,
    update: u,
    late: late
  } do
    pin = Map.take(late, ~w(request_id asset_id starts_at_s ends_at_s))
    input = s["payload"]["inputs"]

    study =
      Map.put(input["study"], "scheduling", %{
        "strategy" => "greedy",
        "max_trials" => 1,
        "protected_activities" => [pin]
      })

    baseline = Reference.create!(input["mission"], study)
    update = Prediction.update!(baseline, u["as_of_s"]) |> Map.put("protect_request_ids", [])
    update = put_in(update, ["assets", "demo-3", "battery_energy_wh", "battery"], 2.5)
    r = Advance.run!(baseline, update)
    assert r.review["status"] == "commitment_conflict" and r.revised_snapshot == :null
    assert r.review["protected_activities"] == Commitments.normalize!([pin])
  end

  test "unconfirmed in-progress work and unknown past execution produce explicit reviews without planning",
       %{
         snapshot: s,
         update: u,
         early: early
       } do
    never = fn _, _, _ -> flunk("preflight reached planner") end
    active = %{u | "as_of_s" => early["starts_at_s"] + 1, "completed_request_ids" => []}
    r = Advance.run!(s, active, never)
    assert r.review["status"] == "in_progress_state_incomplete" and r.revised_snapshot == :null
    missing = Advance.run!(s, %{u | "completed_request_ids" => []}, never)

    assert missing.review["status"] == "execution_history_incomplete" and
             missing.revised_snapshot == :null

    skipped =
      Advance.run!(s, %{
        u
        | "completed_request_ids" => [],
          "not_executed_request_ids" => ["early-3"]
      })

    assert skipped.review["status"] == "ready_for_review"

    assert Enum.any?(
             skipped.revised_snapshot["payload"]["inputs"]["mission"]["requests"],
             &(&1["id"] == "early-3")
           )

    assert skipped.revised_snapshot["payload"]["inputs"]["execution"]["closed_requests"] == []
  end

  test "expired skipped requests close separately from confirmed completions", %{
    snapshot: s,
    late: late
  } do
    u = Prediction.update!(s, late["ends_at_s"])
    u = %{u | "completed_request_ids" => [], "not_executed_request_ids" => ["early-3", "late-1"]}
    r = Advance.run!(s, u)
    assert r.review["status"] == "ready_for_review"

    assert [%{"status" => "expired", "request" => %{"id" => "early-3"}}] =
             r.review["closed_requests"]

    assert Enum.map(r.revised_snapshot["payload"]["inputs"]["mission"]["requests"], & &1["id"]) ==
             ["late-1"]
  end

  test "unknown or budget-limited commitment checks never masquerade as an infeasibility conflict",
       %{snapshot: s, update: u} do
    u = %{u | "protect_request_ids" => ["late-1"]}

    for reason <- [
          {:protected_activity_unknown, "late-1", :profile_sample_limit},
          {:protected_resources_unknown, "demo-3", %{"status" => "unknown"}}
        ] do
      r = Advance.run!(s, u, fn _, _, _ -> {:error, reason} end)
      assert r.review["status"] == "unsupported_revision" and r.revised_snapshot == :null
      assert r.review["planning_failure_category"] == "unknown_feasibility"
    end

    for reason <- [
          {:protected_activity_evaluation_failed, "late-1",
           :attitude_evaluation_budget_exhausted},
          {:protected_resources_evaluation_failed, "demo-3",
           :resource_evaluation_budget_exhausted},
          {:protected_activity_unsupported, "late-1", :path_evaluation_budget_exhausted}
        ] do
      r = Advance.run!(s, u, fn _, _, _ -> {:error, reason} end)
      assert r.review["status"] == "planning_failed" and r.revised_snapshot == :null
      assert r.review["planning_failure_category"] == "evaluation_budget_exhausted"
      assert r.review["conflicts"] == []
    end
  end

  test "a newly content-bound snapshot still rejects inconsistent execution history", %{
    snapshot: s,
    update: u
  } do
    child = Advance.run!(s, u).revised_snapshot
    inputs = child["payload"]["inputs"]

    for bad <- [
          put_in(inputs, ["execution", "closed_requests"], []),
          put_in(inputs, ["execution", "as_of_s"], u["as_of_s"] + 1)
        ] do
      forged =
        Snapshot.new!(bad, child["payload"]["report"], child["payload"]["parent_snapshot_id"])

      assert_raise ArgumentError, ~r/execution ledger/, fn -> Reference.source!(forged) end
    end
  end

  test "incomplete, stale, misframed or physically malformed updates fail before planning", %{
    snapshot: s,
    update: u,
    late: late
  } do
    bads = [
      Map.delete(u, "assets"),
      %{u | "assets" => %{}},
      %{u | "expected_baseline_id" => "wrong"},
      %{u | "time_scale" => "tai"},
      %{u | "frame" => "body_fixed"},
      %{u | "as_of_s" => s["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]},
      %{u | "as_of_s" => s["payload"]["inputs"]["study"]["horizon"]["ends_at_s"]},
      %{u | "completed_request_ids" => ["late-1"]},
      %{u | "completed_request_ids" => ["early-3", "early-3"]},
      %{u | "not_executed_request_ids" => ["early-3"]},
      %{u | "protect_request_ids" => ["early-3"]},
      put_in(u, ["assets", "demo-3", "quaternion_wxyz"], [2, 0, 0, 0]),
      put_in(u, ["assets", "demo-3", "angular_velocity_inertial_deg_s"], [0, 0]),
      put_in(u, ["assets", "demo-3", "battery_energy_wh"], %{}),
      put_in(u, ["assets", "demo-3", "battery_energy_wh", "battery"], 11),
      put_in(u, ["assets", "demo-3", "resource_budgets", "service_tokens"], 3),
      put_in(u, ["assets", "demo-3", "resource_budgets", "service_tokens"], 2),
      Map.put(u, "horizon", %{})
    ]

    for bad <- bads,
        do:
          assert_raise(ArgumentError, fn ->
            Advance.run!(s, bad, fn _, _, _ -> flunk("invalid update reached planner") end)
          end)

    assert_raise ArgumentError, ~r/exact supported resource-state sample/, fn ->
      Prediction.update!(s, late["starts_at_s"] - 0.12345)
    end
  end
end
