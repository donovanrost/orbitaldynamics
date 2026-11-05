defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Prediction do
  @moduledoc "Synthetic state updates from saved baseline motion and exact battery samples; not telemetry."
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Snapshot, Reference}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Motion

  def update!(snapshot, t) do
    Snapshot.verify!(snapshot)
    source = Reference.source!(snapshot)
    report = snapshot["payload"]["report"]
    h = source["study"]["horizon"]

    unless is_number(t) and t > h["starts_at_s"] and t < h["ends_at_s"],
      do: raise(ArgumentError, "prediction time must advance within the horizon")

    {assets, ended, running} = state_data!(source, report, t)

    update = %{
      "revision_id" => "predicted_advance",
      "expected_baseline_id" => snapshot["snapshot_id"],
      "motion_source_snapshot_id" => snapshot["snapshot_id"],
      "source_id" => "synthetic_baseline_prediction",
      "as_of_s" => t,
      "time_scale" => "utc",
      "frame" => "eci_j2000",
      "assets" => assets,
      "completed_request_ids" => Enum.map(ended, & &1["request_id"]),
      "not_executed_request_ids" => [],
      "protect_request_ids" => [],
      "scheduling" => %{"strategy" => "greedy", "max_trials" => 1}
    }

    receipts =
      OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery.synthetic_receipts(
        source,
        report,
        t,
        "synthetic_prediction"
      )

    update = if receipts, do: Map.put(update, "command_receipts", receipts), else: update

    if running == [],
      do: update,
      else: Map.put(update, "in_progress_request_ids", Enum.map(running, & &1["request_id"]))
  end

  @doc "State at an exact supported sample, including the terminal boundary, for synthetic execution replay."
  def state_at!(snapshot, t) do
    Snapshot.verify!(snapshot)
    source = Reference.source!(snapshot)
    h = source["study"]["horizon"]

    unless is_number(t) and t >= h["starts_at_s"] and t <= h["ends_at_s"],
      do: raise(ArgumentError, "state sample must lie inside the saved horizon")

    {assets, _ended, _running} = state_data!(source, snapshot["payload"]["report"], t)
    assets
  end

  defp state_data!(source, report, t) do
    running = OrbitalDynamics.MissionAnalysis.PlanRevision.Continuation.active(report, t)

    ended = Enum.filter(report["activities"], &(&1["ends_at_s"] <= t))

    assets =
      Map.new(source["mission"]["assets"], fn asset ->
        id = asset["id"]
        pose = pose!(report, id, t)

        models = get_in(source, ["study", "resources", "assets", id]) || []

        batteries =
          Map.new(Enum.filter(models, &(&1["model"] == "battery")), fn model ->
            {model["id"], sample_state!(report, id, model, t)["energy_wh"]}
          end)

        wheels =
          Map.new(Enum.filter(models, &(&1["model"] == "reaction_wheels")), fn model ->
            {model["id"],
             sample_state!(report, id, model, t)
             |> OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels.vector()
             |> Tuple.to_list()}
          end)

        thermals =
          Map.new(Enum.filter(models, &(&1["model"] == "thermal")), fn model ->
            {model["id"], sample_state!(report, id, model, t)["temperature_k"]}
          end)

        budgets =
          Enum.reduce(
            Enum.filter(ended ++ running, &(&1["asset_id"] == id)),
            asset["resource_budgets"],
            fn a, b ->
              Enum.reduce(a["resource_costs"], b, fn {key, cost}, b ->
                if(Map.has_key?(b, key), do: Map.update!(b, key, &(&1 - cost)), else: b)
              end)
            end
          )

        value =
          Map.merge(pose, %{"battery_energy_wh" => batteries, "resource_budgets" => budgets})

        value =
          if(map_size(wheels) > 0, do: Map.put(value, "wheel_momentum_nms", wheels), else: value)

        value =
          if thermals == %{}, do: value, else: Map.put(value, "thermal_temperature_k", thermals)

        quality =
          OrbitalDynamics.MissionAnalysis.PlanRevision.StateQuality.stamp(
            source,
            id,
            t,
            "synthetic_prediction",
            "synthetic_baseline_prediction"
          )

        {id, if(quality, do: Map.put(value, "quality", quality), else: value)}
      end)

    {assets, ended, running}
  end

  defp sample_state!(report, id, model, t) do
    evidence = get_in(report, ["attitude_planning", "resource_feasibility", "assets", id])
    m = Enum.find(evidence["models"], &(&1["id"] == model["id"]))
    level = Enum.min_by(m["levels"], & &1["sample_step_s"])
    sample = Enum.find(level["samples"] || [], &(&1["epoch_s"] == t))

    unless evidence["status"] == "supported" and level["status"] == "supported" and sample,
      do:
        raise(
          ArgumentError,
          "prediction requires an exact supported resource-state sample at the update epoch"
        )

    sample["state"]
  end

  defp pose!(report, id, t) do
    endpoint =
      for a <- report["activities"],
          a["asset_id"] == id,
          p <- a["attitude_profile"],
          p["epoch_s"] == t,
          do: p

    case endpoint do
      [p | _] ->
        Map.take(p, ~w(quaternion_wxyz angular_velocity_inertial_deg_s))

      [] ->
        if Enum.any?(
             report["activities"],
             &(&1["asset_id"] == id and &1["starts_at_s"] < t and t < &1["ends_at_s"])
           ),
           do:
             raise(
               ArgumentError,
               "in-progress prediction requires an exact saved attitude sample"
             )

        terminal =
          get_in(report, [
            "attitude_planning",
            "horizon_coverage",
            "assets",
            id,
            "terminal_motion"
          ])

        plans =
          Enum.filter(report["attitude_planning"]["transitions"], &(&1["asset_id"] == id)) ++
            List.wrap(terminal)

        plan =
          Enum.find(plans, &(&1["source_epoch_s"] <= t and t <= &1["destination_epoch_s"])) ||
            raise ArgumentError, "no saved motion coverage at prediction epoch"

        pose = Motion.at_epoch(plan, t)

        %{
          "quaternion_wxyz" => Tuple.to_list(pose.quaternion),
          "angular_velocity_inertial_deg_s" => Tuple.to_list(pose.angular_velocity_deg_s)
        }
    end
  end
end
