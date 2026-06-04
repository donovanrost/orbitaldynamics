defmodule OrbitalDynamics.CentralBody do
  @moduledoc """
  Central-body gravity parameter used by two-body propagation.

  `mu_km3_s2` is the standard gravitational parameter in km^3/s^2.
  """

  @enforce_keys [:name, :mu_km3_s2]
  defstruct [:name, :mu_km3_s2, :equatorial_radius_km, :j2]

  @type t :: %__MODULE__{
          name: atom(),
          mu_km3_s2: float(),
          equatorial_radius_km: float() | nil,
          j2: float() | nil
        }

  @earth_mu_km3_s2 398_600.4418
  @earth_equatorial_radius_km 6_378.1363
  @earth_j2 1.08262668e-3

  @doc """
  Creates central-body metadata.
  """
  def new!(name, mu_km3_s2, opts \\ []) do
    equatorial_radius_km = Keyword.get(opts, :equatorial_radius_km)
    j2 = Keyword.get(opts, :j2)

    cond do
      not is_atom(name) ->
        raise ArgumentError, "central body name must be an atom"

      not positive_number?(mu_km3_s2) ->
        raise ArgumentError, "mu_km3_s2 must be positive"

      not nil_or_positive_number?(equatorial_radius_km) ->
        raise ArgumentError, "equatorial_radius_km must be nil or positive"

      not nil_or_non_negative_number?(j2) ->
        raise ArgumentError, "j2 must be nil or non-negative"

      true ->
        %__MODULE__{
          name: name,
          mu_km3_s2: mu_km3_s2 * 1.0,
          equatorial_radius_km: maybe_float(equatorial_radius_km),
          j2: maybe_float(j2)
        }
    end
  end

  @doc """
  Earth gravitational parameter in km^3/s^2.
  """
  def earth do
    new!(:earth, @earth_mu_km3_s2,
      equatorial_radius_km: @earth_equatorial_radius_km,
      j2: @earth_j2
    )
  end

  defp maybe_float(nil), do: nil
  defp maybe_float(value), do: value * 1.0

  defp positive_number?(value), do: (is_integer(value) or is_float(value)) and value > 0
  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0
  defp nil_or_positive_number?(nil), do: true
  defp nil_or_positive_number?(value), do: positive_number?(value)
  defp nil_or_non_negative_number?(nil), do: true
  defp nil_or_non_negative_number?(value), do: non_negative_number?(value)
end
