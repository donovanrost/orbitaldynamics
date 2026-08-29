defmodule OrbitalDynamics.Search.GridTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Search.Grid
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector}

  @id_prefix_error "id_prefix must be a valid stable ID"
  @invalid_id_prefixes [
    nil,
    :invalid,
    0,
    [],
    %{},
    "",
    " ",
    "\n",
    "prefix\n",
    "_leading",
    "-leading",
    ".leading",
    ":leading",
    "contains/slash",
    "contains\tcontrol",
    <<0xFF>>
  ]

  test "declares generator capabilities" do
    assert %{
             generator: :impulsive_burn_grid,
             validation_level: :assumption_declared,
             output: :scenario_candidates,
             ordering: :input_order_cartesian_product,
             random?: false,
             known_limits: known_limits
           } = Grid.capabilities()

    assert :impulsive_burn_only in known_limits
    assert :no_optimizer in known_limits
  end

  test "expands a deterministic impulsive-burn grid" do
    base = base_scenario()

    scenarios =
      Grid.impulsive_burn_grid(base,
        id_prefix: "raise_apogee",
        burn_epoch_s: [55.0, 60.0],
        delta_v_km_s: [{0.0, 0.005, 0.0}, {0.0, 0.01, 0.0}]
      )

    assert Enum.map(scenarios, & &1.id) == [
             "raise_apogee_1_1",
             "raise_apogee_1_2",
             "raise_apogee_2_1",
             "raise_apogee_2_2"
           ]

    assert [first | _] = scenarios
    assert [burn] = first.maneuvers
    assert burn.id == "raise_apogee_1_1_burn"
    assert burn.epoch.seconds_since_j2000 == 55.0
    assert burn.delta_v_km_s == {0.0, 0.005, 0.0}
  end

  test "preserves a canonical id prefix and rejects every invalid prefix before output" do
    opts = [burn_epoch_s: [55.0], delta_v_km_s: [{0.0, 0.005, 0.0}]]

    assert [%{id: "Mission.1:@-x_1_1", maneuvers: [%{id: "Mission.1:@-x_1_1_burn"}]}] =
             Grid.impulsive_burn_grid(
               base_scenario(),
               Keyword.put(opts, :id_prefix, "Mission.1:@-x")
             )

    Enum.each(@invalid_id_prefixes, fn invalid_id_prefix ->
      assert_raise ArgumentError, @id_prefix_error, fn ->
        Grid.impulsive_burn_grid(
          base_scenario(),
          Keyword.put(opts, :id_prefix, invalid_id_prefix)
        )
      end
    end)
  end

  defp base_scenario do
    earth = CentralBody.earth()

    state =
      StateVector.new!(
        {7_000.0, 0.0, 0.0},
        {0.0, 7.5, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    Scenario.new!("base", Spacecraft.new!("sat", 250.0), state,
      duration_s: 120.0,
      output_step_s: 60.0,
      central_body: earth
    )
  end
end
