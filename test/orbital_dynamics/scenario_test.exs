defmodule OrbitalDynamics.ScenarioTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector}

  test "rejects initial states whose frame center does not match the central body" do
    state =
      StateVector.new!(
        {7_000.0, 0.0, 0.0},
        {0.0, 7.5, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    assert_raise ArgumentError, ~r/frame center must match central_body/, fn ->
      Scenario.new!(:moon_case, Spacecraft.new!(:sat_1, 250.0), state,
        duration_s: 60.0,
        output_step_s: 60.0,
        central_body: CentralBody.new!(:moon, 4_902.800066)
      )
    end
  end
end
