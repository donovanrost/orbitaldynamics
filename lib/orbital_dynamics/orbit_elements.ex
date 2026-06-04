defmodule OrbitalDynamics.OrbitElements do
  @moduledoc """
  Classical orbital element helpers for Cartesian planning states.

  These helpers convert a `StateVector` into two-body osculating elements using
  the supplied central-body gravitational parameter. Frames and time systems are
  not transformed; the returned elements describe the input Cartesian state in
  its existing frame under the stated two-body assumption.
  """

  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Vector3}

  @type t :: %__MODULE__{
          semi_major_axis_km: float() | nil,
          eccentricity: float(),
          inclination_deg: float(),
          raan_deg: float() | nil,
          argument_of_periapsis_deg: float() | nil,
          true_anomaly_deg: float() | nil,
          argument_of_latitude_deg: float() | nil,
          longitude_of_periapsis_deg: float() | nil,
          true_longitude_deg: float() | nil,
          semi_latus_rectum_km: float(),
          perigee_radius_km: float() | nil,
          apogee_radius_km: float() | nil,
          specific_energy_km2_s2: float(),
          specific_angular_momentum_km2_s: float(),
          orbit_class: :elliptic | :parabolic | :hyperbolic
        }

  @enforce_keys [
    :semi_major_axis_km,
    :eccentricity,
    :inclination_deg,
    :raan_deg,
    :argument_of_periapsis_deg,
    :true_anomaly_deg,
    :argument_of_latitude_deg,
    :longitude_of_periapsis_deg,
    :true_longitude_deg,
    :semi_latus_rectum_km,
    :perigee_radius_km,
    :apogee_radius_km,
    :specific_energy_km2_s2,
    :specific_angular_momentum_km2_s,
    :orbit_class
  ]
  defstruct @enforce_keys

  @singularity_epsilon 1.0e-10
  @parabolic_energy_epsilon 1.0e-12
  @degrees_per_radian 180.0 / :math.pi()
  @radians_per_degree :math.pi() / 180.0

  @doc """
  Declares the fidelity and limits of the current element conversion helper.
  """
  def capabilities do
    %{
      model: :two_body_osculating_classical_elements,
      validation_level: :educational,
      input_state: :cartesian_state_vector,
      output_state: :cartesian_state_vector,
      coordinate_units: %{
        position: :kilometer,
        velocity: :kilometer_per_second,
        mu: :kilometer_cubed_per_second_squared,
        angles: :degree
      },
      frame_policy: :input_frame_no_transformation,
      singularity_policy: :undefined_angles_return_nil,
      known_limits: [
        :two_body_assumption_only,
        :no_frame_transformation,
        :no_time_scale_conversion,
        :singular_classical_angles_return_nil
      ]
    }
  end

  @doc """
  Converts a Cartesian state into two-body osculating classical elements.
  """
  def from_state(%StateVector{} = state, %CentralBody{} = central_body) do
    if Frame.compatible_with_central_body?(state.frame, central_body) do
      from_state(state, central_body.mu_km3_s2)
    else
      {:error, :incompatible_frame_center}
    end
  end

  def from_state(%StateVector{} = state, mu_km3_s2)
      when is_number(mu_km3_s2) and mu_km3_s2 > 0.0 do
    position = state.position_km
    velocity = state.velocity_km_s
    radius_km = Vector3.norm(position)

    with true <- radius_km > 0.0,
         angular_momentum <- Vector3.cross(position, velocity),
         h_norm <- Vector3.norm(angular_momentum),
         true <- h_norm > 0.0 do
      speed_squared = Vector3.dot(velocity, velocity)
      specific_energy = speed_squared / 2.0 - mu_km3_s2 / radius_km
      eccentricity_vector = eccentricity_vector(position, velocity, mu_km3_s2)
      eccentricity = Vector3.norm(eccentricity_vector)
      node_vector = Vector3.cross({0.0, 0.0, 1.0}, angular_momentum)
      node_norm = Vector3.norm(node_vector)
      semi_latus_rectum_km = h_norm * h_norm / mu_km3_s2
      semi_major_axis_km = semi_major_axis(specific_energy, mu_km3_s2)

      {:ok,
       %__MODULE__{
         semi_major_axis_km: semi_major_axis_km,
         eccentricity: eccentricity,
         inclination_deg: inclination_deg(angular_momentum, h_norm),
         raan_deg: raan_deg(node_vector, node_norm),
         argument_of_periapsis_deg:
           argument_of_periapsis_deg(node_vector, node_norm, eccentricity_vector, eccentricity),
         true_anomaly_deg:
           true_anomaly_deg(eccentricity_vector, eccentricity, position, velocity),
         argument_of_latitude_deg:
           argument_of_latitude_deg(node_vector, node_norm, position, eccentricity),
         longitude_of_periapsis_deg:
           longitude_of_periapsis_deg(node_norm, eccentricity_vector, eccentricity),
         true_longitude_deg: true_longitude_deg(node_norm, eccentricity, position),
         semi_latus_rectum_km: semi_latus_rectum_km,
         perigee_radius_km:
           perigee_radius(semi_major_axis_km, eccentricity, semi_latus_rectum_km),
         apogee_radius_km: apogee_radius(semi_major_axis_km, eccentricity),
         specific_energy_km2_s2: specific_energy,
         specific_angular_momentum_km2_s: h_norm,
         orbit_class: orbit_class(specific_energy)
       }}
    else
      _invalid_state -> {:error, :degenerate_state}
    end
  end

  def from_state(%StateVector{}, _mu_km3_s2), do: {:error, :invalid_mu_km3_s2}
  def from_state(_state, _central_body_or_mu), do: {:error, :invalid_state}

  @doc """
  Converts two-body osculating classical elements into a Cartesian state vector.

  The caller must supply `:epoch` and `:frame` options so the resulting
  `StateVector` keeps the same explicit time and reference-frame boundary as
  other public Cartesian states. When a `CentralBody` is supplied, the frame
  center is checked against that body; no frame transformation is performed.
  """
  def to_state(elements, central_body_or_mu, opts \\ []) do
    with {:ok, mu_km3_s2} <- resolve_mu(central_body_or_mu),
         {:ok, epoch} <- required_option(opts, :epoch, Epoch),
         {:ok, frame} <- required_option(opts, :frame, Frame),
         :ok <- validate_frame_center(central_body_or_mu, frame),
         {:ok, state_inputs} <- classical_state_inputs(elements, mu_km3_s2) do
      {:ok, StateVector.new!(state_inputs.position_km, state_inputs.velocity_km_s, epoch, frame)}
    end
  end

  @doc """
  Converts classical elements into a Cartesian state, raising on invalid inputs.
  """
  def to_state!(elements, central_body_or_mu, opts \\ []) do
    case to_state(elements, central_body_or_mu, opts) do
      {:ok, state} ->
        state

      {:error, reason} ->
        raise ArgumentError, "cannot compute Cartesian state: #{inspect(reason)}"
    end
  end

  @doc """
  Converts a Cartesian state into elements, raising on invalid inputs.
  """
  def from_state!(state, central_body_or_mu) do
    case from_state(state, central_body_or_mu) do
      {:ok, elements} -> elements
      {:error, reason} -> raise ArgumentError, "cannot compute orbital elements: #{reason}"
    end
  end

  @doc """
  Returns a JSON-friendly element summary map.
  """
  def summary(%__MODULE__{} = elements) do
    %{
      semi_major_axis_km: elements.semi_major_axis_km,
      eccentricity: elements.eccentricity,
      inclination_deg: elements.inclination_deg,
      raan_deg: elements.raan_deg,
      argument_of_periapsis_deg: elements.argument_of_periapsis_deg,
      true_anomaly_deg: elements.true_anomaly_deg,
      argument_of_latitude_deg: elements.argument_of_latitude_deg,
      longitude_of_periapsis_deg: elements.longitude_of_periapsis_deg,
      true_longitude_deg: elements.true_longitude_deg,
      semi_latus_rectum_km: elements.semi_latus_rectum_km,
      perigee_radius_km: elements.perigee_radius_km,
      apogee_radius_km: elements.apogee_radius_km,
      specific_energy_km2_s2: elements.specific_energy_km2_s2,
      specific_angular_momentum_km2_s: elements.specific_angular_momentum_km2_s,
      orbit_class: elements.orbit_class
    }
  end

  defp resolve_mu(%CentralBody{mu_km3_s2: mu_km3_s2}) when mu_km3_s2 > 0.0,
    do: {:ok, mu_km3_s2}

  defp resolve_mu(mu_km3_s2) when is_number(mu_km3_s2) and mu_km3_s2 > 0.0,
    do: {:ok, mu_km3_s2}

  defp resolve_mu(_central_body_or_mu), do: {:error, :invalid_mu_km3_s2}

  defp required_option(opts, key, module) do
    case Keyword.get(opts, key) do
      value when is_struct(value, module) -> {:ok, value}
      nil -> {:error, {:missing_option, key}}
      _value -> {:error, {:invalid_option, key}}
    end
  end

  defp validate_frame_center(%CentralBody{} = central_body, %Frame{} = frame) do
    if Frame.compatible_with_central_body?(frame, central_body) do
      :ok
    else
      {:error, :incompatible_frame_center}
    end
  end

  defp validate_frame_center(_mu_km3_s2, %Frame{}), do: :ok

  defp classical_state_inputs(elements, mu_km3_s2) do
    with {:ok, eccentricity} <- required_number(elements, :eccentricity),
         true <- eccentricity >= 0.0,
         {:ok, inclination_deg} <- required_number(elements, :inclination_deg),
         {:ok, semi_latus_rectum_km} <- semi_latus_rectum(elements, eccentricity),
         true <- semi_latus_rectum_km > 0.0,
         {:ok, angles} <- classical_angles(elements, eccentricity, inclination_deg) do
      true_anomaly_rad = radians(angles.true_anomaly_deg)
      radius_km = semi_latus_rectum_km / (1.0 + eccentricity * :math.cos(true_anomaly_rad))
      velocity_scale = :math.sqrt(mu_km3_s2 / semi_latus_rectum_km)

      position_perifocal = {
        radius_km * :math.cos(true_anomaly_rad),
        radius_km * :math.sin(true_anomaly_rad),
        0.0
      }

      velocity_perifocal = {
        -velocity_scale * :math.sin(true_anomaly_rad),
        velocity_scale * (eccentricity + :math.cos(true_anomaly_rad)),
        0.0
      }

      {:ok,
       %{
         position_km:
           perifocal_to_inertial(
             position_perifocal,
             angles.raan_deg,
             inclination_deg,
             angles.argument_of_periapsis_deg
           ),
         velocity_km_s:
           perifocal_to_inertial(
             velocity_perifocal,
             angles.raan_deg,
             inclination_deg,
             angles.argument_of_periapsis_deg
           )
       }}
    else
      false -> {:error, :invalid_elements}
      {:error, _reason} = error -> error
    end
  end

  defp semi_latus_rectum(elements, eccentricity) do
    case optional_number(elements, :semi_latus_rectum_km) do
      {:ok, semi_latus_rectum_km} ->
        {:ok, semi_latus_rectum_km}

      :missing ->
        with {:ok, semi_major_axis_km} <- required_number(elements, :semi_major_axis_km) do
          {:ok, semi_major_axis_km * (1.0 - eccentricity * eccentricity)}
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp classical_angles(elements, eccentricity, inclination_deg) do
    eccentric? = eccentricity > @singularity_epsilon
    inclined? = abs(inclination_deg) > @singularity_epsilon

    cond do
      eccentric? and inclined? ->
        with {:ok, raan_deg} <- required_number(elements, :raan_deg),
             {:ok, argument_of_periapsis_deg} <-
               required_number(elements, :argument_of_periapsis_deg),
             {:ok, true_anomaly_deg} <- required_number(elements, :true_anomaly_deg) do
          {:ok,
           %{
             raan_deg: raan_deg,
             argument_of_periapsis_deg: argument_of_periapsis_deg,
             true_anomaly_deg: true_anomaly_deg
           }}
        end

      eccentric? ->
        with {:ok, longitude_of_periapsis_deg} <-
               required_number(elements, :longitude_of_periapsis_deg),
             {:ok, true_anomaly_deg} <- required_number(elements, :true_anomaly_deg) do
          {:ok,
           %{
             raan_deg: 0.0,
             argument_of_periapsis_deg: longitude_of_periapsis_deg,
             true_anomaly_deg: true_anomaly_deg
           }}
        end

      inclined? ->
        with {:ok, raan_deg} <- required_number(elements, :raan_deg),
             {:ok, argument_of_latitude_deg} <-
               required_number(elements, :argument_of_latitude_deg) do
          {:ok,
           %{
             raan_deg: raan_deg,
             argument_of_periapsis_deg: 0.0,
             true_anomaly_deg: argument_of_latitude_deg
           }}
        end

      true ->
        with {:ok, true_longitude_deg} <- required_number(elements, :true_longitude_deg) do
          {:ok,
           %{
             raan_deg: 0.0,
             argument_of_periapsis_deg: 0.0,
             true_anomaly_deg: true_longitude_deg
           }}
        end
    end
  end

  defp required_number(elements, key) do
    case element_value(elements, key) do
      value when is_number(value) -> {:ok, value * 1.0}
      nil -> {:error, {:missing_element, key}}
      _value -> {:error, {:invalid_element, key}}
    end
  end

  defp optional_number(elements, key) do
    case element_value(elements, key) do
      value when is_number(value) -> {:ok, value * 1.0}
      nil -> :missing
      _value -> {:error, {:invalid_element, key}}
    end
  end

  defp element_value(%__MODULE__{} = elements, key), do: Map.fetch!(elements, key)

  defp element_value(%{} = elements, key),
    do: Map.get(elements, key) || Map.get(elements, to_string(key))

  defp element_value(_elements, _key), do: nil

  defp eccentricity_vector(position, velocity, mu_km3_s2) do
    radius_km = Vector3.norm(position)
    speed_squared = Vector3.dot(velocity, velocity)
    radial_velocity = Vector3.dot(position, velocity)

    position
    |> Vector3.scale(speed_squared / mu_km3_s2 - 1.0 / radius_km)
    |> Vector3.subtract(Vector3.scale(velocity, radial_velocity / mu_km3_s2))
  end

  defp semi_major_axis(specific_energy, _mu_km3_s2)
       when abs(specific_energy) <= @parabolic_energy_epsilon,
       do: nil

  defp semi_major_axis(specific_energy, mu_km3_s2),
    do: -mu_km3_s2 / (2.0 * specific_energy)

  defp inclination_deg({_hx, _hy, hz}, h_norm), do: (hz / h_norm) |> safe_acos() |> degrees()

  defp raan_deg(_node_vector, node_norm) when node_norm <= @singularity_epsilon, do: nil
  defp raan_deg({nx, ny, _nz}, _node_norm), do: normalized_degrees(:math.atan2(ny, nx))

  defp argument_of_periapsis_deg(_node, node_norm, _ecc, _eccentricity)
       when node_norm <= @singularity_epsilon,
       do: nil

  defp argument_of_periapsis_deg(_node, _node_norm, _ecc, eccentricity)
       when eccentricity <= @singularity_epsilon,
       do: nil

  defp argument_of_periapsis_deg(node, node_norm, eccentricity_vector, eccentricity) do
    angle =
      node
      |> Vector3.dot(eccentricity_vector)
      |> Kernel./(node_norm * eccentricity)
      |> safe_acos()

    case eccentricity_vector do
      {_ex, _ey, ez} when ez < 0.0 -> 2.0 * :math.pi() - angle
      _eccentricity_vector -> angle
    end
    |> normalized_degrees()
  end

  defp true_anomaly_deg(_eccentricity_vector, eccentricity, _position, _velocity)
       when eccentricity <= @singularity_epsilon,
       do: nil

  defp true_anomaly_deg(eccentricity_vector, eccentricity, position, velocity) do
    radius_km = Vector3.norm(position)

    angle =
      eccentricity_vector
      |> Vector3.dot(position)
      |> Kernel./(eccentricity * radius_km)
      |> safe_acos()

    case Vector3.dot(position, velocity) do
      radial_velocity when radial_velocity < 0.0 -> 2.0 * :math.pi() - angle
      _radial_velocity -> angle
    end
    |> normalized_degrees()
  end

  defp argument_of_latitude_deg(_node, node_norm, _position, _eccentricity)
       when node_norm <= @singularity_epsilon,
       do: nil

  defp argument_of_latitude_deg(_node, _node_norm, _position, eccentricity)
       when eccentricity > @singularity_epsilon,
       do: nil

  defp argument_of_latitude_deg(node, node_norm, position, _eccentricity) do
    radius_km = Vector3.norm(position)

    angle =
      node
      |> Vector3.dot(position)
      |> Kernel./(node_norm * radius_km)
      |> safe_acos()

    case position do
      {_rx, _ry, rz} when rz < 0.0 -> 2.0 * :math.pi() - angle
      _position -> angle
    end
    |> normalized_degrees()
  end

  defp longitude_of_periapsis_deg(node_norm, _eccentricity_vector, _eccentricity)
       when node_norm > @singularity_epsilon,
       do: nil

  defp longitude_of_periapsis_deg(_node_norm, _eccentricity_vector, eccentricity)
       when eccentricity <= @singularity_epsilon,
       do: nil

  defp longitude_of_periapsis_deg(_node_norm, {ex, ey, _ez}, _eccentricity),
    do: normalized_degrees(:math.atan2(ey, ex))

  defp true_longitude_deg(node_norm, _eccentricity, _position)
       when node_norm > @singularity_epsilon,
       do: nil

  defp true_longitude_deg(_node_norm, eccentricity, _position)
       when eccentricity > @singularity_epsilon,
       do: nil

  defp true_longitude_deg(_node_norm, _eccentricity, {rx, ry, _rz}),
    do: normalized_degrees(:math.atan2(ry, rx))

  defp perigee_radius(nil, eccentricity, semi_latus_rectum_km),
    do: semi_latus_rectum_km / (1.0 + eccentricity)

  defp perigee_radius(semi_major_axis_km, eccentricity, _semi_latus_rectum_km),
    do: semi_major_axis_km * (1.0 - eccentricity)

  defp apogee_radius(semi_major_axis_km, eccentricity) when eccentricity < 1.0,
    do: semi_major_axis_km * (1.0 + eccentricity)

  defp apogee_radius(_semi_major_axis_km, _eccentricity), do: nil

  defp orbit_class(specific_energy) when abs(specific_energy) <= @parabolic_energy_epsilon,
    do: :parabolic

  defp orbit_class(specific_energy) when specific_energy < 0.0, do: :elliptic
  defp orbit_class(_specific_energy), do: :hyperbolic

  defp safe_acos(value), do: value |> min(1.0) |> max(-1.0) |> :math.acos()
  defp degrees(radians), do: radians * @degrees_per_radian
  defp radians(degrees), do: degrees * @radians_per_degree

  defp perifocal_to_inertial(vector, raan_deg, inclination_deg, argument_of_periapsis_deg) do
    raan = radians(raan_deg)
    inclination = radians(inclination_deg)
    argument_of_periapsis = radians(argument_of_periapsis_deg)

    cos_raan = :math.cos(raan)
    sin_raan = :math.sin(raan)
    cos_inclination = :math.cos(inclination)
    sin_inclination = :math.sin(inclination)
    cos_argument = :math.cos(argument_of_periapsis)
    sin_argument = :math.sin(argument_of_periapsis)

    {x, y, z} = vector

    {
      (cos_raan * cos_argument - sin_raan * sin_argument * cos_inclination) * x +
        (-cos_raan * sin_argument - sin_raan * cos_argument * cos_inclination) * y +
        sin_raan * sin_inclination * z,
      (sin_raan * cos_argument + cos_raan * sin_argument * cos_inclination) * x +
        (-sin_raan * sin_argument + cos_raan * cos_argument * cos_inclination) * y -
        cos_raan * sin_inclination * z,
      sin_argument * sin_inclination * x +
        cos_argument * sin_inclination * y +
        cos_inclination * z
    }
  end

  defp normalized_degrees(radians) do
    degrees = degrees(radians)

    cond do
      degrees < 0.0 -> degrees + 360.0
      degrees >= 360.0 -> degrees - 360.0
      true -> degrees
    end
  end
end
