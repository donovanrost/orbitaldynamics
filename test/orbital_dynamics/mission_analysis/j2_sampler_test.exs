defmodule OrbitalDynamics.MissionAnalysis.J2SamplerTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{CentralBody, Epoch, Vector3}
  alias OrbitalDynamics.MissionAnalysis.{J2Sampler, ReferenceMission, ReferenceResolution}

  defp prepare(step) do
    config = ReferenceMission.load!("studies/reference_illumination.json")

    ReferenceMission.prepare!(%{
      config
      | "duration_s" => 40,
        "sample_step_s" => step,
        "max_step_s" => step
    })
  end

  test "query cadence cannot advance anchors or silently reduce integration steps" do
    p = prepare(10)
    [a] = p.assets
    sample = J2Sampler.new!(p.assets, CentralBody.earth(), 10)
    start = hd(a.trajectory.states).epoch.seconds_since_j2000
    {:ok, expected} = sample.(a, start + 40)
    for t <- 0..40, do: assert({:ok, _} = sample.(a, start + t))
    assert {:ok, ^expected} = sample.(a, start + 40)
    assert expected == List.last(a.trajectory.states)

    fine =
      prepare(1).assets |> hd() |> Map.fetch!(:trajectory) |> Map.fetch!(:states) |> List.last()

    assert Vector3.norm(Vector3.subtract(fine.position_km, expected.position_km)) > 1.0e-12
    assert {:error, :state_sampler_outside_coverage} = sample.(a, start - 1)
  end

  test "rejects empty, unordered and excessively long final anchor intervals" do
    p = prepare(10)
    [a] = p.assets
    [s | _] = a.trajectory.states

    for times <- [[], [0], [0, 10, 100], [0, 10, 5]] do
      states = Enum.map(times, &%{s | epoch: Epoch.new!(&1, :utc)})
      bad = %{a | trajectory: %{a.trajectory | states: states}}
      assert_raise ArgumentError, fn -> J2Sampler.new!([bad], CentralBody.earth(), 10) end
    end
  end

  test "reference adapter varies integration independently from output sampling" do
    config =
      ReferenceMission.load!("studies/reference_illumination.json") |> Map.put("duration_s", 40)

    options = [tracking_lookback_s: 1, time_tolerance_s: 0.01, max_extra_evaluations: 128]
    level = %{"id" => "independent", "sample_step_s" => 1, "max_step_s" => 10}
    assert {:ok, report} = ReferenceResolution.evaluate(config, level, options)
    [pair] = report["analyses"]
    assert pair["trajectory_assumptions"]["integration_anchor_step_s"] == 10
    assert pair["trajectory_assumptions"]["requested_sample_step_s"] == 1
    assert pair["trajectory_assumptions"]["max_step_s"] == 10

    assert Enum.all?(pair["samples"], fn s ->
             Enum.all?(s["checks"], &is_boolean(&1["passed"]))
           end)
  end

  test "shared reference preparation rejects invalid numerical steps as tagged errors" do
    config = ReferenceMission.load!("studies/reference_illumination.json")
    options = [tracking_lookback_s: 1, time_tolerance_s: 0.01, max_extra_evaluations: 128]

    for {key, value} <- [{"sample_step_s", 0}, {"sample_step_s", "bad"}, {"max_step_s", 0}] do
      level = Map.put(%{"sample_step_s" => 1, "max_step_s" => 1}, key, value)
      assert {:error, message} = ReferenceResolution.prepare(config, level, options)
      assert is_binary(message)
    end
  end
end
