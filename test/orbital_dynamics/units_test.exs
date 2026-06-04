defmodule OrbitalDynamics.UnitsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Units

  test "documents canonical units and no implicit conversion policy" do
    policy = Units.policy()

    assert policy["schema_contract"] == "units_policy.v1"
    assert policy["policy"] == "explicit_suffix_units_no_implicit_conversion"
    assert policy["canonical_units"]["distance"] == "kilometer"
    assert policy["canonical_units"]["velocity"] == "kilometer_per_second"
    assert policy["time_policy"] =~ "time scales are not converted"
    assert policy["frame_policy"] =~ "frames are metadata labels"
  end

  test "looks up canonical units for public field names" do
    assert Units.unit_for(:position_km) == {:ok, "kilometer"}
    assert Units.unit_for("velocity_km_s") == {:ok, "kilometer_per_second"}
    assert Units.unit_for("mu_km3_s2") == {:ok, "kilometer_cubed_per_second_squared"}
    assert Units.unit_for("seconds_since_j2000") == {:ok, "second"}
    assert Units.unit_for("time_scale") == {:ok, "time_scale_label"}
    assert Units.unit_for("eccentricity") == {:ok, "dimensionless"}
  end

  test "checks field/unit compatibility" do
    assert Units.compatible?(:delta_v_km_s, "kilometer_per_second")
    assert Units.compatible?("semi_major_axis_km", "kilometer")
    refute Units.compatible?("semi_major_axis_km", "meter")
    refute Units.compatible?(:unknown_field, "kilometer")
  end

  test "top-level helper exposes the same unit policy" do
    assert OrbitalDynamics.units_policy() == Units.policy()
  end

  test "raises for unknown unit fields when using bang lookup" do
    assert_raise ArgumentError, ~r/unknown unit field/, fn ->
      Units.unit_for!(:meters)
    end
  end
end
