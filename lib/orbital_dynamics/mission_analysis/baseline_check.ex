defmodule OrbitalDynamics.MissionAnalysis.BaselineCheck do
  @moduledoc """
  Offline, content-bound comparison of one reference orbit with Orekit 13.1.7.

  Evidence covers one matched-input J2 trajectory and sampled spherical geometry.
  This experimental check is separate from the external-truth registry; it does
  not change any propagator's validation level or validate illumination service.
  """
  alias OrbitalDynamics.{Vector3}
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, SphericalScene}

  @manifest_sha256 "368361be4a59c76c6341020c89c1034edc125d603a29f0dc1859e62aeb7e50e3"
  @files ~w(MissionBaseline.java generate.sh export_inputs.exs dependencies.lock case.properties environment.csv inputs.json reference-output.csv)
  @header "elapsed_s,x_m,y_m,z_m,vx_m_s,vy_m_s,vz_m_s,range_m,elevation_deg,target_sun_elevation_deg,off_nadir_deg,sunlit"
  @tolerances %{
    "position_m" => 1.0,
    "velocity_m_s" => 0.002,
    "range_m" => 1.0,
    "elevation_deg" => 0.0001,
    "target_sun_elevation_deg" => 1.0e-9,
    "off_nadir_deg" => 0.0001
  }

  def bundle_path,
    do: Application.app_dir(:orbital_dynamics, "priv/validation/mission_analysis_orekit")

  def verify(directory \\ bundle_path()) do
    try do
      identity = verify_content!(directory)
      inputs = directory |> Path.join("inputs.json") |> File.read!() |> :json.decode()
      # The expected configuration is fixed in the verified bundle. No external states are inputs.
      config = inputs["baseline_configuration"]
      p = ReferenceMission.prepare!(config)
      [asset] = p.assets
      [request] = p.requests

      environment =
        p.context.environment_provider.describe(p.context.environment_config)
        |> OrbitalDynamics.Schema.JsonSafety.normalize_input!("baseline environment")
        |> Map.update!("content_verification", &Map.delete(&1, "path"))

      unless inputs["environment"] == environment and
               inputs["orbit_estimates"] == p.metadata["orbit_estimates"],
             do:
               raise(
                 ArgumentError,
                 "baseline environment/orbit design no longer matches pinned inputs"
               )

      rows = read_rows!(Path.join(directory, "reference-output.csv"))
      states = asset.trajectory.states

      unless length(rows) == length(states),
        do: raise(ArgumentError, "baseline sample count mismatch")

      errors =
        Enum.zip(states, rows)
        |> Enum.map(fn {state, row} ->
          [t, x, y, z, vx, vy, vz, range, elevation, solar_elevation, off_nadir, sunlit] = row

          unless state.epoch.seconds_since_j2000 - config["epoch_s"] == t,
            do: raise(ArgumentError, "baseline sample epoch mismatch")

          {:ok, scene} = SphericalScene.at(p.context, state, request.subject)

          %{
            "position_m" =>
              Vector3.norm(Vector3.subtract(Vector3.scale(state.position_km, 1000), {x, y, z})),
            "velocity_m_s" =>
              Vector3.norm(
                Vector3.subtract(Vector3.scale(state.velocity_km_s, 1000), {vx, vy, vz})
              ),
            "range_m" => abs(scene.slant_range_km * 1000 - range),
            "elevation_deg" => abs(scene.elevation_deg - elevation),
            "target_sun_elevation_deg" => abs(scene.target_sun_elevation_deg - solar_elevation),
            "off_nadir_deg" => abs(scene.off_nadir_deg - off_nadir),
            "shadow_mismatch" => scene.spacecraft_sunlit? != sunlit
          }
        end)

      measurements =
        Map.new(@tolerances, fn {metric, tolerance} ->
          maximum = errors |> Enum.map(& &1[metric]) |> Enum.max()

          {metric,
           %{
             "max_absolute_error" => maximum,
             "tolerance" => tolerance,
             "passed" => maximum <= tolerance
           }}
        end)

      mismatches = Enum.count(errors, & &1["shadow_mismatch"])
      passed = mismatches == 0 and Enum.all?(measurements, fn {_, m} -> m["passed"] end)

      {:ok,
       %{
         "format" => "mission_baseline_check.v1",
         "status" => if(passed, do: "pass", else: "fail"),
         "tool" => "Orekit 13.1.7 / Hipparchus 4.0.3",
         "sample_count" => length(rows),
         "horizon_s" => config["duration_s"],
         "measurements" => measurements,
         "shadow_mismatch_count" => mismatches,
         "reference_sunlit_sample_count" => Enum.count(rows, &List.last/1),
         "reference_shadowed_sample_count" => Enum.count(rows, &(not List.last(&1))),
         "source_manifest_sha256" => @manifest_sha256,
         "verified_file_sha256" => identity,
         "baseline_configuration" => config,
         "comparison_policy" => %{
           "production_integrator" => "RK4, 10 s maximum step",
           "reference_integrator" =>
             "Dormand-Prince 8(5,3), adaptive 0.001..30 s, Cartesian state",
           "reference_position_absolute_tolerance_m" => 1.0e-5,
           "reference_velocity_absolute_tolerance_m_s" => 1.0e-8,
           "reference_relative_tolerance" => 1.0e-13
         },
         "limits" => [
           "one 600 km circular initial orbit, 6000 s, 301 matched sample epochs",
           "identical point-mass/J2 constants and supplied Sun/rotation inputs",
           "independent circular-element conversion, integration, topocentric geometry and cylindrical shadow routines",
           "Sun/rotation input accuracy, SSO design derivation and UTC/TAI/frame conversion are not independently tested",
           "EME2000 axes identified with repository J2000 axes by explicit comparison assumption",
           "baseline has no shadowed samples; eclipse entry/exit is not checked",
           "no validation of mirror optics, camera GSD, tracking, scheduling, other grid cases, or flight readiness"
         ]
       }}
    rescue
      e in [ArgumentError, MatchError, KeyError, File.Error] ->
        {:error, {:baseline_check_failed, Exception.message(e)}}
    end
  end

  defp verify_content!(directory) do
    manifest = File.read!(Path.join(directory, "SHA256SUMS"))

    unless sha(manifest) == @manifest_sha256,
      do: raise(ArgumentError, "baseline manifest identity mismatch")

    entries =
      manifest
      |> String.split("\n", trim: true)
      |> Enum.map(fn line ->
        [digest, name] = String.split(line, "  ")
        {name, digest}
      end)

    unless Enum.map(entries, &elem(&1, 0)) == @files,
      do: raise(ArgumentError, "unexpected baseline files")

    Enum.each(entries, fn {name, digest} ->
      unless sha(File.read!(Path.join(directory, name))) == digest,
        do: raise(ArgumentError, "baseline content mismatch: #{name}")
    end)

    Map.new(entries)
  end

  defp sha(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp read_rows!(path) do
    [header | rows] = path |> File.read!() |> String.split("\n", trim: true)
    unless header == @header, do: raise(ArgumentError, "unexpected baseline CSV header")

    Enum.map(rows, fn row ->
      cells = String.split(row, ",")
      {numbers, [boolean]} = Enum.split(cells, 11)

      flag =
        case boolean do
          "true" -> true
          "false" -> false
          _ -> raise ArgumentError, "invalid baseline shadow flag"
        end

      Enum.map(numbers, fn value ->
        {n, ""} = Float.parse(value)
        n
      end) ++ [flag]
    end)
  end
end
