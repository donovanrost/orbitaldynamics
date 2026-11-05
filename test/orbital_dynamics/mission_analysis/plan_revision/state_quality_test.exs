defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.StateQualityTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Prediction, Advance}
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.{Checker, Operations}
  alias OrbitalDynamics.MissionAnalysis.Operations.Scenario
  alias OrbitalDynamics.IndependentPlanFixture, as: F

  defp policy,
    do: %{
      "allowed_kinds" => ["observed", "synthetic_prediction", "synthetic_execution"],
      "maximum_measurement_age_s" => 5,
      "minimum_validity_s" => 0,
      "assets" => %{
        "demo-3" => %{
          "attitude_error_deg" => 0.1,
          "rate_error_deg_s" => 0.01,
          "battery_error_wh" => %{"battery" => 0.1},
          "wheel_error_nms" => %{"wheels" => [0.01, 0.01, 0.01]}
        }
      }
    }

  setup_all do
    m = ReferenceMission.load!("studies/automatic_wheel_maintenance.json")

    s =
      ReferenceMission.load!("studies/automatic_wheel_maintenance_planning.json")
      |> Map.put("state_quality_policy", policy())

    snapshot = Reference.create!(m, s)
    u = Prediction.update!(snapshot, 820_497_660)

    observed =
      u
      |> Map.put("source_id", "observation_batch")
      |> put_in(["assets", "demo-3", "quality", "kind"], "observed")
      |> put_in(["assets", "demo-3", "quality", "source_id"], "estimator_A")
      |> put_in(["assets", "demo-3", "quality", "measurement_epoch_s"], 820_497_658)
      |> put_in(["assets", "demo-3", "quality", "valid_until_s"], 820_497_665)

    {:ok, mission: m, study: s, snapshot: snapshot, prediction: u, observed: observed}
  end

  defp reject(s, u, code) do
    r = Advance.run!(s, u)
    assert r.review["status"] == "state_quality_rejected"
    assert r.revised_snapshot == :null
    assert Enum.any?(r.review["state_quality"]["issues"], &(&1["code"] == code))
  end

  test "quality-screened offline observation retains provenance and bounds through revisions",
       ctx do
    u =
      ctx.observed
      |> put_in(["assets", "demo-3", "quality", "bounds", "battery_error_wh", "battery"], 0.05)

    r = Advance.run!(ctx.snapshot, u)
    assert r.review["status"] == "ready_for_review"
    assert r.review["state_quality"]["status"] == "supported"

    assert r.revised_snapshot["payload"]["inputs"]["execution"]["last_update"]["assets"]["demo-3"][
             "quality"
           ] == u["assets"]["demo-3"]["quality"]

    change = %{
      "revision_id" => "keep_observation",
      "protect_request_ids" => [],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    child = Reference.revise!(r.revised_snapshot, change)
    assert child.review["status"] == "ready_for_review"
    assert Checker.snapshot(child.revised_snapshot)["status"] == "passed"
  end

  test "stale, future, expired, wrong-epoch and excessive-error observations cannot become plans",
       ctx do
    path = ["assets", "demo-3", "quality"]

    for {key, value, code} <- [
          {"measurement_epoch_s", 820_497_654, "quality_stale_measurement"},
          {"measurement_epoch_s", 820_497_661, "quality_stale_measurement"},
          {"valid_until_s", 820_497_659, "quality_expired"},
          {"state_epoch_s", 820_497_659, "quality_epoch"}
        ] do
      reject(ctx.snapshot, put_in(ctx.observed, path ++ [key], value), code)
    end

    reject(
      ctx.snapshot,
      put_in(ctx.observed, path ++ ["bounds", "battery_error_wh", "battery"], 0.2),
      "quality_error_bound"
    )

    reject(
      ctx.snapshot,
      put_in(ctx.observed, path ++ ["bounds", "wheel_error_nms"], %{}),
      "quality_metadata"
    )

    reject(
      ctx.snapshot,
      update_in(ctx.observed, ["assets", "demo-3"], &Map.delete(&1, "quality")),
      "quality_metadata"
    )
  end

  test "predictions remain synthetic and observed-only policies reject relabeling without measurement evidence",
       ctx do
    assert ctx.prediction["assets"]["demo-3"]["quality"]["kind"] == "synthetic_prediction"
    assert ctx.prediction["assets"]["demo-3"]["quality"]["measurement_epoch_s"] == :null
    s = put_in(ctx.study, ["state_quality_policy", "allowed_kinds"], ["observed"])
    snapshot = Reference.create!(ctx.mission, s)
    u = Prediction.update!(snapshot, 820_497_660)
    reject(snapshot, u, "quality_kind")

    reject(
      snapshot,
      put_in(u, ["assets", "demo-3", "quality", "kind"], "observed"),
      "quality_stale_measurement"
    )
  end

  test "quality metadata cannot bypass a missing acceptance policy", ctx do
    s = Map.delete(ctx.study, "state_quality_policy")
    snapshot = Reference.create!(ctx.mission, s)

    u =
      ctx.observed
      |> Map.put("expected_baseline_id", snapshot["snapshot_id"])
      |> Map.put("motion_source_snapshot_id", snapshot["snapshot_id"])

    reject(snapshot, u, "quality_policy_required")

    assert not Map.has_key?(
             Prediction.update!(snapshot, 820_497_660)["assets"]["demo-3"],
             "quality"
           )
  end

  test "observed-only policy stops synthetic execution without adopting rejected state", ctx do
    study = put_in(ctx.study, ["state_quality_policy", "allowed_kinds"], ["observed"])

    script =
      ReferenceMission.load!("studies/automatic_wheel_maintenance_operations.json")
      |> Map.update!("steps", &Enum.take(&1, 1))
      |> put_in(["steps", Access.at(0), "expected_status"], "state_quality_rejected")

    r = Scenario.run!(ctx.mission, study, script)
    assert r["verification_status"] == "passed" and r["run_status"] == "stopped_for_review"
    assert hd(r["steps"])["status"] == "state_quality_rejected"
    refute hd(r["steps"])["adopted"]
    assert r["final_snapshot_id"] == r["baseline_snapshot_id"]
  end

  test "rehashed stale observation is rejected independently of producer validation", ctx do
    child = Advance.run!(ctx.snapshot, ctx.observed).revised_snapshot

    u =
      child["payload"]["inputs"]["execution"]["last_update"]
      |> put_in(["assets", "demo-3", "quality", "measurement_epoch_s"], 820_497_654)

    changed =
      child
      |> put_in(["payload", "inputs", "execution", "last_update"], u)
      |> put_in(["payload", "inputs", "execution", "state_update_sha256"], Checker.digest(u))
      |> F.bind()

    result = Checker.snapshot(changed)
    assert result["status"] == "failed"
    assert Enum.any?(result["issues"], &(&1["code"] == "state_quality_freshness"))
    refute Enum.any?(result["issues"], &(&1["code"] == "snapshot_content_identity"))
  end

  test "synthetic execution has distinct provenance and independently valid state-quality lineage",
       ctx do
    script = ReferenceMission.load!("studies/automatic_wheel_maintenance_operations.json")
    Process.put(:quality_files, %{})

    r =
      Scenario.run!(ctx.mission, ctx.study, script, fn name, value ->
        Process.put(:quality_files, Map.put(Process.get(:quality_files), name, value))
      end)

    assert r["verification_status"] == "passed" and r["run_status"] == "completed"

    for step <- r["steps"], step["kind"] == "advance" do
      assert step["state_update"]["assets"]["demo-3"]["quality"]["kind"] == "synthetic_execution"
    end

    assert Operations.validate(r, F.load(Process.get(:quality_files)))["status"] == "passed"
  end
end
