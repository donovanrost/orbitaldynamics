defmodule OrbitalDynamics.MissionAnalysis.Attitude.Reference do
  @moduledoc "Earth/J2000/UTC convenience adapter for configurable attitude planning examples."
  alias OrbitalDynamics.{Epoch, Frame}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{ReferenceResolution, Input}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Policy
  alias OrbitalDynamics.MissionAnalysis.Models.{SurfaceSupport, Illumination, Imaging}

  def run!(mission, study) do
    SurfaceSupport.fields!(
      study,
      ~w(study_id mission_manifest resolution_level refinement attitude) ++
        if(Map.has_key?(study, "path_constraints"), do: ["path_constraints"], else: []),
      "attitude study"
    )

    Input.id!(study["study_id"])

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
          ~w(max_rate_deg_s max_accel_deg_s2 settling_s initial pointing_configurations),
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

        {id,
         %{
           max_rate_deg_s: a["max_rate_deg_s"],
           max_accel_deg_s2: a["max_accel_deg_s2"],
           settling_s: a["settling_s"],
           initial: initial,
           pointing_configurations: configs
         }}
      end)

    policy =
      Policy.new!(assets,
        profile_step_s: config["profile_step_s"],
        derivative_step_s: config["derivative_step_s"],
        search_step_s: config["search_step_s"],
        max_candidate_starts: config["max_candidate_starts"],
        max_evaluations: config["max_evaluations"],
        path_constraints:
          if(Map.has_key?(study, "path_constraints"),
            do: OrbitalDynamics.MissionAnalysis.Path.Reference.policy!(study["path_constraints"]),
            else: nil
          )
      )

    case MissionAnalysis.run(
           p.assets,
           p.requests,
           p.context,
           Keyword.put(p.options, :attitude, policy)
         ) do
      {:ok, report} ->
        Map.merge(report, %{
          "attitude_study_configuration" => study,
          "baseline_configuration" => mission
        })

      {:error, reason} ->
        raise ArgumentError, "attitude analysis failed: #{inspect(reason)}"
    end
  end

  defp model!("illumination"), do: Illumination
  defp model!("imaging"), do: Imaging

  defp model!(other),
    do: raise(ArgumentError, "unsupported reference pointing model: #{inspect(other)}")
end
