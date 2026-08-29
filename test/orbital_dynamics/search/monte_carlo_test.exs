defmodule OrbitalDynamics.Search.MonteCarloTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Search.MonteCarlo
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
             generator: :state_vector_dispersion,
             validation_level: :assumption_declared,
             output: :scenario_candidates,
             rng: :rand_exsss,
             sampling_method: :box_muller_transform,
             deterministic_seed: true,
             known_limits: known_limits
           } = MonteCarlo.capabilities()

    assert :independent_axis_dispersion in known_limits
    assert :no_covariance_matrix in known_limits
  end

  test "expands deterministic state vector dispersions from a seed" do
    opts = [
      count: 3,
      seed: 12_345,
      position_sigma_km: {0.1, 0.1, 0.05},
      velocity_sigma_km_s: {0.0001, 0.0001, 0.00005},
      id_prefix: "dispersion"
    ]

    first_run = MonteCarlo.state_vector_dispersion(base_scenario(), opts)
    second_run = MonteCarlo.state_vector_dispersion(base_scenario(), opts)

    assert Enum.map(first_run, & &1.id) == ["dispersion_1", "dispersion_2", "dispersion_3"]
    assert Enum.map(first_run, & &1.initial_state) == Enum.map(second_run, & &1.initial_state)
    assert hd(first_run).initial_state.position_km != base_scenario().initial_state.position_km
  end

  test "zero sigmas preserve the base initial state" do
    scenarios =
      MonteCarlo.state_vector_dispersion(base_scenario(),
        count: 2,
        seed: 1,
        position_sigma_km: {0.0, 0.0, 0.0},
        velocity_sigma_km_s: {0.0, 0.0, 0.0}
      )

    assert Enum.all?(scenarios, fn scenario ->
             scenario.initial_state.position_km == base_scenario().initial_state.position_km and
               scenario.initial_state.velocity_km_s == base_scenario().initial_state.velocity_km_s
           end)
  end

  test "preserves a canonical id prefix and rejects every invalid prefix before output" do
    opts = [
      count: 1,
      seed: 1,
      position_sigma_km: {0.0, 0.0, 0.0},
      velocity_sigma_km_s: {0.0, 0.0, 0.0}
    ]

    assert [%{id: "Mission.1:@-x_1"}] =
             MonteCarlo.state_vector_dispersion(
               base_scenario(),
               Keyword.put(opts, :id_prefix, "Mission.1:@-x")
             )

    Enum.each(@invalid_id_prefixes, fn invalid_id_prefix ->
      assert_raise ArgumentError, @id_prefix_error, fn ->
        MonteCarlo.state_vector_dispersion(
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
        {7000.0, 0.0, 0.0},
        {0.0, 7.5, 0.0},
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    spacecraft = Spacecraft.new!(:sat_1, 250.0)

    Scenario.new!("base", spacecraft, state,
      duration_s: 120.0,
      output_step_s: 60.0,
      central_body: earth
    )
  end
end
