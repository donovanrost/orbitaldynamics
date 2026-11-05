defmodule Mix.Tasks.OrbitalDynamics.Mission.AdvanceTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Snapshot}
  alias Mix.Tasks.OrbitalDynamics.Mission.{Revision, PredictState}

  test "CLI predicts, advances and explains a conflict without modifying the baseline" do
    dir = Path.join(System.tmp_dir!(), "advance-cli-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    File.mkdir_p!(dir)

    s =
      Reference.create!(
        ReferenceMission.load!("studies/rolling_state_reference.json"),
        ReferenceMission.load!("studies/rolling_state_planning.json")
      )

    baseline = Path.join(dir, "baseline.json")
    bytes = IO.iodata_to_binary(:json.encode(s))
    File.write!(baseline, bytes)
    pred = Path.join(dir, "prediction")
    PredictState.run(["--baseline", baseline, "--at", "820497680.5", "--output-dir", pred])
    input = Path.join(pred, "state_update.json")
    u = ReferenceMission.load!(input)
    assert u["source_id"] == "synthetic_baseline_prediction"
    assert u["completed_request_ids"] == ["early-3"]
    File.write!(input, :json.encode(%{u | "protect_request_ids" => ["late-1"]}))
    out = Path.join(dir, "advance")
    args = ["advance", "--baseline", baseline, "--update", input, "--output-dir", out]
    Revision.run(args)
    child = Snapshot.read!(Path.join(out, "revised_snapshot.json"))
    assert child["payload"]["parent_snapshot_id"] == s["snapshot_id"]

    assert child["payload"]["inputs"]["execution"]["closed_requests"]
           |> hd()
           |> Map.fetch!("status") == "completed"

    markdown = File.read!(Path.join(out, "README.md"))
    assert markdown =~ "Horizon advanced"
    assert markdown =~ "Closed early-3: completed"
    assert markdown =~ "completed work is excluded"
    assert_raise Mix.Error, ~r/already exist/, fn -> Revision.run(args) end

    conflict =
      u
      |> Map.put("protect_request_ids", ["late-1"])
      |> put_in(["assets", "demo-3", "battery_energy_wh", "battery"], 2.5)

    File.write!(input, :json.encode(conflict))
    out2 = Path.join(dir, "conflict")

    assert_raise Mix.Error, ~r/commitment_conflict/, fn ->
      Revision.run(["advance", "--baseline", baseline, "--update", input, "--output-dir", out2])
    end

    assert (File.read!(Path.join(out2, "revision.json")) |> :json.decode())["status"] ==
             "commitment_conflict"

    refute File.exists?(Path.join(out2, "revised_snapshot.json"))
    assert File.read!(baseline) == bytes

    for bad <- [
          ["advance"],
          ["advance", "--baseline", baseline, "--changes", input, "--output-dir", out2]
        ] do
      assert_raise Mix.Error, ~r/required/, fn -> Revision.run(bad) end
    end

    assert_raise Mix.Error, ~r/required/, fn -> PredictState.run(["--baseline", baseline]) end
  end
end
