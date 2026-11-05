defmodule OrbitalDynamics.MissionAnalysis.Attitude.Reference do
  @moduledoc "Earth/J2000/UTC convenience adapter for configurable attitude planning examples."
  alias OrbitalDynamics.{Epoch, Frame}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{ReferenceResolution, Input}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Policy
  alias OrbitalDynamics.MissionAnalysis.Models.{SurfaceSupport, Illumination, Imaging}

  def run!(mission, study, opts \\ []), do: elem(run_profiled!(mission, study, opts), 0)

  @doc "Returns {report, timings}; timings are observations and never embedded in planning evidence."
  def run_profiled!(mission, study, opts \\ []) do
    case run_profiled(mission, study, opts) do
      {:ok, report, timings} -> {report, timings}
      {:error, reason} -> raise ArgumentError, "attitude analysis failed: #{inspect(reason)}"
    end
  end

  @doc "Typed planner failures for review workflows; malformed reference inputs still raise."
  def run_profiled(mission, study, opts \\ []) do
    unless Keyword.keyword?(opts) and Keyword.keys(opts) -- [:service_unavailable_asset_ids] == [] and
             length(Keyword.keys(opts)) == length(Enum.uniq(Keyword.keys(opts))),
           do: raise(ArgumentError, "invalid reference planner options")

    unavailable = Keyword.get(opts, :service_unavailable_asset_ids, [])

    unless is_list(unavailable) and length(unavailable) <= 20 and
             Enum.all?(unavailable, &(&1 in Enum.map(mission["assets"], fn a -> a["id"] end))) and
             length(Enum.uniq(unavailable)) == length(unavailable),
           do: raise(ArgumentError, "service unavailability must name unique known asset IDs")

    unavailable = Enum.sort(unavailable)
    started = System.monotonic_time()

    SurfaceSupport.fields!(
      study,
      ~w(study_id mission_manifest resolution_level refinement attitude) ++
        Enum.filter(
          ~w(path_constraints horizon resources opportunity_search scheduling state_quality_policy continuations rolling_horizon saved_motion),
          &Map.has_key?(study, &1)
        ),
      "attitude study"
    )

    Input.id!(study["study_id"])

    OrbitalDynamics.MissionAnalysis.PlanRevision.StateQuality.validate_policy!(
      study["state_quality_policy"],
      mission,
      study
    )

    SurfaceSupport.fields!(
      study["resolution_level"],
      ~w(sample_step_s max_step_s),
      "attitude resolution"
    )

    SurfaceSupport.fields!(
      study["refinement"],
      ~w(tracking_lookback_s time_tolerance_s max_extra_evaluations),
      "refinement"
    )

    r = study["refinement"]

    {:ok, p} =
      ReferenceResolution.prepare(mission, study["resolution_level"],
        tracking_lookback_s: r["tracking_lookback_s"],
        time_tolerance_s: r["time_tolerance_s"],
        max_extra_evaluations: r["max_extra_evaluations"]
      )

    coverage =
      OrbitalDynamics.MissionAnalysis.PlanRevision.HorizonExtension.capture(mission, study, p)

    {requests, joins} =
      OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.attach!(
        mission,
        study,
        p.requests
      )

    p = %{p | requests: requests}

    available_assets =
      Enum.map(p.assets, fn asset ->
        if asset.id in unavailable, do: %{asset | capabilities: %{}}, else: asset
      end)

    config = study["attitude"]

    SurfaceSupport.fields!(
      config,
      ~w(assets profile_step_s derivative_step_s search_step_s max_candidate_starts max_evaluations),
      "attitude options"
    )

    assets =
      Map.new(config["assets"], fn {id, a} ->
        SurfaceSupport.fields!(
          a,
          ~w(max_rate_deg_s max_accel_deg_s2 settling_s initial pointing_configurations) ++
            if(Map.has_key?(a, "rigid_body"), do: ["rigid_body"], else: []),
          "asset attitude"
        )

        initial =
          case a["initial"] do
            :null ->
              :unknown

            i ->
              SurfaceSupport.fields!(
                i,
                ~w(epoch_s time_scale frame quaternion_wxyz angular_velocity_inertial_deg_s),
                "initial attitude"
              )

              unless i["time_scale"] == "utc" and i["frame"] == "eci_j2000",
                do:
                  raise(
                    ArgumentError,
                    "reference attitude requires explicit Earth/J2000/UTC initial state"
                  )

              %{
                epoch: Epoch.new!(i["epoch_s"], :utc),
                frame: Frame.earth_inertial_j2000(),
                quaternion: i["quaternion_wxyz"],
                angular_velocity_deg_s: i["angular_velocity_inertial_deg_s"]
              }
          end

        configs = Map.new(a["pointing_configurations"], fn {name, c} -> {model!(name), c} end)

        value = %{
          max_rate_deg_s: a["max_rate_deg_s"],
          max_accel_deg_s2: a["max_accel_deg_s2"],
          settling_s: a["settling_s"],
          initial: initial,
          pointing_configurations: configs
        }

        value =
          if get_in(study, ["saved_motion", "assets", id]),
            do: Map.put(value, :saved_motion, get_in(study, ["saved_motion", "assets", id])),
            else: value

        value = if joins[id], do: Map.put(value, :continuation_request_id, joins[id]), else: value

        value =
          if Map.has_key?(a, "rigid_body") do
            c = a["rigid_body"]

            unless is_map(c),
              do: raise(ArgumentError, "rigid body must be an explicit configuration object")

            SurfaceSupport.fields!(
              c,
              ~w(frame principal_moments_kg_m2 max_body_torque_nm),
              "rigid body"
            )

            unless c["frame"] == "body_principal_axes",
              do: raise(ArgumentError, "rigid body frame must explicitly be body_principal_axes")

            Map.put(value, :rigid_body, %{
              frame: :body_principal_axes,
              principal_moments_kg_m2: c["principal_moments_kg_m2"],
              max_body_torque_nm: c["max_body_torque_nm"]
            })
          else
            value
          end

        {id, value}
      end)

    policy =
      Policy.new!(assets,
        profile_step_s: config["profile_step_s"],
        derivative_step_s: config["derivative_step_s"],
        search_step_s: config["search_step_s"],
        max_candidate_starts: config["max_candidate_starts"],
        max_evaluations: config["max_evaluations"],
        resources:
          if(Map.has_key?(study, "resources"),
            do: OrbitalDynamics.MissionAnalysis.Resource.Reference.policy!(study["resources"]),
            else: nil
          ),
        horizon: horizon!(study["horizon"]),
        path_constraints:
          if(Map.has_key?(study, "path_constraints"),
            do: OrbitalDynamics.MissionAnalysis.Path.Reference.policy!(study["path_constraints"]),
            else: nil
          )
      )

    preparation_ms =
      System.convert_time_unit(System.monotonic_time() - started, :native, :microsecond) / 1000

    case MissionAnalysis.run_profiled(
           available_assets,
           p.requests,
           p.context,
           p.options
           |> Keyword.put(:attitude, policy)
           |> opportunity_options(study)
           |> scheduling_options(study)
         ) do
      {:ok, report, timings} ->
        report =
          Map.merge(report, %{
            "attitude_study_configuration" => study,
            "baseline_configuration" => mission
          })
          |> OrbitalDynamics.MissionAnalysis.Resource.SolarDiagnostics.annotate()

        report = if coverage, do: Map.put(report, "trajectory_coverage", coverage), else: report

        report =
          if unavailable == [],
            do: report,
            else:
              Map.put(report, "service_unavailability", %{
                "asset_ids" => unavailable,
                "scope" => "all_service_opportunities_in_this_analysis",
                "assumption" =>
                  "trajectory, attitude, idle/terminal paths and resources remain modeled"
              })

        {:ok, report, Map.put(timings, "preparation_ms", preparation_ms)}

      {:error, _} = error ->
        error
    end
  end

  defp scheduling_options(options, %{"scheduling" => config}),
    do:
      Keyword.put(
        options,
        :scheduling,
        OrbitalDynamics.MissionAnalysis.Scheduling.Reference.policy!(config)
      )

  defp scheduling_options(options, _), do: options

  defp opportunity_options(options, %{"opportunity_search" => config}) do
    keys =
      ~w(max_check_step_s time_tolerance_s max_iterations max_evaluations entry_margin_s exit_margin_s)a

    SurfaceSupport.fields!(config, Enum.map(keys, &Atom.to_string/1), "opportunity search")

    policy =
      OrbitalDynamics.MissionAnalysis.Opportunity.Policy.new!(
        Enum.map(keys, fn key -> {key, Map.fetch!(config, Atom.to_string(key))} end)
      )

    Keyword.put(options, :opportunity_search, policy)
  end

  defp opportunity_options(options, _), do: options

  defp horizon!(nil), do: nil

  defp horizon!(h) do
    SurfaceSupport.fields!(h, ~w(starts_at_s ends_at_s time_scale terminals), "horizon")
    unless h["time_scale"] == "utc", do: raise(ArgumentError, "reference horizon requires UTC")

    terminals =
      Map.new(h["terminals"], fn {id, t} ->
        value =
          case t do
            :null ->
              :unknown

            _ ->
              SurfaceSupport.fields!(
                t,
                ~w(strategy frame quaternion_wxyz mode) ++
                  if(t["strategy"] in ["activity_boundary", "execution_boundary"],
                    do: ["angular_velocity_inertial_deg_s"],
                    else: []
                  ),
                "terminal"
              )

              unless t["strategy"] in [
                       "fixed_inertial",
                       "activity_boundary",
                       "execution_boundary"
                     ] and
                       t["frame"] == "eci_j2000",
                     do:
                       raise(
                         ArgumentError,
                         "reference terminal requires fixed_inertial in eci_j2000"
                       )

              value = %{
                frame: Frame.earth_inertial_j2000(),
                quaternion: t["quaternion_wxyz"],
                mode: if(t["mode"] == :null, do: :unknown, else: t["mode"])
              }

              if t["strategy"] in ["activity_boundary", "execution_boundary"],
                do:
                  Map.merge(value, %{
                    boundary: true,
                    angular_velocity_deg_s: t["angular_velocity_inertial_deg_s"]
                  }),
                else: value
          end

        {id, value}
      end)

    %{
      start: Epoch.new!(h["starts_at_s"], :utc),
      stop: Epoch.new!(h["ends_at_s"], :utc),
      terminals: terminals
    }
  end

  defp model!("illumination"), do: Illumination
  defp model!("imaging"), do: Imaging
  defp model!("fixed_attitude"), do: OrbitalDynamics.MissionAnalysis.Models.FixedAttitude

  defp model!(other),
    do: raise(ArgumentError, "unsupported reference pointing model: #{inspect(other)}")
end
