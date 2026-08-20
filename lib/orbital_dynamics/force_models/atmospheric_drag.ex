defmodule OrbitalDynamics.ForceModels.AtmosphericDrag do
  @moduledoc """
  Deterministic atmospheric-drag acceleration at one orbital state.

  The evaluator joins explicit spacecraft ballistic properties with a validated
  atmosphere-density provider and the built-in constant Earth-rotation
  assumption. `OrbitalDynamics.Propagators.TwoBodyDrag` and
  `OrbitalDynamics.Propagators.J2Drag` integrate this acceleration through
  explicit opt-in scalar propagation paths; default and accelerated
  propagators do not consume it.
  """

  alias OrbitalDynamics.Environment

  alias OrbitalDynamics.Environment.{
    ConstantEarthRotationProvider,
    ExponentialAtmosphereProvider
  }

  alias OrbitalDynamics.{CentralBody, Frame, Spacecraft, StateVector, Vector3}

  @default_atmosphere_provider ExponentialAtmosphereProvider

  @doc """
  Declares the force-model inputs, outputs, and current fidelity limits.
  """
  def capabilities do
    %{
      force_model: :atmospheric_drag,
      model: :co_rotating_reference_atmosphere_drag,
      validation_level: :educational,
      supported_bodies: [:earth],
      supported_frames: [:eci_j2000],
      default_atmosphere_provider: "environment.provider.atmosphere.exponential_reference",
      atmosphere_rotation_provider: "environment.provider.earth_rotation.constant_rate",
      public_facades: [:atmospheric_drag_acceleration],
      inputs: [
        :state_position_km,
        :state_velocity_km_s,
        :spacecraft_mass_kg,
        :drag_area_m2,
        :drag_coefficient,
        :atmosphere_density_kg_m3
      ],
      outputs: [
        :acceleration_km_s2,
        :acceleration_magnitude_km_s2,
        :relative_velocity_km_s,
        :density_provider_provenance
      ],
      known_limits: [
        :standalone_evaluator_two_body_drag_and_j2_drag_propagators_only,
        :not_integrated_by_accelerated_propagators,
        :constant_earth_rotation,
        :no_winds,
        :fixed_drag_area_and_coefficient,
        :reference_atmosphere_not_space_weather_calibrated,
        :not_flight_certified
      ]
    }
  end

  @doc """
  Returns the declared model limits as artifact-facing strings.
  """
  def model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  @doc """
  Evaluates atmospheric-drag acceleration for one state and spacecraft.

  The optional `:atmosphere_provider` may be a provider module or a
  `{provider_module, provider_opts}` tuple. The provider must declare Earth and
  `density_kg_m3` request coverage through the environment-provider contract.
  """
  def evaluate(state, spacecraft, central_body, opts \\ [])

  def evaluate(
        %StateVector{} = state,
        %Spacecraft{} = spacecraft,
        %CentralBody{} = central_body,
        opts
      )
      when is_list(opts) do
    with :ok <- validate_options(opts),
         provider = Keyword.get(opts, :atmosphere_provider, @default_atmosphere_provider),
         :ok <- validate_central_body(central_body),
         :ok <- validate_state_vector(state),
         :ok <- validate_state_frame(state, central_body),
         {:ok, mass_kg} <- spacecraft_mass(spacecraft),
         altitude_km = Vector3.norm(state.position_km) - central_body.equatorial_radius_km,
         :ok <- validate_non_negative(:altitude_km, altitude_km),
         :ok <- validate_positive(:spacecraft_mass_kg, mass_kg),
         :ok <- validate_spacecraft_non_negative(:drag_area_m2, spacecraft.area_m2),
         :ok <- validate_spacecraft_non_negative(:drag_coefficient, spacecraft.drag_coefficient),
         {:ok, provider_module, provider_opts, provider_capability} <-
           validate_atmosphere_provider(provider, state, central_body),
         {:ok, density_product} <-
           fetch_density(provider_module, provider_opts, altitude_km),
         {:ok, density_kg_m3} <- density(density_product, provider_capability),
         {:ok, rotation_product} <-
           ConstantEarthRotationProvider.fetch(:earth_rotation,
             seconds_since_j2000: state.epoch.seconds_since_j2000
           ) do
      rotation_rate_rad_s = Map.fetch!(rotation_product, "earth_rotation_rate_rad_s")

      atmosphere_velocity_km_s =
        Vector3.cross({0.0, 0.0, rotation_rate_rad_s}, state.position_km)

      relative_velocity_km_s =
        Vector3.subtract(state.velocity_km_s, atmosphere_velocity_km_s)

      acceleration_km_s2 =
        acceleration_from_density(
          relative_velocity_km_s,
          density_kg_m3,
          spacecraft.area_m2,
          spacecraft.drag_coefficient,
          mass_kg
        )

      {:ok,
       %{
         model: :co_rotating_reference_atmosphere_drag,
         validation_level: :educational,
         altitude_km: altitude_km,
         density_kg_m3: density_kg_m3,
         spacecraft_mass_kg: mass_kg * 1.0,
         drag_area_m2: spacecraft.area_m2 * 1.0,
         drag_coefficient: spacecraft.drag_coefficient * 1.0,
         atmosphere_velocity_km_s: atmosphere_velocity_km_s,
         relative_velocity_km_s: relative_velocity_km_s,
         relative_speed_km_s: Vector3.norm(relative_velocity_km_s),
         acceleration_km_s2: acceleration_km_s2,
         acceleration_magnitude_km_s2: Vector3.norm(acceleration_km_s2),
         atmosphere_density_product: density_product,
         atmosphere_provider_id: provider_capability["id"],
         atmosphere_provider_model: density_product["model"] || provider_capability["model"],
         earth_rotation_provider_id: rotation_product["provider_id"],
         earth_rotation_model: rotation_product["model"],
         earth_rotation_rate_rad_s: rotation_rate_rad_s,
         model_limits: model_limits(),
         assumptions: %{
           force_model: :atmospheric_drag,
           atmosphere_rotation: :constant_rate_co_rotation,
           density_interpolation: provider_capability["interpolation"],
           frame: state.frame.name,
           position_unit: :kilometer,
           velocity_unit: :kilometer_per_second,
           acceleration_unit: :kilometer_per_second_squared
         }
       }}
    end
  end

  def evaluate(_state, _spacecraft, _central_body, _opts),
    do: {:error, {:invalid_input, :atmospheric_drag}}

  @doc false
  # Velocity is kilometers per second and the returned acceleration is
  # kilometers per second squared. Density, area, and mass use SI units.
  def acceleration_from_density(
        relative_velocity_km_s,
        density_kg_m3,
        area_m2,
        drag_coefficient,
        mass_kg
      )
      when is_tuple(relative_velocity_km_s) do
    speed_km_s = Vector3.norm(relative_velocity_km_s)

    if speed_km_s == 0.0 or density_kg_m3 == 0.0 do
      {0.0, 0.0, 0.0}
    else
      scale =
        -0.5 * density_kg_m3 * drag_coefficient * area_m2 / mass_kg * speed_km_s * 1_000.0

      Vector3.scale(relative_velocity_km_s, scale)
    end
  end

  defp validate_central_body(%CentralBody{name: :earth, equatorial_radius_km: radius_km})
       when is_number(radius_km) and radius_km > 0.0,
       do: :ok

  defp validate_central_body(%CentralBody{}),
    do: {:error, {:invalid_central_body, :atmospheric_drag}}

  defp validate_state_vector(%StateVector{
         position_km: position_km,
         velocity_km_s: velocity_km_s,
         epoch: %{seconds_since_j2000: seconds_since_j2000}
       }) do
    if Vector3.valid?(position_km) and Vector3.valid?(velocity_km_s) and
         is_number(seconds_since_j2000) do
      :ok
    else
      {:error, {:invalid_state, :state_vector}}
    end
  end

  defp validate_state_vector(%StateVector{}),
    do: {:error, {:invalid_state, :state_vector}}

  defp validate_state_frame(%StateVector{frame: frame}, central_body) do
    if Frame.compatible_with_central_body?(frame, central_body) and frame.name == :eci_j2000 and
         frame.orientation == :j2000 do
      :ok
    else
      {:error, {:invalid_state, :frame}}
    end
  end

  defp validate_atmosphere_provider(provider, state, central_body) do
    request = %{
      starts_at_s: state.epoch.seconds_since_j2000,
      ends_at_s: state.epoch.seconds_since_j2000,
      body: central_body.name,
      output: :density_kg_m3
    }

    with {:ok, provider_module, provider_opts} <- provider_parts(provider),
         {:ok, capability} <- Environment.configured_provider_capability(provider),
         :ok <- validate_provider_fetch(provider_module),
         true <- Environment.provider_supports_request?(capability, request) do
      {:ok, provider_module, provider_opts, capability}
    else
      false -> {:error, {:unsupported_environment_request, :atmosphere_density}}
      {:error, _reason} -> {:error, {:invalid_option, :atmosphere_provider}}
    end
  end

  defp provider_parts({provider_module, provider_opts})
       when is_atom(provider_module) and is_list(provider_opts) do
    if Keyword.keyword?(provider_opts),
      do: {:ok, provider_module, provider_opts},
      else: {:error, {:invalid_option, :atmosphere_provider}}
  end

  defp provider_parts(provider_module) when is_atom(provider_module),
    do: {:ok, provider_module, []}

  defp provider_parts(_provider), do: {:error, {:invalid_option, :atmosphere_provider}}

  defp validate_provider_fetch(provider_module) do
    if function_exported?(provider_module, :fetch, 2),
      do: :ok,
      else: {:error, {:invalid_option, :atmosphere_provider}}
  end

  defp fetch_density(provider_module, provider_opts, altitude_km) do
    provider_module.fetch(
      :atmosphere_density,
      Keyword.put(provider_opts, :altitude_km, altitude_km)
    )
  end

  defp density(%{} = product, capability) do
    with :ok <- validate_product_field(product, capability, "provider_id", "id"),
         :ok <- validate_product_field(product, capability, "model", "model") do
      case product["density_kg_m3"] || product[:density_kg_m3] do
        value when is_number(value) and value >= 0.0 -> {:ok, value * 1.0}
        _value -> {:error, {:invalid_environment_product, :density_kg_m3}}
      end
    end
  end

  defp density(_product, _capability),
    do: {:error, {:invalid_environment_product, :density_kg_m3}}

  defp validate_product_field(product, capability, product_field, capability_field) do
    product_atom_field = product_atom_field(product_field)
    product_value = product[product_field] || product[product_atom_field]

    if is_binary(product_value) and product_value == capability[capability_field],
      do: :ok,
      else: {:error, {:invalid_environment_product, product_atom_field}}
  end

  defp product_atom_field("provider_id"), do: :provider_id
  defp product_atom_field("model"), do: :model

  defp validate_options(opts) do
    if Keyword.keyword?(opts),
      do: :ok,
      else: {:error, {:invalid_option, :options}}
  end

  defp spacecraft_mass(%Spacecraft{
         dry_mass_kg: dry_mass_kg,
         propellant_mass_kg: propellant_mass_kg
       })
       when is_number(dry_mass_kg) and dry_mass_kg >= 0.0 and is_number(propellant_mass_kg) and
              propellant_mass_kg >= 0.0,
       do: {:ok, (dry_mass_kg + propellant_mass_kg) * 1.0}

  defp spacecraft_mass(%Spacecraft{}),
    do: {:error, {:invalid_spacecraft, :spacecraft_mass_kg}}

  defp validate_non_negative(_field, value) when is_number(value) and value >= 0.0, do: :ok
  defp validate_non_negative(field, _value), do: {:error, {:invalid_state, field}}

  defp validate_positive(_field, value) when is_number(value) and value > 0.0, do: :ok
  defp validate_positive(field, _value), do: {:error, {:invalid_spacecraft, field}}

  defp validate_spacecraft_non_negative(_field, value)
       when is_number(value) and value >= 0.0,
       do: :ok

  defp validate_spacecraft_non_negative(field, _value),
    do: {:error, {:invalid_spacecraft, field}}
end
