# Export physical inputs only; no Elixir-computed states or geometry are sent to Orekit.
alias OrbitalDynamics.MissionAnalysis.ReferenceMission
[directory] = System.argv()
config = ReferenceMission.load!("studies/reference_illumination.json")
p = ReferenceMission.prepare!(config)
[asset] = p.assets
[request] = p.requests
[design] = p.metadata["orbit_estimates"]
[spec] = config["assets"]
body = p.context.body

properties = %{
  "semi_major_axis_m" => (body.equatorial_radius_km + spec["altitude_km"]) * 1000,
  "inclination_deg" => design["inclination_deg"],
  "raan_deg" => design["raan_deg"],
  "argument_of_latitude_deg" => spec["initial_argument_of_latitude_deg"],
  "mu_m3_s2" => body.mu_km3_s2 * 1.0e9,
  "radius_m" => body.equatorial_radius_km * 1000,
  "j2" => body.j2,
  "target_latitude_deg" => request.subject.latitude_deg,
  "target_longitude_deg" => request.subject.longitude_deg,
  "target_altitude_m" => request.subject.altitude_km * 1000
}

File.mkdir_p!(directory)

File.write!(
  Path.join(directory, "case.properties"),
  Enum.map_join(Enum.sort(properties), "\n", fn {k, v} -> "#{k}=#{v}" end) <> "\n"
)

rows =
  Enum.map(asset.trajectory.states, fn state ->
    {:ok, e} = p.context.environment_provider.at(state.epoch, p.context.environment_config)

    [state.epoch.seconds_since_j2000 - config["epoch_s"], e.rotation_angle_rad | e.sun_direction]
    |> Enum.join(",")
  end)

File.write!(
  Path.join(directory, "environment.csv"),
  "elapsed_s,rotation_angle_rad,sun_x,sun_y,sun_z\n" <> Enum.join(rows, "\n") <> "\n"
)

File.write!(Path.join(directory, "inputs.json"), [
  :json.encode(%{
    "baseline_configuration" => config,
    "environment" =>
      p.context.environment_provider.describe(p.context.environment_config)
      |> OrbitalDynamics.Schema.JsonSafety.normalize_input!("baseline environment")
      |> Map.update!("content_verification", &Map.delete(&1, "path")),
    "orbit_estimates" => p.metadata["orbit_estimates"],
    "epoch_policy" =>
      "elapsed SI seconds only; Orekit uses a dummy TAI epoch; no UTC/frame conversion is tested"
  }),
  "\n"
])
