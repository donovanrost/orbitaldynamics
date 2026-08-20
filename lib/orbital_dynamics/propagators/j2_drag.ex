defmodule OrbitalDynamics.Propagators.J2Drag do
  @moduledoc """
  Deterministic scalar Earth propagation with point-mass gravity, J2, and drag.

  This opt-in educational path evaluates all three acceleration components in
  one fixed-step RK4 derivative. It does not sequence existing propagators and
  does not change any default propagation or planning selection.

  One immutable, offline atmosphere/rotation policy and the spacecraft's
  ballistic parameters are captured before integration. The atmosphere density
  provider is still evaluated at every RK4 stage because density varies with
  altitude, but its module, options, capability, source revision, and full-horizon
  coverage are never reselected during a run.
  """

  alias OrbitalDynamics.Environment

  alias OrbitalDynamics.Environment.{
    ConstantEarthRotationProvider,
    ExponentialAtmosphereProvider
  }

  alias OrbitalDynamics.ForceModels.AtmosphericDrag
  alias OrbitalDynamics.Propagators.J2

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    Scenario,
    Spacecraft,
    StateVector,
    Trajectory,
    Vector3
  }

  @behaviour OrbitalDynamics.Propagator

  @default_max_step_s 10.0
  @maximum_max_step_s 30.0
  @maximum_duration_s 86_400.0
  @minimum_initial_altitude_km 120.0
  @maximum_initial_altitude_km 2_000.0
  @minimum_earth_mu_km3_s2 350_000.0
  @maximum_earth_mu_km3_s2 450_000.0
  @minimum_earth_equatorial_radius_km 6_000.0
  @maximum_earth_equatorial_radius_km 7_000.0
  @maximum_earth_j2 2.0e-3
  @maximum_position_component_km 9_000.0
  @maximum_velocity_component_km_s 15.0
  @maximum_epoch_magnitude_s 1.0e12
  @minimum_spacecraft_mass_kg 0.1
  @maximum_spacecraft_mass_kg 10_000_000.0
  @maximum_drag_area_m2 1_000_000.0
  @maximum_drag_coefficient 5.0
  @maximum_density_kg_m3 1.0e-3
  @maximum_earth_rotation_rate_rad_s 1.0e-3
  @minimum_reference_altitude_km 0.0
  @maximum_reference_altitude_km 2_000.0
  @minimum_scale_height_km 1.0
  @maximum_scale_height_km 1_000.0
  @maximum_positive_atmosphere_exponent 600.0
  @time_epsilon_s 1.0e-12
  @built_in_atmosphere_source_revision "exponential-reference.v1"
  @earth_rotation_source_revision "constant-earth-rotation.v1"
  @convergence_position_tolerance_km 1.0e-3
  @convergence_velocity_tolerance_km_s 1.0e-6

  defmodule EnvironmentPolicy do
    @moduledoc false

    @enforce_keys [
      :atmosphere_evaluation,
      :atmosphere_provider,
      :atmosphere_provider_opts,
      :atmosphere_capability,
      :atmosphere_source_revision,
      :earth_rotation_capability,
      :earth_rotation_source_revision,
      :earth_rotation_rate_rad_s,
      :spacecraft_mass_kg,
      :drag_area_m2,
      :drag_coefficient
    ]
    defstruct @enforce_keys
  end

  @impl OrbitalDynamics.Propagator
  def capabilities do
    %{
      backend: :scalar_elixir,
      force_models: [:point_mass_two_body, :j2, :atmospheric_drag],
      force_composition: :single_acceleration_sum_per_rk4_stage,
      numerical_methods: [:rk4_fixed_step],
      validation_level: :educational,
      supports_batching: false,
      supports_events: false,
      supports_maneuvers: false,
      supports_adaptive_step: false,
      supported_bodies: [:earth],
      supported_frames: [:eci_j2000],
      supported_time_scales: [:tdb],
      initial_altitude_envelope_km: %{
        minimum: @minimum_initial_altitude_km,
        maximum: @maximum_initial_altitude_km
      },
      duration_envelope_s: %{minimum: 0.0, maximum: @maximum_duration_s},
      output_step_envelope_s: %{minimum_exclusive: 0.0, maximum: @maximum_duration_s},
      max_step_envelope_s: %{
        minimum_exclusive: 0.0,
        default: @default_max_step_s,
        maximum: @maximum_max_step_s
      },
      supported_numeric_envelope: %{
        central_body: %{
          mu_km3_s2: %{minimum: @minimum_earth_mu_km3_s2, maximum: @maximum_earth_mu_km3_s2},
          equatorial_radius_km: %{
            minimum: @minimum_earth_equatorial_radius_km,
            maximum: @maximum_earth_equatorial_radius_km
          },
          j2: %{minimum: 0.0, maximum: @maximum_earth_j2}
        },
        state: %{
          position_component_abs_max_km: @maximum_position_component_km,
          velocity_component_abs_max_km_s: @maximum_velocity_component_km_s,
          epoch_abs_max_s_since_j2000: @maximum_epoch_magnitude_s
        },
        spacecraft: %{
          total_mass_kg: %{
            minimum: @minimum_spacecraft_mass_kg,
            maximum: @maximum_spacecraft_mass_kg
          },
          drag_area_m2: %{minimum: 0.0, maximum: @maximum_drag_area_m2},
          drag_coefficient: %{minimum: 0.0, maximum: @maximum_drag_coefficient}
        },
        environment: %{
          density_kg_m3: %{minimum: 0.0, maximum: @maximum_density_kg_m3},
          earth_rotation_rate_rad_s: %{
            minimum: 0.0,
            maximum: @maximum_earth_rotation_rate_rad_s
          },
          reference_altitude_km: %{
            minimum: @minimum_reference_altitude_km,
            maximum: @maximum_reference_altitude_km
          },
          scale_height_km: %{
            minimum: @minimum_scale_height_km,
            maximum: @maximum_scale_height_km
          },
          positive_exponential_argument_max: @maximum_positive_atmosphere_exponent
        }
      },
      environment_policy: :offline_immutable_captured_once_before_integration,
      atmosphere_provider: :built_in_default_or_explicit_programmatic_option,
      manifest_support: false,
      public_facades: [:propagate_j2_drag, :j2_drag_acceleration],
      planning_horizon_step_convergence: %{
        evidence_type: :internal_numerical_step_convergence,
        external_acceptance: false,
        horizon_s: @maximum_duration_s,
        coarse_max_step_s: @default_max_step_s,
        fine_max_step_s: @default_max_step_s / 2.0,
        position_tolerance_km: @convergence_position_tolerance_km,
        velocity_tolerance_km_s: @convergence_velocity_tolerance_km_s
      },
      known_limits: [
        :earth_leo_only,
        :tdb_seconds_since_j2000_only,
        :fixed_spacecraft_mass_area_and_drag_coefficient,
        :constant_earth_rotation,
        :no_winds_or_space_weather_calibration,
        :j2_only_gravity_perturbation,
        :fixed_step_rk4_only,
        :explicit_earth_leo_numeric_envelope,
        :maximum_24_hour_duration,
        :offline_atmosphere_providers_only,
        :no_maneuvers_events_covariance_or_accelerated_backend,
        :internal_step_convergence_not_external_acceptance,
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
  Propagates one Earth/J2000/TDB LEO scenario with summed gravity, J2, and drag.

  Options are:

    * `:max_step_s` - fixed RK4 maximum step, default 10 s and maximum 30 s
    * `:atmosphere_provider` - provider module or `{module, provider_opts}`
    * `:atmosphere_source_revision` - required non-empty revision for custom
      providers; the built-in provider has a stable default revision label

  The Earth-specific numeric envelope is published in `capabilities/0`. It
  bounds body constants, state components, total mass, drag area/coefficient,
  density, rotation rate, and configurable exponential-atmosphere parameters
  before force arithmetic. Values outside that envelope return typed error
  tuples; they are not delegated to floating-point overflow behavior.
  """
  @impl OrbitalDynamics.Propagator
  def propagate(scenario, opts \\ [])

  def propagate(%Scenario{} = scenario, opts) when is_list(opts) do
    with :ok <- validate_options(opts, propagation_option_keys()),
         max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s),
         :ok <- validate_max_step(max_step_s),
         :ok <- validate_scenario(scenario),
         {:ok, policy} <- capture_environment_policy(scenario, opts) do
      propagate_with_policy(scenario, max_step_s * 1.0, policy)
    end
  end

  def propagate(%Scenario{}, _opts), do: {:error, {:invalid_option, :options}}
  def propagate(_scenario, _opts), do: {:error, {:invalid_input, :scenario}}

  @doc """
  Propagates with explicitly captured atmosphere and Earth-rotation inputs.

  This immutable composition path never selects a provider, calls provider
  capability functions, or reads ambient configuration. The caller supplies
  the already captured capability documents and source revisions. Density is
  evaluated by the canonical exponential-atmosphere implementation.
  """
  def propagate_captured(scenario, captured_environment, opts \\ [])

  def propagate_captured(%Scenario{} = scenario, %{} = captured_environment, opts)
      when is_list(opts) do
    with :ok <- validate_options(opts, [:max_step_s]),
         max_step_s = Keyword.get(opts, :max_step_s, @default_max_step_s),
         :ok <- validate_max_step(max_step_s),
         :ok <- validate_scenario(scenario),
         {:ok, policy} <-
           captured_environment_policy(scenario, captured_environment) do
      propagate_with_policy(scenario, max_step_s * 1.0, policy)
    end
  end

  def propagate_captured(%Scenario{}, %{}, _opts),
    do: {:error, {:invalid_option, :options}}

  def propagate_captured(%Scenario{}, _captured_environment, _opts),
    do: {:error, {:invalid_option, :captured_environment}}

  def propagate_captured(_scenario, _captured_environment, _opts),
    do: {:error, {:invalid_input, :scenario}}

  @doc """
  Evaluates the instantaneous point-mass, J2, drag, and total acceleration.

  The returned total is the direct vector sum of the three declared component
  vectors. This evaluates one state; it does not propagate sequential force
  models. The same published numeric envelope as `propagate/2` applies, and
  unsupported finite inputs return typed error tuples.
  """
  def acceleration_components(state, spacecraft, central_body, opts \\ [])

  def acceleration_components(
        %StateVector{} = state,
        %Spacecraft{} = spacecraft,
        %CentralBody{} = central_body,
        opts
      )
      when is_list(opts) do
    with :ok <- validate_options(opts, acceleration_option_keys()),
         :ok <- validate_central_body(central_body),
         :ok <- validate_state(state, central_body),
         :ok <- validate_spacecraft(spacecraft),
         :ok <- validate_initial_altitude(state, central_body),
         scenario = acceleration_scenario(state, spacecraft, central_body),
         {:ok, policy} <- capture_environment_policy(scenario, opts),
         {:ok, components} <- acceleration_with_policy(state, scenario, policy) do
      {:ok, components}
    end
  end

  def acceleration_components(_state, _spacecraft, _central_body, _opts),
    do: {:error, {:invalid_input, :j2_drag_acceleration}}

  defp acceleration_scenario(state, spacecraft, central_body) do
    %Scenario{
      id: :j2_drag_acceleration,
      spacecraft: spacecraft,
      initial_state: state,
      duration_s: 0.0,
      output_step_s: 1.0,
      central_body: central_body,
      metadata: %{},
      maneuvers: []
    }
  end

  defp capture_environment_policy(%Scenario{} = scenario, opts) do
    provider = Keyword.get(opts, :atmosphere_provider, ExponentialAtmosphereProvider)

    with {:ok, provider_module, provider_opts} <- provider_parts(provider),
         {:ok, source_revision} <- atmosphere_source_revision(provider_module, opts),
         {:ok, atmosphere_capability} <-
           configured_atmosphere_capability(provider_module, provider_opts),
         :ok <- validate_provider_fetch(provider_module),
         :ok <- validate_offline_provider(atmosphere_capability),
         :ok <- validate_provider_time_scale(atmosphere_capability),
         :ok <- validate_atmosphere_capability_parameters(atmosphere_capability),
         :ok <- validate_provider_request(atmosphere_capability, scenario),
         {:ok, earth_rotation_capability} <- earth_rotation_capability(),
         {:ok, mass_kg} <- spacecraft_mass(scenario.spacecraft) do
      {:ok,
       %EnvironmentPolicy{
         atmosphere_evaluation: :legacy_provider,
         atmosphere_provider: provider_module,
         atmosphere_provider_opts: provider_opts,
         atmosphere_capability: atmosphere_capability,
         atmosphere_source_revision: source_revision,
         earth_rotation_capability: earth_rotation_capability,
         earth_rotation_source_revision: @earth_rotation_source_revision,
         earth_rotation_rate_rad_s:
           get_in(earth_rotation_capability, ["parameters", "earth_rotation_rate_rad_s"]),
         spacecraft_mass_kg: mass_kg,
         drag_area_m2: scenario.spacecraft.area_m2 * 1.0,
         drag_coefficient: scenario.spacecraft.drag_coefficient * 1.0
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp captured_environment_policy(%Scenario{} = scenario, captured) do
    with {:ok, atmosphere_capability} <-
           captured_field(captured, "atmosphere_capability", :atmosphere_capability),
         {:ok, atmosphere_source_revision} <-
           captured_field(
             captured,
             "atmosphere_source_revision",
             :atmosphere_source_revision
           ),
         {:ok, earth_rotation_capability} <-
           captured_field(captured, "earth_rotation_capability", :earth_rotation_capability),
         {:ok, earth_rotation_source_revision} <-
           captured_field(
             captured,
             "earth_rotation_source_revision",
             :earth_rotation_source_revision
           ),
         :ok <- Environment.validate_provider_capability(atmosphere_capability),
         :ok <- validate_offline_provider(atmosphere_capability),
         :ok <- validate_provider_time_scale(atmosphere_capability),
         :ok <- validate_atmosphere_capability_parameters(atmosphere_capability),
         :ok <- validate_provider_request(atmosphere_capability, scenario),
         :ok <- Environment.validate_provider_capability(earth_rotation_capability),
         :ok <- validate_offline_provider(earth_rotation_capability),
         :ok <- validate_provider_time_scale(earth_rotation_capability),
         :ok <- validate_source_revision(atmosphere_source_revision, :atmosphere_source_revision),
         :ok <-
           validate_source_revision(
             earth_rotation_source_revision,
             :earth_rotation_source_revision
           ),
         {:ok, earth_rotation_rate_rad_s} <-
           captured_earth_rotation_rate(earth_rotation_capability),
         {:ok, mass_kg} <- spacecraft_mass(scenario.spacecraft) do
      {:ok,
       %EnvironmentPolicy{
         atmosphere_evaluation: :captured_exponential,
         atmosphere_provider: ExponentialAtmosphereProvider,
         atmosphere_provider_opts: [],
         atmosphere_capability: atmosphere_capability,
         atmosphere_source_revision: atmosphere_source_revision,
         earth_rotation_capability: earth_rotation_capability,
         earth_rotation_source_revision: earth_rotation_source_revision,
         earth_rotation_rate_rad_s: earth_rotation_rate_rad_s,
         spacecraft_mass_kg: mass_kg,
         drag_area_m2: scenario.spacecraft.area_m2 * 1.0,
         drag_coefficient: scenario.spacecraft.drag_coefficient * 1.0
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp captured_field(captured, field, error_field) do
    case Map.fetch(captured, field) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_option, error_field}}
    end
  end

  defp validate_source_revision(value, field)
       when is_binary(value) and byte_size(value) > 0,
       do:
         if(String.valid?(value) and String.trim(value) != "",
           do: :ok,
           else: {:error, {:invalid_option, field}}
         )

  defp validate_source_revision(_value, field), do: {:error, {:invalid_option, field}}

  defp captured_earth_rotation_rate(capability) do
    rate_rad_s = get_in(capability, ["parameters", "earth_rotation_rate_rad_s"])

    if number_in_range?(rate_rad_s, 0.0, @maximum_earth_rotation_rate_rad_s),
      do: {:ok, rate_rad_s * 1.0},
      else: {:error, {:invalid_environment_product, :earth_rotation_rate_rad_s}}
  end

  defp propagate_with_policy(scenario, max_step_s, policy) do
    with {:ok, initial_components} <-
           acceleration_with_policy(scenario.initial_state, scenario, policy),
         {:ok, states} <- propagate_samples(scenario, max_step_s, policy) do
      {:ok, trajectory(scenario, states, max_step_s, policy, initial_components)}
    end
  end

  defp earth_rotation_capability do
    capability = ConstantEarthRotationProvider.capabilities()
    rate_rad_s = get_in(capability, ["parameters", "earth_rotation_rate_rad_s"])

    with :ok <- Environment.validate_provider_capability(capability),
         :ok <- validate_offline_provider(capability),
         :ok <- validate_provider_time_scale(capability),
         true <- number_in_range?(rate_rad_s, 0.0, @maximum_earth_rotation_rate_rad_s) do
      {:ok, capability}
    else
      false -> {:error, {:invalid_environment_product, :earth_rotation_rate_rad_s}}
      {:error, reason} -> {:error, {:invalid_earth_rotation_provider, reason}}
    end
  end

  defp atmosphere_source_revision(provider_module, opts) do
    case Keyword.fetch(opts, :atmosphere_source_revision) do
      {:ok, value} when is_binary(value) ->
        if valid_source_revision?(value),
          do: {:ok, value},
          else: {:error, {:invalid_option, :atmosphere_source_revision}}

      {:ok, _value} ->
        {:error, {:invalid_option, :atmosphere_source_revision}}

      :error when provider_module == ExponentialAtmosphereProvider ->
        {:ok, @built_in_atmosphere_source_revision}

      :error ->
        {:error, {:missing_option, :atmosphere_source_revision}}
    end
  end

  defp valid_source_revision?(value),
    do: String.valid?(value) and String.trim(value) != ""

  defp provider_parts({provider_module, provider_opts})
       when is_atom(provider_module) and is_list(provider_opts) do
    if Keyword.keyword?(provider_opts),
      do: {:ok, provider_module, provider_opts},
      else: {:error, {:invalid_option, :atmosphere_provider}}
  end

  defp provider_parts(provider_module) when is_atom(provider_module),
    do: {:ok, provider_module, []}

  defp provider_parts(_provider), do: {:error, {:invalid_option, :atmosphere_provider}}

  defp configured_atmosphere_capability(provider_module, provider_opts) do
    try do
      Environment.configured_provider_capability(provider_module, provider_opts)
    rescue
      ArithmeticError ->
        {:error, {:environment_provider_error, :capability_arithmetic}}
    end
  end

  defp validate_provider_fetch(provider_module) do
    if Code.ensure_loaded?(provider_module) and function_exported?(provider_module, :fetch, 2),
      do: :ok,
      else: {:error, {:invalid_option, :atmosphere_provider}}
  end

  defp validate_offline_provider(%{"network_access" => false}), do: :ok
  defp validate_offline_provider(%{"network_access" => true}), do: {:error, :network_access}
  defp validate_offline_provider(_capability), do: {:error, :network_access_policy}

  defp validate_provider_time_scale(%{"coverage" => %{"time_scale" => "seconds_since_j2000"}}),
    do: :ok

  defp validate_provider_time_scale(%{"coverage" => coverage}),
    do: {:error, {:unsupported_provider_time_scale, Map.get(coverage, "time_scale")}}

  defp validate_provider_time_scale(_capability),
    do: {:error, {:unsupported_provider_time_scale, nil}}

  defp validate_atmosphere_capability_parameters(%{"parameters" => parameters})
       when is_map(parameters) do
    with :ok <-
           validate_provider_parameter(
             parameters,
             :reference_altitude_km,
             "reference_altitude_km",
             @minimum_reference_altitude_km,
             @maximum_reference_altitude_km
           ),
         :ok <-
           validate_provider_parameter(
             parameters,
             :reference_density_kg_m3,
             "reference_density_kg_m3",
             0.0,
             @maximum_density_kg_m3
           ),
         :ok <-
           validate_provider_parameter(
             parameters,
             :scale_height_km,
             "scale_height_km",
             @minimum_scale_height_km,
             @maximum_scale_height_km
           ),
         :ok <- validate_exponential_provider_combination(parameters) do
      :ok
    end
  end

  defp validate_atmosphere_capability_parameters(%{"parameters" => _parameters}),
    do: {:error, {:invalid_environment_provider_parameter, :parameters}}

  defp validate_atmosphere_capability_parameters(_capability), do: :ok

  defp validate_provider_parameter(parameters, field, string_field, minimum, maximum) do
    value = Map.get(parameters, string_field, Map.get(parameters, field, :not_declared))

    cond do
      value == :not_declared ->
        :ok

      not number?(value) ->
        {:error, {:invalid_environment_provider_parameter, field}}

      not number_in_range?(value, minimum, maximum) ->
        {:error, {:unsupported_environment_provider_parameter, field}}

      true ->
        :ok
    end
  end

  defp validate_exponential_provider_combination(parameters) do
    reference_altitude_km =
      Map.get(parameters, "reference_altitude_km", Map.get(parameters, :reference_altitude_km))

    scale_height_km =
      Map.get(parameters, "scale_height_km", Map.get(parameters, :scale_height_km))

    if number?(reference_altitude_km) and number?(scale_height_km) and
         reference_altitude_km / scale_height_km > @maximum_positive_atmosphere_exponent do
      {:error, {:unsupported_environment_provider_parameter, :exponential_argument}}
    else
      :ok
    end
  end

  defp validate_provider_request(capability, scenario) do
    start_s = scenario.initial_state.epoch.seconds_since_j2000 * 1.0
    end_s = start_s + scenario.duration_s

    request = %{
      starts_at_s: start_s,
      ends_at_s: end_s,
      body: :earth,
      output: :density_kg_m3
    }

    cond do
      Environment.provider_supports_request?(capability, request) ->
        :ok

      not Environment.provider_covers_time_span?(capability, request) ->
        {:error, {:unsupported_provider_coverage, {start_s, end_s}}}

      true ->
        {:error, {:unsupported_environment_request, :atmosphere_density}}
    end
  end

  defp propagate_samples(%Scenario{} = scenario, max_step_s, policy) do
    sample_times = sample_times(scenario.duration_s, scenario.output_step_s)

    result =
      Enum.reduce_while(
        sample_times,
        {[], 0.0, scenario.initial_state},
        fn sample_time_s, {states, elapsed_s, state} ->
          case integrate_for(
                 state,
                 sample_time_s - elapsed_s,
                 max_step_s,
                 scenario,
                 policy
               ) do
            {:ok, next_state} ->
              {:cont, {[next_state | states], sample_time_s, next_state}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
        end
      )

    case result do
      {states, _elapsed_s, _state} -> {:ok, Enum.reverse(states)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp integrate_for(%StateVector{} = state, duration_s, _max_step_s, _scenario, _policy)
       when duration_s >= 0 and duration_s <= @time_epsilon_s,
       do: {:ok, state}

  defp integrate_for(%StateVector{} = state, duration_s, max_step_s, scenario, policy)
       when duration_s >= 0 do
    step_s = min(duration_s, max_step_s)

    with {:ok, next_state} <- rk4_step(state, step_s, scenario, policy) do
      remaining_s = duration_s - step_s

      if remaining_s <= @time_epsilon_s,
        do: {:ok, next_state},
        else: integrate_for(next_state, remaining_s, max_step_s, scenario, policy)
    end
  end

  defp rk4_step(%StateVector{} = state, step_s, scenario, policy) do
    with {:ok, k1} <- derivative(state, scenario, policy),
         {:ok, k2} <-
           state
           |> intermediate_state(k1, step_s / 2.0)
           |> derivative(scenario, policy),
         {:ok, k3} <-
           state
           |> intermediate_state(k2, step_s / 2.0)
           |> derivative(scenario, policy),
         {:ok, k4} <-
           state
           |> intermediate_state(k3, step_s)
           |> derivative(scenario, policy) do
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

  defp derivative(%StateVector{} = state, scenario, policy) do
    with {:ok, components} <- acceleration_with_policy(state, scenario, policy) do
      {:ok, {state.velocity_km_s, components.total_acceleration_km_s2}}
    end
  end

  defp acceleration_with_policy(%StateVector{} = state, scenario, policy) do
    try do
      do_acceleration_with_policy(state, scenario, policy)
    rescue
      ArithmeticError -> {:error, {:numerical_error, :j2_drag_acceleration}}
    end
  end

  defp do_acceleration_with_policy(%StateVector{} = state, scenario, policy) do
    with :ok <- validate_dynamic_state_for_arithmetic(state),
         altitude_km =
           Vector3.norm(state.position_km) - scenario.central_body.equatorial_radius_km,
         :ok <- validate_non_negative_altitude(altitude_km),
         {:ok, density_product} <- fetch_density(policy, state, altitude_km),
         {:ok, density_kg_m3} <- density(density_product, policy.atmosphere_capability) do
      gravity =
        J2.acceleration_components(
          state.position_km,
          scenario.central_body.mu_km3_s2,
          scenario.central_body.equatorial_radius_km,
          scenario.central_body.j2
        )

      atmosphere_velocity_km_s =
        Vector3.cross({0.0, 0.0, policy.earth_rotation_rate_rad_s}, state.position_km)

      relative_velocity_km_s =
        Vector3.subtract(state.velocity_km_s, atmosphere_velocity_km_s)

      drag_acceleration_km_s2 =
        AtmosphericDrag.acceleration_from_density(
          relative_velocity_km_s,
          density_kg_m3,
          policy.drag_area_m2,
          policy.drag_coefficient,
          policy.spacecraft_mass_kg
        )

      total_acceleration_km_s2 =
        gravity.total_acceleration_km_s2
        |> Vector3.add(drag_acceleration_km_s2)

      {:ok,
       %{
         point_mass_acceleration_km_s2: gravity.point_mass_acceleration_km_s2,
         j2_acceleration_km_s2: gravity.j2_acceleration_km_s2,
         atmospheric_drag_acceleration_km_s2: drag_acceleration_km_s2,
         total_acceleration_km_s2: total_acceleration_km_s2,
         altitude_km: altitude_km,
         density_kg_m3: density_kg_m3,
         atmosphere_velocity_km_s: atmosphere_velocity_km_s,
         relative_velocity_km_s: relative_velocity_km_s,
         force_models: [:point_mass_two_body, :j2, :atmospheric_drag],
         force_composition: :direct_component_vector_sum,
         validation_level: :educational,
         spacecraft_ballistic_parameters: ballistic_parameters(policy),
         atmosphere_provider: atmosphere_provider_provenance(policy),
         earth_rotation_provider: earth_rotation_provider_provenance(policy)
       }}
    end
  end

  defp fetch_density(
         %EnvironmentPolicy{atmosphere_evaluation: :legacy_provider} = policy,
         state,
         altitude_km
       ) do
    opts =
      policy.atmosphere_provider_opts
      |> Keyword.put(:altitude_km, altitude_km)
      |> Keyword.put(:seconds_since_j2000, state.epoch.seconds_since_j2000)

    try do
      case policy.atmosphere_provider.fetch(:atmosphere_density, opts) do
        {:ok, %{} = product} -> {:ok, product}
        {:error, reason} -> {:error, reason}
        _other -> {:error, {:invalid_environment_product, :atmosphere_density}}
      end
    rescue
      ArithmeticError ->
        {:error, {:environment_provider_error, :atmosphere_density_arithmetic}}
    end
  end

  defp fetch_density(
         %EnvironmentPolicy{atmosphere_evaluation: :captured_exponential} = policy,
         state,
         altitude_km
       ) do
    ExponentialAtmosphereProvider.fetch_captured(
      :atmosphere_density,
      policy.atmosphere_capability,
      altitude_km: altitude_km,
      seconds_since_j2000: state.epoch.seconds_since_j2000,
      source_revision: policy.atmosphere_source_revision
    )
  end

  defp density(%{} = product, capability) do
    with :ok <- matching_product_field(product, capability, "provider_id", "id"),
         :ok <- matching_product_field(product, capability, "model", "model") do
      case product["density_kg_m3"] || product[:density_kg_m3] do
        value when is_number(value) and value >= 0.0 and value <= @maximum_density_kg_m3 ->
          {:ok, value * 1.0}

        value when is_number(value) and value >= 0.0 ->
          {:error, {:unsupported_environment_product, :density_kg_m3}}

        _value ->
          {:error, {:invalid_environment_product, :density_kg_m3}}
      end
    end
  end

  defp matching_product_field(product, capability, product_field, capability_field) do
    atom_field = if product_field == "provider_id", do: :provider_id, else: :model
    product_value = product[product_field] || product[atom_field]

    if is_binary(product_value) and product_value == capability[capability_field],
      do: :ok,
      else: {:error, {:invalid_environment_product, atom_field}}
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

  defp trajectory(scenario, states, max_step_s, policy, initial_components) do
    %Trajectory{
      scenario_id: scenario.id,
      states: states,
      assumptions:
        %{
          backend: :scalar_elixir,
          force_model: :earth_j2_atmospheric_drag,
          force_models: [:point_mass_two_body, :j2, :atmospheric_drag],
          force_composition: :single_acceleration_sum_per_rk4_stage,
          force_component_assumptions: %{
            point_mass_two_body: %{
              mu_km3_s2: scenario.central_body.mu_km3_s2
            },
            j2: %{
              enabled: scenario.central_body.j2 > 0.0,
              j2: scenario.central_body.j2,
              equatorial_radius_km: scenario.central_body.equatorial_radius_km
            },
            atmospheric_drag: %{
              model: :co_rotating_reference_atmosphere_drag,
              constant_ballistic_parameters: true,
              constant_earth_rotation: true,
              no_winds: true
            }
          },
          numerical_method: :rk4_fixed_step,
          max_step_s: max_step_s,
          maximum_allowed_max_step_s: @maximum_max_step_s,
          duration_s: scenario.duration_s * 1.0,
          maximum_duration_s: @maximum_duration_s,
          supported_numeric_envelope: capabilities().supported_numeric_envelope,
          position_unit: :kilometer,
          velocity_unit: :kilometer_per_second,
          acceleration_unit: :kilometer_per_second_squared,
          duration_unit: :second,
          mu_km3_s2: scenario.central_body.mu_km3_s2,
          equatorial_radius_km: scenario.central_body.equatorial_radius_km,
          j2: scenario.central_body.j2,
          frame: scenario.initial_state.frame.name,
          epoch_scale: scenario.initial_state.epoch.scale,
          environment_policy: :offline_immutable_captured_once_before_integration,
          atmosphere_provider: atmosphere_provider_provenance(policy),
          earth_rotation_provider: earth_rotation_provider_provenance(policy),
          atmosphere_provider_id: policy.atmosphere_capability["id"],
          atmosphere_provider_model: policy.atmosphere_capability["model"],
          atmosphere_provider_source: policy.atmosphere_capability["source"],
          atmosphere_provider_source_revision: policy.atmosphere_source_revision,
          atmosphere_provider_coverage: policy.atmosphere_capability["coverage"],
          earth_rotation_provider_id: policy.earth_rotation_capability["id"],
          earth_rotation_model: policy.earth_rotation_capability["model"],
          earth_rotation_source: policy.earth_rotation_capability["source"],
          earth_rotation_source_revision: policy.earth_rotation_source_revision,
          earth_rotation_coverage: policy.earth_rotation_capability["coverage"],
          earth_rotation_rate_rad_s: policy.earth_rotation_rate_rad_s,
          spacecraft_ballistic_parameters: ballistic_parameters(policy),
          spacecraft_mass_kg: policy.spacecraft_mass_kg,
          drag_area_m2: policy.drag_area_m2,
          drag_coefficient: policy.drag_coefficient,
          initial_density_kg_m3: initial_components.density_kg_m3,
          validation_evidence: :internal_step_convergence_not_external_acceptance,
          model_limits: model_limits()
        }
        |> maybe_merge_scenario_metadata(scenario.metadata)
    }
  end

  defp ballistic_parameters(policy) do
    %{
      mass_kg: policy.spacecraft_mass_kg,
      drag_area_m2: policy.drag_area_m2,
      drag_coefficient: policy.drag_coefficient
    }
  end

  defp atmosphere_provider_provenance(policy) do
    %{
      id: policy.atmosphere_capability["id"],
      model: policy.atmosphere_capability["model"],
      source: policy.atmosphere_capability["source"],
      source_revision: policy.atmosphere_source_revision,
      coverage: policy.atmosphere_capability["coverage"],
      interpolation: policy.atmosphere_capability["interpolation"],
      parameters: policy.atmosphere_capability["parameters"],
      network_access: policy.atmosphere_capability["network_access"],
      validation_level: policy.atmosphere_capability["validation_level"],
      known_limits: policy.atmosphere_capability["known_limits"]
    }
  end

  defp earth_rotation_provider_provenance(policy) do
    %{
      id: policy.earth_rotation_capability["id"],
      model: policy.earth_rotation_capability["model"],
      source: policy.earth_rotation_capability["source"],
      source_revision: policy.earth_rotation_source_revision,
      coverage: policy.earth_rotation_capability["coverage"],
      interpolation: policy.earth_rotation_capability["interpolation"],
      parameters: policy.earth_rotation_capability["parameters"],
      network_access: policy.earth_rotation_capability["network_access"],
      validation_level: policy.earth_rotation_capability["validation_level"],
      known_limits: policy.earth_rotation_capability["known_limits"]
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

  defp validate_options(opts, allowed_keys) do
    if Keyword.keyword?(opts) do
      case Keyword.keys(opts) -- allowed_keys do
        [] -> :ok
        [unsupported | _rest] -> {:error, {:invalid_option, unsupported}}
      end
    else
      {:error, {:invalid_option, :options}}
    end
  end

  defp propagation_option_keys,
    do: [:max_step_s, :atmosphere_provider, :atmosphere_source_revision]

  defp acceleration_option_keys,
    do: [:atmosphere_provider, :atmosphere_source_revision]

  defp validate_max_step(value) do
    cond do
      not positive_number?(value) -> {:error, {:invalid_option, :max_step_s}}
      value > @maximum_max_step_s -> {:error, {:unsupported_option, :max_step_s}}
      true -> :ok
    end
  end

  defp validate_scenario(%Scenario{} = scenario) do
    with :ok <- validate_central_body(scenario.central_body),
         :ok <- validate_state(scenario.initial_state, scenario.central_body),
         :ok <- validate_spacecraft(scenario.spacecraft),
         :ok <- validate_initial_altitude(scenario.initial_state, scenario.central_body),
         :ok <- validate_duration(scenario.duration_s),
         :ok <- validate_output_step(scenario.output_step_s),
         :ok <- validate_metadata(scenario.metadata),
         :ok <- validate_maneuvers(scenario.maneuvers) do
      :ok
    end
  end

  defp validate_central_body(%CentralBody{} = central_body) do
    cond do
      central_body.name != :earth ->
        {:error, {:unsupported_scenario, :central_body}}

      not positive_number?(central_body.mu_km3_s2) ->
        {:error, {:invalid_scenario, :central_body_mu_km3_s2}}

      not number_in_range?(
        central_body.mu_km3_s2,
        @minimum_earth_mu_km3_s2,
        @maximum_earth_mu_km3_s2
      ) ->
        {:error, {:unsupported_scenario, :central_body_mu_km3_s2}}

      not positive_number?(central_body.equatorial_radius_km) ->
        {:error, {:invalid_scenario, :equatorial_radius_km}}

      not number_in_range?(
        central_body.equatorial_radius_km,
        @minimum_earth_equatorial_radius_km,
        @maximum_earth_equatorial_radius_km
      ) ->
        {:error, {:unsupported_scenario, :equatorial_radius_km}}

      not non_negative_number?(central_body.j2) ->
        {:error, {:invalid_scenario, :j2}}

      central_body.j2 > @maximum_earth_j2 ->
        {:error, {:unsupported_scenario, :j2}}

      true ->
        :ok
    end
  end

  defp validate_central_body(_central_body), do: {:error, {:invalid_scenario, :central_body}}

  defp validate_state(%StateVector{} = state, central_body) do
    cond do
      not Vector3.valid?(state.position_km) ->
        {:error, {:invalid_scenario, :initial_state_position_km}}

      not Vector3.valid?(state.velocity_km_s) ->
        {:error, {:invalid_scenario, :initial_state_velocity_km_s}}

      not vector_components_within?(state.position_km, @maximum_position_component_km) ->
        {:error, {:unsupported_state, :position_km}}

      not vector_components_within?(state.velocity_km_s, @maximum_velocity_component_km_s) ->
        {:error, {:unsupported_state, :velocity_km_s}}

      Vector3.norm(state.position_km) <= 0.0 ->
        {:error, {:invalid_scenario, :initial_state_radius_km}}

      not match?(%Epoch{}, state.epoch) ->
        {:error, {:invalid_scenario, :initial_state_epoch}}

      not number?(state.epoch.seconds_since_j2000) ->
        {:error, {:invalid_scenario, :initial_state_epoch}}

      abs(state.epoch.seconds_since_j2000) > @maximum_epoch_magnitude_s ->
        {:error, {:unsupported_time, :seconds_since_j2000}}

      state.epoch.scale != :tdb ->
        {:error, {:unsupported_time_scale, state.epoch.scale}}

      not match?(%Frame{}, state.frame) ->
        {:error, {:invalid_scenario, :initial_state_frame}}

      not Frame.compatible_with_central_body?(state.frame, central_body) or
        state.frame.name != :eci_j2000 or state.frame.orientation != :j2000 ->
        {:error, {:unsupported_frame, state.frame.name}}

      true ->
        :ok
    end
  end

  defp validate_state(_state, _central_body),
    do: {:error, {:invalid_scenario, :initial_state}}

  defp validate_dynamic_state_for_arithmetic(%StateVector{} = state) do
    cond do
      not vector_components_within?(state.position_km, @maximum_position_component_km) ->
        {:error, {:unsupported_state, :position_km}}

      not vector_components_within?(state.velocity_km_s, @maximum_velocity_component_km_s) ->
        {:error, {:unsupported_state, :velocity_km_s}}

      true ->
        :ok
    end
  end

  defp validate_spacecraft(%Spacecraft{} = spacecraft) do
    with {:ok, _mass_kg} <- spacecraft_mass(spacecraft),
         :ok <-
           validate_spacecraft_parameter(
             :drag_area_m2,
             spacecraft.area_m2,
             @maximum_drag_area_m2
           ),
         :ok <-
           validate_spacecraft_parameter(
             :drag_coefficient,
             spacecraft.drag_coefficient,
             @maximum_drag_coefficient
           ) do
      :ok
    end
  end

  defp validate_spacecraft(_spacecraft), do: {:error, {:invalid_scenario, :spacecraft}}

  defp spacecraft_mass(%Spacecraft{
         dry_mass_kg: dry_mass_kg,
         propellant_mass_kg: propellant_mass_kg
       }) do
    cond do
      not non_negative_number?(dry_mass_kg) or not non_negative_number?(propellant_mass_kg) ->
        {:error, {:invalid_spacecraft, :spacecraft_mass_kg}}

      dry_mass_kg > @maximum_spacecraft_mass_kg or
          propellant_mass_kg > @maximum_spacecraft_mass_kg ->
        {:error, {:unsupported_spacecraft, :spacecraft_mass_kg}}

      dry_mass_kg + propellant_mass_kg < @minimum_spacecraft_mass_kg ->
        {:error, {:invalid_spacecraft, :spacecraft_mass_kg}}

      dry_mass_kg + propellant_mass_kg > @maximum_spacecraft_mass_kg ->
        {:error, {:unsupported_spacecraft, :spacecraft_mass_kg}}

      true ->
        {:ok, (dry_mass_kg + propellant_mass_kg) * 1.0}
    end
  end

  defp validate_spacecraft_parameter(field, value, maximum) do
    cond do
      not non_negative_number?(value) -> {:error, {:invalid_spacecraft, field}}
      value > maximum -> {:error, {:unsupported_spacecraft, field}}
      true -> :ok
    end
  end

  defp validate_initial_altitude(state, central_body) do
    altitude_km = Vector3.norm(state.position_km) - central_body.equatorial_radius_km

    if altitude_km >= @minimum_initial_altitude_km and
         altitude_km <= @maximum_initial_altitude_km do
      :ok
    else
      {:error, {:unsupported_scenario, :initial_altitude_km}}
    end
  end

  defp validate_non_negative_altitude(value) when is_number(value) and value >= 0.0, do: :ok
  defp validate_non_negative_altitude(_value), do: {:error, {:invalid_state, :altitude_km}}

  defp validate_duration(value) do
    cond do
      not non_negative_number?(value) -> {:error, {:invalid_scenario, :duration_s}}
      value > @maximum_duration_s -> {:error, {:unsupported_scenario, :duration_s}}
      true -> :ok
    end
  end

  defp validate_output_step(value) do
    cond do
      not positive_number?(value) -> {:error, {:invalid_scenario, :output_step_s}}
      value > @maximum_duration_s -> {:error, {:unsupported_scenario, :output_step_s}}
      true -> :ok
    end
  end

  defp validate_metadata(value),
    do: if(is_map(value), do: :ok, else: {:error, {:invalid_scenario, :metadata}})

  defp validate_maneuvers([]), do: :ok
  defp validate_maneuvers(_maneuvers), do: {:error, {:unsupported_scenario, :maneuvers}}

  defp maybe_merge_scenario_metadata(assumptions, metadata) when metadata == %{}, do: assumptions

  defp maybe_merge_scenario_metadata(assumptions, metadata),
    do: Map.put(assumptions, :scenario_metadata, metadata)

  defp close?(left, right), do: abs(left - right) <= @time_epsilon_s
  defp number?(value), do: is_integer(value) or is_float(value)
  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0

  defp number_in_range?(value, minimum, maximum),
    do: number?(value) and value >= minimum and value <= maximum

  defp vector_components_within?({x, y, z}, maximum) do
    number_in_range?(x, -maximum, maximum) and
      number_in_range?(y, -maximum, maximum) and
      number_in_range?(z, -maximum, maximum)
  end

  defp vector_components_within?(_vector, _maximum), do: false
end
