defmodule OrbitalDynamics.MissionAnalysis.ReferenceMission do
  @moduledoc """
  Runnable Earth circular-SSO examples built on the generic MissionAnalysis API.

  This convenience adapter deliberately accepts named surface models and fixed-attitude tasks
  and the checked-in finite Earth environment. Other bodies, trajectories, and
  models use the core API directly. It is not a flight mission definition format.
  """
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, OrbitElements, Scenario, Spacecraft, Target}
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider, as: Provider
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Input, OrbitDesign, Request, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Environments.Campaign
  alias OrbitalDynamics.MissionAnalysis.Models.{Illumination, Imaging, SurfaceSupport}
  alias OrbitalDynamics.Propagators.J2

  def load!(path) do
    bytes = File.read!(path)
    if byte_size(bytes) > 1_000_000, do: raise(ArgumentError, "manifest exceeds 1 MB")

    decoders = %{
      object_start: fn _ -> %{} end,
      object_push: fn key, value, object ->
        if Map.has_key?(object, key), do: raise(ArgumentError, "duplicate JSON key: #{key}")
        Map.put(object, key, value)
      end,
      object_finish: fn object, old -> {object, old} end
    }

    case :json.decode(bytes, :root, decoders) do
      {%{} = config, :root, <<>>} -> config
      _ -> raise ArgumentError, "expected one JSON object"
    end
  end

  def run!(config) do
    prepared = prepare!(config)

    case MissionAnalysis.run(
           prepared.assets,
           prepared.requests,
           prepared.context,
           prepared.options
         ) do
      {:ok, report} -> Map.put(report, "reference_mission", prepared.metadata)
      {:error, reason} -> raise ArgumentError, "mission analysis failed: #{inspect(reason)}"
    end
  end

  @doc "Builds explicit core inputs, also available to independent baseline comparisons."
  def prepare!(config) do
    fields!(
      config,
      ~w(mission_id epoch_s duration_s sample_step_s max_step_s solar_year_s max_sample_gap_s asset_separation_s assets requests)
    )

    id = Input.id!(config["mission_id"])
    duration = Input.number!(config["duration_s"], "duration_s", 1, 86_400)
    step = Input.number!(config["sample_step_s"], "sample_step_s", 1, duration)
    max_step = Input.number!(config["max_step_s"], "max_step_s", 0.1, step)
    if duration / step > 9999, do: raise(ArgumentError, "too many trajectory samples")
    bounded_list!(config["assets"], 100, "assets")
    bounded_list!(config["requests"], 100, "requests", 0)
    epoch = Epoch.new!(Input.number!(config["epoch_s"], "epoch_s", -1.0e12, 1.0e12), :utc)
    body = CentralBody.earth()
    frame = Frame.earth_inertial_j2000()
    {:ok, dataset} = Provider.load(Provider.checked_in_options())
    {:ok, environment} = Campaign.at(epoch, dataset)
    # Check the full propagation interval, not just each eventual opportunity.
    {:ok, _} = Campaign.at(Epoch.shift(epoch, duration), dataset)
    scene = SphericalScene.new!(body, frame, :utc, {Campaign, dataset})

    pairs =
      Enum.map(config["assets"], fn spec ->
        fields!(
          spec,
          ~w(id altitude_km local_time_ascending_node_h initial_argument_of_latitude_deg dry_mass_kg payloads resource_budgets)
        )

        altitude = Input.number!(spec["altitude_km"], "altitude_km", 150, 2000)

        inclination =
          OrbitDesign.sun_synchronous_inclination_deg!(body, altitude, config["solar_year_s"])

        raan =
          OrbitDesign.raan_deg!(environment.sun_direction, spec["local_time_ascending_node_h"])

        phase =
          Input.number!(
            spec["initial_argument_of_latitude_deg"],
            "initial_argument_of_latitude_deg",
            0,
            360
          )

        state =
          OrbitElements.to_state!(
            %{
              semi_major_axis_km: body.equatorial_radius_km + altitude,
              eccentricity: 0.0,
              inclination_deg: inclination,
              raan_deg: raan,
              argument_of_latitude_deg: phase
            },
            body,
            epoch: epoch,
            frame: frame
          )

        spacecraft =
          Spacecraft.new!(spec["id"], Input.positive!(spec["dry_mass_kg"], "dry_mass_kg"))

        scenario =
          Scenario.new!(spec["id"], spacecraft, state,
            duration_s: duration,
            output_step_s: step,
            central_body: body
          )

        {:ok, trajectory} = J2.propagate(scenario, max_step_s: max_step)

        unless is_map(spec["payloads"]) and map_size(spec["payloads"]) > 0,
          do: raise(ArgumentError, "payloads must be a nonempty object")

        capabilities =
          Map.new(spec["payloads"], fn {name, payload} -> {model!(name), payload} end)

        asset = Asset.new!(spec["id"], trajectory, capabilities, spec["resource_budgets"])
        {asset, %{"asset_id" => asset.id, "inclination_deg" => inclination, "raan_deg" => raan}}
      end)

    requests = Enum.map(config["requests"], &request!/1)

    %{
      assets: Enum.map(pairs, &elem(&1, 0)),
      requests: requests,
      context: scene,
      options: [
        max_sample_gap_s: config["max_sample_gap_s"],
        asset_separation_s: config["asset_separation_s"]
      ],
      metadata: %{
        "mission_id" => id,
        "configuration" => config,
        "orbit_estimates" => Enum.map(pairs, &elem(&1, 1)),
        "limits" => [
          "Earth circular orbit reference adapter, not company spacecraft specifications",
          "first-order mean J2 sun-synchronous inclination initialized as osculating elements; no exact repeat guarantee",
          "ascending-node local solar time estimated from initial Sun right ascension; not a mean-Sun ephemeris",
          "J2-only propagation; no drag, maneuvers, orbit determination uncertainty, or station keeping"
        ]
      }
    }
  end

  @doc "Parse one trusted reference request, also used to preserve original sessions for activity segments."
  def request!(spec) do
    fields!(
      spec,
      ~w(id model activity_type target starts_at_s ends_at_s duration_s value parameters resource_costs)
    )

    subject =
      if spec["model"] == "fixed_attitude" do
        unless spec["target"] == :null,
          do: raise(ArgumentError, "fixed attitude requires null target")

        nil
      else
        target = spec["target"]
        fields!(target, ~w(id latitude_deg longitude_deg altitude_km minimum_elevation_deg))

        Target.new!(target["id"], target["latitude_deg"], target["longitude_deg"],
          altitude_km: target["altitude_km"],
          minimum_elevation_deg: target["minimum_elevation_deg"]
        )
      end

    Request.new!(spec["id"], model!(spec["model"]), subject,
      activity_type: spec["activity_type"],
      starts_at_s: spec["starts_at_s"],
      ends_at_s: spec["ends_at_s"],
      duration_s: spec["duration_s"],
      time_scale: :utc,
      value: spec["value"],
      parameters: spec["parameters"],
      resource_costs: spec["resource_costs"]
    )
  end

  defp model!("illumination"), do: Illumination
  defp model!("imaging"), do: Imaging
  defp model!("fixed_attitude"), do: OrbitalDynamics.MissionAnalysis.Models.FixedAttitude
  defp model!(other), do: raise(ArgumentError, "unsupported reference model: #{inspect(other)}")
  defp fields!(map, keys), do: SurfaceSupport.fields!(map, keys, "reference configuration")

  defp bounded_list!(list, limit, name, minimum \\ 1) do
    unless is_list(list) and length(list) in minimum..limit,
      do: raise(ArgumentError, "#{name} must contain #{minimum}..#{limit} entries")
  end
end
