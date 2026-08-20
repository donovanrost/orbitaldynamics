defmodule OrbitalDynamics.FrameTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CentralBody, Frame}

  test "constructs explicit frame metadata" do
    frame = Frame.new!(:moon_inertial, :moon, :j2000)

    assert frame.name == :moon_inertial
    assert frame.center == :moon
    assert frame.orientation == :j2000
  end

  test "checks exact frame compatibility" do
    assert Frame.compatible?(Frame.earth_inertial_j2000(), Frame.earth_inertial_j2000())

    refute Frame.compatible?(
             Frame.earth_inertial_j2000(),
             Frame.earth_fixed()
           )
  end

  test "preserves the existing provider-defined Earth-fixed frame label" do
    assert Frame.earth_fixed() == Frame.new!(:earth_body_fixed, :earth, :body_fixed)
    assert Frame.earth_inertial_j2000() == Frame.new!(:eci_j2000, :earth, :j2000)
  end

  test "checks central-body center compatibility" do
    assert Frame.compatible_with_central_body?(
             Frame.earth_inertial_j2000(),
             CentralBody.earth()
           )

    refute Frame.compatible_with_central_body?(
             Frame.earth_inertial_j2000(),
             CentralBody.new!(:moon, 4_902.800066)
           )
  end

  test "rejects invalid frame metadata" do
    assert_raise ArgumentError, ~r/frame name/, fn ->
      Frame.new!("eci", :earth, :j2000)
    end
  end
end
