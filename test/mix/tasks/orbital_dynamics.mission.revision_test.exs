defmodule Mix.Tasks.OrbitalDynamics.Mission.RevisionTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  defp fixture(dir) do
    m =
      ReferenceMission.load!("studies/repeated_service.json")
      |> Map.put("duration_s", 250)
      |> Map.update!("assets", &Enum.take(&1, 1))
      |> Map.update!("requests", &Enum.take(&1, 1))

    s = ReferenceMission.load!("studies/repeated_service_planning.json")

    s =
      Enum.reduce(
        [
          ["attitude", "assets"],
          ["path_constraints", "assets"],
          ["resources", "assets"],
          ["horizon", "terminals"]
        ],
        s,
        fn path, s -> update_in(s, path, &Map.take(&1, ["demo-1"])) end
      )

    s = put_in(s, ["horizon", "ends_at_s"], m["epoch_s"] + 250)

    s =
      put_in(s, ["path_constraints", "assets", "demo-1", "activity_modes"], %{
        "early-1" => "reflecting"
      })
      |> Map.put("mission_manifest", "mission.json")

    File.mkdir_p!(dir)
    study = Path.join(dir, "study.json")
    mission = Path.join(dir, "mission.json")
    File.write!(study, :json.encode(s))
    File.write!(mission, :json.encode(m))
    {study, mission}
  end

  defp change,
    do: %{
      "revision_id" => "cli_revision",
      "protect_request_ids" => ["early-1"],
      "add_requests" => [],
      "unavailable_asset_ids" => [],
      "scheduling" => %{"strategy" => "bounded_replacement", "max_trials" => 1}
    }

  test "CLI saves, reloads and revises a baseline without the original input files, then reports conflicts" do
    dir = Path.join(System.tmp_dir!(), "revision-cli-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    {study, mission} = fixture(dir)
    baseline_dir = Path.join(dir, "baseline")

    Mix.Tasks.OrbitalDynamics.Mission.Revision.run([
      "baseline",
      "--study",
      study,
      "--output-dir",
      baseline_dir
    ])

    baseline = Path.join(baseline_dir, "baseline_snapshot.json")
    bytes = File.read!(baseline)
    parent = Snapshot.read!(baseline)

    assert_raise Mix.Error, ~r/already exist/, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Revision.run([
        "baseline",
        "--study",
        study,
        "--output-dir",
        baseline_dir
      ])
    end

    File.rm!(study)
    File.rm!(mission)
    request = Path.join(dir, "change.json")
    File.write!(request, :json.encode(change()))
    output = Path.join(dir, "revision")

    Mix.Tasks.OrbitalDynamics.Mission.Revision.run([
      "revise",
      "--baseline",
      baseline,
      "--changes",
      request,
      "--output-dir",
      output
    ])

    review = File.read!(Path.join(output, "revision.json")) |> :json.decode()
    assert review["status"] == "ready_for_review"
    child = Snapshot.read!(Path.join(output, "revised_snapshot.json"))
    assert child["payload"]["parent_snapshot_id"] == parent["snapshot_id"]
    assert File.read!(baseline) == bytes

    assert_raise Mix.Error, ~r/already exist/, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Revision.run([
        "revise",
        "--baseline",
        baseline,
        "--changes",
        request,
        "--output-dir",
        output
      ])
    end

    File.write!(request, :json.encode(%{change() | "unavailable_asset_ids" => ["demo-1"]}))
    conflict_dir = Path.join(dir, "conflict")

    assert_raise Mix.Error, ~r/commitment_conflict/, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Revision.run([
        "revise",
        "--baseline",
        baseline,
        "--changes",
        request,
        "--output-dir",
        conflict_dir
      ])
    end

    conflict = File.read!(Path.join(conflict_dir, "revision.json")) |> :json.decode()
    assert conflict["status"] == "commitment_conflict"
    refute File.exists?(Path.join(conflict_dir, "revised_snapshot.json"))
    assert File.read!(baseline) == bytes
  end

  test "malformed controls and linked output files fail before planning" do
    for args <- [
          [],
          ["other"],
          ["baseline", "--study", "missing"],
          [
            "revise",
            "--baseline",
            "missing",
            "--changes",
            "missing",
            "--output-dir",
            "tmp/unused",
            "--unknown"
          ]
        ] do
      assert_raise Mix.Error, fn -> Mix.Tasks.OrbitalDynamics.Mission.Revision.run(args) end
    end

    dir = Path.join(System.tmp_dir!(), "revision-links-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    {study, _} = fixture(dir)
    bytes = File.read!(study)
    output = Path.join(dir, "out")
    File.mkdir_p!(output)
    File.ln_s!(study, Path.join(output, "baseline_snapshot.json"))

    assert_raise Mix.Error, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Revision.run([
        "baseline",
        "--study",
        study,
        "--output-dir",
        output
      ])
    end

    assert File.read!(study) == bytes
  end
end
