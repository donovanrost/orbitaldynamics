defmodule OrbitalDynamics.MissionAnalysis.Scheduling.AvailabilityTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, Scheduling.Availability}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference, as: Planner
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.IndependentPlanFixture, as: F

  defp inputs do
    m =
      ReferenceMission.load!("studies/automatic_wheel_maintenance.json")
      |> put_in(["requests", Access.at(1), "ends_at_s"], 820_497_695)

    {m, ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")}
  end

  defp outage(kind, ids, a, b),
    do: %{
      "id" => "outage",
      "asset_id" => "demo-3",
      "starts_at_s" => 820_497_600 + a,
      "ends_at_s" => 820_497_600 + b,
      "scope" =>
        if(kind == "all_activities", do: %{"kind" => kind}, else: %{"kind" => kind, "ids" => ids})
    }

  defp calendar(outages), do: %{"time_scale" => "utc", "outages" => outages}
  defp with_calendar(s, outages), do: put_in(s, ["scheduling", "availability"], calendar(outages))

  defp change(id, availability, protect \\ []),
    do: %{
      "revision_id" => id,
      "protect_request_ids" => protect,
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1, "availability" => availability}
    }

  test "overlapping outages form a union with exact half-open restoration boundaries" do
    q = %{id: "r", activity_type: "service", duration_s: 4, time_scale: :utc}

    opportunity = %{
      "id" => "o",
      "asset_id" => "demo-3",
      "request_id" => "r",
      "starts_at_s" => 820_497_600,
      "ends_at_s" => 820_497_620,
      "sample_count" => 21
    }

    report = %{
      "asset_id" => "demo-3",
      "request_id" => "r",
      "status" => "opportunities_found",
      "opportunities" => [opportunity]
    }

    a = outage("all_activities", [], 5, 8)
    b = outage("activity_types", ["service"], 7, 12) |> Map.put("id", "second")

    [r] =
      Availability.apply(
        [report],
        Availability.validate!(calendar([b, a])),
        [%{id: "demo-3"}],
        [q],
        nil
      )

    assert Enum.map(
             r["opportunities"],
             &{&1["starts_at_s"] - 820_497_600, &1["ends_at_s"] - 820_497_600}
           ) == [{0, 5}, {12, 20}]

    assert r["source_opportunities"] == [opportunity]
    assert Enum.all?(r["opportunities"], &is_map(&1["availability_evidence"]))
  end

  test "service and maintenance-mode outages shift only matching activities and preserve resource evolution" do
    {m, s} = inputs()

    for {kind, ids, a, b, rid, expected} <- [
          {"activity_types", ["service"], 70, 75, "service", 75},
          {"modes", ["desaturate"], 20, 30, "unload", 30},
          {"all_activities", [], 20, 30, "unload", 30}
        ] do
      r = Planner.run!(m, with_calendar(s, [outage(kind, ids, a, b)]))
      assert r["attitude_planning"]["planning_status"] == "supported"
      selected = Enum.find(r["activities"], &(&1["request_id"] == rid))
      assert selected["starts_at_s"] == 820_497_600 + expected

      assert Checker.snapshot(Reference.create!(m, with_calendar(s, [outage(kind, ids, a, b)])))[
               "status"
             ] == "passed"
    end

    r = Planner.run!(m, with_calendar(s, [outage("modes", ["desaturate"], 20, 60)]))
    assert r["attitude_planning"]["planning_status"] == "violated"

    assert Enum.find(r["requests"], &(&1["request_id"] == "unload"))["reasons"] == [
             "no_available_opportunity"
           ]

    wheels =
      r["attitude_planning"]["resource_feasibility"]["assets"]["demo-3"]["models"]
      |> Enum.find(&(&1["id"] == "wheels"))

    assert_in_delta hd(wheels["levels"])["final_state"]["wheel_3_momentum_nms"], 2, 1.0e-8
  end

  test "revision can impose and restore intervals while protected work produces an explicit conflict" do
    {m, s} = inputs()
    base = Reference.create!(m, s)
    cal = calendar([outage("activity_types", ["service"], 70, 75)])
    revised = Reference.revise!(base, change("outage", cal))
    assert revised.review["status"] == "ready_for_review"

    assert Enum.find(revised.candidate_report["activities"], &(&1["request_id"] == "service"))[
             "starts_at_s"
           ] == 820_497_675

    conflict = Reference.revise!(base, change("pinned_outage", cal, ["service"]))

    assert conflict.review["status"] == "commitment_conflict" and
             conflict.revised_snapshot == :null

    assert hd(conflict.review["conflicts"])["kind"] == "protected_activity_unavailable"
    restored = Reference.revise!(revised.revised_snapshot, change("restored", calendar([])))
    assert restored.review["status"] == "ready_for_review"

    assert Enum.find(restored.candidate_report["activities"], &(&1["request_id"] == "service"))[
             "starts_at_s"
           ] == 820_497_670
  end

  test "advance retains calendar and detects a newly imposed outage on a protected activity" do
    {m, s} = inputs()
    snapshot = Reference.create!(m, with_calendar(s, [outage("modes", ["desaturate"], 20, 30)]))
    u = Prediction.update!(snapshot, 820_497_610)
    r = Advance.run!(snapshot, u)
    assert r.review["status"] == "ready_for_review"

    assert r.revised_snapshot["payload"]["inputs"]["study"]["scheduling"]["availability"] ==
             snapshot["payload"]["inputs"]["study"]["scheduling"]["availability"]

    u =
      u
      |> Map.put("protect_request_ids", ["service"])
      |> put_in(
        ["scheduling", "availability"],
        calendar([outage("activity_types", ["service"], 70, 75)])
      )

    assert Advance.run!(snapshot, u).review["status"] == "commitment_conflict"
  end

  test "a rehashed artifact cannot schedule inside a declared outage" do
    {m, s} = inputs()
    snapshot = Reference.create!(m, s)

    changed =
      put_in(
        snapshot,
        ["payload", "inputs", "study", "scheduling", "availability"],
        calendar([outage("activity_types", ["service"], 70, 75)])
      )
      |> F.bind()

    r = Checker.snapshot(changed)
    assert r["status"] == "failed"
    assert Enum.any?(r["issues"], &(&1["code"] == "availability_conflict"))
    refute Enum.any?(r["issues"], &(&1["code"] == "snapshot_content_identity"))
  end

  test "operations replay preserves eligibility calendar through execution and independent checking" do
    {m, s} = inputs()

    script =
      ReferenceMission.load!("studies/automatic_wheel_maintenance_operations.json")
      |> put_in(
        ["steps", Access.at(1), "change", "scheduling", "availability"],
        calendar([outage("modes", ["desaturate"], 20, 30)])
      )

    Process.put(:availability_files, %{})

    r =
      Scenario.run!(m, s, script, fn name, v ->
        Process.put(:availability_files, Map.put(Process.get(:availability_files), name, v))
      end)

    assert r["verification_status"] == "passed" and r["run_status"] == "completed"
    assert Operations.validate(r, F.load(Process.get(:availability_files)))["status"] == "passed"
  end

  test "malformed intervals and unknown asset, mode or time-scale references cannot be used" do
    {m, s} = inputs()
    valid = outage("all_activities", [], 20, 30)

    assert_raise ArgumentError, fn ->
      Availability.validate!(calendar([%{valid | "ends_at_s" => valid["starts_at_s"]}]))
    end

    assert_raise ArgumentError, fn -> Availability.validate!(calendar([valid, valid])) end

    for cal <- [
          calendar([%{valid | "asset_id" => "missing"}]),
          calendar([outage("modes", ["missing"], 20, 30)]),
          Map.put(calendar([valid]), "time_scale", "tai")
        ] do
      assert {:error, {:invalid_mission_analysis, _}} =
               Planner.run_profiled(m, put_in(s, ["scheduling", "availability"], cal))
    end
  end
end
