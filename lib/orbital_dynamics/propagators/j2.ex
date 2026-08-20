defmodule OrbitalDynamics.Propagators.J2 do
  @moduledoc """
  Deterministic Earth J2 propagation.

  This propagator applies point-mass gravity plus the oblateness perturbation
  from the central body's `j2` and `equatorial_radius_km` values.
  """

  alias OrbitalDynamics.Propagators.ManeuverSupport
  alias OrbitalDynamics.{Epoch, Scenario, StateVector, Trajectory, Vector3}

  @behaviour OrbitalDynamics.Propagator

  @default_max_step_s 60.0
  @time_epsilon_s 1.0e-12

  @impl OrbitalDynamics.Propagator
  def capabilities do
    %{
      backend: :scalar_elixir,
      force_models: [:point_mass_two_body, :j2],
      numerical_methods: [:rk4_fixed_step],
      validation_level: :educational,
      supports_batching: false,
      supports_events: false,
      supports_maneuvers: true
    }
  end

  @impl OrbitalDynamics.Propagator
  def propagate(%Scenario{} = scenario, opts \\ []) do
    max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s)

    with :ok <- validate_max_step(max_step_s),
         :ok <- validate_scenario(scenario),
         :ok <- ManeuverSupport.validate_scalar_maneuvers(scenario, max_step_s) do
      {:ok, propagate!(scenario, max_step_s)}
    end
  end

  def propagate!(scenario, max_step_s_or_opts \\ @default_max_step_s)

  def propagate!(%Scenario{} = scenario, opts) when is_list(opts) do
    max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s)
    propagate!(scenario, max_step_s)
  end

  def propagate!(%Scenario{} = scenario, max_step_s)
      when is_integer(max_step_s) or is_float(max_step_s) do
    unless positive_number?(max_step_s),
      do: raise(ArgumentError, "max_step_s must be positive seconds")

    sample_times = sample_times(scenario.duration_s, scenario.output_step_s)
    elapsed_burns = ManeuverSupport.elapsed_burns(scenario)

    states =
      propagate_samples(
        scenario.initial_state,
        sample_times,
        max_step_s,
        scenario.central_body.mu_km3_s2,
        scenario.central_body.equatorial_radius_km,
        scenario.central_body.j2,
        elapsed_burns
      )

    %Trajectory{
      scenario_id: scenario.id,
      states: states,
      assumptions:
        %{
          force_model: :earth_j2,
          numerical_method: :rk4_fixed_step,
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
        |> maybe_merge_scenario_metadata(scenario.metadata)
        |> Map.merge(ManeuverSupport.maneuver_assumptions(scenario.maneuvers))
    }
  end

  def acceleration(position_km, mu_km3_s2, equatorial_radius_km, j2) do
    position_km
    |> acceleration_components(mu_km3_s2, equatorial_radius_km, j2)
    |> Map.fetch!(:total_acceleration_km_s2)
  end

  @doc """
  Returns the point-mass, J2, and summed acceleration vectors.

  This is the same component calculation used by J2 propagation. It exists so
  combined force models can compose the declared vectors without reimplementing
  or sequentially propagating the J2 path.
  """
  def acceleration_components(position_km, mu_km3_s2, equatorial_radius_km, j2) do
    radius_km = Vector3.norm(position_km)

    if radius_km <= 0.0 do
      raise ArithmeticError, "J2 propagation requires non-zero radius"
    end

    point_mass = Vector3.scale(position_km, -mu_km3_s2 / :math.pow(radius_km, 3))
    {x, y, z} = position_km
    radius_squared = radius_km * radius_km
    z_ratio_squared = z * z / radius_squared

    factor =
      1.5 * j2 * mu_km3_s2 * equatorial_radius_km * equatorial_radius_km / :math.pow(radius_km, 5)

    j2_acceleration = {
      factor * x * (5.0 * z_ratio_squared - 1.0),
      factor * y * (5.0 * z_ratio_squared - 1.0),
      factor * z * (5.0 * z_ratio_squared - 3.0)
    }

    %{
      point_mass_acceleration_km_s2: point_mass,
      j2_acceleration_km_s2: j2_acceleration,
      total_acceleration_km_s2: Vector3.add(point_mass, j2_acceleration)
    }
  end

  defp propagate_samples(
         initial_state,
         sample_times,
         max_step_s,
         mu_km3_s2,
         equatorial_radius_km,
         j2,
         elapsed_burns
       ) do
    {states, _acc} =
      Enum.map_reduce(sample_times, {0.0, initial_state, elapsed_burns}, fn sample_time_s,
                                                                            {elapsed_s, state,
                                                                             burns} ->
        {next_state, next_elapsed_s, remaining_burns} =
          propagate_to_sample(
            state,
            elapsed_s,
            sample_time_s,
            burns,
            max_step_s,
            mu_km3_s2,
            equatorial_radius_km,
            j2
          )

        {next_state, {next_elapsed_s, next_state, remaining_burns}}
      end)

    states
  end

  defp propagate_to_sample(
         state,
         elapsed_s,
         sample_time_s,
         burns,
         max_step_s,
         mu_km3_s2,
         equatorial_radius_km,
         j2
       ) do
    {state, burns} = ManeuverSupport.apply_due_burns(state, elapsed_s, burns)

    case burns do
      [{burn_elapsed_s, _burn} | _rest] when burn_elapsed_s <= sample_time_s ->
        state =
          integrate_for(
            state,
            burn_elapsed_s - elapsed_s,
            max_step_s,
            mu_km3_s2,
            equatorial_radius_km,
            j2
          )

        {state, burns} = ManeuverSupport.apply_due_burns(state, burn_elapsed_s, burns)

        propagate_to_sample(
          state,
          burn_elapsed_s,
          sample_time_s,
          burns,
          max_step_s,
          mu_km3_s2,
          equatorial_radius_km,
          j2
        )

      _other ->
        delta_s = sample_time_s - elapsed_s

        next_state =
          integrate_for(state, delta_s, max_step_s, mu_km3_s2, equatorial_radius_km, j2)

        {next_state, sample_time_s, burns}
    end
  end

  defp sample_times(duration_s, output_step_s) do
    full_steps = trunc(Float.floor(duration_s / output_step_s))
    samples = Enum.map(0..full_steps, &(&1 * output_step_s))
    final_sample = List.last(samples)

    if close?(final_sample, duration_s),
      do: List.replace_at(samples, -1, duration_s * 1.0),
      else: samples ++ [duration_s * 1.0]
  end

  defp integrate_for(%StateVector{} = state, duration_s, _max_step_s, _mu, _radius, _j2)
       when duration_s >= 0 and duration_s <= @time_epsilon_s,
       do: state

  defp integrate_for(%StateVector{} = state, duration_s, max_step_s, mu, radius, j2)
       when duration_s >= 0 do
    step_s = min(duration_s, max_step_s)
    next_state = rk4_step(state, step_s, mu, radius, j2)
    remaining_s = duration_s - step_s

    if remaining_s <= @time_epsilon_s,
      do: next_state,
      else: integrate_for(next_state, remaining_s, max_step_s, mu, radius, j2)
  end

  defp rk4_step(%StateVector{} = state, step_s, mu, radius, j2) do
    y0 = {state.position_km, state.velocity_km_s}

    k1 = derivative(y0, mu, radius, j2)
    k2 = derivative(add_scaled(y0, k1, step_s / 2.0), mu, radius, j2)
    k3 = derivative(add_scaled(y0, k2, step_s / 2.0), mu, radius, j2)
    k4 = derivative(add_scaled(y0, k3, step_s), mu, radius, j2)

    {dr, dv} = combine_rk4(k1, k2, k3, k4) |> scale_state(step_s / 6.0)

    %{
      state
      | position_km: Vector3.add(state.position_km, dr),
        velocity_km_s: Vector3.add(state.velocity_km_s, dv),
        epoch: Epoch.shift(state.epoch, step_s)
    }
  end

  defp derivative({position_km, velocity_km_s}, mu, radius, j2) do
    {velocity_km_s, acceleration(position_km, mu, radius, j2)}
  end

  defp add_scaled({position, velocity}, {d_position, d_velocity}, scalar) do
    {Vector3.add(position, Vector3.scale(d_position, scalar)),
     Vector3.add(velocity, Vector3.scale(d_velocity, scalar))}
  end

  defp combine_rk4(k1, k2, k3, k4),
    do: k1 |> add_state(scale_state(k2, 2.0)) |> add_state(scale_state(k3, 2.0)) |> add_state(k4)

  defp add_state({ar, av}, {br, bv}), do: {Vector3.add(ar, br), Vector3.add(av, bv)}
  defp scale_state({r, v}, scalar), do: {Vector3.scale(r, scalar), Vector3.scale(v, scalar)}

  defp maybe_merge_scenario_metadata(assumptions, metadata) when metadata == %{}, do: assumptions

  defp maybe_merge_scenario_metadata(assumptions, metadata),
    do: Map.put(assumptions, :scenario_metadata, metadata)

  defp validate_max_step(value),
    do: if(positive_number?(value), do: :ok, else: {:error, {:invalid_option, :max_step_s}})

  defp validate_scenario(%Scenario{} = scenario) do
    cond do
      not positive_number?(scenario.central_body.mu_km3_s2) ->
        {:error, {:invalid_scenario, :central_body_mu_km3_s2}}

      not positive_number?(scenario.central_body.equatorial_radius_km) ->
        {:error, {:invalid_scenario, :equatorial_radius_km}}

      not non_negative_number?(scenario.central_body.j2) ->
        {:error, {:invalid_scenario, :j2}}

      scenario.central_body.name != :earth ->
        {:error, {:unsupported_scenario, :central_body}}

      Vector3.norm(scenario.initial_state.position_km) <= 0.0 ->
        {:error, {:invalid_scenario, :initial_state_radius_km}}

      true ->
        :ok
    end
  end

  defp close?(left, right), do: abs(left - right) <= @time_epsilon_s
  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0
end
