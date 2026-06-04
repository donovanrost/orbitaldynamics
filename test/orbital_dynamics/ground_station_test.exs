defmodule OrbitalDynamics.GroundStationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.GroundStation

  test "creates ground station metadata" do
    assert %GroundStation{
             id: :goldstone,
             latitude_deg: 35.2472,
             longitude_deg: -116.7933,
             altitude_km: 1.0,
             minimum_elevation_deg: 10.0
           } =
             GroundStation.new!(:goldstone, 35.2472, -116.7933,
               altitude_km: 1.0,
               minimum_elevation_deg: 10.0
             )
  end

  test "rejects invalid ground station metadata" do
    assert_raise ArgumentError, "latitude_deg must be between -90 and 90", fn ->
      GroundStation.new!(:bad, 91.0, 0.0)
    end

    assert_raise ArgumentError, "longitude_deg must be between -180 and 180", fn ->
      GroundStation.new!(:bad, 0.0, 181.0)
    end
  end
end
