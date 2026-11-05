defmodule Mix.Tasks.OrbitalDynamics.Mission.CheckpointTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission, as: M

  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{
    Reference,
    Prediction,
    ExecutionCheckpoint,
    Snapshot
  }

  alias Mix.Tasks.OrbitalDynamics.Mission.{Checkpoint, Revision}

  test "accept, fail planning, and retry from disk preserve immutable execution and parent bytes" do
    dir = Path.join(System.tmp_dir!(), "checkpoint-cli-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    File.mkdir_p!(dir)

    root =
      Reference.create!(
        M.load!("studies/thermal_cooldown_reference.json"),
        M.load!("studies/thermal_cooldown_planning.json")
      )

    parent = Path.join(dir, "baseline.json")
    File.write!(parent, :json.encode(root))
    parent_bytes = File.read!(parent)

    u =
      Prediction.update!(root, 820_497_675)
      |> put_in(["scheduling", "work_budget"], %{"max_evaluations" => 1})

    update = Path.join(dir, "update.json")
    File.write!(update, :json.encode(u))
    accepted = Path.join(dir, "accepted")
    Checkpoint.run(["accept", "--baseline", parent, "--update", update, "--output-dir", accepted])
    cp_path = Path.join(accepted, "execution_checkpoint.json")
    cp = ExecutionCheckpoint.read!(cp_path)
    cp_bytes = File.read!(cp_path)
    refute File.exists?(Path.join(accepted, "revised_snapshot.json"))
    attempt = Path.join(dir, "attempt.json")

    spec = %{
      "attempt_id" => "limited",
      "scheduling" => %{
        "strategy" => "greedy",
        "max_trials" => 1,
        "work_budget" => %{"max_evaluations" => 1}
      }
    }

    File.write!(attempt, :json.encode(spec))
    failed = Path.join(dir, "failed")

    assert_raise Mix.Error, ~r/checkpoint retained/, fn ->
      Checkpoint.run([
        "plan",
        "--baseline",
        parent,
        "--checkpoint",
        cp_path,
        "--attempt",
        attempt,
        "--output-dir",
        failed
      ])
    end

    assert (File.read!(Path.join(failed, "revision.json"))
            |> :json.decode())["execution_checkpoint_id"] == cp["checkpoint_id"]

    refute File.exists?(Path.join(failed, "revised_snapshot.json"))

    spec =
      spec
      |> Map.put("attempt_id", "retry")
      |> put_in(["scheduling", "work_budget", "max_evaluations"], 100_000)

    File.write!(attempt, :json.encode(spec))
    success = Path.join(dir, "success")

    Checkpoint.run([
      "plan",
      "--baseline",
      parent,
      "--checkpoint",
      cp_path,
      "--attempt",
      attempt,
      "--output-dir",
      success
    ])

    child = Snapshot.read!(Path.join(success, "revised_snapshot.json"))
    assert child["payload"]["inputs"]["execution"] == cp["payload"]["inputs"]["execution"]
    assert File.read!(parent) == parent_bytes
    assert File.read!(cp_path) == cp_bytes

    assert_raise Mix.Error, ~r/already exist/, fn ->
      Checkpoint.run([
        "plan",
        "--baseline",
        parent,
        "--checkpoint",
        cp_path,
        "--attempt",
        attempt,
        "--output-dir",
        success
      ])
    end

    # The one-command advance path also persists state before returning a planning failure.
    combined = Path.join(dir, "combined")

    assert_raise Mix.Error, ~r/planning_failed/, fn ->
      Revision.run([
        "advance",
        "--baseline",
        parent,
        "--update",
        update,
        "--output-dir",
        combined
      ])
    end

    assert ExecutionCheckpoint.read!(Path.join(combined, "execution_checkpoint.json")) == cp
    refute File.exists?(Path.join(combined, "revised_snapshot.json"))
  end
end
