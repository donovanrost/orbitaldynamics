defmodule OrbitalDynamics.Environment.FixedSunProvider do
  @moduledoc """
  Internal fixed-Sun environment provider.

  This adapter exists to make the current fixed inertial solar-direction
  assumption explicit through the provider contract. It is not an ephemeris
  provider.
  """

  @behaviour OrbitalDynamics.Environment.Provider

  @default_direction {1.0, 0.0, 0.0}

  @impl OrbitalDynamics.Environment.Provider
  def capabilities do
    %{
      "id" => "environment.provider.solar.fixed_inertial_direction",
      "schema_contract" => "environment_provider_capability.v1",
      "category" => "solar_direction",
      "model" => "fixed_inertial_solar_direction",
      "source" => "internal_fixed_sun_assumption",
      "validation_level" => "assumption_declared",
      "coverage" => %{
        "starts_at_s" => nil,
        "ends_at_s" => nil,
        "time_scale" => "seconds_since_j2000",
        "coverage_policy" => "all_times"
      },
      "interpolation" => "constant",
      "supported_bodies" => ["earth"],
      "network_access" => false,
      "outputs" => ["sun_direction"],
      "known_limits" => [
        "not an ephemeris provider",
        "no Sun range or light-time correction",
        "no time-varying apparent solar direction"
      ]
    }
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:sun_direction, opts) do
    direction = Keyword.get(opts, :sun_direction, @default_direction)

    {:ok,
     %{
       "provider_id" => capabilities()["id"],
       "sun_direction" => encode_direction(direction),
       "frame" => "eci_j2000_inertial",
       "model" => "fixed_inertial_solar_direction"
     }}
  end

  def fetch(kind, _opts), do: {:error, {:unsupported_environment_product, kind}}

  defp encode_direction({x, y, z}), do: [x, y, z]
  defp encode_direction([_x, _y, _z] = direction), do: direction
  defp encode_direction(direction), do: direction
end
