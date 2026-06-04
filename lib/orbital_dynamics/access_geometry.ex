defmodule OrbitalDynamics.AccessGeometry do
  @moduledoc """
  Simplified ground-station access geometry.

  The initial model assumes a spherical Earth and a constant Earth rotation
  angle from J2000 seconds. It is intentionally explicit so later frame/time
  systems can replace it without hiding assumptions.
  """

  alias OrbitalDynamics.{CentralBody, GroundStation, StateVector, Target, Vector3}

  @earth_rotation_rate_rad_s 7.2921150e-5

  @doc """
  Returns the assumptions used by this geometry model.
  """
  def assumptions do
    %{
      geometry_model: :simplified_spherical_earth_rotation,
      earth_rotation_rate_rad_s: @earth_rotation_rate_rad_s,
      interpolation: :sample_based,
      refraction: :none,
      terrain_mask: :none
    }
  end

  @doc """
  Computes sample elevation in degrees.
  """
  def elevation_deg(
        %StateVector{} = state,
        %GroundStation{} = station,
        %CentralBody{} = central_body
      ) do
    station_position = station_inertial_km(station, central_body, state.epoch.seconds_since_j2000)
    line_of_sight = Vector3.subtract(state.position_km, station_position)
    up = station_up_inertial(station, state.epoch.seconds_since_j2000)

    line_of_sight_norm = Vector3.norm(line_of_sight)

    if line_of_sight_norm <= 0.0 do
      90.0
    else
      sin_elevation =
        line_of_sight
        |> Vector3.dot(up)
        |> Kernel./(line_of_sight_norm)
        |> clamp(-1.0, 1.0)

      radians_to_degrees(:math.asin(sin_elevation))
    end
  end

  def elevation_deg(%StateVector{} = state, %Target{} = target, %CentralBody{} = central_body) do
    target_position =
      surface_point_inertial_km(target, central_body, state.epoch.seconds_since_j2000)

    line_of_sight = Vector3.subtract(state.position_km, target_position)
    up = surface_point_up_inertial(target, state.epoch.seconds_since_j2000)

    line_of_sight_norm = Vector3.norm(line_of_sight)

    if line_of_sight_norm <= 0.0 do
      90.0
    else
      sin_elevation =
        line_of_sight
        |> Vector3.dot(up)
        |> Kernel./(line_of_sight_norm)
        |> clamp(-1.0, 1.0)

      radians_to_degrees(:math.asin(sin_elevation))
    end
  end

  @doc """
  Returns true when the state is above the station minimum elevation.
  """
  def visible?(%StateVector{} = state, %GroundStation{} = station, %CentralBody{} = central_body) do
    elevation_deg(state, station, central_body) >= station.minimum_elevation_deg
  end

  def visible?(%StateVector{} = state, %Target{} = target, %CentralBody{} = central_body) do
    elevation_deg(state, target, central_body) >= target.minimum_elevation_deg
  end

  defp station_inertial_km(station, central_body, seconds_since_j2000) do
    surface_point_inertial_km(station, central_body, seconds_since_j2000)
  end

  defp surface_point_inertial_km(point, central_body, seconds_since_j2000) do
    radius_km = central_body.equatorial_radius_km + point.altitude_km
    {x, y, z} = geodetic_unit_vector(point)

    rotate_z(
      {x * radius_km, y * radius_km, z * radius_km},
      earth_rotation_angle(seconds_since_j2000)
    )
  end

  defp station_up_inertial(station, seconds_since_j2000) do
    surface_point_up_inertial(station, seconds_since_j2000)
  end

  defp surface_point_up_inertial(point, seconds_since_j2000) do
    point
    |> geodetic_unit_vector()
    |> rotate_z(earth_rotation_angle(seconds_since_j2000))
  end

  defp geodetic_unit_vector(station) do
    latitude_rad = degrees_to_radians(station.latitude_deg)
    longitude_rad = degrees_to_radians(station.longitude_deg)
    cos_latitude = :math.cos(latitude_rad)

    {
      cos_latitude * :math.cos(longitude_rad),
      cos_latitude * :math.sin(longitude_rad),
      :math.sin(latitude_rad)
    }
  end

  defp earth_rotation_angle(seconds_since_j2000) do
    @earth_rotation_rate_rad_s * seconds_since_j2000
  end

  defp rotate_z({x, y, z}, angle_rad) do
    cos_angle = :math.cos(angle_rad)
    sin_angle = :math.sin(angle_rad)

    {
      cos_angle * x - sin_angle * y,
      sin_angle * x + cos_angle * y,
      z
    }
  end

  defp degrees_to_radians(degrees), do: degrees * :math.pi() / 180.0
  defp radians_to_degrees(radians), do: radians * 180.0 / :math.pi()
  defp clamp(value, min, _max) when value < min, do: min
  defp clamp(value, _min, max) when value > max, do: max
  defp clamp(value, _min, _max), do: value
end
