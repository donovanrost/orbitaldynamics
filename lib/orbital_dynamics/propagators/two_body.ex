defmodule OrbitalDynamics.Propagators.TwoBody do
  @moduledoc """
  Deterministic point-mass two-body propagation.

  The default implementation uses fixed-step fourth-order Runge-Kutta
  integration. Callers can opt into deterministic step-doubling adaptation for
  event-sensitive educational studies, but the default remains fixed-step so
  repeated scenario runs keep the same numerical assumptions.
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
      force_models: [:point_mass_two_body],
      numerical_methods: [:rk4_fixed_step, :rk4_adaptive_step_doubling],
      validation_level: :educational,
      supports_batching: false,
      supports_events: false,
      supports_maneuvers: true,
      supports_adaptive_step: true
    }
  end

  @doc """
  Propagates a scenario and returns `{:ok, trajectory}`.

  Options:

    * `:max_step_s` - maximum RK4 integration step in seconds, default 60.0
    * `:integration` - `:fixed_step` or `:adaptive_step`, default `:fixed_step`
    * `:min_step_s` - lower bound for adaptive step splitting
    * `:adaptive_position_tolerance_km` - step-doubling position tolerance
    * `:adaptive_velocity_tolerance_km_s` - step-doubling velocity tolerance
  """
  @impl OrbitalDynamics.Propagator
  def propagate(%Scenario{} = scenario, opts \\ []) do
    max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s)

    with {:ok, integration} <- integration_options(opts),
         :ok <- validate_scenario(scenario),
         :ok <- ManeuverSupport.validate_scalar_maneuvers(scenario, max_step_s) do
      {:ok, do_propagate(scenario, integration)}
    end
  end

  @doc """
  Propagates a scenario or raises for invalid numerical options.
  """
  def propagate!(scenario, max_step_s_or_opts \\ @default_max_step_s)

  def propagate!(%Scenario{} = scenario, opts) when is_list(opts) do
    integration =
      case integration_options(opts) do
        {:ok, integration} -> integration
        {:error, {:invalid_option, option}} -> raise ArgumentError, "#{option} is invalid"
      end

    do_propagate(scenario, integration)
  end

  def propagate!(%Scenario{} = scenario, max_step_s)
      when is_integer(max_step_s) or is_float(max_step_s) do
    unless positive_number?(max_step_s) do
      raise ArgumentError, "max_step_s must be positive seconds"
    end

    do_propagate(scenario, fixed_step_options(max_step_s))
  end

  defp do_propagate(%Scenario{} = scenario, integration) do
    sample_times = sample_times(scenario.duration_s, scenario.output_step_s)
    elapsed_burns = ManeuverSupport.elapsed_burns(scenario)

    {states, integration_stats} =
      propagate_samples(
        scenario.initial_state,
        sample_times,
        integration,
        scenario.central_body.mu_km3_s2,
        elapsed_burns
      )

    %Trajectory{
      scenario_id: scenario.id,
      states: states,
      assumptions:
        %{
          force_model: :point_mass_two_body,
          position_unit: :kilometer,
          velocity_unit: :kilometer_per_second,
          duration_unit: :second,
          mu_km3_s2: scenario.central_body.mu_km3_s2,
          equatorial_radius_km: scenario.central_body.equatorial_radius_km,
          frame: scenario.initial_state.frame.name,
          epoch_scale: scenario.initial_state.epoch.scale
        }
        |> Map.merge(integration_assumptions(integration, integration_stats))
        |> maybe_merge_scenario_metadata(scenario.metadata)
        |> Map.merge(ManeuverSupport.maneuver_assumptions(scenario.maneuvers))
    }
  end

  defp propagate_samples(initial_state, sample_times, integration, mu_km3_s2, elapsed_burns) do
    {states, {_elapsed_s, _state, _burns, integration_stats}} =
      Enum.map_reduce(
        sample_times,
        {0.0, initial_state, elapsed_burns, empty_integration_stats()},
        fn sample_time_s, {elapsed_s, state, burns, stats} ->
          {next_state, next_elapsed_s, remaining_burns, sample_stats} =
            propagate_to_sample(state, elapsed_s, sample_time_s, burns, integration, mu_km3_s2)

          {next_state,
           {next_elapsed_s, next_state, remaining_burns, merge_stats(stats, sample_stats)}}
        end
      )

    {states, integration_stats}
  end

  defp propagate_to_sample(state, elapsed_s, sample_time_s, burns, integration, mu_km3_s2) do
    {state, burns} = ManeuverSupport.apply_due_burns(state, elapsed_s, burns)

    case burns do
      [{burn_elapsed_s, _burn} | _rest] when burn_elapsed_s <= sample_time_s ->
        {state, burn_stats} =
          integrate_for(state, burn_elapsed_s - elapsed_s, integration, mu_km3_s2)

        {state, burns} = ManeuverSupport.apply_due_burns(state, burn_elapsed_s, burns)

        {state, next_elapsed_s, burns, sample_stats} =
          propagate_to_sample(state, burn_elapsed_s, sample_time_s, burns, integration, mu_km3_s2)

        {state, next_elapsed_s, burns, merge_stats(burn_stats, sample_stats)}

      _other ->
        delta_s = sample_time_s - elapsed_s
        {next_state, stats} = integrate_for(state, delta_s, integration, mu_km3_s2)
        {next_state, sample_time_s, burns, stats}
    end
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

  defp integrate_for(%StateVector{} = state, duration_s, _integration, _mu_km3_s2)
       when duration_s >= 0 and duration_s <= @time_epsilon_s,
       do: {state, empty_integration_stats()}

  defp integrate_for(
         %StateVector{} = state,
         duration_s,
         %{mode: :fixed_step, max_step_s: max_step_s},
         mu_km3_s2
       )
       when duration_s >= 0 do
    {integrate_fixed(state, duration_s, max_step_s, mu_km3_s2), empty_integration_stats()}
  end

  defp integrate_for(
         %StateVector{} = state,
         duration_s,
         %{mode: :adaptive_step} = integration,
         mu_km3_s2
       )
       when duration_s >= 0 do
    integrate_adaptive(
      state,
      duration_s,
      min(duration_s, integration.max_step_s),
      integration,
      mu_km3_s2,
      empty_integration_stats()
    )
  end

  defp integrate_fixed(%StateVector{} = state, duration_s, _max_step_s, _mu_km3_s2)
       when duration_s >= 0 and duration_s <= @time_epsilon_s,
       do: state

  defp integrate_fixed(%StateVector{} = state, duration_s, max_step_s, mu_km3_s2)
       when duration_s >= 0 do
    step_s = min(duration_s, max_step_s)
    next_state = rk4_step(state, step_s, mu_km3_s2)
    remaining_s = duration_s - step_s

    if remaining_s <= @time_epsilon_s do
      next_state
    else
      integrate_fixed(next_state, remaining_s, max_step_s, mu_km3_s2)
    end
  end

  defp integrate_adaptive(state, remaining_s, _step_s, _integration, _mu_km3_s2, stats)
       when remaining_s <= @time_epsilon_s,
       do: {state, stats}

  defp integrate_adaptive(state, remaining_s, step_s, integration, mu_km3_s2, stats) do
    step_s = min(step_s, remaining_s)

    {candidate, position_error_km, velocity_error_km_s} =
      adaptive_candidate(state, step_s, mu_km3_s2)

    acceptable? = adaptive_step_acceptable?(position_error_km, velocity_error_km_s, integration)
    min_step? = step_s <= integration.min_step_s + @time_epsilon_s

    cond do
      acceptable? or min_step? ->
        stats =
          stats
          |> record_accepted_step(step_s)
          |> record_min_step_limited(min_step? and not acceptable?)

        next_step_s =
          if adaptive_error_very_small?(position_error_km, velocity_error_km_s, integration) do
            min(integration.max_step_s, step_s * 2.0)
          else
            step_s
          end

        integrate_adaptive(
          candidate,
          remaining_s - step_s,
          next_step_s,
          integration,
          mu_km3_s2,
          stats
        )

      true ->
        integrate_adaptive(
          state,
          remaining_s,
          max(integration.min_step_s, step_s / 2.0),
          integration,
          mu_km3_s2,
          record_rejected_step(stats)
        )
    end
  end

  defp adaptive_candidate(state, step_s, mu_km3_s2) do
    full_step = rk4_step(state, step_s, mu_km3_s2)

    half_step =
      state
      |> rk4_step(step_s / 2.0, mu_km3_s2)
      |> rk4_step(step_s / 2.0, mu_km3_s2)

    {
      half_step,
      Vector3.subtract(half_step.position_km, full_step.position_km) |> Vector3.norm(),
      Vector3.subtract(half_step.velocity_km_s, full_step.velocity_km_s) |> Vector3.norm()
    }
  end

  defp adaptive_step_acceptable?(position_error_km, velocity_error_km_s, integration) do
    position_error_km <= integration.position_tolerance_km and
      velocity_error_km_s <= integration.velocity_tolerance_km_s
  end

  defp adaptive_error_very_small?(position_error_km, velocity_error_km_s, integration) do
    position_error_km <= integration.position_tolerance_km / 16.0 and
      velocity_error_km_s <= integration.velocity_tolerance_km_s / 16.0
  end

  defp rk4_step(%StateVector{} = state, step_s, mu_km3_s2) do
    y0 = {state.position_km, state.velocity_km_s}

    k1 = derivative(y0, mu_km3_s2)
    k2 = derivative(add_scaled(y0, k1, step_s / 2.0), mu_km3_s2)
    k3 = derivative(add_scaled(y0, k2, step_s / 2.0), mu_km3_s2)
    k4 = derivative(add_scaled(y0, k3, step_s), mu_km3_s2)

    {dr, dv} =
      combine_rk4(k1, k2, k3, k4)
      |> scale_state(step_s / 6.0)

    %{
      state
      | position_km: Vector3.add(state.position_km, dr),
        velocity_km_s: Vector3.add(state.velocity_km_s, dv),
        epoch: Epoch.shift(state.epoch, step_s)
    }
  end

  defp derivative({position_km, velocity_km_s}, mu_km3_s2) do
    {velocity_km_s, gravitational_acceleration(position_km, mu_km3_s2)}
  end

  defp gravitational_acceleration(position_km, mu_km3_s2) do
    radius_km = Vector3.norm(position_km)

    if radius_km <= 0.0 do
      raise ArithmeticError, "two-body propagation requires non-zero radius"
    end

    Vector3.scale(position_km, -mu_km3_s2 / :math.pow(radius_km, 3))
  end

  defp add_scaled({position, velocity}, {d_position, d_velocity}, scalar) do
    {
      Vector3.add(position, Vector3.scale(d_position, scalar)),
      Vector3.add(velocity, Vector3.scale(d_velocity, scalar))
    }
  end

  defp combine_rk4(k1, k2, k3, k4) do
    k1
    |> add_state(scale_state(k2, 2.0))
    |> add_state(scale_state(k3, 2.0))
    |> add_state(k4)
  end

  defp add_state({ar, av}, {br, bv}), do: {Vector3.add(ar, br), Vector3.add(av, bv)}
  defp scale_state({r, v}, scalar), do: {Vector3.scale(r, scalar), Vector3.scale(v, scalar)}

  defp maybe_merge_scenario_metadata(assumptions, metadata) when metadata == %{}, do: assumptions

  defp maybe_merge_scenario_metadata(assumptions, metadata),
    do: Map.put(assumptions, :scenario_metadata, metadata)

  defp integration_options(opts) do
    max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s)
    mode = Keyword.get(opts, :integration, :fixed_step)

    with :ok <- validate_max_step(max_step_s),
         {:ok, mode} <- normalize_integration_mode(mode),
         {:ok, min_step_s} <- min_step_s(opts, max_step_s),
         {:ok, position_tolerance_km} <-
           positive_option(
             opts,
             :adaptive_position_tolerance_km,
             1.0e-3
           ),
         {:ok, velocity_tolerance_km_s} <-
           positive_option(
             opts,
             :adaptive_velocity_tolerance_km_s,
             1.0e-6
           ) do
      {:ok,
       %{
         mode: mode,
         max_step_s: max_step_s * 1.0,
         min_step_s: min_step_s,
         position_tolerance_km: position_tolerance_km,
         velocity_tolerance_km_s: velocity_tolerance_km_s
       }}
    end
  end

  defp fixed_step_options(max_step_s) do
    %{
      mode: :fixed_step,
      max_step_s: max_step_s * 1.0,
      min_step_s: max_step_s * 1.0,
      position_tolerance_km: nil,
      velocity_tolerance_km_s: nil
    }
  end

  defp normalize_integration_mode(mode) when mode in [:fixed_step, "fixed_step"],
    do: {:ok, :fixed_step}

  defp normalize_integration_mode(mode) when mode in [:adaptive_step, "adaptive_step"],
    do: {:ok, :adaptive_step}

  defp normalize_integration_mode(_mode), do: {:error, {:invalid_option, :integration}}

  defp min_step_s(opts, max_step_s) do
    min_step_s = Keyword.get(opts, :min_step_s, max_step_s / 1024.0)

    cond do
      not positive_number?(min_step_s) ->
        {:error, {:invalid_option, :min_step_s}}

      min_step_s > max_step_s ->
        {:error, {:invalid_option, :min_step_s}}

      true ->
        {:ok, min_step_s * 1.0}
    end
  end

  defp positive_option(opts, key, default) do
    value = Keyword.get(opts, key, default)

    if positive_number?(value) do
      {:ok, value * 1.0}
    else
      {:error, {:invalid_option, key}}
    end
  end

  defp validate_max_step(value) do
    if positive_number?(value), do: :ok, else: {:error, {:invalid_option, :max_step_s}}
  end

  defp integration_assumptions(%{mode: :fixed_step, max_step_s: max_step_s}, _stats) do
    %{
      numerical_method: :rk4_fixed_step,
      max_step_s: max_step_s
    }
  end

  defp integration_assumptions(%{mode: :adaptive_step} = integration, stats) do
    %{
      numerical_method: :rk4_adaptive_step_doubling,
      integration_mode: :adaptive_step,
      max_step_s: integration.max_step_s,
      min_step_s: integration.min_step_s,
      adaptive_position_tolerance_km: integration.position_tolerance_km,
      adaptive_velocity_tolerance_km_s: integration.velocity_tolerance_km_s,
      adaptive_accepted_step_count: stats.accepted_step_count,
      adaptive_rejected_step_count: stats.rejected_step_count,
      adaptive_min_accepted_step_s: stats.min_accepted_step_s,
      adaptive_max_accepted_step_s: stats.max_accepted_step_s,
      adaptive_min_step_limited_count: stats.min_step_limited_count,
      adaptive_error_estimate: :step_doubling
    }
  end

  defp empty_integration_stats do
    %{
      accepted_step_count: 0,
      rejected_step_count: 0,
      min_accepted_step_s: nil,
      max_accepted_step_s: nil,
      min_step_limited_count: 0
    }
  end

  defp merge_stats(left, right) do
    %{
      accepted_step_count: left.accepted_step_count + right.accepted_step_count,
      rejected_step_count: left.rejected_step_count + right.rejected_step_count,
      min_accepted_step_s: min_number(left.min_accepted_step_s, right.min_accepted_step_s),
      max_accepted_step_s: max_number(left.max_accepted_step_s, right.max_accepted_step_s),
      min_step_limited_count: left.min_step_limited_count + right.min_step_limited_count
    }
  end

  defp record_accepted_step(stats, step_s) do
    %{
      stats
      | accepted_step_count: stats.accepted_step_count + 1,
        min_accepted_step_s: min_number(stats.min_accepted_step_s, step_s),
        max_accepted_step_s: max_number(stats.max_accepted_step_s, step_s)
    }
  end

  defp record_rejected_step(stats),
    do: %{stats | rejected_step_count: stats.rejected_step_count + 1}

  defp record_min_step_limited(stats, true),
    do: %{stats | min_step_limited_count: stats.min_step_limited_count + 1}

  defp record_min_step_limited(stats, false), do: stats

  defp min_number(nil, value), do: value
  defp min_number(value, nil), do: value
  defp min_number(left, right), do: min(left, right)

  defp max_number(nil, value), do: value
  defp max_number(value, nil), do: value
  defp max_number(left, right), do: max(left, right)

  defp validate_scenario(%Scenario{} = scenario) do
    cond do
      not positive_number?(scenario.central_body.mu_km3_s2) ->
        {:error, {:invalid_scenario, :central_body_mu_km3_s2}}

      Vector3.norm(scenario.initial_state.position_km) <= 0.0 ->
        {:error, {:invalid_scenario, :initial_state_radius_km}}

      true ->
        :ok
    end
  end

  defp close?(left, right), do: abs(left - right) <= @time_epsilon_s

  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
end
