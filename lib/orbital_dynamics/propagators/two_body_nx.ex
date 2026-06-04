defmodule OrbitalDynamics.Propagators.TwoBodyNx do
  @moduledoc """
  Batched point-mass two-body propagation using Nx tensors.

  This backend is an experiment target, not a replacement for the scalar
  propagator. It evaluates homogeneous scenario batches with tensor operations
  and converts the result back into normal `Trajectory` structs for callers.
  """

  alias OrbitalDynamics.Propagators.ManeuverSupport
  alias OrbitalDynamics.{Epoch, Scenario, StateVector, Trajectory, Vector3}

  @behaviour OrbitalDynamics.Propagator
  @behaviour OrbitalDynamics.BatchPropagator

  @default_max_step_s 60.0
  @time_epsilon_s 1.0e-12

  @impl OrbitalDynamics.Propagator
  def capabilities do
    %{
      backend: :nx,
      force_models: [:point_mass_two_body],
      numerical_methods: [:rk4_fixed_step],
      validation_level: :educational,
      supports_batching: true,
      supports_events: false,
      supports_maneuvers: false,
      batching: %{
        homogeneous_duration: true,
        homogeneous_output_step: true,
        homogeneous_central_body: true
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

    with :ok <- validate_max_step(max_step_s),
         :ok <- validate_scenarios(scenarios) do
      {:ok, propagate_homogeneous_batch(scenarios, max_step_s)}
    end
  end

  defp propagate_homogeneous_batch([first | _rest] = scenarios, max_step_s) do
    sample_times = sample_times(first.duration_s, first.output_step_s)
    mu_km3_s2 = first.central_body.mu_km3_s2

    positions =
      scenarios
      |> Enum.map(&Tuple.to_list(&1.initial_state.position_km))
      |> Nx.tensor(type: :f64)

    velocities =
      scenarios
      |> Enum.map(&Tuple.to_list(&1.initial_state.velocity_km_s))
      |> Nx.tensor(type: :f64)

    {samples, _acc} =
      Enum.map_reduce(sample_times, {0.0, positions, velocities}, fn sample_time_s,
                                                                     {elapsed_s, position,
                                                                      velocity} ->
        delta_s = sample_time_s - elapsed_s

        {next_position, next_velocity} =
          integrate_for(position, velocity, delta_s, max_step_s, mu_km3_s2)

        {{next_position, next_velocity}, {sample_time_s, next_position, next_velocity}}
      end)

    {position_samples, velocity_samples} = Enum.unzip(samples)

    position_vectors =
      position_samples |> Nx.stack(axis: 1) |> tensor_to_vectors(length(sample_times))

    velocity_vectors =
      velocity_samples |> Nx.stack(axis: 1) |> tensor_to_vectors(length(sample_times))

    scenarios
    |> Enum.zip(position_vectors)
    |> Enum.zip(velocity_vectors)
    |> Enum.map(fn {{scenario, scenario_positions}, scenario_velocities} ->
      build_trajectory(
        scenario,
        scenario_positions,
        scenario_velocities,
        sample_times,
        max_step_s
      )
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
        force_model: :point_mass_two_body,
        numerical_method: :rk4_fixed_step,
        backend: :nx,
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

  defp integrate_for(position, velocity, duration_s, _max_step_s, _mu_km3_s2)
       when duration_s >= 0 and duration_s <= @time_epsilon_s,
       do: {position, velocity}

  defp integrate_for(position, velocity, duration_s, max_step_s, mu_km3_s2)
       when duration_s >= 0 do
    step_s = min(duration_s, max_step_s)
    {next_position, next_velocity} = rk4_step(position, velocity, step_s, mu_km3_s2)
    remaining_s = duration_s - step_s

    if remaining_s <= @time_epsilon_s do
      {next_position, next_velocity}
    else
      integrate_for(next_position, next_velocity, remaining_s, max_step_s, mu_km3_s2)
    end
  end

  defp rk4_step(position, velocity, step_s, mu_km3_s2) do
    y0 = {position, velocity}

    k1 = derivative(y0, mu_km3_s2)
    k2 = derivative(add_scaled(y0, k1, step_s / 2.0), mu_km3_s2)
    k3 = derivative(add_scaled(y0, k2, step_s / 2.0), mu_km3_s2)
    k4 = derivative(add_scaled(y0, k3, step_s), mu_km3_s2)

    {dr, dv} =
      combine_rk4(k1, k2, k3, k4)
      |> scale_state(step_s / 6.0)

    {Nx.add(position, dr), Nx.add(velocity, dv)}
  end

  defp derivative({position, velocity}, mu_km3_s2) do
    {velocity, gravitational_acceleration(position, mu_km3_s2)}
  end

  defp gravitational_acceleration(position, mu_km3_s2) do
    radius_km =
      position
      |> Nx.multiply(position)
      |> Nx.sum(axes: [1])
      |> Nx.sqrt()

    factor = Nx.divide(-mu_km3_s2, Nx.pow(radius_km, 3))

    Nx.multiply(position, Nx.new_axis(factor, -1))
  end

  defp add_scaled({position, velocity}, {d_position, d_velocity}, scalar) do
    {
      Nx.add(position, Nx.multiply(d_position, scalar)),
      Nx.add(velocity, Nx.multiply(d_velocity, scalar))
    }
  end

  defp combine_rk4(k1, k2, k3, k4) do
    k1
    |> add_state(scale_state(k2, 2.0))
    |> add_state(scale_state(k3, 2.0))
    |> add_state(k4)
  end

  defp add_state({ar, av}, {br, bv}), do: {Nx.add(ar, br), Nx.add(av, bv)}
  defp scale_state({r, v}, scalar), do: {Nx.multiply(r, scalar), Nx.multiply(v, scalar)}

  defp tensor_to_vectors(tensor, sample_count) do
    tensor
    |> Nx.to_flat_list()
    |> Enum.chunk_every(3)
    |> Enum.map(&List.to_tuple/1)
    |> Enum.chunk_every(sample_count)
  end

  defp sample_times(duration_s, output_step_s) do
    full_steps = trunc(Float.floor(duration_s / output_step_s))
    samples = Enum.map(0..full_steps, &(&1 * output_step_s))
    final_sample = List.last(samples)

    if close?(final_sample, duration_s) do
      List.replace_at(samples, -1, duration_s * 1.0)
    else
      samples ++ [duration_s * 1.0]
    end
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

  defp close?(left, right), do: abs(left - right) <= @time_epsilon_s
  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
end
