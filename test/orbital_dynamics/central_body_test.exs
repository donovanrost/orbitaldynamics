defmodule OrbitalDynamics.CentralBodyTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CentralBody

  test "creates central body metadata with positive mu" do
    assert %CentralBody{name: :moon, mu_km3_s2: 4_902.800066} =
             CentralBody.new!(:moon, 4_902.800066)
  end

  test "rejects invalid central body metadata" do
    assert_raise ArgumentError, "central body name must be an atom", fn ->
      CentralBody.new!("earth", 398_600.4418)
    end

    assert_raise ArgumentError, "mu_km3_s2 must be positive", fn ->
      CentralBody.new!(:earth, 0.0)
    end
  end
end
