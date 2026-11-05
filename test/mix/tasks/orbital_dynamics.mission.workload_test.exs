defmodule Mix.Tasks.OrbitalDynamics.Mission.WorkloadTest do
  use ExUnit.Case, async: false

  test "rejects malformed controls before loading physical inputs" do
    for args <- [
          [],
          ["--output-dir", "tmp/unused", "--max-trials", "0"],
          ["--output-dir", "tmp/unused", "--max-trials", "65"],
          ["--output-dir", "tmp/unused", "--max-trials", "2", "--max-trials", "3"],
          ["--output-dir", "tmp/unused", "--unknown"]
        ] do
      assert_raise Mix.Error, fn -> Mix.Tasks.OrbitalDynamics.Mission.Workload.run(args) end
    end
  end

  defp fixture(dir, unknown? \\ false) do
    alias OrbitalDynamics.MissionAnalysis.ReferenceMission

    mission =
      ReferenceMission.load!("studies/repeated_service.json")
      |> Map.update!("assets", &Enum.take(&1, 1))
      |> Map.update!("requests", &Enum.take(&1, 1))

    study = ReferenceMission.load!("studies/repeated_service_planning.json")

    study =
      Enum.reduce(
        [
          ["attitude", "assets"],
          ["path_constraints", "assets"],
          ["resources", "assets"],
          ["horizon", "terminals"]
        ],
        study,
        fn path, config -> update_in(config, path, &Map.take(&1, ["demo-1"])) end
      )

    study =
      put_in(study, ["path_constraints", "assets", "demo-1", "activity_modes"], %{
        "early-1" => "reflecting"
      })

    study =
      if unknown?,
        do:
          put_in(study, ["attitude", "assets", "demo-1", "initial"], :null)
          |> Map.delete("opportunity_search"),
        else: study

    File.mkdir_p!(dir)
    mission_path = Path.join(dir, "mission.json")
    study_path = Path.join(dir, "study.json")
    study = Map.put(study, "mission_manifest", "mission.json")
    File.write!(mission_path, :json.encode(mission))
    File.write!(study_path, :json.encode(study))
    {study_path, mission_path}
  end

  test "valid unknown-attitude custom study retains unknown/null diagnostics and writes checkpoints" do
    dir = Path.join(System.tmp_dir!(), "service-unknown-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    {study, _} = fixture(dir, true)
    out = Path.join(dir, "out")

    Mix.Tasks.OrbitalDynamics.Mission.Workload.run([
      "--study",
      study,
      "--output-dir",
      out,
      "--max-trials",
      "1"
    ])

    summary = File.read!(Path.join(out, "summary.json")) |> :json.decode()

    for run <- summary["runs"] do
      assert run["planning_status"] == "unknown"
      assert run["batteries"]["demo-1"]["status"] == "unknown"
      assert run["batteries"]["demo-1"]["reason"] == "initial_attitude_unknown"
      assert run["batteries"]["demo-1"]["minimum_energy_wh"] == :null
      assert run["inter_service_energy"]["demo-1"] == :null
      assert run["opportunity_evaluation_count"] == :null
      assert File.exists?(Path.join(out, "summary-#{run["strategy"]}.json"))
    end

    assert File.read!(Path.join(out, "README.md")) =~ "unknown"
  end

  test "custom-study commitments apply to all compared orbital strategies but not unrelated quality cases" do
    dir = Path.join(System.tmp_dir!(), "service-protected-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    {study_path, _} = fixture(dir)
    study = File.read!(study_path) |> :json.decode()
    epoch = 820_497_600

    pin = %{
      "request_id" => "early-1",
      "asset_id" => "demo-1",
      "starts_at_s" => epoch + 65.25,
      "ends_at_s" => epoch + 85.25
    }

    study =
      Map.put(study, "scheduling", %{
        "strategy" => "bounded_replacement",
        "max_trials" => 4,
        "protected_activities" => [pin]
      })

    File.write!(study_path, :json.encode(study))
    output = Path.join(dir, "out")

    Mix.Tasks.OrbitalDynamics.Mission.Workload.run([
      "--study",
      study_path,
      "--output-dir",
      output,
      "--max-trials",
      "1"
    ])

    summary = File.read!(Path.join(output, "summary.json")) |> :json.decode()
    assert summary["protected_activities"] == [pin]
    assert length(summary["runs"]) == 3

    for run <- summary["runs"] do
      assert [
               %{
                 "request_id" => "early-1",
                 "asset_id" => "demo-1",
                 "starts_at_s" => start,
                 "ends_at_s" => stop
               }
             ] =
               Enum.map(
                 run["assignments"],
                 &Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s))
               )

      assert start == pin["starts_at_s"] and stop == pin["ends_at_s"]
      assert run["planning_status"] == "supported"
    end

    assert Enum.all?(summary["quality_cases"], fn {_, cases} -> length(cases) == 4 end)
  end

  test "output-file links and directory aliases cannot overwrite selected inputs" do
    dir = Path.join(System.tmp_dir!(), "service-links-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    {study, mission} = fixture(dir)
    originals = {File.read!(study), File.read!(mission)}
    out = Path.join(dir, "out")
    File.mkdir_p!(out)

    for name <- [
          "summary.json",
          "report-bounded_replacement.json.gz",
          "summary-bounded_replacement.json"
        ] do
      link = Path.join(out, name)
      File.ln_s!(study, link)

      assert_raise Mix.Error, ~r/symlinks/, fn ->
        Mix.Tasks.OrbitalDynamics.Mission.Workload.run(["--study", study, "--output-dir", out])
      end

      File.rm!(link)
    end

    alias_dir = Path.join(dir, "alias")
    File.ln_s!(dir, alias_dir)
    # The study may itself have the same filename as an output.
    input = Path.join(dir, "summary.json")
    File.cp!(study, input)

    assert_raise Mix.Error, ~r/overwrite/, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Workload.run([
        "--study",
        input,
        "--output-dir",
        alias_dir
      ])
    end

    assert originals == {File.read!(study), File.read!(mission)}
    assert File.read!(input) == elem(originals, 0)
  end
end
