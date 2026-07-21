defmodule OrbitalDynamics.Propagators.TwoBodyDrag do
  @moduledoc """
  Deterministic point-mass propagation with provider-backed atmospheric drag.

  This opt-in scalar propagator evaluates the validated atmospheric-drag model
  at every fixed-step RK4 stage. It is intentionally separate from the default
  two-body and J2 propagators so adding drag never changes an existing study's
  numerical behavior implicitly.
  """

  alias OrbitalDynamics.ForceModels.AtmosphericDrag
  alias OrbitalDynamics.Propagators.ManeuverSupport

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Scenario,
    Spacecraft,
    StateVector,
    Trajectory,
    Vector3
  }

  @behaviour OrbitalDynamics.Propagator

  @default_max_step_s 10.0
  @time_epsilon_s 1.0e-12

  @impl OrbitalDynamics.Propagator
  def capabilities do
    %{
      backend: :scalar_elixir,
      force_models: [:point_mass_two_body, :atmospheric_drag],
      numerical_methods: [:rk4_fixed_step],
      validation_level: :educational,
      supports_batching: false,
      supports_events: false,
      supports_maneuvers: true,
      supports_adaptive_step: false,
      supported_bodies: [:earth],
      supported_frames: [:eci_j2000],
      atmosphere_provider: :built_in_manifest_or_programmatic_option,
      manifest_support: :built_in_exponential_atmosphere_provider,
      known_limits: [
        :fixed_spacecraft_mass_area_and_drag_coefficient,
        :constant_earth_rotation,
        :no_winds,
        :reference_atmosphere_not_space_weather_calibrated,
        :point_mass_gravity_without_j2_or_higher_order_terms,
        :fixed_step_only,
        :not_flight_certified
      ]
    }
  end

  @doc """
  Returns the propagator's declared model limits as artifact-facing strings.
  """
  def model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  @doc """
  Propagates one Earth/J2000 scenario with point-mass gravity and atmospheric drag.

  Options:

    * `:max_step_s` - maximum fixed RK4 step in seconds, default 10.0
    * `:atmosphere_provider` - provider module or `{module, provider_opts}` tuple
  """
  @impl OrbitalDynamics.Propagator
  def propagate(scenario, opts \\ [])

  def propagate(%Scenario{} = scenario, opts) when is_list(opts) do
    with :ok <- validate_options(opts) do
      do_propagate(scenario, opts)
    end
  end

  def propagate(%Scenario{}, _opts), do: {:error, {:invalid_option, :options}}
  def propagate(_scenario, _opts), do: {:error, {:invalid_input, :scenario}}

  defp do_propagate(%Scenario{} = scenario, opts) do
    max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s)
    drag_opts = Keyword.take(opts, [:atmosphere_provider])

    with :ok <- validate_max_step(max_step_s),
         :ok <- validate_scenario(scenario),
         :ok <- ManeuverSupport.validate_scalar_maneuvers(scenario, max_step_s),
         {:ok, provenance} <-
           AtmosphericDrag.evaluate(
             scenario.initial_state,
             scenario.spacecraft,
             scenario.central_body,
             drag_opts
           ),
         {:ok, states} <- propagate_samples(scenario, max_step_s * 1.0, drag_opts) do
      {:ok, trajectory(scenario, states, max_step_s * 1.0, provenance)}
    end
  end

  defp propagate_samples(%Scenario{} = scenario, max_step_s, drag_opts) do
    sample_times = sample_times(scenario.duration_s, scenario.output_step_s)
    elapsed_burns = ManeuverSupport.elapsed_burns(scenario)

    result =
      Enum.reduce_while(
        sample_times,
        {[], 0.0, scenario.initial_state, elapsed_burns},
        fn sample_time_s, {states, elapsed_s, state, burns} ->
          case propagate_to_sample(
                 state,
                 elapsed_s,
                 sample_time_s,
                 burns,
                 max_step_s,
                 scenario,
                 drag_opts
               ) do
            {:ok, next_state, next_elapsed_s, remaining_burns} ->
              {:cont, {[next_state | states], next_elapsed_s, next_state, remaining_burns}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
        end
      )

    case result do
      {states, _elapsed_s, _state, _burns} -> {:ok, Enum.reverse(states)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp propagate_to_sample(
         state,
         elapsed_s,
         sample_time_s,
         burns,
         max_step_s,
         scenario,
         drag_opts
       ) do
    {state, burns} = ManeuverSupport.apply_due_burns(state, elapsed_s, burns)

    case burns do
      [{burn_elapsed_s, _burn} | _rest] when burn_elapsed_s <= sample_time_s ->
        with {:ok, state} <-
               integrate_for(
                 state,
                 burn_elapsed_s - elapsed_s,
                 max_step_s,
                 scenario,
                 drag_opts
               ) do
          {state, burns} = ManeuverSupport.apply_due_burns(state, burn_elapsed_s, burns)

          propagate_to_sample(
            state,
            burn_elapsed_s,
            sample_time_s,
            burns,
            max_step_s,
            scenario,
            drag_opts
          )
        end

      _other ->
        with {:ok, next_state} <-
               integrate_for(
                 state,
                 sample_time_s - elapsed_s,
                 max_step_s,
                 scenario,
                 drag_opts
               ) do
          {:ok, next_state, sample_time_s, burns}
        end
    end
  end

  defp integrate_for(%StateVector{} = state, duration_s, _max_step_s, _scenario, _drag_opts)
       when duration_s >= 0 and duration_s <= @time_epsilon_s,
       do: {:ok, state}

  defp integrate_for(
         %StateVector{} = state,
         duration_s,
         max_step_s,
         scenario,
         drag_opts
       )
       when duration_s >= 0 do
    step_s = min(duration_s, max_step_s)

    with {:ok, next_state} <- rk4_step(state, step_s, scenario, drag_opts) do
      remaining_s = duration_s - step_s

      if remaining_s <= @time_epsilon_s do
        {:ok, next_state}
      else
        integrate_for(next_state, remaining_s, max_step_s, scenario, drag_opts)
      end
    end
  end

  defp rk4_step(%StateVector{} = state, step_s, scenario, drag_opts) do
    with {:ok, k1} <- derivative(state, scenario, drag_opts),
         {:ok, k2} <-
           state
           |> intermediate_state(k1, step_s / 2.0)
           |> derivative(scenario, drag_opts),
         {:ok, k3} <-
           state
           |> intermediate_state(k2, step_s / 2.0)
           |> derivative(scenario, drag_opts),
         {:ok, k4} <-
           state
           |> intermediate_state(k3, step_s)
           |> derivative(scenario, drag_opts) do
      {dr, dv} =
        k1
        |> add_derivative(scale_derivative(k2, 2.0))
        |> add_derivative(scale_derivative(k3, 2.0))
        |> add_derivative(k4)
        |> scale_derivative(step_s / 6.0)

      {:ok,
       %{
         state
         | position_km: Vector3.add(state.position_km, dr),
           velocity_km_s: Vector3.add(state.velocity_km_s, dv),
           epoch: Epoch.shift(state.epoch, step_s)
       }}
    end
  end

  defp derivative(%StateVector{} = state, scenario, drag_opts) do
    with {:ok, gravity_acceleration} <-
           gravitational_acceleration(state.position_km, scenario.central_body.mu_km3_s2),
         {:ok, drag} <-
           AtmosphericDrag.evaluate(
             state,
             scenario.spacecraft,
             scenario.central_body,
             drag_opts
           ) do
      {:ok, {state.velocity_km_s, Vector3.add(gravity_acceleration, drag.acceleration_km_s2)}}
    end
  end

  defp gravitational_acceleration(position_km, mu_km3_s2) do
    radius_km = Vector3.norm(position_km)

    if radius_km > 0.0 do
      {:ok, Vector3.scale(position_km, -mu_km3_s2 / :math.pow(radius_km, 3))}
    else
      {:error, {:invalid_state, :position_km}}
    end
  end

  defp intermediate_state(%StateVector{} = state, {d_position, d_velocity}, step_s) do
    %{
      state
      | position_km: Vector3.add(state.position_km, Vector3.scale(d_position, step_s)),
        velocity_km_s: Vector3.add(state.velocity_km_s, Vector3.scale(d_velocity, step_s)),
        epoch: Epoch.shift(state.epoch, step_s)
    }
  end

  defp add_derivative({ar, av}, {br, bv}),
    do: {Vector3.add(ar, br), Vector3.add(av, bv)}

  defp scale_derivative({position, velocity}, scalar),
    do: {Vector3.scale(position, scalar), Vector3.scale(velocity, scalar)}

  defp trajectory(scenario, states, max_step_s, provenance) do
    %Trajectory{
      scenario_id: scenario.id,
      states: states,
      assumptions:
        %{
          backend: :scalar_elixir,
          force_model: :point_mass_two_body_atmospheric_drag,
          force_models: [:point_mass_two_body, :atmospheric_drag],
          numerical_method: :rk4_fixed_step,
          max_step_s: max_step_s,
          position_unit: :kilometer,
          velocity_unit: :kilometer_per_second,
          acceleration_unit: :kilometer_per_second_squared,
          duration_unit: :second,
          mu_km3_s2: scenario.central_body.mu_km3_s2,
          equatorial_radius_km: scenario.central_body.equatorial_radius_km,
          frame: scenario.initial_state.frame.name,
          epoch_scale: scenario.initial_state.epoch.scale,
          atmosphere_provider_id: provenance.atmosphere_provider_id,
          atmosphere_provider_model: provenance.atmosphere_provider_model,
          earth_rotation_provider_id: provenance.earth_rotation_provider_id,
          earth_rotation_model: provenance.earth_rotation_model,
          earth_rotation_rate_rad_s: provenance.earth_rotation_rate_rad_s,
          spacecraft_mass_kg: provenance.spacecraft_mass_kg,
          drag_area_m2: provenance.drag_area_m2,
          drag_coefficient: provenance.drag_coefficient,
          model_limits: model_limits()
        }
        |> maybe_merge_scenario_metadata(scenario.metadata)
        |> Map.merge(ManeuverSupport.maneuver_assumptions(scenario.maneuvers))
    }
  end

  defp sample_times(duration_s, output_step_s) do
    full_steps = trunc(Float.floor(duration_s / output_step_s))
    samples = Enum.map(0..full_steps, &(&1 * output_step_s))
    final_sample = List.last(samples)

    if close?(final_sample, duration_s),
      do: List.replace_at(samples, -1, duration_s * 1.0),
      else: samples ++ [duration_s * 1.0]
  end

  defp validate_options(opts) do
    if Keyword.keyword?(opts) do
      case Keyword.keys(opts) -- [:max_step_s, :atmosphere_provider] do
        [] -> :ok
        [unsupported | _rest] -> {:error, {:invalid_option, unsupported}}
      end
    else
      {:error, {:invalid_option, :options}}
    end
  end

  defp validate_max_step(value),
    do: if(positive_number?(value), do: :ok, else: {:error, {:invalid_option, :max_step_s}})

  defp validate_scenario(%Scenario{} = scenario) do
    cond do
      not match?(%CentralBody{}, scenario.central_body) ->
        {:error, {:invalid_scenario, :central_body}}

      not match?(%Spacecraft{}, scenario.spacecraft) ->
        {:error, {:invalid_scenario, :spacecraft}}

      not match?(%StateVector{}, scenario.initial_state) ->
        {:error, {:invalid_scenario, :initial_state}}

      not positive_number?(scenario.central_body.mu_km3_s2) ->
        {:error, {:invalid_scenario, :central_body_mu_km3_s2}}

      not positive_number?(scenario.central_body.equatorial_radius_km) ->
        {:error, {:invalid_scenario, :equatorial_radius_km}}

      scenario.central_body.name != :earth ->
        {:error, {:unsupported_scenario, :central_body}}

      not non_negative_number?(scenario.duration_s) ->
        {:error, {:invalid_scenario, :duration_s}}

      not positive_number?(scenario.output_step_s) ->
        {:error, {:invalid_scenario, :output_step_s}}

      not Vector3.valid?(scenario.initial_state.position_km) ->
        {:error, {:invalid_scenario, :initial_state_position_km}}

      Vector3.norm(scenario.initial_state.position_km) <= 0.0 ->
        {:error, {:invalid_scenario, :initial_state_radius_km}}

      true ->
        :ok
    end
  end

  defp maybe_merge_scenario_metadata(assumptions, metadata) when metadata == %{}, do: assumptions

  defp maybe_merge_scenario_metadata(assumptions, metadata),
    do: Map.put(assumptions, :scenario_metadata, metadata)

  defp close?(left, right), do: abs(left - right) <= @time_epsilon_s
  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0

  defp non_negative_number?(value),
    do: (is_integer(value) or is_float(value)) and value >= 0
end
