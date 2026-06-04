defmodule OrbitalDynamics.Maneuver.ImpulsiveBurnTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.{Epoch, Frame}

  test "creates an impulsive burn with explicit units and frame" do
    epoch = Epoch.new!(60.0, :tdb)
    frame = Frame.earth_inertial_j2000()

    assert %ImpulsiveBurn{id: :raise_apogee, epoch: ^epoch, frame: ^frame} =
             burn = ImpulsiveBurn.new!(:raise_apogee, epoch, {0.0, 0.01, 0.0}, frame)

    assert burn.delta_v_km_s == {0.0, 0.01, 0.0}
  end

  test "emits assumption metadata" do
    burn =
      ImpulsiveBurn.new!(
        :burn_1,
        Epoch.new!(60.0, :tdb),
        {0.0, 0.01, 0.0},
        Frame.earth_inertial_j2000()
      )

    assert %{
             id: :burn_1,
             type: :impulsive_burn,
             epoch_s: 60.0,
             epoch_scale: :tdb,
             delta_v_magnitude_km_s: 0.01,
             frame: :eci_j2000
           } = assumptions = ImpulsiveBurn.assumptions(burn)

    assert assumptions.delta_v_km_s == {0.0, 0.01, 0.0}
  end

  test "rejects invalid burn fields" do
    assert_raise ArgumentError, "maneuver id is required", fn ->
      ImpulsiveBurn.new!(
        "",
        Epoch.new!(60.0, :tdb),
        {0.0, 0.01, 0.0},
        Frame.earth_inertial_j2000()
      )
    end

    assert_raise ArgumentError, "delta_v_km_s must be a numeric {x, y, z} tuple", fn ->
      ImpulsiveBurn.new!(:bad, Epoch.new!(60.0, :tdb), {0.0, 0.01}, Frame.earth_inertial_j2000())
    end
  end
end
