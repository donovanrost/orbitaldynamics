defmodule OrbitalDynamics.MissionAnalysis.Scheduling.MaintenanceReferenceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference, as: Planner
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Operations

  defp inputs do
    {ReferenceMission.load!("studies/automatic_wheel_maintenance.json"),
     ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")}
  end

  defp search(r), do: r["scheduling_search"]["maintenance_search"]
  defp supported?(r), do: r["attitude_planning"]["planning_status"] == "supported"

  test "repairs saturation with a planner-selected costed unload and enables service" do
    {m, s} = inputs()
    r = Planner.run!(m, s)
    assert supported?(r)
    assert [unload, service] = r["activities"]
    assert unload["request_id"] == "unload" and unload["automatic_maintenance"]
    refute Map.has_key?(unload, "protected")
    assert service["request_id"] == "service"
    assert unload["resource_costs"] == %{"unload_tokens" => 1}
    assert unload["starts_at_s"] == m["epoch_s"] + 20
    [baseline, repair | _] = search(r)["trials"]
    assert baseline["planning_status"] == "violated" and baseline["service_value"] == 0
    assert repair["accepted"] and repair["enabled_service_request_ids"] == ["service"]
    assert search(r)["status"] == "candidate_sets_exhausted"

    explanation =
      OrbitalDynamics.MissionAnalysis.Scheduling.Explanation.from_report!(r, "service")

    assert explanation["search"]["maintenance_search"]["trial_count"] == search(r)["trial_count"]

    assert IO.iodata_to_binary(
             OrbitalDynamics.MissionAnalysis.Scheduling.Explanation.markdown(explanation)
           ) =~ "Maintenance search"

    snap = Reference.create!(m, s)
    u = Prediction.update!(snap, m["epoch_s"] + 90)
    assert_in_delta u["assets"]["demo-3"]["battery_energy_wh"]["battery"], 9.927777777778, 1.0e-8
    assert_in_delta Enum.at(u["assets"]["demo-3"]["wheel_momentum_nms"]["wheels"], 2), 0.7, 1.0e-8
  end

  test "declared duration alternatives are evaluated, not treated as interchangeable" do
    {m, s} = inputs()
    short = hd(m["requests"]) |> Map.put("id", "a_short") |> Map.put("duration_s", 10)
    m = Map.update!(m, "requests", &[short | &1])

    s =
      put_in(
        s,
        ["path_constraints", "assets", "demo-3", "activity_modes", "a_short"],
        "desaturate"
      )
      |> put_in(["scheduling", "maintenance", "request_ids"], ["a_short", "unload"])

    r = Planner.run!(m, s)
    assert supported?(r)
    assert Enum.map(r["activities"], & &1["request_id"]) == ["unload", "service"]

    assert Enum.any?(search(r)["trials"], fn t ->
             Enum.any?(t["reservations"], &(&1["request_id"] == "a_short")) and not t["accepted"]
           end)
  end

  test "no gratuitous unload when the original service plan is already feasible" do
    {m, s} = inputs()

    s =
      put_in(
        s,
        [
          "resources",
          "assets",
          "demo-3",
          Access.at(1),
          "configuration",
          "disturbance_torque_body_nm"
        ],
        [0, 0, 0]
      )

    r = Planner.run!(m, s)
    assert supported?(r)
    assert Enum.map(r["activities"], & &1["request_id"]) == ["service"]
    assert search(r)["selected_reservations"] == []
  end

  test "unavailable, too late, incorrectly mode-gated or unaffordable unloading cannot repair the plan" do
    {m, s} = inputs()
    zero = put_in(m, ["assets", Access.at(0), "resource_budgets", "unload_tokens"], 0)

    expensive =
      put_in(
        s,
        ["path_constraints", "assets", "demo-3", "modes", "desaturate", "power_load_w"],
        2000
      )

    wrong =
      put_in(s, ["path_constraints", "assets", "demo-3", "activity_modes", "unload"], "idle")

    late =
      m
      |> put_in(["requests", Access.at(0), "starts_at_s"], m["epoch_s"] + 55)
      |> put_in(["requests", Access.at(0), "ends_at_s"], m["epoch_s"] + 75)

    for {mission, study, opts} <- [
          {zero, s, []},
          {m, expensive, []},
          {m, wrong, []},
          {late, s, []},
          {m, s, [service_unavailable_asset_ids: ["demo-3"]]}
        ] do
      r = Planner.run!(mission, study, opts)
      refute supported?(r)
      assert search(r)["selected_reservations"] == []
      refute Enum.any?(r["activities"], & &1["automatic_maintenance"])
    end
  end

  test "trial and candidate caps are explicit and deterministic" do
    {m, s} = inputs()
    one = put_in(s, ["scheduling", "maintenance", "max_trials"], 1)
    r = Planner.run!(m, one)
    refute supported?(r)
    assert search(r)["trial_count"] == 1 and search(r)["status"] == "trial_limit_reached"
    limited = put_in(s, ["scheduling", "maintenance", "max_candidates"], 1)
    r = Planner.run!(m, limited)
    assert supported?(r)
    assert search(r)["candidate_generation_truncated"]
    assert search(r)["candidate_count"] == 1
    assert r == Planner.run!(m, limited)
  end

  test "joint reservations preserve a protected service even when the baseline alone fails" do
    {m, s} = inputs()

    s =
      put_in(s, ["scheduling", "protected_activities"], [
        %{
          "request_id" => "service",
          "asset_id" => "demo-3",
          "starts_at_s" => m["epoch_s"] + 70,
          "ends_at_s" => m["epoch_s"] + 80
        }
      ])

    r = Planner.run!(m, s)
    assert supported?(r)
    assert Enum.find(r["activities"], &(&1["request_id"] == "service"))["protected"]
    assert hd(search(r)["trials"])["planning_status"] == "rejected"
  end

  test "maintenance survives revisions and is archived without replay after completion" do
    {m, s} = inputs()
    snapshot = Reference.create!(m, s)
    early = Advance.run!(snapshot, Prediction.update!(snapshot, m["epoch_s"] + 10))
    assert early.review["status"] == "ready_for_review"
    child = early.revised_snapshot

    assert child["payload"]["inputs"]["study"]["scheduling"]["maintenance"]["request_ids"] == [
             "unload"
           ]

    change = %{
      "revision_id" => "retain_maintenance",
      "protect_request_ids" => [],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    revision = Reference.revise!(child, change)
    assert revision.review["status"] == "ready_for_review"
    assert search(revision.candidate_report)["selected_reservations"] != []

    next =
      Advance.run!(
        revision.revised_snapshot,
        Prediction.update!(revision.revised_snapshot, m["epoch_s"] + 60)
      )

    assert next.review["status"] == "ready_for_review"

    refute Map.has_key?(
             next.revised_snapshot["payload"]["inputs"]["study"]["scheduling"],
             "maintenance"
           )

    assert Enum.map(next.candidate_report["activities"], & &1["request_id"]) == ["service"]
  end

  test "execution replay and independent structural checks agree across maintenance replanning" do
    {m, s} = inputs()
    script = ReferenceMission.load!("studies/automatic_wheel_maintenance_operations.json")
    Process.put(:maintenance_files, %{})

    r =
      Scenario.run!(m, s, script, fn name, value ->
        Process.put(:maintenance_files, Map.put(Process.get(:maintenance_files), name, value))
      end)

    assert r["verification_status"] == "passed" and r["run_status"] == "completed"
    files = Process.get(:maintenance_files)
    validation = Operations.validate(r, &Map.fetch(files, &1))
    assert validation["status"] == "passed"
    assert Enum.all?(validation["issues"], &(&1["severity"] == "unsupported"))
  end
end
