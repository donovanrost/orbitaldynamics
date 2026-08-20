defmodule OrbitalDynamics.Search.LocalTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Search.Local

  test "declares a deterministic bounded neighborhood and honest model limits" do
    assert %{
             generator: :numeric_parameter_local_neighborhood,
             model: :deterministic_bounded_single_axis_step,
             validation_level: :input_validated,
             output: :inspectable_parameter_alternatives,
             ordering: :seed_then_parameter_ascending_then_decrease_increase,
             random?: false,
             default_max_alternatives: 17,
             max_step_parameters: 32,
             max_alternatives_limit: 65,
             known_limits: known_limits
           } = Local.capabilities()

    assert :numeric_scalar_parameters_only in known_limits
    assert :single_axis_single_step_moves_only in known_limits
    assert :one_neighborhood_generation in known_limits
    assert :no_constraint_evaluation in known_limits
    assert :no_solver in known_limits
  end

  test "generates a bounded inspectable neighborhood in stable parameter and move order" do
    neighborhood =
      Local.neighborhood(%{"alpha" => 1.0, z: 3.0},
        steps: %{z: 0.5, alpha: 1.0},
        bounds: %{alpha: {0.0, 1.0}, z: {2.5, 4.0}},
        id_prefix: "trial",
        max_alternatives: 3
      )

    assert neighborhood["step_parameters"] == ["alpha", "z"]
    assert neighborhood["generated_move_count"] == 4
    assert neighborhood["feasible_move_count"] == 3
    assert neighborhood["alternative_count"] == 3
    assert neighborhood["rejected_move_count"] == 2
    assert neighborhood["truncated_move_count"] == 1

    assert Enum.map(neighborhood["alternatives"], & &1["id"]) == [
             "trial:seed",
             "trial:alpha:decrease",
             "trial:z:decrease"
           ]

    assert Enum.map(neighborhood["alternatives"], & &1["generation_index"]) == [0, 1, 3]

    assert %{
             "parameters" => parameters,
             "move" => %{
               "parameter" => "alpha",
               "direction" => "decrease",
               "delta" => -1.0,
               "from" => 1.0,
               "to" => to
             }
           } = Enum.at(neighborhood["alternatives"], 1)

    assert parameters == %{"alpha" => 0.0, "z" => 3.0}
    assert to == 0.0

    assert Enum.map(neighborhood["rejected_moves"], &{&1["id"], &1["reason"]}) == [
             {"trial:alpha:increase", "above_maximum_bound"},
             {"trial:z:increase", "alternative_limit"}
           ]
  end

  test "rejects malformed or unsafe neighborhood inputs" do
    assert_raise ArgumentError, "steps must contain only positive numeric values", fn ->
      Local.neighborhood(%{x: 1.0}, steps: %{x: 0.0})
    end

    assert_raise ArgumentError, "steps keys must identify seed parameters", fn ->
      Local.neighborhood(%{x: 1.0}, steps: %{y: 1.0})
    end

    assert_raise ArgumentError, "seed parameter x must be within its declared bound", fn ->
      Local.neighborhood(%{x: 1.0}, steps: %{x: 0.5}, bounds: %{x: {2.0, 3.0}})
    end

    assert_raise ArgumentError, ~r/max_alternatives must be an integer from 1 through 65/, fn ->
      Local.neighborhood(%{x: 1.0}, steps: %{x: 0.5}, max_alternatives: 66)
    end

    too_many_parameters = Map.new(1..33, &{"p#{&1}", 1.0})

    assert_raise ArgumentError, "steps may contain at most 32 parameters", fn ->
      Local.neighborhood(too_many_parameters, steps: too_many_parameters)
    end
  end

  test "repeats byte-for-byte equivalent neighborhood data" do
    opts = [
      steps: %{burn_epoch_s: 5.0, tangential_delta_v_km_s: 0.002},
      bounds: %{burn_epoch_s: {50.0, 70.0}, tangential_delta_v_km_s: {0.0, 0.02}},
      id_prefix: "raise_apogee",
      max_alternatives: 5
    ]

    first = Local.neighborhood(%{burn_epoch_s: 60.0, tangential_delta_v_km_s: 0.01}, opts)
    second = Local.neighborhood(%{tangential_delta_v_km_s: 0.01, burn_epoch_s: 60.0}, opts)

    assert first == second
  end
end
