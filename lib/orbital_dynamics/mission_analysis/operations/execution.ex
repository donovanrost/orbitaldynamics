defmodule OrbitalDynamics.MissionAnalysis.Operations.Execution do
  @moduledoc "Scripted execution follows saved motion to its checkpoint; declared skips use an explicit counterfactual replay."
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{
    Snapshot,
    Reference,
    Prediction,
    Continuation
  }

  alias OrbitalDynamics.MissionAnalysis.Attitude.Reference, as: Planner
  alias OrbitalDynamics.MissionAnalysis.Input

  def run!(parent, step) do
    Snapshot.verify!(parent)
    source = Reference.source!(parent)
    t = step["as_of_s"]
    h = source["study"]["horizon"]
    Input.number!(t, "execution boundary", h["starts_at_s"], h["ends_at_s"])

    unless t > h["starts_at_s"] and t < h["ends_at_s"],
      do: raise(ArgumentError, "execution boundary must strictly advance within the horizon")

    activities = parent["payload"]["report"]["activities"]

    running = Continuation.active(parent["payload"]["report"], t)

    ended = Enum.filter(activities, &(&1["ends_at_s"] <= t))
    skipped = step["not_executed_request_ids"]

    unless Enum.all?(skipped, fn id -> Enum.any?(ended, &(&1["request_id"] == id)) end),
      do: raise(ArgumentError, "script can skip only ended baseline services")

    if Enum.any?(skipped, &Map.has_key?(source["study"]["continuations"] || %{}, &1)),
      do: raise(ArgumentError, "already started activities cannot be skipped")

    executed = Enum.reject(ended, &(&1["request_id"] in skipped))
    completed_ids = Enum.map(executed, & &1["request_id"])
    records = Continuation.records(source, parent, running, "execution_prefix")
    sliced = Enum.map(running, fn a -> a |> Map.put("ends_at_s", t) |> Map.put("value", 0) end)
    executed = Enum.sort_by(executed ++ sliced, &{&1["starts_at_s"], &1["request_id"]})
    ids = Enum.map(executed, & &1["request_id"])

    mission =
      Map.update!(source["mission"], "requests", &Enum.filter(&1, fn r -> r["id"] in ids end))

    mission =
      Map.update!(mission, "requests", fn requests ->
        Enum.map(requests, fn request ->
          if records[request["id"]],
            do:
              Continuation.slice(
                request,
                records[request["id"]],
                Enum.find(running, &(&1["request_id"] == request["id"]))["starts_at_s"],
                t,
                "execution_prefix"
              ),
            else: request
        end)
      end)

    continuations = Map.merge(Map.take(source["study"]["continuations"] || %{}, ids), records)

    study =
      source["study"]
      |> put_in(["horizon", "ends_at_s"], t)
      |> Map.put("scheduling", %{
        "strategy" => "greedy",
        "max_trials" => 1,
        "protected_activities" =>
          Enum.map(executed, &Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s)))
      })
      |> update_in(
        ["scheduling"],
        &Map.merge(
          Map.take(source["study"]["scheduling"] || %{}, ["availability", "command_delivery"]),
          &1
        )
      )
      |> update_in(["path_constraints", "assets"], fn assets ->
        Map.new(assets, fn {id, a} ->
          {id, Map.update!(a, "activity_modes", &Map.take(&1, ids))}
        end)
      end)

    study =
      if c = get_in(study, ["scheduling", "command_delivery"]) do
        put_in(
          study,
          ["scheduling", "command_delivery"],
          c
          |> Map.update!("requirements", &Enum.filter(&1, fn r -> r["request_id"] in ids end))
          |> Map.update!("receipts", &Enum.filter(&1, fn r -> r["request_id"] in ids end))
        )
      else
        study
      end

    study =
      if continuations == %{},
        do: Map.delete(study, "continuations"),
        else: Map.put(study, "continuations", continuations)

    # Unchanged execution uses saved motion rather than planning a new terminal return.
    faithful = skipped == []

    study =
      if faithful do
        study =
          Map.put(
            study,
            "saved_motion",
            OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory.replay(
              parent,
              t,
              executed,
              running
            )
          )

        terminals =
          Map.new(source["mission"]["assets"], fn a ->
            {a["id"],
             OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory.terminal(
               parent,
               a["id"],
               t
             )}
          end)

        put_in(study, ["horizon", "terminals"], terminals)
      else
        study = Map.delete(study, "saved_motion")

        Enum.reduce(executed, study, fn activity, acc ->
          if activity["ends_at_s"] == t,
            do:
              put_in(
                acc,
                ["horizon", "terminals", activity["asset_id"]],
                OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory.terminal(
                  parent,
                  activity["asset_id"],
                  t
                )
              ),
            else: acc
        end)
      end

    case Planner.run_profiled(mission, study,
           service_unavailable_asset_ids: source["service_unavailable_asset_ids"]
         ) do
      {:ok, report, _timings} ->
        unless report["attitude_planning"]["planning_status"] == "supported",
          do: raise(ArgumentError, "scripted execution replay is unsupported")

        inputs = %{
          "mission" => mission,
          "study" => study,
          "service_unavailable_asset_ids" => source["service_unavailable_asset_ids"]
        }

        inputs =
          if source["execution"],
            do: Map.put(inputs, "execution", source["execution"]),
            else: inputs

        replay = Snapshot.new!(inputs, report, parent["snapshot_id"])
        predicted_assets = Prediction.state_at!(replay, t)

        predicted_assets =
          Map.new(predicted_assets, fn {id, a} ->
            quality =
              OrbitalDynamics.MissionAnalysis.PlanRevision.StateQuality.stamp(
                inputs,
                id,
                t,
                "synthetic_execution",
                "scripted_execution_and_declared_energy_loss"
              )

            {id, if(quality, do: Map.put(a, "quality", quality), else: a)}
          end)

        assets = apply_losses!(predicted_assets, step["energy_losses_wh"])

        update = %{
          "revision_id" => step["id"],
          "expected_baseline_id" => parent["snapshot_id"],
          "source_id" => "scripted_execution_and_declared_energy_loss",
          "as_of_s" => t,
          "time_scale" => "utc",
          "frame" => "eci_j2000",
          "assets" => assets,
          "completed_request_ids" => completed_ids,
          "not_executed_request_ids" => skipped,
          "protect_request_ids" => step["protect_request_ids"],
          "scheduling" => step["scheduling"]
        }

        update =
          if faithful,
            do: Map.put(update, "motion_source_snapshot_id", parent["snapshot_id"]),
            else: update

        receipts =
          OrbitalDynamics.MissionAnalysis.Scheduling.CommandDelivery.synthetic_receipts(
            source,
            parent["payload"]["report"],
            t,
            "synthetic_execution"
          )

        update = if receipts, do: Map.put(update, "command_receipts", receipts), else: update

        update =
          if step["horizon_extension"],
            do: Map.put(update, "horizon_extension", step["horizon_extension"]),
            else: update

        update =
          if running == [],
            do: update,
            else:
              Map.put(update, "in_progress_request_ids", Enum.map(running, & &1["request_id"]))

        %{snapshot: replay, update: update, predicted_assets: predicted_assets}

      {:error, reason} ->
        raise ArgumentError, "execution replay failed: #{inspect(reason, limit: 10)}"
    end
  end

  defp apply_losses!(assets, losses) do
    unless is_map(losses), do: raise(ArgumentError, "energy losses must be an asset/model map")

    Enum.reduce(losses, assets, fn {id, models}, acc ->
      unless Map.has_key?(assets, id) and is_map(models),
        do: raise(ArgumentError, "energy loss names an unknown asset or invalid model map")

      Enum.reduce(models, acc, fn {model, loss}, acc ->
        energies = assets[id]["battery_energy_wh"]

        unless Map.has_key?(energies, model),
          do: raise(ArgumentError, "energy loss names an unknown battery")

        loss = Input.number!(loss, "declared energy loss", 0, energies[model])
        put_in(acc, [id, "battery_energy_wh", model], energies[model] - loss)
      end)
    end)
  end
end
