defmodule OrbitalDynamics.EventSearch.Products do
  @moduledoc """
  Study event products evaluated by the shared scalar search on an explicitly
  declared cubic-Hermite trajectory interpolant. Root bounds apply to that
  interpolant, not to propagation accuracy. Incomplete searches fail closed.
  """
  alias OrbitalDynamics.{AccessGeometry, CentralBody, Epoch, EventSearch, Vector3}
  alias OrbitalDynamics.EventSearch.{Function, Source}

  def capabilities(kind) do
    %{
      detector: :shared_event_search,
      model: kind,
      validation_level: :analysis,
      interpolation: :cubic_hermite,
      boundary_refinement: :shared_scalar_bisection,
      timing_policy: :bounded_root_on_explicit_state_source,
      known_limits:
        physics_limits(kind) ++
          [:interpolated_state_source, :search_policy_limited, :analysis_only]
    }
  end

  defp physics_limits(:cylindrical_central_body_shadow),
    do: [:cylindrical_shadow, :no_penumbra_model]

  defp physics_limits(kind) when kind in [:ground_station_access, :target_visibility],
    do: [:spherical_ground_geometry, :constant_earth_rotation, :no_refraction, :no_terrain_mask]

  defp physics_limits(_), do: [:geocentric_spherical_coordinates]

  def access(trajectory, opts),
    do: ground(trajectory, opts, :ground_station_access, :ground_station)

  def visibility(trajectory, opts), do: ground(trajectory, opts, :target_visibility, :target)

  defp ground(trajectory, opts, type, key) do
    object = Keyword.fetch!(opts, key)
    body = Keyword.get(opts, :central_body, CentralBody.earth())
    validate_frame!(trajectory, body)

    unless body.name == :earth,
      do:
        raise(
          ArgumentError,
          "surface products require terrestrial rotation; use explicit scene for other bodies"
        )

    f =
      Function.new!(
        Atom.to_string(type),
        fn state ->
          elevation = AccessGeometry.elevation_deg(state, object, body)
          {:ok, elevation - object.minimum_elevation_deg, nil, %{"elevation_deg" => elevation}}
        end,
        units: "deg",
        value_tolerance: 1.0e-9,
        condition: :nonnegative
      )

    run(trajectory, f, opts, type, fn samples ->
      elevations = Enum.map(samples, & &1["metadata"]["elevation_deg"])

      AccessGeometry.assumptions()
      |> Map.merge(%{
        minimum_elevation_deg: object.minimum_elevation_deg,
        max_elevation_deg: Enum.max(elevations, fn -> nil end)
      })
      |> Map.merge(
        if key == :ground_station,
          do: %{ground_station_id: object.id},
          else: %{target_id: object.id, target_priority: object.priority}
      )
    end)
  rescue
    e in [ArgumentError, KeyError, MatchError] ->
      {:error, {:invalid_event_search, Exception.message(e)}}
  end

  def eclipse(trajectory, opts) do
    body = Keyword.get(opts, :central_body, CentralBody.earth())
    validate_frame!(trajectory, body)

    {:ok, sun_at} = OrbitalDynamics.EventDetectors.Eclipses.search_sun_geometry(opts)

    f =
      Function.new!(
        "cylindrical_eclipse",
        fn state ->
          with {:ok, sun, provenance} <- sun_at.(state) do
            axial = Vector3.dot(state.position_km, sun)

            distance =
              Vector3.norm(Vector3.subtract(state.position_km, Vector3.scale(sun, axial)))

            radius = body.equatorial_radius_km

            {:ok, max(axial, distance - radius), nil,
             %{
               "sun_direction" => Tuple.to_list(sun),
               "axis_distance_km" => distance,
               "shadow_margin_km" => radius - distance,
               "environment" => provenance
             }}
          end
        end,
        units: "km",
        value_tolerance: 1.0e-9,
        condition: :nonpositive
      )

    run(trajectory, f, opts, :eclipse, fn samples ->
      first = hd(samples)["metadata"]

      %{
        shadow_model: :cylindrical_central_body_shadow,
        central_body: body.name,
        central_body_radius_km: body.equatorial_radius_km,
        sun_direction: List.to_tuple(first["sun_direction"]),
        campaign_environment: first["environment"]["provenance"] || %{},
        minimum_shadow_axis_distance_km:
          samples |> Enum.map(& &1["metadata"]["axis_distance_km"]) |> Enum.min(),
        maximum_shadow_margin_km:
          samples |> Enum.map(& &1["metadata"]["shadow_margin_km"]) |> Enum.max()
      }
    end)
  rescue
    e in [ArgumentError, KeyError, MatchError] ->
      {:error, {:invalid_event_search, Exception.message(e)}}
  end

  def crossing(trajectory, opts) do
    kind = Keyword.fetch!(opts, :crossing)
    target = Keyword.fetch!(opts, if(kind == :latitude, do: :latitude_deg, else: :longitude_deg))

    OrbitalDynamics.MissionAnalysis.Input.number!(
      target,
      "ground angle",
      if(kind == :latitude, do: -90, else: -180),
      if(kind == :latitude, do: 90, else: 180)
    )

    validate_frame!(trajectory, nil)

    if hd(trajectory.states).frame.center != :earth and
         Keyword.get(opts, :frame, :inertial) == :body_fixed and
         not Keyword.has_key?(opts, :rotation_rate_rad_s) and
         not Keyword.has_key?(opts, :earth_rotation_provider),
       do: raise(ArgumentError, "non-Earth rotation must be explicit")

    {:ok, coordinates} = OrbitalDynamics.EventDetectors.GroundTrackCrossings.search_geometry(opts)
    angle = target * :math.pi() / 180
    frame = Keyword.get(opts, :frame, :inertial)

    unless kind in [:latitude, :longitude] and frame in [:inertial, :body_fixed],
      do: raise(ArgumentError, "unsupported ground coordinate")

    f =
      Function.new!(
        "ground_#{kind}",
        fn state ->
          with {:ok, lat, lon, provenance} <- coordinates.(state) do
            a = lon * :math.pi() / 180

            value =
              if kind == :latitude,
                do: :math.sin(lat * :math.pi() / 180) - :math.sin(angle),
                else: :math.sin(a - angle)

            {:ok, value, nil, %{"forward" => :math.cos(a - angle) > 0, "rotation" => provenance}}
          end
        end,
        units: "1",
        value_tolerance: 1.0e-12,
        root_filter: fn m -> kind == :latitude or m["forward"] end
      )

    run(
      trajectory,
      f,
      opts,
      if(kind == :latitude, do: :latitude_crossing, else: :longitude_crossing),
      fn samples ->
        rotation_metadata = hd(samples)["metadata"]["rotation"]

        rotation_metadata =
          Map.new(rotation_metadata, fn {key, value} ->
            value = if key == "coordinate_model", do: String.to_existing_atom(value), else: value
            {String.to_existing_atom(key), value}
          end)

        Map.merge(rotation_metadata, %{
          crossing: kind,
          target_deg: target,
          frame: frame,
          crossing_direction: :unknown
        })
      end
    )
  rescue
    e in [ArgumentError, KeyError, MatchError] ->
      {:error, {:invalid_event_search, Exception.message(e)}}
  end

  defp run(trajectory, f, opts, type, details) do
    source = Source.from_trajectory!(trajectory, interpolation: :cubic_hermite)
    controls = controls(source, trajectory, opts)

    with {:ok, report} <- EventSearch.run(source, [f], controls) do
      if report["status"] != "complete_under_search_policy" do
        {:error, {:incomplete_event_search, report}}
      else
        [result] = report["results"]
        evidence = Map.drop(report, ["results"])

        metadata = fn item, samples ->
          details.(samples)
          |> Map.merge(%{
            scenario_id: trajectory.scenario_id,
            sample_count: length(samples),
            interpolation: :cubic_hermite,
            boundary_refinement: :shared_scalar_bisection,
            event_timing_policy: :bounded_root_on_explicit_state_source,
            event_detector: :shared_event_search,
            validation_level: :analysis,
            confidence:
              if(Map.has_key?(item, "epoch_s"),
                do: :bounded_root_in_interpolated_state,
                else: :estimated_condition_window
              ),
            event_time_tolerance_s: uncertainty(item),
            max_sample_step_s: report["maximum_observed_scan_gap_s"],
            event_search:
              Map.merge(evidence, %{"function" => result["function"], "product" => item}),
            known_limits:
              Enum.reject(
                physics_limits(
                  if(type == :eclipse, do: :cylindrical_central_body_shadow, else: type)
                ) ++ Map.get(details.(samples), :known_limits, []),
                &(&1 in [
                    "sample_cadence_limited",
                    "refinement_not_root_solved",
                    :sample_cadence_limited,
                    :refinement_not_root_solved
                  ])
              ) ++
                [:interpolated_state_source, :search_policy_limited, :analysis_only]
          })
        end

        events =
          if f.condition == :none do
            for e <- result["events"] do
              %{
                type: type,
                starts_at: Epoch.new!(e["epoch_s"], source.start.scale),
                metadata:
                  Map.put(
                    metadata.(e, [%{"metadata" => e["metadata"]}]),
                    :crossing_direction,
                    direction(type, e["direction"])
                  )
              }
            end
          else
            for w <- result["condition_windows"] do
              samples =
                Enum.filter(
                  result["scan_samples"],
                  &(&1["epoch_s"] >= w["starts_at_s"] and &1["epoch_s"] <= w["ends_at_s"])
                )

              # Reuse accounted observations; never sample after the search context closes.
              samples =
                if samples == [],
                  do:
                    Enum.filter(
                      result["events"],
                      &(&1["epoch_s"] >= w["starts_at_s"] and &1["epoch_s"] <= w["ends_at_s"])
                    ),
                  else: samples

              %{
                type: type,
                starts_at: Epoch.new!(w["starts_at_s"], source.start.scale),
                ends_at: Epoch.new!(w["ends_at_s"], source.start.scale),
                metadata:
                  metadata.(w, samples)
                  |> Map.merge(%{
                    start_boundary: w["start_kind"],
                    end_boundary: w["end_kind"],
                    start_boundary_detail: w["start_boundary"],
                    end_boundary_detail: w["end_boundary"]
                  })
              }
            end
          end

        {:ok, events}
      end
    end
  rescue
    e in [ArgumentError, KeyError, MatchError] ->
      {:error, {:invalid_event_search, Exception.message(e)}}
  end

  def controls(source, trajectory, opts) do
    gaps =
      trajectory.states
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> b.epoch.seconds_since_j2000 - a.epoch.seconds_since_j2000 end)

    step =
      max(
        (source.stop.seconds_since_j2000 - source.start.seconds_since_j2000) / 9999,
        min(60.0, Enum.max(gaps))
      )

    [
      starts_at: source.start,
      ends_at: source.stop,
      max_check_step_s: step,
      time_tolerance_s: min(Keyword.get(opts, :root_tolerance_s, 0.001), step / 10),
      max_iterations: Keyword.get(opts, :root_max_iterations, 64),
      max_evaluations: 100_000,
      include_samples: true
    ]
  end

  defp direction(:latitude_crossing, "increasing"), do: :northbound
  defp direction(:latitude_crossing, "decreasing"), do: :southbound
  defp direction(:longitude_crossing, "increasing"), do: :eastbound
  defp direction(:longitude_crossing, "decreasing"), do: :westbound
  defp direction(_, "boundary"), do: :boundary
  defp direction(_, _), do: :touching

  defp uncertainty(%{"midpoint_time_bound_s" => bound}), do: bound

  defp uncertainty(window) do
    Enum.map(["start_boundary", "end_boundary"], fn key ->
      Map.get(window[key] || %{}, "midpoint_time_bound_s", 0.0)
    end)
    |> Enum.max()
  end

  defp validate_frame!(trajectory, body) do
    frame = hd(trajectory.states).frame

    unless frame.orientation in [:j2000, :eme2000] and (body == nil or frame.center == body.name),
      do:
        raise(
          ArgumentError,
          "event geometry requires a body-centered J2000/EME2000 inertial source"
        )
  end
end
