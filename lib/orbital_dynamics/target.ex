defmodule OrbitalDynamics.Target do
  @moduledoc """
  Surface target metadata for LEO campaign planning.

  The V1 target model mirrors the simplified spherical-Earth geometry used by
  ground-station access. Latitude and longitude are stored in degrees, altitude
  is kilometers above the reference central-body radius, and `minimum_elevation`
  is the required spacecraft elevation above the target local horizon.
  """

  @enforce_keys [
    :id,
    :latitude_deg,
    :longitude_deg,
    :altitude_km,
    :minimum_elevation_deg,
    :priority
  ]
  defstruct [:id, :latitude_deg, :longitude_deg, :altitude_km, :minimum_elevation_deg, :priority]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          latitude_deg: float(),
          longitude_deg: float(),
          altitude_km: float(),
          minimum_elevation_deg: float(),
          priority: float()
        }

  @doc """
  Creates a surface target.
  """
  def new!(id, latitude_deg, longitude_deg, opts \\ []) do
    altitude_km = Keyword.get(opts, :altitude_km, 0.0)
    minimum_elevation_deg = Keyword.get(opts, :minimum_elevation_deg, 0.0)
    priority = Keyword.get(opts, :priority, 1.0)

    cond do
      id in [nil, ""] ->
        raise ArgumentError, "target id is required"

      not number?(latitude_deg) or latitude_deg < -90.0 or latitude_deg > 90.0 ->
        raise ArgumentError, "latitude_deg must be between -90 and 90"

      not number?(longitude_deg) or longitude_deg < -180.0 or longitude_deg > 180.0 ->
        raise ArgumentError, "longitude_deg must be between -180 and 180"

      not number?(altitude_km) ->
        raise ArgumentError, "altitude_km must be numeric"

      not number?(minimum_elevation_deg) or minimum_elevation_deg < -90.0 or
          minimum_elevation_deg > 90.0 ->
        raise ArgumentError, "minimum_elevation_deg must be between -90 and 90"

      not number?(priority) or priority < 0.0 ->
        raise ArgumentError, "priority must be a non-negative number"

      true ->
        %__MODULE__{
          id: id,
          latitude_deg: latitude_deg * 1.0,
          longitude_deg: longitude_deg * 1.0,
          altitude_km: altitude_km * 1.0,
          minimum_elevation_deg: minimum_elevation_deg * 1.0,
          priority: priority * 1.0
        }
    end
  end

  defp number?(value), do: is_integer(value) or is_float(value)
end
