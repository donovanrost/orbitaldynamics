defmodule OrbitalDynamics.MissionAnalysis.Scheduling.WorkTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, Scheduling.Work}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Reference, as: Revision

  defp inputs,
    do:
      {ReferenceMission.load!("studies/automatic_wheel_maintenance.json"),
       ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")}

  setup_all do
    {m, s} = inputs()
    r = Reference.run!(m, s)
    {:ok, mission: m, study: s, report: r}
  end

  test "whole search counts include rejected candidate callbacks and endpoint verification",
       ctx do
    work = ctx.report["scheduling_search"]["work_accounting"]
    assert work["total_evaluations"] == Enum.sum(Map.values(work["counts"]))
    outer = ctx.report["scheduling_search"]["maintenance_search"]["trials"]

    for {kind, total} <- work["counts"] do
      assert Enum.sum(Enum.map(outer, & &1["work_counts"][kind])) == total
    end

    assert work["counts"]["endpoint"] > 0

    bad =
      put_in(
        ctx.study,
        ["path_constraints", "assets", "demo-3", "activity_modes", "unload"],
        "idle"
      )

    r = Reference.run!(ctx.mission, bad)
    work = r["scheduling_search"]["work_accounting"]
    failed = Enum.filter(work["trials"], &(&1["outcome"] == "failed"))
    assert failed != []
    assert Enum.all?(failed, &(Enum.sum(Map.values(&1["counts"])) > 0))
    assert not Work.active?()
  end

  test "shared cap stops midway through a later candidate and keeps only a fully verified incumbent",
       ctx do
    after_repair =
      Enum.at(ctx.report["scheduling_search"]["work_accounting"]["trials"], 1)[
        "total_evaluations_after"
      ]

    # two verified endpoints per selected activity
    cap = after_repair + 4
    s = put_in(ctx.study, ["scheduling", "work_budget"], %{"max_evaluations" => cap})
    r = Reference.run!(ctx.mission, s)
    assert r["attitude_planning"]["planning_status"] == "supported"
    assert Enum.map(r["activities"], & &1["request_id"]) == ["unload", "service"]
    work = r["scheduling_search"]["work_accounting"]
    assert work["budget_exhausted"] and work["total_evaluations"] == cap
    assert List.last(work["trials"])["outcome"] == "failed"
    assert r["scheduling_search"]["maintenance_search"]["status"] == "work_budget_exhausted"
    snap = Revision.create!(ctx.mission, s)

    change = %{
      "revision_id" => "budget_inherited",
      "protect_request_ids" => [],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    child = Revision.revise!(snap, change)
    assert child.review["status"] == "ready_for_review"

    assert child.revised_snapshot["payload"]["inputs"]["study"]["scheduling"]["work_budget"] ==
             s["scheduling"]["work_budget"]
  end

  test "no verified baseline yields a typed budget failure with exact consumed work", ctx do
    s = put_in(ctx.study, ["scheduling", "work_budget"], %{"max_evaluations" => 1})

    assert {:error, {:planning_work_budget_exhausted, work}} =
             Reference.run_profiled(ctx.mission, s)

    assert work["total_evaluations"] == 1 and work["budget_exhausted"]
    assert not Work.active?()

    assert Reference.run!(ctx.mission, ctx.study)["scheduling_search"]["work_accounting"] ==
             ctx.report["scheduling_search"]["work_accounting"]
  end

  test "context restores after callback exceptions and rejected nested scopes" do
    assert_raise RuntimeError, fn -> Work.run(true, nil, fn -> raise "provider error" end) end
    refute Work.active?()

    assert_raise ArgumentError, fn ->
      Work.run(true, nil, fn -> Work.run(true, nil, fn -> :never end) end)
    end

    refute Work.active?()

    for invalid <- [%{}, %{"max_evaluations" => 0}, %{"max_evaluations" => 1, "extra" => 2}] do
      assert_raise ArgumentError, fn -> Work.validate!(invalid) end
    end
  end
end
