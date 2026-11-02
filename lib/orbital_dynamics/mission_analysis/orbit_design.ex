defmodule OrbitalDynamics.MissionAnalysis.OrbitDesign do
  @moduledoc "First-order circular J2 sun-synchronous orbit estimates, with explicit inputs."
  alias OrbitalDynamics.MissionAnalysis.Input

  def sun_synchronous_inclination_deg!(body, altitude_km, solar_year_s) do
    altitude = Input.positive!(altitude_km, "altitude_km")
    year = Input.positive!(solar_year_s, "solar_year_s")
    Input.positive!(body.equatorial_radius_km, "body radius")
    Input.positive!(body.mu_km3_s2, "body gravitational parameter")
    Input.positive!(body.j2, "body J2")
    if body.j2 <= 0, do: raise(ArgumentError, "positive J2 required for this orbit estimate")
    a = body.equatorial_radius_km + altitude
    n = :math.sqrt(body.mu_km3_s2 / :math.pow(a, 3))

    cosine =
      -(2 * :math.pi() / year) / (1.5 * body.j2 * n * :math.pow(body.equatorial_radius_km / a, 2))

    if abs(cosine) > 1, do: raise(ArgumentError, "no circular sun-synchronous solution")
    :math.acos(cosine) * 180 / :math.pi()
  end

  def raan_deg!(sun_direction, local_time_ascending_node_h) do
    {x, y, _} = Input.unit!(sun_direction, "sun_direction")
    hour = Input.number!(local_time_ascending_node_h, "local_time_ascending_node_h", 0, 24)
    angle = :math.atan2(y, x) * 180 / :math.pi() + 15 * (hour - 12)
    angle - 360 * :math.floor(angle / 360)
  end
end
