defmodule OrbitalDynamics.MissionAnalysis.Attitude.RigidBodyReferenceTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference, as: Planner
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Snapshot}
  alias OrbitalDynamics.MissionAnalysis.Scheduling.Explanation

  setup_all do
    mission = ReferenceMission.load!("studies/rolling_state_reference.json")
    strong = ReferenceMission.load!("studies/rigid_body_planning.json")
    weak = ReferenceMission.load!("studies/rigid_body_limited_planning.json")
    supported = Planner.run!(mission, strong)
    limited = Planner.run!(mission, weak)
    {:ok, mission: mission, strong: strong, weak: weak, supported: supported, limited: limited}
  end

  test "optional reference model screens tracking, acquisition, between-service and terminal motions",
       %{supported: r} do
    assert length(r["activities"]) == 2
    assert r["attitude_planning"]["planning_status"] == "supported"

    for a <- r["activities"], p <- a["attitude_profile"] do
      assert p["rigid_body_torque"]["status"] == "supported"
      assert p["rigid_body_torque"]["frame"] == "body_principal_axes"
    end

    for t <- r["attitude_planning"]["transitions"],
        do: assert(t["rigid_body_torque"]["status"] == "supported")

    assert get_in(r, [
             "attitude_planning",
             "horizon_coverage",
             "assets",
             "demo-3",
             "terminal_motion",
             "rigid_body_torque",
             "status"
           ]) == "supported"
  end

  test "torque-limited opportunities remain physically available but unfulfilled with numeric torque explanations",
       %{limited: r, supported: normal} do
    assert r["activities"] == []
    assert r["opportunities"] == normal["opportunities"]
    assert r["attitude_planning"]["planning_status"] == "supported"

    for request <- r["requests"] do
      assert request["status"] == "unfulfilled"
      e = Explanation.from_report!(r, request["request_id"])

      assert Enum.any?(
               e["summary"]["constraint_issues"],
               &(&1["kind"] == "rigid_body_torque" and &1["margin_unit"] == "Nm" and
                   &1["margin"] < 0)
             )

      assert Enum.any?(e["placements"], fn p ->
               Enum.any?(
                 p["attempts"],
                 &(get_in(&1, ["incoming", "rigid_body_torque", "status"]) == "violated")
               )
             end)
    end
  end

  test "an exact protected placement cannot bypass torque checks and its conflict retains torque evidence",
       %{mission: m, weak: study, supported: high, strong: strong} do
    a = hd(high["activities"])
    pin = Map.take(a, ~w(request_id asset_id starts_at_s ends_at_s))
    study = put_in(study, ["scheduling", "protected_activities"], [pin])

    assert {:error,
            {:protected_activity_unsupported, _,
             {:rigid_body_torque_exceeds_limit, "incoming", assessment}}} =
             error = Planner.run_profiled(m, study)

    assert assessment["status"] == "violated" and is_map(assessment["first_violation"])

    baseline =
      Snapshot.new!(
        %{"mission" => m, "study" => strong, "service_unavailable_asset_ids" => []},
        high
      )

    change = %{
      "revision_id" => "typed_torque_conflict",
      "protect_request_ids" => [a["request_id"]],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    # Verify the revision boundary's handling of this real typed replay failure.
    result = Reference.revise!(baseline, change, fn _, _, _ -> error end)
    assert result.review["status"] == "commitment_conflict" and result.revised_snapshot == :null
    assert hd(result.review["conflicts"])["kind"] == "protected_torque_capacity_exceeded"
    assert hd(result.review["conflicts"])["torque_evidence"] == assessment
  end

  test "idle spacecraft braking and terminal return are checked even without service requests", %{
    mission: m,
    weak: study
  } do
    study =
      put_in(
        study,
        ["attitude", "assets", "demo-3", "initial", "angular_velocity_inertial_deg_s"],
        [0, 0, 1]
      )

    m = Map.put(m, "requests", [])
    study = put_in(study, ["path_constraints", "assets", "demo-3", "activity_modes"], %{})
    report = Planner.run!(m, study)
    assert report["activities"] == []
    assert report["attitude_planning"]["planning_status"] == "violated"

    evidence =
      get_in(report, [
        "attitude_planning",
        "horizon_coverage",
        "assets",
        "demo-3",
        "terminal_path_evidence"
      ])

    assert evidence["reason"] == "rigid_body_torque_exceeds_limit"
    assert evidence["rigid_body_torque"]["first_violation"]["phase"] == "brake"
  end

  test "JSON adapter rejects unknown inertia frames and incomplete optional models", %{
    mission: m,
    strong: study
  } do
    for body <- [
          %{
            "frame" => "inertial",
            "principal_moments_kg_m2" => [1, 1, 1],
            "max_body_torque_nm" => [1, 1, 1]
          },
          :null
        ] do
      bad = put_in(study, ["attitude", "assets", "demo-3", "rigid_body"], body)
      assert_raise ArgumentError, fn -> Planner.run!(m, bad) end
    end
  end
end
