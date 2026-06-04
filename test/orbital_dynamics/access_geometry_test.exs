defmodule OrbitalDynamics.AccessGeometryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{AccessGeometry, CentralBody, Epoch, Frame, GroundStation, StateVector}

  test "computes high elevation for a spacecraft directly above a station" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0)
    state = state({earth.equatorial_radius_km + 500.0, 0.0, 0.0})

    assert_in_delta AccessGeometry.elevation_deg(state, station, earth), 90.0, 1.0e-9
    assert AccessGeometry.visible?(state, station, earth)
  end

  test "computes negative elevation for a spacecraft on the opposite side of Earth" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0)
    state = state({-(earth.equatorial_radius_km + 500.0), 0.0, 0.0})

    assert AccessGeometry.elevation_deg(state, station, earth) < 0.0
    refute AccessGeometry.visible?(state, station, earth)
  end

  test "respects minimum elevation threshold" do
    earth = CentralBody.earth()
    station = GroundStation.new!(:equator, 0.0, 0.0, minimum_elevation_deg: 80.0)
    state = state({earth.equatorial_radius_km + 500.0, 1_000.0, 0.0})

    refute AccessGeometry.visible?(state, station, earth)
  end

  defp state(position_km) do
    StateVector.new!(
      position_km,
      {0.0, 0.0, 0.0},
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end
end
