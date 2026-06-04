defmodule OrbitalDynamics.Environment.ConstantEarthRotationProvider do
  @moduledoc """
  Internal constant-rate Earth-rotation environment provider.

  This adapter exposes the same simplified rotation assumption used by surface
  geometry. It does not provide Earth orientation parameters.
  """

  @behaviour OrbitalDynamics.Environment.Provider

  alias OrbitalDynamics.AccessGeometry

  @impl OrbitalDynamics.Environment.Provider
  def capabilities do
    assumptions = AccessGeometry.assumptions()

    %{
      "id" => "environment.provider.earth_rotation.constant_rate",
      "schema_contract" => "environment_provider_capability.v1",
      "category" => "body_rotation",
      "model" => "constant_earth_rotation",
      "source" => "internal_simplified_geometry",
      "validation_level" => "assumption_declared",
      "coverage" => %{
        "starts_at_s" => nil,
        "ends_at_s" => nil,
        "time_scale" => "seconds_since_j2000",
        "coverage_policy" => "all_times"
      },
      "interpolation" => "analytic_constant_rate",
      "supported_bodies" => ["earth"],
      "network_access" => false,
      "outputs" => ["earth_rotation", "earth_rotation_angle_rad", "earth_rotation_rate_rad_s"],
      "parameters" => %{
        "earth_rotation_rate_rad_s" => Map.fetch!(assumptions, :earth_rotation_rate_rad_s),
        "geometry_model" => Atom.to_string(Map.fetch!(assumptions, :geometry_model))
      },
      "known_limits" => [
        "no Earth orientation parameters",
        "no UT1 or polar-motion correction",
        "spherical surface geometry"
      ]
    }
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:earth_rotation, opts) do
    seconds_since_j2000 = Keyword.fetch!(opts, :seconds_since_j2000)
    rate = capabilities()["parameters"]["earth_rotation_rate_rad_s"]

    {:ok,
     %{
       "provider_id" => capabilities()["id"],
       "earth_rotation_rate_rad_s" => rate,
       "earth_rotation_angle_rad" => rate * seconds_since_j2000,
       "model" => "constant_earth_rotation"
     }}
  end

  def fetch(kind, _opts), do: {:error, {:unsupported_environment_product, kind}}
end
