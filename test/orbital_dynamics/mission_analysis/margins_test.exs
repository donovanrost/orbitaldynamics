defmodule OrbitalDynamics.MissionAnalysis.MarginsTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.{Evaluation, ReferenceMission}
  alias OrbitalDynamics.MissionAnalysis.Models.{Illumination, Imaging}

  test "real illumination and imaging checks report direction and explicit units" do
    for {file, model, id, metric, unit, sense} <- [
          {"illumination", Illumination, "minimum_nominal_irradiance_w_m2",
           "nominal_irradiance_w_m2", "W/m2", :min},
          {"imaging", Imaging, "maximum_nominal_center_gsd_m", "nominal_center_worst_axis_gsd_m",
           "m", :max}
        ] do
      config = ReferenceMission.load!("studies/reference_#{file}.json")
      p = ReferenceMission.prepare!(config)
      [a] = p.assets
      [r] = p.requests
      {:ok, session, _} = model.prepare(r, a.capabilities[model], p.context)
      [previous, state | _] = a.trajectory.states
      {:ok, e} = model.evaluate(state, previous, session)
      check = Enum.find(e.checks, &(&1["id"] == id))
      assert check["margin_unit"] == unit
      assert check["margin"] >= 0
      # The physical quantity is an excess over a minimum or headroom below a maximum.
      expected =
        if sense == :min,
          do: e.metrics[metric] - check["limit"],
          else: check["limit"] - e.metrics[metric]

      assert_in_delta check["margin"], expected, 1.0e-12
      {:ok, first} = model.evaluate(previous, nil, session)
      unknown = Enum.find(first.checks, &(&1["id"] == "maximum_tracking_rate_deg_s"))
      assert unknown["margin"] == :null
      refute unknown["passed"]
    end
  end

  test "malformed numeric margin metadata is rejected without affecting older model checks" do
    assert %Evaluation{} = Evaluation.new!([%{"id" => "legacy", "passed" => true}], %{})

    for changes <- [
          %{"margin" => 1},
          %{"margin" => 1, "margin_unit" => "m"},
          %{"margin" => "unknown", "margin_unit" => "m", "margin_comparison" => "min"}
        ] do
      assert_raise ArgumentError, fn ->
        Evaluation.new!([Map.merge(%{"id" => "bad", "passed" => true}, changes)], %{})
      end
    end
  end
end
