defmodule OrbitalDynamics.Validation.EventSearch.LeoCheck do
  @moduledoc false
  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    Scenario,
    Spacecraft,
    StateVector,
    Trajectory
  }

  alias OrbitalDynamics.EventSearch.Products
  alias OrbitalDynamics.Propagators.J2Drag
  alias OrbitalDynamics.Validation.EventSearch.{Comparison, ReferenceBundle}
  alias OrbitalDynamics.Validation.ExternalTruth.OrekitLeoCase

  def verify do
    with {:ok, bundle} <- OrekitLeoCase.reference_bundle() do
      reference = bundle.reference
      c = bundle.config
      files = ReferenceBundle.load!()
      fine_reference = :json.decode(files["leo-reference.json"])

      {:ok, fine_config} =
        OrbitalDynamics.Validation.ExternalTruth.StrictBundle.parse_properties_strict(
          files["leo-fine.properties"]
        )

      changed_keys = ~w(case_id generated_at_utc integrator_step_s state_output_step_s)

      unless Map.drop(c, changed_keys) == Map.drop(fine_config, changed_keys) and
               fine_config["integrator_step_s"] == "2.5" and
               fine_config["state_output_step_s"] == "2.5" and
               fine_reference["case_id"] == fine_config["case_id"] and
               fine_reference["identity"] == reference["identity"] and
               fine_reference["model"] == Map.put(reference["model"], "integrator_step_s", 2.5) and
               fine_reference["retained_state_grid_s"] == 10 and
               Enum.map(fine_reference["states"], & &1["epoch_s"]) ==
                 Enum.map(reference["states"], & &1["epoch_s"]),
             do: raise(ArgumentError, "finer LEO reference semantics mismatch")

      body =
        CentralBody.new!(:earth, number(c, "mu_m3_s2") / 1.0e9,
          equatorial_radius_km: number(c, "equatorial_radius_m") / 1000,
          j2: number(c, "j2")
        )

      station =
        GroundStation.new!(
          "reference-station",
          number(c, "station_latitude_deg"),
          number(c, "station_longitude_deg"),
          altitude_km: number(c, "station_altitude_m") / 1000,
          minimum_elevation_deg: number(c, "station_minimum_elevation_deg")
        )

      anchors =
        Enum.map(reference["states"], fn row ->
          StateVector.new!(
            vector(row["position_m"], 0.001),
            vector(row["velocity_m_s"], 0.001),
            Epoch.new!(row["epoch_s"], :tdb),
            Frame.earth_inertial_j2000()
          )
        end)

      frozen = %Trajectory{scenario_id: "orekit-anchors", states: anchors, assumptions: %{}}

      interpolation =
        for tolerance <- [0.001, 0.000001] do
          path(frozen, body, station, reference, tolerance)
          |> Map.put("root_tolerance_s", tolerance)
          |> Map.put(
            "state_source",
            "Hermite interpolation of frozen Orekit states; not Orekit dense output"
          )
        end

      # All inputs come from the content-verified case, including the mass,
      # atmosphere parameters and fixed output horizon. J2Drag's declared
      # atmosphere defaults are separately matched by the existing case seal.
      initial = hd(anchors)

      satellite =
        Spacecraft.new!("event-check", number(c, "spacecraft_mass_kg"),
          area_m2: number(c, "spacecraft_drag_area_m2"),
          drag_coefficient: number(c, "spacecraft_drag_coefficient")
        )

      propagated =
        for {integration, output} <- [{10.0, 10.0}, {5.0, 10.0}, {2.5, 10.0}, {2.5, 5.0}] do
          scenario =
            Scenario.new!("event-check", satellite, initial,
              duration_s: reference["horizon_s"],
              output_step_s: output,
              central_body: body
            )

          {:ok, trajectory} = J2Drag.propagate(scenario, max_step_s: integration)

          comparison_reference = if integration == 10.0, do: reference, else: fine_reference

          comparison_anchors =
            if integration == 10.0, do: anchors, else: reference_states(fine_reference)

          residuals = state_residuals(trajectory, comparison_anchors)

          sensitivity =
            state_residuals(trajectory, anchors)
            |> Map.drop(["status", "position_tolerance_m", "velocity_tolerance_m_s"])

          runtime = runtime_parameters(trajectory, c)
          controls = sampling_controls(trajectory, integration, output)
          result = path(trajectory, body, station, comparison_reference, 0.000001)

          result
          |> Map.put(
            "status",
            if(
              result["status"] == "pass" and residuals["status"] == "pass" and
                runtime["status"] == "pass" and controls["status"] == "pass",
              do: "pass",
              else: "fail"
            )
          )
          |> Map.merge(%{
            "integration_step_s" => integration,
            "output_step_s" => output,
            "state_source" =>
              "production J2Drag propagation followed by production Hermite event products",
            "state_residuals" => residuals,
            "difference_from_original_10s_reference" => sensitivity,
            "reference_integrator_step_s" => comparison_reference["model"]["integrator_step_s"],
            "runtime_parameters" => runtime,
            "sampling_controls" => controls
          })
        end

      groups = interpolation ++ propagated

      {:ok,
       %{
         "status" => if(Enum.all?(groups, &(&1["status"] == "pass")), do: "pass", else: "fail"),
         "reference_identity" => bundle.identity,
         "fine_reference_manifest_sha256" => ReferenceBundle.manifest_identity(),
         "case_id" => reference["case_id"],
         "frame_mapping" =>
           "project eci_j2000 axes matched to this case's EME2000 axes; no frame transformation tested",
         "horizon_s" => reference["horizon_s"],
         "reference_state_count" => length(anchors),
         "interpolation_and_root_precision" => interpolation,
         "propagation_and_output_sensitivity" => propagated,
         "limits" => [
           "frozen Orekit RK4 10s case is an independent numerical reference, not physical truth",
           "finer integration is a sensitivity comparison, not an assumed truth oracle",
           "event tolerances apply to this exact fixed-Sun cylindrical-shadow and spherical constant-rotation case",
           "root brackets bound the supplied interpolant; residuals to external events include interpolation and propagation differences"
         ]
       }}
    end
  end

  defp path(trajectory, body, station, reference, tolerance) do
    {:ok, access} =
      Products.access(trajectory,
        central_body: body,
        ground_station: station,
        root_tolerance_s: tolerance,
        root_max_iterations: 64
      )

    {:ok, eclipses} =
      Products.eclipse(trajectory,
        central_body: body,
        sun_direction: {1, 0, 0},
        root_tolerance_s: tolerance,
        root_max_iterations: 64
      )

    a =
      Comparison.compare(
        reference["events"]["access"],
        boundaries(access, "aos", "los"),
        0.001,
        tolerance
      )

    e =
      Comparison.compare(
        reference["events"]["eclipse"],
        boundaries(eclipses, "ingress", "egress"),
        0.001,
        tolerance
      )

    %{
      "status" => if(a["status"] == "pass" and e["status"] == "pass", do: "pass", else: "fail"),
      "access" => a,
      "eclipse" => e,
      "access_search_policy" => hd(access).metadata.event_search |> Map.drop(["product"]),
      "eclipse_search_policy" => hd(eclipses).metadata.event_search |> Map.drop(["product"])
    }
  end

  def boundaries(events, entry, exit) do
    Enum.flat_map(events, fn event ->
      product = event.metadata.event_search["product"]

      for {kind, key, epoch} <- [
            {entry, "start_boundary", event.starts_at},
            {exit, "end_boundary", event.ends_at}
          ] do
        Map.merge(product[key], %{"type" => kind, "epoch_s" => epoch.seconds_since_j2000})
      end
    end)
  end

  @doc false
  def sampling_controls(trajectory, integration, output) do
    actual = Enum.map(trajectory.states, & &1.epoch.seconds_since_j2000)
    expected = for i <- 0..trunc(21600 / output), do: i * output
    actual_step = Map.get(trajectory.assumptions, :max_step_s, :null)

    first_mismatch =
      Enum.zip(expected, actual)
      |> Enum.with_index()
      |> Enum.find_value(:null, fn {{e, a}, i} ->
        if e != a, do: %{"index" => i, "expected_epoch_s" => e, "observed_epoch_s" => a}
      end)

    %{
      "status" => if(actual == expected and actual_step == integration, do: "pass", else: "fail"),
      "expected_output_step_s" => output,
      "requested_integration_step_s" => integration,
      "observed_integration_step_s" => actual_step,
      "expected_state_count" => length(expected),
      "observed_state_count" => length(actual),
      "epoch_grid_matches" => actual == expected,
      "first_epoch_mismatch" => first_mismatch
    }
  end

  defp reference_states(reference) do
    for row <- reference["states"],
        do:
          StateVector.new!(
            vector(row["position_m"], 0.001),
            vector(row["velocity_m_s"], 0.001),
            Epoch.new!(row["epoch_s"], :tdb),
            Frame.earth_inertial_j2000()
          )
  end

  defp runtime_parameters(trajectory, c) do
    a = trajectory.assumptions

    expected = %{
      "mu_km3_s2" => number(c, "mu_m3_s2") / 1.0e9,
      "equatorial_radius_km" => number(c, "equatorial_radius_m") / 1000,
      "j2" => number(c, "j2"),
      "spacecraft_mass_kg" => number(c, "spacecraft_mass_kg"),
      "drag_area_m2" => number(c, "spacecraft_drag_area_m2"),
      "drag_coefficient" => number(c, "spacecraft_drag_coefficient"),
      "earth_rotation_rate_rad_s" => number(c, "earth_rotation_rate_rad_s"),
      "numerical_method" => "rk4_fixed_step",
      "force_composition" => "single_acceleration_sum_per_rk4_stage",
      "frame" => "eci_j2000",
      "epoch_scale" => "tdb",
      "atmosphere_parameters" => %{
        "reference_altitude_km" => number(c, "atmosphere_reference_altitude_m") / 1000,
        "reference_density_kg_m3" => number(c, "atmosphere_reference_density_kg_m3"),
        "scale_height_km" => number(c, "atmosphere_scale_height_m") / 1000
      }
    }

    observed =
      Map.new(expected, fn {key, _} ->
        value =
          if key == "atmosphere_parameters",
            do: a.atmosphere_provider.parameters,
            else: Map.fetch!(a, String.to_existing_atom(key))

        {key, if(is_atom(value), do: Atom.to_string(value), else: value)}
      end)

    %{
      "status" => if(expected == observed, do: "pass", else: "fail"),
      "expected" => expected,
      "observed" => observed
    }
  end

  defp state_residuals(trajectory, reference) do
    states = Map.new(trajectory.states, &{&1.epoch.seconds_since_j2000, &1})

    residuals =
      for r <- reference do
        o = Map.fetch!(states, r.epoch.seconds_since_j2000)

        {max_component(o.position_km, r.position_km) * 1000,
         max_component(o.velocity_km_s, r.velocity_km_s) * 1000}
      end

    p = residuals |> Enum.map(&elem(&1, 0)) |> Enum.max()
    v = residuals |> Enum.map(&elem(&1, 1)) |> Enum.max()

    %{
      "matched_epoch_count" => length(residuals),
      "max_position_component_error_m" => p,
      "max_velocity_component_error_m_s" => v,
      "position_tolerance_m" => 0.01,
      "velocity_tolerance_m_s" => 0.00001,
      "status" => if(p <= 0.01 and v <= 0.00001, do: "pass", else: "fail")
    }
  end

  defp max_component(a, b),
    do: Enum.zip_with(Tuple.to_list(a), Tuple.to_list(b), fn x, y -> abs(x - y) end) |> Enum.max()

  defp vector(xs, scale), do: xs |> Enum.map(&(&1 * scale)) |> List.to_tuple()
  defp number(c, k), do: c |> Map.fetch!(k) |> Float.parse() |> elem(0)
end
