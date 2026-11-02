defmodule OrbitalDynamics.MissionAnalysis.ReferenceMissionTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.ReferenceMission

  test "both reference missions produce replayable, source-bound, analysis-only reports" do
    for model <- ["illumination", "imaging"] do
      config = ReferenceMission.load!("studies/reference_#{model}.json")
      report = ReferenceMission.run!(config)
      assert report == ReferenceMission.run!(config)
      assert length(report["activities"]) == 1
      assert hd(report["requests"])["status"] == "scheduled"
      assert report["format"] == "mission_analysis.v1"
      assert report["execution_boundary"] == "analysis_only_no_command_execution"
      analysis = hd(report["analyses"])
      environment = analysis["assumptions"]["geometry"]["environment"]
      assert environment["content_verification"] != %{}
      assert length(environment["sources"]) > 0
      assert report["reference_mission"]["configuration"] == config
      assert report == report |> :json.encode() |> IO.iodata_to_binary() |> :json.decode()
    end
  end

  test "shared runner handles two payload models competing for one asset" do
    illumination = ReferenceMission.load!("studies/reference_illumination.json")
    imaging = ReferenceMission.load!("studies/reference_imaging.json")
    [a] = illumination["assets"]
    [b] = imaging["assets"]
    # Relax only the daytime requirement to exercise shared scheduling at the same site.
    [ir] = imaging["requests"]
    [lr] = illumination["requests"]

    ir = %{
      ir
      | "target" => lr["target"],
        "parameters" => Map.put(ir["parameters"], "minimum_target_sun_elevation_deg", -90)
    }

    config = %{
      illumination
      | "assets" => [%{a | "payloads" => Map.merge(a["payloads"], b["payloads"])}],
        "requests" => [lr, ir]
    }

    report = ReferenceMission.run!(config)
    assert length(report["analyses"]) == 2
    assert Enum.all?(report["analyses"], &(&1["status"] == "opportunities_found"))
    activities = report["activities"]
    assert length(activities) == 2
    [first, second] = activities
    assert second["starts_at_s"] >= first["ends_at_s"] + config["asset_separation_s"]
  end

  test "reference format rejects unknown models, ignored fields and duplicate JSON keys" do
    config = ReferenceMission.load!("studies/reference_illumination.json")
    assert_raise ArgumentError, fn -> ReferenceMission.run!(Map.put(config, "typo", 1)) end
    [request] = config["requests"]

    assert_raise ArgumentError, fn ->
      ReferenceMission.run!(%{config | "requests" => [%{request | "model" => "unknown"}]})
    end

    path =
      Path.join(System.tmp_dir!(), "mission-duplicate-#{System.unique_integer([:positive])}.json")

    on_exit(fn -> File.rm(path) end)
    File.write!(path, ~s({"mission_id":"a","mission_id":"b"}))
    assert_raise ArgumentError, ~r/duplicate JSON key/, fn -> ReferenceMission.load!(path) end
  end
end
