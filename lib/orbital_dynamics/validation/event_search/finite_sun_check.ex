defmodule OrbitalDynamics.Validation.EventSearch.FiniteSunCheck do
  @moduledoc false
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, EventSearch}
  alias OrbitalDynamics.EventSearch.Source
  alias OrbitalDynamics.EventDetectors.Occultations
  alias OrbitalDynamics.MissionAnalysis.{SphericalScene, Environments.Fixed}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Pointing
  alias OrbitalDynamics.MissionAnalysis.Resource.Generation.SolarArray
  alias OrbitalDynamics.Validation.EventSearch.{Comparison, ReferenceBundle}

  @angle_tolerance 1.0e-10
  @fraction_tolerance 1.0e-8
  @power_tolerance_w 1.0e-5
  @contact_tolerance_s 1.0e-5
  @root_tolerance_s 1.0e-6

  defdelegate bundle_path(), to: ReferenceBundle

  def verify(directory \\ bundle_path()) do
    try do
      files = ReferenceBundle.load!(directory)
      reference = :json.decode(files["reference-output.json"])

      unless reference["format"] == "orekit_finite_sun_reference.v1" and
               Enum.map(reference["cases"], & &1["id"]) == ["total", "annular"],
             do: raise(ArgumentError, "finite-Sun reference identity mismatch")

      cases = Enum.map(reference["cases"], &verify_case/1)

      {:ok,
       %{
         "status" => if(Enum.all?(cases, &(&1["status"] == "pass")), do: "pass", else: "fail"),
         "manifest_sha256" => ReferenceBundle.manifest_identity(),
         "tool" => reference["tool"],
         "java_runtime" => reference["java_runtime"],
         "cases" => cases,
         "limits" => [
           "two synthetic straight flybys, not orbital dynamics or mission acceptance",
           "uniform angular disks and center-ray panel cosine; no radiance integral, limb darkening, atmosphere or array hardware validation",
           "exact contact labels within the angular comparison band are excluded from classification checks only",
           "finite scans and exact expected case counts do not prove discovery for arbitrary sources"
         ]
       }}
    rescue
      e in [ArgumentError, KeyError, MatchError, File.Error] ->
        {:error, {:finite_sun_reference_failed, Exception.message(e)}}
    end
  end

  defp verify_case(c) do
    p = c["inputs"]
    frame = Frame.new!(:reference, :reference, :inertial)
    start = Epoch.new!(0, :tai)
    stop = Epoch.new!(p["stop_s"], :tai)

    observer =
      Source.new!(fn t -> {:ok, state(p, t, frame)} end, start, stop, frame, %{
        "evaluation" => "analytic_straight_flyby",
        "inputs" => p
      })

    constant = fn position, label ->
      Source.new!(
        fn t -> {:ok, StateVector.new!(position, {0, 0, 0}, Epoch.new!(t, :tai), frame)} end,
        start,
        stop,
        frame,
        %{"evaluation" => label}
      )
    end

    sun = constant.({p["sun_x_km"], 0, 0}, "declared_fixed_sun")
    body = constant.({0, 0, 0}, "body_origin")

    functions =
      Occultations.functions("reference", sun, p["sun_radius_km"], body, p["body_radius_km"],
        value_tolerance: 1.0e-14
      )

    {:ok, search} =
      EventSearch.run(observer, functions,
        starts_at: start,
        ends_at: stop,
        max_check_step_s: 0.25,
        time_tolerance_s: @root_tolerance_s,
        max_iterations: 64,
        max_evaluations: 50000
      )

    {:ok, solar, _} = SolarArray.prepare(nil, scene(p, frame), solar_configuration(p))
    {:ok, _, solar_search} = SolarArray.search_boundaries(solar, observer)
    catalog_contacts = contacts(c["contacts"], catalog_boundaries(search))
    solar_contacts = contacts(c["contacts"], catalog_boundaries(solar_search))

    rows =
      for r <- c["samples"] do
        s = state(p, r["epoch_s"], frame)
        {:ok, g} = Occultations.geometry(s, sun, p["sun_radius_km"], body, p["body_radius_km"])

        {:ok, watts, metrics} =
          SolarArray.evaluate(
            %{
              epoch_s: r["epoch_s"],
              spacecraft_state: s,
              pointing: Pointing.new!(frame, {1, 0, 0, 0}),
              interval_start_s: r["epoch_s"],
              interval_end_s: r["epoch_s"]
            },
            solar
          )

        m = g.metadata

        angle_error =
          Enum.max([
            abs(m["source_angular_radius_rad"] - r["source_radius_rad"]),
            abs(m["occulter_angular_radius_rad"] - r["body_radius_rad"]),
            abs(m["angular_separation_rad"] - r["separation_rad"])
          ])

        ambiguous =
          min(
            abs(r["separation_rad"] - r["source_radius_rad"] - r["body_radius_rad"]),
            abs(r["separation_rad"] - abs(r["source_radius_rad"] - r["body_radius_rad"]))
          ) <= @angle_tolerance

        fraction_error = abs(m["visible_fraction"] - r["visible_fraction"])
        power_error = abs(watts - r["bus_power_w"])

        regime_passed =
          ambiguous or
            (m["regime"] == r["regime"] and metrics["occultation_regime"] == r["regime"])

        %{
          "epoch_s" => r["epoch_s"],
          "reference_regime" => r["regime"],
          "observed_regime" => m["regime"],
          "contact_label_ambiguous" => ambiguous,
          "angle_error_rad" => angle_error,
          "reference_visible_fraction" => r["visible_fraction"],
          "observed_visible_fraction" => m["visible_fraction"],
          "fraction_error" => fraction_error,
          "reference_bus_power_w" => r["bus_power_w"],
          "observed_bus_power_w" => watts,
          "power_error_w" => power_error,
          "status" =>
            if(
              angle_error <= @angle_tolerance and fraction_error <= @fraction_tolerance and
                power_error <= @power_tolerance_w and regime_passed,
              do: "pass",
              else: "fail"
            )
        }
      end

    required =
      if c["id"] == "total",
        do: %{"outer" => 2, "umbra" => 2},
        else: %{"outer" => 2, "antumbra" => 2}

    coverage =
      Enum.frequencies_by(c["contacts"], & &1["kind"]) == required and
        Enum.all?(
          if(c["id"] == "total", do: ~w(none penumbra umbra), else: ~w(none penumbra antumbra)),
          fn regime ->
            Enum.any?(
              rows,
              &(&1["reference_regime"] == regime and not &1["contact_label_ambiguous"])
            )
          end
        )

    passed =
      coverage and search["status"] == "complete_under_search_policy" and
        solar_search["status"] == "complete_under_search_policy" and
        Enum.all?(rows, &(&1["status"] == "pass")) and
        Enum.all?(catalog_contacts ++ solar_contacts, &(&1["status"] == "pass"))

    %{
      "id" => c["id"],
      "status" => if(passed, do: "pass", else: "fail"),
      "expected_case_coverage_passed" => coverage,
      "inputs" => p,
      "sample_count" => length(rows),
      "tolerances" => %{
        "angle_rad" => @angle_tolerance,
        "visible_fraction" => @fraction_tolerance,
        "bus_power_w" => @power_tolerance_w,
        "contact_s" => @contact_tolerance_s
      },
      "max_angle_error_rad" => rows |> Enum.map(& &1["angle_error_rad"]) |> Enum.max(),
      "max_fraction_error" => rows |> Enum.map(& &1["fraction_error"]) |> Enum.max(),
      "max_power_error_w" => rows |> Enum.map(& &1["power_error_w"]) |> Enum.max(),
      "ambiguous_contact_label_count" => Enum.count(rows, & &1["contact_label_ambiguous"]),
      "catalog_contacts" => catalog_contacts,
      "solar_consumer_contacts" => solar_contacts,
      "samples" => rows,
      "catalog_search" => search,
      "solar_consumer_search" => solar_search
    }
  end

  defp contacts(expected, observed) do
    for kind <- ~w(outer umbra antumbra) do
      ref = for r <- expected, r["kind"] == kind, do: %{"type" => kind, "epoch_s" => r["epoch_s"]}
      obs = Enum.filter(observed, &(&1["type"] == kind)) |> Enum.sort_by(& &1["epoch_s"])

      Comparison.compare(ref, obs, @contact_tolerance_s, @root_tolerance_s)
      |> Map.put("kind", kind)
    end
  end

  defp catalog_boundaries(search) do
    for r <- search["results"],
        e <- r["events"],
        r["function"]["id"] |> String.split(".") |> List.last() != "penumbra" do
      kind = r["function"]["id"] |> String.split(".") |> List.last()
      Map.put(e, "type", if(kind == "any", do: "outer", else: kind))
    end
  end

  defp state(p, t, frame),
    do:
      StateVector.new!(
        {p["x_km"], p["y0_km"] + p["vy_km_s"] * t, p["z_km"]},
        {0, p["vy_km_s"], 0},
        Epoch.new!(t, :tai),
        frame
      )

  defp scene(p, frame) do
    env =
      Fixed.new!(frame, Epoch.new!(0, :tai),
        starts_at_s: 0,
        ends_at_s: p["stop_s"],
        sun_direction: {1, 0, 0},
        rotation_rate_rad_s: 0,
        rotation_angle_rad: 0
      )

    SphericalScene.new!(
      CentralBody.new!(:reference, 1, equatorial_radius_km: p["body_radius_km"]),
      frame,
      :tai,
      {Fixed, env}
    )
  end

  defp solar_configuration(p),
    do: %{
      "kind" => "solar_array",
      "shadow_model" => "finite_sun",
      "solar_radius_km" => p["sun_radius_km"],
      "solar_distance_km" => p["sun_x_km"],
      "solar_irradiance_w_m2" => 1000,
      "bus_efficiency" => 1,
      "panels" => [
        %{"id" => "panel", "area_m2" => 1, "efficiency" => 1, "normal_body" => [1, 0, 0]}
      ],
      "event_search" => %{
        "max_check_step_s" => 0.25,
        "time_tolerance_s" => @root_tolerance_s,
        "max_iterations" => 64,
        "max_evaluations" => 50000
      }
    }
end
