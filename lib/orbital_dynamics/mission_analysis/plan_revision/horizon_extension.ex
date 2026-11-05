defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.HorizonExtension do
  @moduledoc "Explicit finite Earth/J2 coverage extension; saved checkpoints check overlap, not continuous accuracy."
  alias OrbitalDynamics.MissionAnalysis.{Input, ReferenceResolution}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Snapshot, Reference}
  alias OrbitalDynamics.MissionAnalysis.Environments.Campaign
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider, as: Provider
  alias OrbitalDynamics.Epoch

  def recipe(m, s) do
    %{
      "epoch_s" => m["epoch_s"],
      "solar_year_s" => m["solar_year_s"],
      "resolution_level" => s["resolution_level"],
      "assets" =>
        Enum.map(
          m["assets"],
          &Map.take(
            &1,
            ~w(id altitude_km local_time_ascending_node_h initial_argument_of_latitude_deg dry_mass_kg)
          )
        )
    }
  end

  def capture(m, s, p) do
    case s["rolling_horizon"] do
      nil ->
        nil

      policy ->
        S.fields!(policy, ~w(provider sample_step_s max_samples_per_asset), "rolling horizon")

        unless policy["provider"] == "reference_j2",
          do: raise(ArgumentError, "unsupported trajectory extension provider")

        step = Input.positive!(policy["sample_step_s"], "coverage sample step")
        limit = policy["max_samples_per_asset"]

        unless is_integer(limit) and limit in 2..512,
          do: raise(ArgumentError, "coverage sample bound must be 2..512")

        n = round(m["duration_s"] / step)

        unless n >= 1 and n + 1 <= limit and abs(n * step - m["duration_s"]) <= 1.0e-8,
          do:
            raise(
              ArgumentError,
              "coverage end must align with the bounded coverage checkpoint grid"
            )

        h = s["horizon"]
        guard_s = 2 * s["attitude"]["derivative_step_s"]

        unless h["starts_at_s"] >= m["epoch_s"] and
                 h["ends_at_s"] + guard_s <= m["epoch_s"] + m["duration_s"],
               do:
                 raise(
                   ArgumentError,
                   "trajectory coverage must include the horizon and derivative lookahead"
                 )

        sampler = Keyword.fetch!(p.options, :window_refinement).state_at
        times = Enum.map(0..n, &(m["epoch_s"] + &1 * step))
        {:ok, dataset} = Provider.load(Provider.checked_in_options())

        environment =
          Enum.map(times, fn t ->
            {:ok, e} = Campaign.at(Epoch.new!(t, :utc), dataset)

            %{
              "epoch_s" => t,
              "sun_direction" => e.sun_direction,
              "rotation_angle_rad" => e.rotation_angle_rad
            }
          end)

        assets =
          Map.new(p.assets, fn a ->
            rows =
              Enum.map(times, fn t ->
                {:ok, state} = sampler.(a, t)

                unless state.frame == OrbitalDynamics.Frame.earth_inertial_j2000() and
                         state.epoch.scale == :utc,
                       do: raise(ArgumentError, "trajectory checkpoint frame/scale mismatch")

                %{
                  "epoch_s" => t,
                  "position_km" => Tuple.to_list(state.position_km),
                  "velocity_km_s" => Tuple.to_list(state.velocity_km_s)
                }
              end)

            {a.id, rows}
          end)

        %{
          "provider" => "reference_j2",
          "frame" => "eci_j2000",
          "time_scale" => "utc",
          "starts_at_s" => m["epoch_s"],
          "ends_at_s" => m["epoch_s"] + m["duration_s"],
          "recipe_sha256" => Snapshot.digest(recipe(m, s)),
          "environment_identity" =>
            OrbitalDynamics.Schema.JsonSafety.normalize_input!(
              Campaign.describe(dataset),
              "coverage environment identity"
            ),
          "environment_samples" => environment,
          "assets" => assets,
          "sample_step_s" => step,
          "scope" => "finite_saved_checkpoints_not_continuous_validation"
        }
    end
  end

  def apply(inputs, _parent, nil), do: {:ok, inputs, nil}

  def apply(inputs, parent, extension) do
    try do
      S.fields!(
        extension,
        ~w(provider ends_at_s coverage_ends_at_s add_requests),
        "horizon extension"
      )

      old = parent["payload"]["inputs"]
      policy = old["study"]["rolling_horizon"]

      unless is_map(policy) and extension["provider"] == policy["provider"],
        do: raise(ArgumentError, "extension requires the saved explicit provider policy")

      stop =
        Input.number!(
          extension["ends_at_s"],
          "extended horizon end",
          old["study"]["horizon"]["ends_at_s"],
          1.0e12
        )

      coverage =
        Input.number!(
          extension["coverage_ends_at_s"],
          "extended trajectory end",
          old["mission"]["epoch_s"] + old["mission"]["duration_s"],
          1.0e12
        )

      unless stop > old["study"]["horizon"]["ends_at_s"],
        do: raise(ArgumentError, "extension must increase the horizon end")

      change = %{
        "revision_id" => "horizon_extension",
        "protect_request_ids" => [],
        "unavailable_asset_ids" => inputs["service_unavailable_asset_ids"],
        "add_requests" => extension["add_requests"],
        "scheduling" =>
          Map.take(
            inputs["study"]["scheduling"],
            ~w(strategy max_trials work_budget availability)
          )
      }

      Reference.validate_change!(change, inputs, parent["snapshot_id"])
      protected = get_in(inputs, ["study", "scheduling", "protected_activities"]) || []
      {mission, study} = Reference.updated_inputs(inputs, change, protected)
      mission = Map.put(mission, "duration_s", coverage - mission["epoch_s"])
      study = put_in(study, ["horizon", "ends_at_s"], stop)
      r = study["refinement"]

      {:ok, p} =
        ReferenceResolution.prepare(mission, study["resolution_level"],
          tracking_lookback_s: r["tracking_lookback_s"],
          time_tolerance_s: r["time_tolerance_s"],
          max_extra_evaluations: r["max_extra_evaluations"]
        )

      evidence = capture(mission, study, p)
      prior = parent["payload"]["report"]["trajectory_coverage"]

      unless overlap?(prior, evidence),
        do:
          raise(
            ArgumentError,
            "new trajectory/environment predictions disagree with saved overlap checkpoints"
          )

      {:ok, Map.merge(inputs, %{"mission" => mission, "study" => study}),
       %{
         "status" => "supported",
         "previous_coverage_ends_at_s" => prior["ends_at_s"],
         "coverage_ends_at_s" => coverage,
         "checked_epochs_per_asset" => length(hd(Map.values(prior["assets"]))),
         "position_tolerance_km" => 1.0e-8,
         "velocity_tolerance_km_s" => 1.0e-11,
         "scope" => "finite_saved_overlap_checkpoints"
       }}
    rescue
      e in [ArgumentError, MatchError, KeyError, BadMapError, FunctionClauseError] ->
        {:error, Exception.message(e)}
    end
  end

  defp overlap?(a, b) when is_map(a) and is_map(b) do
    Map.take(
      a,
      ~w(provider frame time_scale recipe_sha256 environment_identity sample_step_s starts_at_s)
    ) ==
      Map.take(
        b,
        ~w(provider frame time_scale recipe_sha256 environment_identity sample_step_s starts_at_s)
      ) and
      Enum.sort(Map.keys(a["assets"])) == Enum.sort(Map.keys(b["assets"])) and
      a["ends_at_s"] <= b["ends_at_s"] and
      Enum.take(b["environment_samples"], length(a["environment_samples"])) ==
        a["environment_samples"] and
      Enum.all?(a["assets"], fn {id, rows} ->
        Enum.zip(rows, Enum.take(b["assets"][id], length(rows)))
        |> Enum.all?(fn {x, y} ->
          x["epoch_s"] == y["epoch_s"] and
            near_vector?(x["position_km"], y["position_km"], 1.0e-8) and
            near_vector?(x["velocity_km_s"], y["velocity_km_s"], 1.0e-11)
        end)
      end)
  end

  defp overlap?(_, _), do: false

  defp near_vector?(a, b, tol),
    do:
      length(a) == 3 and length(b) == 3 and
        Enum.zip_with(a, b, &(abs(&1 - &2) <= tol)) |> Enum.all?()
end
