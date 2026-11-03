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
        Enum.filter(
          ~w(path_constraints horizon resources opportunity_search),
          &Map.has_key?(study, &1)
        ),
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

    case MissionAnalysis.run(
           p.assets,
           p.requests,
           p.context,
           p.options |> Keyword.put(:attitude, policy) |> opportunity_options(study)
         ) do
      {:ok, report} ->
        Map.merge(report, %{
          "attitude_study_configuration" => study,
          "baseline_configuration" => mission
        })
        |> OrbitalDynamics.MissionAnalysis.Resource.SolarDiagnostics.annotate()

      {:error, reason} ->
        raise ArgumentError, "attitude analysis failed: #{inspect(reason)}"
    end
  end

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
              SurfaceSupport.fields!(t, ~w(strategy frame quaternion_wxyz mode), "terminal")

              unless t["strategy"] == "fixed_inertial" and t["frame"] == "eci_j2000",
                do:
                  raise(ArgumentError, "reference terminal requires fixed_inertial in eci_j2000")

              %{
                frame: Frame.earth_inertial_j2000(),
                quaternion: t["quaternion_wxyz"],
                mode: if(t["mode"] == :null, do: :unknown, else: t["mode"])
              }
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

  defp model!(other),
    do: raise(ArgumentError, "unsupported reference pointing model: #{inspect(other)}")
end
