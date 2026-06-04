defmodule OrbitalDynamics.Propagators.TwoBodyNxCompiled do
  @moduledoc """
  Compiled Nx two-body propagation for homogeneous batches.

  This backend moves the fixed-step RK4 sample loop into `Nx.Defn`. It is more
  restrictive than `TwoBodyNx`: each sample interval must be evenly divisible by
  `max_step_s`, and the duration must be evenly divisible by `output_step_s`.
  Those restrictions keep the first compiled experiment shape-stable.
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

    defn propagate_samples(position, velocity, mu_km3_s2, opts \\ []) do
      opts =
        keyword!(opts,
          batch_size: 1,
          sample_count: 1,
          substeps_per_sample: 1,
          step_s: 1.0
        )

      batch_size = opts[:batch_size]
      sample_count = opts[:sample_count]
      substeps_per_sample = opts[:substeps_per_sample]
      step_s = opts[:step_s]

      position_samples = Nx.broadcast(0.0, {batch_size, sample_count, 3})
      velocity_samples = Nx.broadcast(0.0, {batch_size, sample_count, 3})

      position_samples = Nx.put_slice(position_samples, [0, 0, 0], Nx.new_axis(position, 1))
      velocity_samples = Nx.put_slice(velocity_samples, [0, 0, 0], Nx.new_axis(velocity, 1))

      {_, _, _, position_samples, velocity_samples, _, _, _, _} =
        while {sample_idx = 1, position, velocity, position_samples, velocity_samples,
               sample_count, substeps_per_sample, step_s, mu_km3_s2},
              sample_idx < sample_count do
          {_, position, velocity, _, _, _} =
            while {substep_idx = 0, position, velocity, substeps_per_sample, step_s, mu_km3_s2},
                  substep_idx < substeps_per_sample do
              {position, velocity} = rk4_step(position, velocity, step_s, mu_km3_s2)
              {substep_idx + 1, position, velocity, substeps_per_sample, step_s, mu_km3_s2}
            end

          position_samples =
            Nx.put_slice(position_samples, [0, sample_idx, 0], Nx.new_axis(position, 1))

          velocity_samples =
            Nx.put_slice(velocity_samples, [0, sample_idx, 0], Nx.new_axis(velocity, 1))

          {sample_idx + 1, position, velocity, position_samples, velocity_samples, sample_count,
           substeps_per_sample, step_s, mu_km3_s2}
        end

      {position_samples, velocity_samples}
    end

    defnp rk4_step(position, velocity, step_s, mu_km3_s2) do
      y0 = {position, velocity}

      k1 = derivative(y0, mu_km3_s2)
      k2 = derivative(add_scaled(y0, k1, step_s / 2.0), mu_km3_s2)
      k3 = derivative(add_scaled(y0, k2, step_s / 2.0), mu_km3_s2)
      k4 = derivative(add_scaled(y0, k3, step_s), mu_km3_s2)

      {dr, dv} =
        combine_rk4(k1, k2, k3, k4)
        |> scale_state(step_s / 6.0)

      {position + dr, velocity + dv}
    end

    defnp derivative({position, velocity}, mu_km3_s2) do
      {velocity, gravitational_acceleration(position, mu_km3_s2)}
    end

    defnp gravitational_acceleration(position, mu_km3_s2) do
      radius_km =
        position
        |> Nx.multiply(position)
        |> Nx.sum(axes: [1])
        |> Nx.sqrt()

      factor = -mu_km3_s2 / Nx.pow(radius_km, 3)

      position * Nx.new_axis(factor, -1)
    end

    defnp add_scaled({position, velocity}, {d_position, d_velocity}, scalar) do
      {position + d_position * scalar, velocity + d_velocity * scalar}
    end

    defnp combine_rk4(k1, k2, k3, k4) do
      k1
      |> add_state(scale_state(k2, 2.0))
      |> add_state(scale_state(k3, 2.0))
      |> add_state(k4)
    end

    defnp(add_state({ar, av}, {br, bv}), do: {ar + br, av + bv})
    defnp(scale_state({r, v}, scalar), do: {r * scalar, v * scalar})
  end

  @impl OrbitalDynamics.Propagator
  def capabilities do
    %{
      backend: :nx_compiled,
      force_models: [:point_mass_two_body],
      numerical_methods: [:rk4_fixed_step],
      validation_level: :educational,
      supports_batching: true,
      supports_events: false,
      supports_maneuvers: false,
      batching: %{
        homogeneous_duration: true,
        homogeneous_output_step: true,
        homogeneous_central_body: true,
        requires_duration_multiple_of_output_step: true,
        requires_output_step_multiple_of_max_step: true
      }
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
    compiler_options = Keyword.get(opts, :compiler_options, [])
    backend = Keyword.get(opts, :backend, :nx_compiled)

    with :ok <- validate_max_step(max_step_s),
         :ok <- validate_scenarios(scenarios),
         {:ok, shape} <- compiled_shape(List.first(scenarios), max_step_s) do
      {:ok, propagate_homogeneous_batch(scenarios, max_step_s, shape, compiler_options, backend)}
    end
  end

  defp propagate_homogeneous_batch(
         [first | _rest] = scenarios,
         max_step_s,
         shape,
         compiler_options,
         backend
       ) do
    sample_times = Enum.map(0..(shape.sample_count - 1), &(&1 * first.output_step_s))
    mu_km3_s2 = Nx.tensor(first.central_body.mu_km3_s2, type: :f64)

    positions =
      scenarios
      |> Enum.map(&Tuple.to_list(&1.initial_state.position_km))
      |> Nx.tensor(type: :f64)

    velocities =
      scenarios
      |> Enum.map(&Tuple.to_list(&1.initial_state.velocity_km_s))
      |> Nx.tensor(type: :f64)

    kernel_opts = [
      batch_size: length(scenarios),
      sample_count: shape.sample_count,
      substeps_per_sample: shape.substeps_per_sample,
      step_s: max_step_s * 1.0
    ]

    {position_samples, velocity_samples} =
      apply_kernel(positions, velocities, mu_km3_s2, kernel_opts, compiler_options)

    position_vectors = tensor_to_vectors(position_samples, shape.sample_count)
    velocity_vectors = tensor_to_vectors(velocity_samples, shape.sample_count)

    scenarios
    |> Enum.zip(position_vectors)
    |> Enum.zip(velocity_vectors)
    |> Enum.map(fn {{scenario, scenario_positions}, scenario_velocities} ->
      build_trajectory(
        scenario,
        scenario_positions,
        scenario_velocities,
        sample_times,
        max_step_s,
        backend
      )
    end)
  end

  defp apply_kernel(positions, velocities, mu_km3_s2, kernel_opts, []) do
    DefnKernel.propagate_samples(positions, velocities, mu_km3_s2, kernel_opts)
  end

  defp apply_kernel(positions, velocities, mu_km3_s2, kernel_opts, compiler_options) do
    Nx.Defn.jit_apply(
      &DefnKernel.propagate_samples/4,
      [positions, velocities, mu_km3_s2, kernel_opts],
      compiler_options
    )
  end

  defp build_trajectory(
         %Scenario{initial_state: %StateVector{} = initial_state} = scenario,
         positions,
         velocities,
         sample_times,
         max_step_s,
         backend
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
        force_model: :point_mass_two_body,
        numerical_method: :rk4_fixed_step,
        backend: backend,
        max_step_s: max_step_s * 1.0,
        position_unit: :kilometer,
        velocity_unit: :kilometer_per_second,
        duration_unit: :second,
        mu_km3_s2: scenario.central_body.mu_km3_s2,
        equatorial_radius_km: scenario.central_body.equatorial_radius_km,
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

  defp tensor_to_vectors(tensor, sample_count) do
    tensor
    |> Nx.to_flat_list()
    |> Enum.chunk_every(3)
    |> Enum.map(&List.to_tuple/1)
    |> Enum.chunk_every(sample_count)
  end

  defp validate_max_step(value) do
    if positive_number?(value), do: :ok, else: {:error, {:invalid_option, :max_step_s}}
  end

  defp validate_scenarios([]), do: {:error, {:invalid_batch, :empty_scenarios}}

  defp validate_scenarios([first | _rest] = scenarios) do
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

      not positive_number?(first.central_body.mu_km3_s2) ->
        {:error, {:invalid_scenario, :central_body_mu_km3_s2}}

      Enum.any?(scenarios, &(Vector3.norm(&1.initial_state.position_km) <= 0.0)) ->
        {:error, {:invalid_scenario, :initial_state_radius_km}}

      true ->
        :ok
    end
  end

  defp homogeneous?([first | rest], fun) do
    first_value = fun.(first)
    Enum.all?(rest, &(fun.(&1) == first_value))
  end

  defp whole_number?(value), do: abs(value - Float.round(value)) <= @time_epsilon_s
  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
end
