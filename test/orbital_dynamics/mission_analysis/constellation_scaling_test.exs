defmodule OrbitalDynamics.MissionAnalysis.ConstellationScalingTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.MissionAnalysis.{ConstellationScaling, ReferenceMission}

  test "nested 100-spacecraft fixture preserves the six-asset baseline and fixed numerical controls" do
    {m, s} = ConstellationScaling.inputs!(6)
    original = ReferenceMission.load!("studies/small_constellation.json")
    assert m === original
    {large, study} = ConstellationScaling.inputs!(100)
    assert length(large["assets"]) == 100 and length(large["requests"]) == 9
    assert Enum.take(large["assets"], 6) === m["assets"]
    assert large["requests"] === m["requests"]
    assert Enum.uniq_by(large["assets"], & &1["id"]) == large["assets"]

    assert Enum.all?(
             large["assets"],
             &(&1["initial_argument_of_latitude_deg"] >= 0 and
                 &1["initial_argument_of_latitude_deg"] < 360)
           )

    assert study["resolution_level"] === s["resolution_level"]
    assert study["refinement"] === s["refinement"]
    assert study["horizon"]["ends_at_s"] == s["horizon"]["ends_at_s"]
    assert map_size(study["resources"]["assets"]) == 100
    assert map_size(study["horizon"]["terminals"]) == 100
  end

  test "demand can grow explicitly and mode bindings remain complete" do
    {m, s} = ConstellationScaling.inputs!(100, 100)
    assert length(m["requests"]) == 100
    ids = Enum.map(m["requests"], & &1["id"])
    assert Enum.uniq(ids) == ids

    for {_, p} <- s["path_constraints"]["assets"],
        do: assert(Enum.sort(Map.keys(p["activity_modes"])) == Enum.sort(ids))
  end

  test "one-million subsystem budgets and fixture sizes remain bounded" do
    for {n, d} <- [{5, 9}, {101, 9}, {6, 0}, {100, 101}, {6.0, 9}],
        do: assert_raise(ArgumentError, fn -> ConstellationScaling.inputs!(n, d) end)

    constructors = [
      fn n ->
        OrbitalDynamics.MissionAnalysis.Attitude.Policy.new!(%{},
          profile_step_s: 1,
          derivative_step_s: 0.1,
          search_step_s: 1,
          max_candidate_starts: 32,
          max_evaluations: n
        )
      end,
      fn n ->
        OrbitalDynamics.MissionAnalysis.Path.Policy.new!(%{},
          sample_steps_s: [1],
          max_samples_per_segment: 100,
          max_evaluations: n
        )
      end,
      fn n ->
        OrbitalDynamics.MissionAnalysis.Resource.Policy.new!(%{},
          sample_steps_s: [1],
          max_intervals_per_asset: 100,
          max_evaluations: n
        )
      end
    ]

    for make <- constructors do
      assert make.(1_000_000).max_evaluations == 1_000_000
      assert_raise ArgumentError, fn -> make.(1_000_001) end
    end
  end

  test "memory failure is explicit, saved and stops later cases" do
    dir = Path.join(System.tmp_dir!(), "scaling-cap-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)

    assert_raise Mix.Error, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Scaling.run([
        "--output-dir",
        dir,
        "--sizes",
        "6,25",
        "--memory-mb",
        "16"
      ])
    end

    report = ReferenceMission.load!(Path.join(dir, "summary.json"))
    assert report["unprocessed_sizes"] == [25]
    assert hd(report["runs"])["status"] == "memory_budget_exceeded"
    refute File.exists?(Path.join(dir, "summary-25.json"))
    refute ConstellationScaling.supported?(hd(report["runs"]))
  end

  test "timeout stops a large case without producing a supported summary" do
    result =
      ConstellationScaling.run_case!(100, 100,
        max_memory_bytes: 8_000_000_000,
        timeout_ms: 1000,
        profile: true
      )

    assert result["status"] == "timeout"
    refute Map.has_key?(result, "summary")
    refute ConstellationScaling.supported?(result)
    assert result["stack_profile"]["sample_count"] > 0
  end

  test "invalid CLI controls are rejected before creating artifacts" do
    for args <- [
          [],
          ["--output-dir", "tmp/unused", "--sizes", "101"],
          ["--output-dir", "tmp/unused", "--sizes", "6,6"],
          ["--output-dir", "tmp/unused", "--requests", "101"],
          ["--output-dir", "tmp/unused", "--memory-mb", "0"]
        ],
        do: assert_raise(Mix.Error, fn -> Mix.Tasks.OrbitalDynamics.Mission.Scaling.run(args) end)
  end
end
