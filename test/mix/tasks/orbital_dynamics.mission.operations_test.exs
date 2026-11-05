defmodule Mix.Tasks.OrbitalDynamics.Mission.OperationsTest do
  use ExUnit.Case, async: false
  alias Mix.Tasks.OrbitalDynamics.Mission.Operations
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  test "CLI saves chronological evidence and reusable snapshots, rejects overwrites, and records failed scenarios before exiting" do
    dir = Path.join(System.tmp_dir!(), "operations-cli-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    File.mkdir_p!(dir)
    mission = ReferenceMission.load!("studies/rolling_state_reference.json")
    study = ReferenceMission.load!("studies/rolling_state_planning.json")
    mission_path = Path.join(dir, "mission.json")
    study_path = Path.join(dir, "study.json")
    File.write!(mission_path, :json.encode(mission))
    File.write!(study_path, :json.encode(study))

    spec = %{
      "scenario_id" => "cli_operations",
      "mission_manifest" => "mission.json",
      "planning_study" => "study.json",
      "steps" => [
        %{
          "id" => "execute",
          "kind" => "advance",
          "expected_status" => "ready_for_review",
          "as_of_s" => 820_497_800,
          "not_executed_request_ids" => [],
          "energy_losses_wh" => %{},
          "protect_request_ids" => [],
          "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
        }
      ]
    }

    path = Path.join(dir, "scenario.json")
    File.write!(path, :json.encode(spec))
    original = Map.new([mission_path, study_path, path], &{&1, File.read!(&1)})
    out = Path.join(dir, "success")
    args = ["--scenario", path, "--output-dir", out]
    Operations.run(args)
    report = File.read!(Path.join(out, "operations.json")) |> :json.decode()
    assert report["verification_status"] == "passed" and report["run_status"] == "completed"
    baseline = Snapshot.read!(Path.join(out, "baseline_snapshot.json"))
    child = Snapshot.read!(Path.join(out, "step-01-revised_snapshot.json"))
    replay = Snapshot.read!(Path.join(out, "step-01-execution_snapshot.json"))
    assert child["payload"]["parent_snapshot_id"] == baseline["snapshot_id"]
    assert replay["payload"]["parent_snapshot_id"] == baseline["snapshot_id"]

    assert hd(child["payload"]["inputs"]["execution"]["closed_requests"])["request"]["id"] ==
             "early-3"

    assert File.read!(Path.join(out, "README.md")) =~ "Executed: early-3"
    assert_raise Mix.Error, ~r/already exist/, fn -> Operations.run(args) end
    assert Enum.all?(original, fn {p, bytes} -> File.read!(p) == bytes end)
    # A malformed operation is a recorded failure; it cannot replace the baseline.
    bad_step = %{
      "id" => "bad_asset",
      "kind" => "revise",
      "expected_status" => "ready_for_review",
      "change" => %{
        "revision_id" => "bad_asset",
        "protect_request_ids" => [],
        "add_requests" => [],
        "unavailable_asset_ids" => ["missing"],
        "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
      }
    }

    File.write!(path, :json.encode(%{spec | "steps" => [bad_step]}))
    failed = Path.join(dir, "failed")

    assert_raise Mix.Error, ~r/verification failed/, fn ->
      Operations.run(["--scenario", path, "--output-dir", failed])
    end

    evidence = File.read!(Path.join(failed, "operations.json")) |> :json.decode()
    assert evidence["verification_status"] == "failed"
    assert evidence["final_snapshot_id"] == evidence["baseline_snapshot_id"]
    assert hd(evidence["steps"])["status"] == "invalid_step"
    refute File.exists?(Path.join(failed, "step-01-revised_snapshot.json"))
    assert File.read!(Path.join(failed, "README.md")) =~ "stopped_for_review"
  end

  test "strict command controls are rejected before opening files" do
    for args <- [
          [],
          ["--scenario", "missing"],
          ["--scenario", "missing", "--output-dir", "out", "--scenario", "duplicate"],
          ["--scenario", "missing", "--output-dir", "out", "--unknown"]
        ] do
      assert_raise Mix.Error, ~r/required/, fn -> Operations.run(args) end
    end
  end
end
