defmodule OrbitalDynamics.Search.MonteCarlo do
  @moduledoc """
  Deterministic Monte Carlo scenario expansion.

  The generator perturbs a base scenario's Cartesian initial state with
  independent normal dispersions and preserves all other scenario assumptions.
  """

  alias OrbitalDynamics.{Scenario, StateVector, Vector3}

  @doc """
  Declares the dispersion model, reproducibility policy, and known limits.
  """
  def capabilities do
    %{
      generator: :state_vector_dispersion,
      model: :seeded_independent_normal_cartesian_dispersion,
      validation_level: :assumption_declared,
      output: :scenario_candidates,
      rng: :rand_exsss,
      sampling_method: :box_muller_transform,
      deterministic_seed: true,
      known_limits: [
        :independent_axis_dispersion,
        :no_covariance_matrix,
        :no_truncated_distribution,
        :not_a_statistical_validation
      ]
    }
  end

  @doc """
  Expands one base scenario into `count` normally dispersed initial states.
  """
  def state_vector_dispersion(%Scenario{} = base_scenario, opts) when is_list(opts) do
    count = Keyword.fetch!(opts, :count)
    seed = Keyword.fetch!(opts, :seed)
    position_sigma_km = Keyword.fetch!(opts, :position_sigma_km)
    velocity_sigma_km_s = Keyword.fetch!(opts, :velocity_sigma_km_s)
    id_prefix = Keyword.get(opts, :id_prefix, "#{base_scenario.id}_mc")

    validate!(count, seed, position_sigma_km, velocity_sigma_km_s, id_prefix)

    rand_state = :rand.seed_s(:exsss, seed_tuple(seed))

    {scenarios, _rand_state} =
      Enum.map_reduce(1..count, rand_state, fn index, rand_state ->
        {position_delta_km, rand_state} = normal_vector(position_sigma_km, rand_state)
        {velocity_delta_km_s, rand_state} = normal_vector(velocity_sigma_km_s, rand_state)

        %StateVector{} = base_initial_state = base_scenario.initial_state

        initial_state = %StateVector{
          base_initial_state
          | position_km: Vector3.add(base_initial_state.position_km, position_delta_km),
            velocity_km_s: Vector3.add(base_initial_state.velocity_km_s, velocity_delta_km_s)
        }

        scenario = %Scenario{
          base_scenario
          | id: "#{id_prefix}_#{index}",
            initial_state: initial_state
        }

        {scenario, rand_state}
      end)

    scenarios
  end

  defp validate!(count, seed, position_sigma_km, velocity_sigma_km_s, id_prefix) do
    cond do
      not is_integer(count) or count <= 0 ->
        raise ArgumentError, "count must be a positive integer"

      not is_integer(seed) or seed < 0 ->
        raise ArgumentError, "seed must be a non-negative integer"

      not non_negative_vector?(position_sigma_km) ->
        raise ArgumentError, "position_sigma_km must be a non-negative numeric {x, y, z} vector"

      not non_negative_vector?(velocity_sigma_km_s) ->
        raise ArgumentError,
              "velocity_sigma_km_s must be a non-negative numeric {x, y, z} vector"

      not is_binary(id_prefix) or id_prefix == "" ->
        raise ArgumentError, "id_prefix must be a non-empty string"

      true ->
        :ok
    end
  end

  defp non_negative_vector?({x, y, z} = vector) do
    Vector3.valid?(vector) and x >= 0.0 and y >= 0.0 and z >= 0.0
  end

  defp non_negative_vector?(_vector), do: false

  defp normal_vector({sigma_x, sigma_y, sigma_z}, rand_state) do
    {x, rand_state} = normal(rand_state)
    {y, rand_state} = normal(rand_state)
    {z, rand_state} = normal(rand_state)

    {{x * sigma_x, y * sigma_y, z * sigma_z}, rand_state}
  end

  defp normal(rand_state) do
    {u1, rand_state} = :rand.uniform_s(rand_state)
    {u2, rand_state} = :rand.uniform_s(rand_state)

    z =
      :math.sqrt(-2.0 * :math.log(max(u1, 1.0e-12))) *
        :math.cos(2.0 * :math.pi() * u2)

    {z, rand_state}
  end

  defp seed_tuple(seed) do
    {
      positive_seed_part(seed),
      positive_seed_part(seed * 1_103_515_245 + 12_345),
      positive_seed_part(seed * 1_664_525 + 1_013_904_223)
    }
  end

  defp positive_seed_part(value), do: rem(value, 30_000) + 1
end
