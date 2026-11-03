defmodule OrbitalDynamics.MissionAnalysis.Resource.Generation.SolarArray do
  @moduledoc "Fixed body panels with cosine incidence and explicit point-Sun or finite-Sun illumination."
  @behaviour OrbitalDynamics.MissionAnalysis.Resource.Generation
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.Frame
  alias OrbitalDynamics.MissionAnalysis.{Input, SphericalScene, Models.SurfaceSupport}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q

  def prepare(asset, context, c) do
    SurfaceSupport.fields!(
      c,
      ~w(kind panels solar_irradiance_w_m2 bus_efficiency shadow_model) ++
        if(c["shadow_model"] == "finite_sun",
          do: ~w(solar_radius_km solar_distance_km event_search),
          else: []
        ),
      "solar array"
    )

    unless c["kind"] == "solar_array" and
             c["shadow_model"] in ["cylindrical_point_sun", "finite_sun"],
           do: raise(ArgumentError, "explicit solar_array and supported shadow model required")

    if c["shadow_model"] == "finite_sun" do
      Input.positive!(c["solar_radius_km"], "solar radius")
      Input.positive!(c["solar_distance_km"], "solar distance")

      unless c["solar_distance_km"] > c["solar_radius_km"],
        do: raise(ArgumentError, "Sun distance must exceed radius")

      SurfaceSupport.fields!(
        c["event_search"],
        ~w(max_check_step_s time_tolerance_s max_iterations max_evaluations),
        "solar contact search"
      )

      Input.positive!(c["event_search"]["max_check_step_s"], "solar search step")
      Input.positive!(c["event_search"]["time_tolerance_s"], "solar search tolerance")
      integer!(c["event_search"]["max_iterations"], "solar search iterations", 1, 128)
      integer!(c["event_search"]["max_evaluations"], "solar search evaluations", 1, 100_000)

      unless c["event_search"]["time_tolerance_s"] < c["event_search"]["max_check_step_s"],
        do: raise(ArgumentError, "solar tolerance must be below search step")
    end

    nullable!(c["solar_irradiance_w_m2"], "solar irradiance", 0, 1.0e8)
    nullable!(c["bus_efficiency"], "solar bus efficiency", 0, 1)

    unless is_list(c["panels"]) and length(c["panels"]) in 1..32,
      do: raise(ArgumentError, "1..32 explicit solar panels required")

    panels =
      Enum.map(c["panels"], fn p ->
        SurfaceSupport.fields!(p, ~w(id area_m2 efficiency normal_body), "solar panel")
        Input.id!(p["id"])
        nullable!(p["area_m2"], "panel area", 0, 1.0e8)
        nullable!(p["efficiency"], "panel efficiency", 0, 1)

        normal =
          if p["normal_body"] == :null,
            do: :unknown,
            else: Input.unit!(p["normal_body"], "panel body normal")

        %{id: p["id"], area: p["area_m2"], efficiency: p["efficiency"], normal: normal}
      end)

    if length(Enum.uniq_by(panels, & &1.id)) != length(panels),
      do: raise(ArgumentError, "duplicate solar panel IDs")

    scene = if match?(%SphericalScene{}, context), do: context, else: nil

    if scene && asset do
      first = hd(asset.trajectory.states)

      unless Frame.compatible?(scene.frame, first.frame) and scene.time_scale == first.epoch.scale,
        do: raise(ArgumentError, "solar scene frame/time scale must match asset")
    end

    environment =
      if scene, do: scene.environment_provider.describe(scene.environment_config), else: :null

    coverage =
      case environment do
        %{"coverage" => %{"starts_at_s" => a, "ends_at_s" => b}}
        when is_number(a) and is_number(b) ->
          Input.number!(a, "solar environment start", -1.0e12, 1.0e12)
          Input.number!(b, "solar environment end", -1.0e12, 1.0e12)
          unless b > a, do: raise(ArgumentError, "invalid solar environment coverage")
          {a, b}

        _ ->
          nil
      end

    {:ok,
     %{
       shadow_model: c["shadow_model"],
       solar_radius: c["solar_radius_km"],
       solar_distance: c["solar_distance_km"],
       search: c["event_search"],
       scene: scene,
       coverage: coverage,
       panels: panels,
       irradiance: c["solar_irradiance_w_m2"],
       bus_efficiency: c["bus_efficiency"]
     },
     %{
       "model" => "body_fixed_solar_array_v1",
       "configuration" => c,
       "body" => if(scene, do: Atom.to_string(scene.body.name), else: :null),
       "radius_km" => if(scene, do: scene.body.equatorial_radius_km, else: :null),
       "frame" =>
         if(scene,
           do: %{
             "name" => Atom.to_string(scene.frame.name),
             "center" => Atom.to_string(scene.frame.center),
             "orientation" => Atom.to_string(scene.frame.orientation)
           },
           else: :null
         ),
       "time_scale" => if(scene, do: Atom.to_string(scene.time_scale), else: :null),
       "environment" => environment,
       "power_units" => "bus-side W before battery charge efficiency",
       "limits" => [
         if(c["shadow_model"] == "finite_sun",
           do:
             "simultaneous spherical Sun/body; uniform angular-disk overlap; declared constant Sun range along environment direction; no limb darkening, atmosphere or light-time",
           else:
             "spherical opaque body, parallel point-Sun rays, binary cylindrical shadow; no penumbra"
         ),
         "visible disk area fraction times center-ray panel cosine is a separable approximation, not a finite-disk projected irradiance integral near panel edges",
         "fixed single-sided body-mounted panels; no deployment, hinge, mode-dependent inhibition or self-shadowing",
         "declared fixed irradiance and efficiencies; no Sun-distance scaling, thermal, degradation, wiring or regulator dynamics",
         "midpoint power integration; finite-Sun contact search uses the runtime state source with explicit discovery limits; contact brackets do not bound integrated energy error"
       ]
     }}
  end

  # Geometric eclipse crossings depend on the checked runtime state source; they
  # are not claimed as exact static boundaries by this sampled provider. Known
  # finite environment coverage boundaries are retained to stop at their edges.
  def boundaries(%{coverage: {a, b}}), do: [a, b]
  def boundaries(_), do: []

  def evaluate(_input, %{scene: nil}), do: {:unknown, :solar_environment_missing}

  def evaluate(input, session) do
    cond do
      session.coverage == nil ->
        {:unknown, :solar_environment_coverage_unknown}

      outside_coverage?(input, session.coverage) ->
        {:unknown, :solar_environment_outside_coverage}

      session.irradiance == :null or session.bus_efficiency == :null or
          Enum.any?(
            session.panels,
            &(&1.area == :null or &1.efficiency == :null or &1.normal == :unknown)
          ) ->
        {:unknown, :solar_configuration_unknown}

      input.epoch_s != input.spacecraft_state.epoch.seconds_since_j2000 ->
        {:error, :solar_input_epoch_mismatch}

      not Frame.compatible?(input.pointing.frame, input.spacecraft_state.frame) ->
        {:error, :solar_pointing_frame_mismatch}

      true ->
        case SphericalScene.environment_at(session.scene, input.spacecraft_state) do
          {:ok, environment} ->
            if session.shadow_model == "finite_sun" do
              with {:ok, _, _} <- finite_geometry(input.spacecraft_state, environment, session),
                   do: generation(input, environment, session)
            else
              generation(input, environment, session)
            end

          {:error, :environment_outside_coverage} ->
            {:unknown, :solar_environment_outside_coverage}

          {:error, {:outside_coverage, _}} ->
            {:unknown, :solar_environment_outside_coverage}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp generation(input, environment, s) do
    r = input.spacecraft_state.position_km
    sun = environment.sun_direction
    axial = V.dot(r, sun)
    perpendicular = V.norm(V.subtract(r, V.scale(sun, axial)))
    radius = s.scene.body.equatorial_radius_km

    {fraction, regime, sun} =
      if s.shadow_model == "finite_sun" do
        {:ok, g, sun} = finite_geometry(input.spacecraft_state, environment, s)
        {g.metadata["visible_fraction"], g.metadata["regime"], sun}
      else
        lit = not (axial < 0 and perpendicular < radius)
        {if(lit, do: 1.0, else: 0.0), if(lit, do: "none", else: "umbra"), sun}
      end

    sunlit = fraction > 0

    panels =
      Enum.map(s.panels, fn p ->
        normal = Q.rotate(input.pointing.quaternion, p.normal)
        cosine = max(-1.0, min(1.0, V.dot(normal, sun)))
        incident = s.irradiance * p.area * max(0.0, cosine)
        power = fraction * incident * p.efficiency * s.bus_efficiency

        %{
          "id" => p.id,
          "normal_inertial" => Tuple.to_list(normal),
          "incidence_cosine" => cosine,
          "unshadowed_incident_w" => incident,
          "generation_w" => power
        }
      end)

    watts = Enum.sum(Enum.map(panels, & &1["generation_w"]))
    Input.number!(watts, "solar bus generation", 0, 1.0e12)

    {:ok, watts,
     %{
       "model" => "body_fixed_solar_array_v1",
       "spacecraft_sunlit" => sunlit,
       "visible_fraction" => fraction,
       "occultation_regime" => regime,
       "shadow_model" => s.shadow_model,
       "shadow_margin_km" => max(axial, perpendicular - radius),
       "sun_direction_inertial" => Tuple.to_list(sun),
       "panels" => panels
     }}
  end

  @doc false
  def search_boundaries(%{shadow_model: "finite_sun", scene: scene} = session, source)
      when scene != nil do
    alias OrbitalDynamics.EventSearch.Function

    functions =
      for {kind, field} <- [{"outer", :outer}, {"umbra", :umbra}, {"antumbra", :antumbra}] do
        Function.new!(
          "solar." <> kind,
          fn state ->
            with {:ok, env} <- contact_environment(scene, state),
                 {:ok, g, _} <- finite_geometry(state, env, session) do
              # Environment direction need not supply a derivative. Do not use
              # apparent-rate estimates based on an invented solar velocity.
              {:ok, Map.fetch!(g, field), nil, g.metadata}
            end
          end,
          units: "1",
          value_tolerance: 1.0e-12
        )
      end

    c = session.search

    controls = [
      starts_at: source.start,
      ends_at: source.stop,
      max_check_step_s: c["max_check_step_s"],
      time_tolerance_s: c["time_tolerance_s"],
      max_iterations: c["max_iterations"],
      max_evaluations: c["max_evaluations"]
    ]

    case OrbitalDynamics.EventSearch.run(source, functions, controls) do
      {:ok, %{"status" => "complete_under_search_policy"} = report} ->
        points =
          for r <- report["results"],
              e <- r["events"],
              key <- ["bracket_start_s", "epoch_s", "bracket_end_s"],
              do: e[key]

        {:ok, Enum.uniq(points), report}

      {:ok, report} ->
        {:unknown, report}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_boundaries(%{shadow_model: "finite_sun"}, _),
    do: {:unknown, "solar_environment_missing"}

  def search_boundaries(_, _), do: {:ok, [], :null}

  defp contact_environment(scene, state) do
    case SphericalScene.environment_at(scene, state) do
      {:error, :environment_outside_coverage} -> {:unknown, :solar_environment_outside_coverage}
      {:error, {:outside_coverage, _}} -> {:unknown, :solar_environment_outside_coverage}
      result -> result
    end
  end

  defp finite_geometry(state, environment, session) do
    sun_position = V.scale(environment.sun_direction, session.solar_distance)
    sun = %{state | position_km: sun_position, velocity_km_s: {0, 0, 0}}
    body = %{state | position_km: {0, 0, 0}, velocity_km_s: {0, 0, 0}}

    with {:ok, geometry} <-
           OrbitalDynamics.EventDetectors.Occultations.geometry_states(
             state,
             sun,
             session.solar_radius,
             body,
             session.scene.body.equatorial_radius_km
           ) do
      ray = V.subtract(sun_position, state.position_km)
      {:ok, geometry, V.scale(ray, 1 / V.norm(ray))}
    end
  end

  defp outside_coverage?(input, {a, b}) do
    Map.get(input, :interval_start_s, input.epoch_s) < a or
      Map.get(input, :interval_end_s, input.epoch_s) > b
  end

  defp integer!(value, label, low, high) do
    unless is_integer(value) and value >= low and value <= high,
      do: raise(ArgumentError, "#{label} must be an integer in range")

    value
  end

  defp nullable!(:null, _, _, _), do: :null
  defp nullable!(v, label, low, high), do: Input.number!(v, label, low, high)
end
