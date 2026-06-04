defmodule OrbitalDynamics.Propagators.J2ExlaCpu do
  @moduledoc """
  EXLA CPU Earth J2 propagation for homogeneous batches.
  """

  alias OrbitalDynamics.Propagators.ManeuverSupport
  alias OrbitalDynamics.{Epoch, Scenario, StateVector, Trajectory, Vector3}

  @behaviour OrbitalDynamics.Propagator
  @behaviour OrbitalDynamics.BatchPropagator

  @default_max_step_s 60.0
  @time_epsilon_s 1.0e-12

  defmodule DefnKernel do
    @moduledoc false
    import Nx.Defn

    defn propagate_samples(position, velocity, mu, radius, j2, opts \\ []) do
      opts = keyword!(opts, batch_size: 1, sample_count: 1, substeps_per_sample: 1, step_s: 1.0)
      batch_size = opts[:batch_size]
      sample_count = opts[:sample_count]
      substeps_per_sample = opts[:substeps_per_sample]
      step_s = opts[:step_s]

      position_samples = Nx.broadcast(0.0, {batch_size, sample_count, 3})
      velocity_samples = Nx.broadcast(0.0, {batch_size, sample_count, 3})
      position_samples = Nx.put_slice(position_samples, [0, 0, 0], Nx.new_axis(position, 1))
      velocity_samples = Nx.put_slice(velocity_samples, [0, 0, 0], Nx.new_axis(velocity, 1))

      {_, _, _, position_samples, velocity_samples, _, _, _, _, _, _} =
        while {sample_idx = 1, position, velocity, position_samples, velocity_samples,
               sample_count, substeps_per_sample, step_s, mu, radius, j2},
              sample_idx < sample_count do
          {_, position, velocity, _, _, _, _, _} =
            while {substep_idx = 0, position, velocity, substeps_per_sample, step_s, mu, radius,
                   j2},
                  substep_idx < substeps_per_sample do
              {position, velocity} = rk4_step(position, velocity, step_s, mu, radius, j2)
              {substep_idx + 1, position, velocity, substeps_per_sample, step_s, mu, radius, j2}
            end

          position_samples =
            Nx.put_slice(position_samples, [0, sample_idx, 0], Nx.new_axis(position, 1))

          velocity_samples =
            Nx.put_slice(velocity_samples, [0, sample_idx, 0], Nx.new_axis(velocity, 1))

          {sample_idx + 1, position, velocity, position_samples, velocity_samples, sample_count,
           substeps_per_sample, step_s, mu, radius, j2}
        end

      {position_samples, velocity_samples}
    end

    defnp rk4_step(position, velocity, step_s, mu, radius, j2) do
      y0 = {position, velocity}
      k1 = derivative(y0, mu, radius, j2)
      k2 = derivative(add_scaled(y0, k1, step_s / 2.0), mu, radius, j2)
      k3 = derivative(add_scaled(y0, k2, step_s / 2.0), mu, radius, j2)
      k4 = derivative(add_scaled(y0, k3, step_s), mu, radius, j2)
      {dr, dv} = combine_rk4(k1, k2, k3, k4) |> scale_state(step_s / 6.0)
      {position + dr, velocity + dv}
    end

    defnp(derivative({position, velocity}, mu, radius, j2),
      do: {velocity, acceleration(position, mu, radius, j2)}
    )

    defnp acceleration(position, mu, radius, j2) do
      radius_norm = position |> Nx.multiply(position) |> Nx.sum(axes: [1]) |> Nx.sqrt()
      point_mass = position * Nx.new_axis(-mu / Nx.pow(radius_norm, 3), -1)
      z = position[[.., 2]]
      z_ratio_squared = z * z / (radius_norm * radius_norm)
      factor = 1.5 * j2 * mu * radius * radius / Nx.pow(radius_norm, 5)
      xy_scale = Nx.new_axis(factor * (5.0 * z_ratio_squared - 1.0), -1)
      z_scale = Nx.new_axis(factor * (5.0 * z_ratio_squared - 3.0), -1)
      xy = Nx.slice_along_axis(position, 0, 2, axis: 1) * xy_scale
      z_acc = Nx.new_axis(z, -1) * z_scale
      point_mass + Nx.concatenate([xy, z_acc], axis: 1)
    end

    defnp(add_scaled({position, velocity}, {d_position, d_velocity}, scalar),
      do: {position + d_position * scalar, velocity + d_velocity * scalar}
    )

    defnp(combine_rk4(k1, k2, k3, k4),
      do:
        k1 |> add_state(scale_state(k2, 2.0)) |> add_state(scale_state(k3, 2.0)) |> add_state(k4)
    )

    defnp(add_state({ar, av}, {br, bv}), do: {ar + br, av + bv})
    defnp(scale_state({r, v}, scalar), do: {r * scalar, v * scalar})
  end

  @impl OrbitalDynamics.Propagator
  def capabilities do
    %{
      backend: :exla_cpu,
      force_models: [:point_mass_two_body, :j2],
      numerical_methods: [:rk4_fixed_step],
      validation_level: :educational,
      supports_batching: true,
      supports_events: false,
      supports_maneuvers: false
    }
  end

  @impl OrbitalDynamics.Propagator
  def propagate(%Scenario{} = scenario, opts \\ []) do
    case propagate_many([scenario], opts) do
      {:ok, [trajectory]} -> {:ok, trajectory}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl OrbitalDynamics.BatchPropagator
  def propagate_many(scenarios, opts \\ []) when is_list(scenarios) do
    max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s)

    with :ok <- validate_max_step(max_step_s),
         :ok <- validate_scenarios(scenarios),
         {:ok, shape} <- compiled_shape(List.first(scenarios), max_step_s) do
      {:ok, propagate_batch(scenarios, max_step_s, shape)}
    end
  end

  defp propagate_batch([first | _] = scenarios, max_step_s, shape) do
    sample_times = Enum.map(0..(shape.sample_count - 1), &(&1 * first.output_step_s))

    positions =
      scenarios |> Enum.map(&Tuple.to_list(&1.initial_state.position_km)) |> Nx.tensor(type: :f64)

    velocities =
      scenarios
      |> Enum.map(&Tuple.to_list(&1.initial_state.velocity_km_s))
      |> Nx.tensor(type: :f64)

    {position_samples, velocity_samples} =
      Nx.Defn.jit_apply(
        &DefnKernel.propagate_samples/6,
        [
          positions,
          velocities,
          Nx.tensor(first.central_body.mu_km3_s2, type: :f64),
          Nx.tensor(first.central_body.equatorial_radius_km, type: :f64),
          Nx.tensor(first.central_body.j2, type: :f64),
          [
            batch_size: length(scenarios),
            sample_count: shape.sample_count,
            substeps_per_sample: shape.substeps_per_sample,
            step_s: max_step_s * 1.0
          ]
        ],
        compiler: EXLA,
        client: :host
      )

    position_vectors = tensor_to_vectors(position_samples, shape.sample_count)
    velocity_vectors = tensor_to_vectors(velocity_samples, shape.sample_count)

    scenarios
    |> Enum.zip(position_vectors)
    |> Enum.zip(velocity_vectors)
    |> Enum.map(fn {{scenario, positions}, velocities} ->
      build_trajectory(scenario, positions, velocities, sample_times, max_step_s)
    end)
  end

  defp build_trajectory(
         %Scenario{initial_state: %StateVector{} = initial_state} = scenario,
         positions,
         velocities,
         sample_times,
         max_step_s
       ) do
    states =
      positions
      |> Enum.zip(velocities)
      |> Enum.zip(sample_times)
      |> Enum.map(fn {{position, velocity}, sample_time_s} ->
        %StateVector{
          initial_state
          | position_km: position,
            velocity_km_s: velocity,
            epoch: Epoch.shift(initial_state.epoch, sample_time_s)
        }
      end)

    %Trajectory{
      scenario_id: scenario.id,
      states: states,
      assumptions: %{
        force_model: :earth_j2,
        numerical_method: :rk4_fixed_step,
        backend: :exla_cpu,
        max_step_s: max_step_s * 1.0,
        position_unit: :kilometer,
        velocity_unit: :kilometer_per_second,
        duration_unit: :second,
        mu_km3_s2: scenario.central_body.mu_km3_s2,
        equatorial_radius_km: scenario.central_body.equatorial_radius_km,
        j2: scenario.central_body.j2,
        frame: scenario.initial_state.frame.name,
        epoch_scale: scenario.initial_state.epoch.scale
      }
    }
  end

  defp compiled_shape(scenario, max_step_s) do
    duration_steps = scenario.duration_s / scenario.output_step_s
    substeps_per_sample = scenario.output_step_s / max_step_s

    cond do
      not whole_number?(duration_steps) ->
        {:error, {:unsupported_batch, :duration_not_multiple_of_output_step_s}}

      not whole_number?(substeps_per_sample) ->
        {:error, {:unsupported_batch, :output_step_not_multiple_of_max_step_s}}

      true ->
        {:ok,
         %{
           sample_count: trunc(Float.round(duration_steps)) + 1,
           substeps_per_sample: trunc(Float.round(substeps_per_sample))
         }}
    end
  end

  defp tensor_to_vectors(tensor, sample_count),
    do:
      tensor
      |> Nx.to_flat_list()
      |> Enum.chunk_every(3)
      |> Enum.map(&List.to_tuple/1)
      |> Enum.chunk_every(sample_count)

  defp validate_max_step(value),
    do: if(positive_number?(value), do: :ok, else: {:error, {:invalid_option, :max_step_s}})

  defp validate_scenarios([]), do: {:error, {:invalid_batch, :empty_scenarios}}

  defp validate_scenarios([first | _] = scenarios) do
    cond do
      not Enum.all?(scenarios, &match?(%Scenario{}, &1)) ->
        {:error, {:invalid_batch, :scenario}}

      not homogeneous?(scenarios, & &1.duration_s) ->
        {:error, {:unsupported_batch, :heterogeneous_duration_s}}

      not homogeneous?(scenarios, & &1.output_step_s) ->
        {:error, {:unsupported_batch, :heterogeneous_output_step_s}}

      not homogeneous?(scenarios, & &1.central_body.name) or
          not homogeneous?(scenarios, & &1.central_body.mu_km3_s2) ->
        {:error, {:unsupported_batch, :heterogeneous_central_body}}

      ManeuverSupport.reject_maneuver_batch(scenarios) != :ok ->
        {:error, {:unsupported_scenario, :maneuvers}}

      first.central_body.name != :earth ->
        {:error, {:unsupported_scenario, :central_body}}

      not positive_number?(first.central_body.equatorial_radius_km) ->
        {:error, {:invalid_scenario, :equatorial_radius_km}}

      not non_negative_number?(first.central_body.j2) ->
        {:error, {:invalid_scenario, :j2}}

      Enum.any?(scenarios, &(Vector3.norm(&1.initial_state.position_km) <= 0.0)) ->
        {:error, {:invalid_scenario, :initial_state_radius_km}}

      true ->
        :ok
    end
  end

  defp homogeneous?([first | rest], fun), do: Enum.all?(rest, &(fun.(&1) == fun.(first)))
  defp whole_number?(value), do: abs(value - Float.round(value)) <= @time_epsilon_s
  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0
end
