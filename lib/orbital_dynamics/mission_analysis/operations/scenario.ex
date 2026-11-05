defmodule OrbitalDynamics.MissionAnalysis.Operations.Scenario do
  @moduledoc "Bounded deterministic scenario driver over the reference revision and execution replay APIs."
  alias OrbitalDynamics.MissionAnalysis.{Input, Scheduling}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{Reference, Advance}
  alias OrbitalDynamics.MissionAnalysis.Operations.Execution

  def validate!(script) do
    script = OrbitalDynamics.Schema.JsonSafety.normalize_input!(script, "operations script")
    S.fields!(script, ~w(scenario_id mission_manifest planning_study steps), "operations script")
    Input.id!(script["scenario_id"])

    unless is_binary(script["mission_manifest"]) and is_binary(script["planning_study"]) and
             is_list(script["steps"]) and length(script["steps"]) in 1..16,
           do: raise(ArgumentError, "scenario requires input paths and 1..16 steps")

    ids =
      Enum.map(script["steps"], fn step ->
        keys =
          case step["kind"] do
            "revise" ->
              ~w(id kind expected_status change)

            "advance" ->
              ~w(id kind expected_status as_of_s not_executed_request_ids energy_losses_wh protect_request_ids scheduling)

            "retry" ->
              ~w(id kind expected_status scheduling)

            _ ->
              raise ArgumentError, "unknown scenario step kind"
          end

        S.fields!(
          step,
          keys ++ Enum.filter(["horizon_extension"], &Map.has_key?(step, &1)),
          "scenario step"
        )

        Input.id!(step["id"])

        unless step["expected_status"] in ~w(ready_for_review commitment_conflict unsupported_revision planning_failed invalid_step state_quality_rejected horizon_extension_rejected in_progress_motion_unconfirmed),
          do: raise(ArgumentError, "unknown expected scenario status")

        if step["kind"] == "retry" do
          c = step["scheduling"]

          unless is_map(c) and Map.keys(c) -- ~w(strategy max_trials work_budget) == [],
            do: raise(ArgumentError, "retry cannot change state or constraints")

          Scheduling.Reference.policy!(c)
        end

        if step["kind"] == "advance" do
          for key <- ~w(not_executed_request_ids protect_request_ids) do
            values = step[key]

            unless is_list(values) and length(values) <= 100 and
                     length(Enum.uniq(values)) == length(values),
                   do: raise(ArgumentError, "scenario request IDs must be bounded and unique")

            Enum.each(values, &Input.id!/1)
          end

          Input.number!(step["as_of_s"], "scenario epoch", -1.0e12, 1.0e12)

          unless is_map(step["energy_losses_wh"]),
            do: raise(ArgumentError, "energy losses require a map")

          S.fields!(
            step["scheduling"],
            ~w(strategy max_trials) ++
              Enum.filter(~w(work_budget availability), &Map.has_key?(step["scheduling"], &1)),
            "scenario scheduling"
          )

          Scheduling.Reference.policy!(step["scheduling"])
        end

        step["id"]
      end)

    unless length(Enum.uniq(ids)) == length(ids),
      do: raise(ArgumentError, "scenario step identities must be unique")

    script
  end

  def artifact_names(script) do
    ["operations.json", "README.md", "baseline_snapshot.json"] ++
      for(
        {_, n} <- Enum.with_index(script["steps"], 1),
        suffix <-
          ~w(execution_snapshot execution_checkpoint revised_snapshot rejected_snapshot failed_candidate),
        do: artifact(n, suffix)
      )
  end

  def run!(mission, study, script, emit \\ fn _, _ -> :ok end) do
    script = validate!(script)
    baseline = Reference.create!(mission, study)
    emit.("baseline_snapshot.json", baseline)

    {current, latest, checkpoint_artifact, pending, rows} =
      script["steps"]
      |> Enum.with_index(1)
      |> Enum.reduce_while({baseline, :null, :null, false, []}, fn {step, n},
                                                                   {parent, latest,
                                                                    checkpoint_artifact, pending,
                                                                    rows} ->
        action = perform_step(parent, step, n, emit, if(pending, do: latest, else: :null))
        r = action.result
        child = r.revised_snapshot

        if Map.get(r, :candidate_report, :null) != :null and child == :null,
          do: emit.(artifact(n, "failed_candidate"), r.candidate_report)

        checks = if child == :null, do: [], else: checks(parent, child, action)
        valid = Enum.all?(checks, & &1["passed"])
        adopted = child != :null and r.review["status"] == "ready_for_review" and valid

        if child != :null,
          do:
            emit.(
              artifact(n, if(adopted, do: "revised_snapshot", else: "rejected_snapshot")),
              child
            )

        new_checkpoint = Map.get(r, :execution_checkpoint, :null)
        latest = if is_map(new_checkpoint), do: new_checkpoint, else: latest

        checkpoint_artifact =
          if step["kind"] == "advance" and is_map(new_checkpoint),
            do: artifact(n, "execution_checkpoint"),
            else: checkpoint_artifact

        next = if adopted, do: child, else: parent

        pending =
          is_map(latest) and
            next["payload"]["inputs"]["execution_checkpoint_id"] != latest["checkpoint_id"]

        report =
          if adopted, do: child["payload"]["report"], else: parent["payload"]["report"]

        row = %{
          "index" => n,
          "id" => step["id"],
          "kind" => step["kind"],
          "status" => r.review["status"],
          "expected_status" => step["expected_status"],
          "expectation_met" => r.review["status"] == step["expected_status"],
          "adopted" => adopted,
          "invariant_status" =>
            if(checks == [], do: "not_evaluated", else: if(valid, do: "passed", else: "failed")),
          "baseline_snapshot_id" => parent["snapshot_id"],
          "accepted_snapshot_id" => next["snapshot_id"],
          "accepted_plan_epoch_s" => next["payload"]["inputs"]["study"]["horizon"]["starts_at_s"],
          "execution_epoch_s" => action.execution_epoch,
          "accepted_execution_epoch_s" =>
            if(is_map(latest),
              do: latest["payload"]["state_update"]["as_of_s"],
              else: baseline["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]
            ),
          "execution_checkpoint_id" =>
            if(is_map(latest), do: latest["checkpoint_id"], else: :null),
          "execution_checkpoint_artifact" => checkpoint_artifact,
          "execution_checkpoint_accepted" => step["kind"] == "advance" and is_map(new_checkpoint),
          "plan_readiness" =>
            if(pending,
              do: "stale_pending_replan",
              else: if(adopted, do: "supported_at_declared_boundary", else: "review_required")
            ),
          "review" => Map.delete(r.review, "planner_timings"),
          "checks" => checks,
          "execution_replay" => action.replay,
          "state_update" => action.update,
          "executed_services" =>
            if(action.update == :null,
              do: [],
              else:
                parent["payload"]["report"]["activities"]
                |> Enum.filter(&(&1["request_id"] in action.update["completed_request_ids"]))
                |> Enum.map(&Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s value)))
            ),
          "accepted_plan" => summary(report),
          "candidate_report_artifact" =>
            if(Map.get(r, :candidate_report, :null) != :null and child == :null,
              do: artifact(n, "failed_candidate"),
              else: :null
            ),
          "unfulfilled_explanations" =>
            for(
              request <- report["requests"],
              request["status"] == "unfulfilled",
              do: Scheduling.Explanation.from_report!(report, request["request_id"])
            )
        }

        next_step = Enum.at(script["steps"], n)

        retry_next =
          pending and valid and row["expectation_met"] and is_map(next_step) and
            next_step["kind"] == "retry"

        state = {next, latest, checkpoint_artifact, pending, rows ++ [row]}
        if adopted or retry_next, do: {:cont, state}, else: {:halt, state}
      end)

    last = List.last(rows)
    completed = length(rows) == length(script["steps"])

    passed =
      completed and Enum.all?(rows, & &1["expectation_met"]) and
        Enum.all?(rows, fn r -> Enum.all?(r["checks"], & &1["passed"]) end)

    simulated = Enum.flat_map(rows, & &1["executed_services"])

    execution_history =
      if is_map(latest),
        do: latest["payload"]["inputs"]["execution"],
        else: current["payload"]["inputs"]["execution"] || :null

    closed = if is_map(execution_history), do: execution_history["closed_requests"], else: []

    %{
      "format" => "mission_operations_scenario.v2",
      "execution_summary" => %{
        "simulated_completion_count" => length(simulated),
        "simulated_completed_value" => Enum.sum(Enum.map(simulated, & &1["value"])),
        "scripted_skip_count" =>
          Enum.sum(
            Enum.map(rows, fn r ->
              if(r["state_update"] == :null,
                do: 0,
                else: length(r["state_update"]["not_executed_request_ids"])
              )
            end)
          ),
        "accepted_completion_count" => Enum.count(closed, &(&1["status"] == "completed")),
        "accepted_expired_count" => Enum.count(closed, &(&1["status"] == "expired"))
      },
      "scenario_id" => script["scenario_id"],
      "script" => script,
      "verification_status" => if(passed, do: "passed", else: "failed"),
      "run_status" =>
        if(last["adopted"] and completed and not pending,
          do: "completed",
          else: "stopped_for_review"
        ),
      "baseline_snapshot_id" => baseline["snapshot_id"],
      "final_snapshot_id" => current["snapshot_id"],
      "baseline_plan" => summary(baseline["payload"]["report"]),
      "steps" => rows,
      "unprocessed_step_ids" =>
        script["steps"] |> Enum.drop(length(rows)) |> Enum.map(& &1["id"]),
      "final_accepted_execution_history" => execution_history,
      "final_plan_bound_execution_history" => current["payload"]["inputs"]["execution"] || :null,
      "accepted_execution_epoch_s" =>
        if(is_map(latest),
          do: latest["payload"]["state_update"]["as_of_s"],
          else: baseline["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]
        ),
      "latest_execution_checkpoint_id" =>
        if(is_map(latest), do: latest["checkpoint_id"], else: :null),
      "latest_execution_checkpoint_artifact" => checkpoint_artifact,
      "plan_readiness" =>
        if(pending,
          do: "stale_pending_replan",
          else: if(last["adopted"], do: "supported_at_declared_boundary", else: "review_required")
        ),
      "execution_epoch_s" => last["execution_epoch_s"],
      "accepted_plan_epoch_s" => current["payload"]["inputs"]["study"]["horizon"]["starts_at_s"],
      "execution_boundary" => "synthetic_analysis_no_commands_or_telemetry",
      "limits" => [
        "unchanged execution follows saved parent motion through the checkpoint without an artificial terminal return",
        "declared skips use explicit counterfactual replanning; motion already committed at a prior boundary cannot be silently aborted",
        "energy losses are declared external state disturbances; their physical cause is not simulated",
        "validated execution checkpoints persist before planning; a pending checkpoint permits only explicit planning retries",
        "failed planning never becomes an accepted replacement plan and does not undo accepted execution state",
        "expected failure can pass a scenario assertion while operations remain stopped for review",
        "shared feasibility models test orchestration consistency, not independent spacecraft physics"
      ]
    }
  end

  defp perform_step(parent, %{"kind" => "retry"} = step, _n, _emit, checkpoint)
       when is_map(checkpoint) do
    result =
      Advance.plan!(parent, checkpoint, %{
        "attempt_id" => step["id"],
        "scheduling" => step["scheduling"]
      })

    %{
      result: result,
      replay: :null,
      update: :null,
      execution_epoch: checkpoint["payload"]["state_update"]["as_of_s"]
    }
  end

  defp perform_step(parent, step, n, emit, :null), do: perform(parent, step, n, emit)

  defp perform_step(parent, _step, _n, _emit, checkpoint),
    do:
      invalid(
        parent,
        ArgumentError.exception("pending execution checkpoint requires a planning retry")
      )
      |> Map.put(:execution_epoch, checkpoint["payload"]["state_update"]["as_of_s"])

  defp perform(parent, %{"kind" => "retry"}, _n, _emit),
    do: invalid(parent, ArgumentError.exception("no pending execution checkpoint to retry"))

  defp perform(parent, %{"kind" => "revise"} = step, _n, _emit) do
    result = Reference.revise!(parent, step["change"])

    %{
      result: result,
      replay: :null,
      update: :null,
      execution_epoch: parent["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]
    }
  rescue
    e in [ArgumentError, KeyError, MatchError] -> invalid(parent, e)
  end

  defp perform(parent, %{"kind" => "advance"} = step, n, emit) do
    execution = Execution.run!(parent, step)
    emit.(artifact(n, "execution_snapshot"), execution.snapshot)
    result = advance_result(parent, execution.update, n, emit)

    %{
      result: result,
      replay: %{
        "policy" =>
          if(step["not_executed_request_ids"] == [],
            do: "follow_saved_parent_motion",
            else: "replanned_counterfactual_for_declared_skips"
          ),
        "artifact" => artifact(n, "execution_snapshot"),
        "snapshot_id" => execution.snapshot["snapshot_id"],
        "predicted_assets" => execution.predicted_assets,
        "energy_losses_wh" => step["energy_losses_wh"]
      },
      update: execution.update,
      execution_epoch: step["as_of_s"]
    }
  rescue
    e in [ArgumentError, KeyError, MatchError] -> invalid(parent, e)
  end

  defp advance_result(parent, update, n, emit) do
    accepted = Advance.accept!(parent, update)

    if accepted.execution_checkpoint == :null do
      accepted
    else
      emit.(artifact(n, "execution_checkpoint"), accepted.execution_checkpoint)
      Advance.plan!(parent, accepted.execution_checkpoint)
    end
  end

  defp invalid(parent, e),
    do: %{
      result: %{
        review: %{"status" => "invalid_step", "error" => Exception.message(e)},
        revised_snapshot: :null
      },
      replay: :null,
      update: :null,
      execution_epoch: parent["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]
    }

  defp checks(parent, child, action) do
    old = parent["payload"]["inputs"]
    new = child["payload"]["inputs"]
    report = child["payload"]["report"]
    old_closed = get_in(old, ["execution", "closed_requests"]) || []
    closed = get_in(new, ["execution", "closed_requests"]) || []
    old_ids = MapSet.new(old_closed, & &1["request"]["id"])
    closed_ids = MapSet.new(closed, & &1["request"]["id"])
    active = MapSet.new(new["mission"]["requests"], & &1["id"])
    served = MapSet.new(report["activities"], & &1["request_id"])
    protected = action.result.review["protected_activities"]

    inherited =
      (get_in(old, ["study", "scheduling", "protected_activities"]) || [])
      |> Enum.filter(&(&1["starts_at_s"] >= new["study"]["horizon"]["starts_at_s"]))

    base = [
      check(
        "inherited_future_commitments_exact",
        Scheduling.Commitments.intact?(report["activities"], inherited)
      ),
      check("snapshot_lineage", child["payload"]["parent_snapshot_id"] == parent["snapshot_id"]),
      check(
        "closed_requests_persist",
        MapSet.subset?(old_ids, closed_ids) and Enum.all?(old_closed, &(&1 in closed))
      ),
      check(
        "closed_requests_not_active_or_scheduled",
        MapSet.disjoint?(closed_ids, active) and MapSet.disjoint?(closed_ids, served)
      ),
      check("commitments_exact", Scheduling.Commitments.intact?(report["activities"], protected)),
      check(
        "service_unavailability_respected",
        Enum.all?(
          report["activities"],
          &(&1["asset_id"] not in new["service_unavailable_asset_ids"])
        )
      ),
      check(
        "full_remaining_plan_supported",
        report["attitude_planning"]["planning_status"] == "supported"
      )
    ]

    checkpoint = Map.get(action.result, :execution_checkpoint, :null)

    update =
      if action.update == :null and is_map(checkpoint),
        do: checkpoint["payload"]["state_update"],
        else: action.update

    if update == :null do
      base ++
        [
          check(
            "same_boundary_and_state",
            old["study"]["horizon"] == new["study"]["horizon"] and
              old["execution"] == new["execution"] and
              old["mission"]["assets"] == new["mission"]["assets"]
          )
        ]
    else
      u = update

      executed =
        Enum.filter(
          parent["payload"]["report"]["activities"],
          &(&1["request_id"] in (u["completed_request_ids"] ++
                                   Map.get(u, "in_progress_request_ids", [])))
        )

      budgets_ok =
        Enum.all?(old["mission"]["assets"], fn asset ->
          next = Enum.find(new["mission"]["assets"], &(&1["id"] == asset["id"]))

          Enum.all?(asset["resource_budgets"], fn {key, original} ->
            used =
              executed
              |> Enum.filter(&(&1["asset_id"] == asset["id"]))
              |> Enum.map(&Map.get(&1["resource_costs"], key, 0))
              |> Enum.sum()

            abs(next["resource_budgets"][key] - (original - used)) <= 1.0e-9
          end)
        end)

      energy_ok =
        Enum.all?(u["assets"], fn {id, a} ->
          resources = report["attitude_planning"]["resource_feasibility"]

          models =
            if is_map(resources), do: get_in(resources, ["assets", id, "models"]) || [], else: []

          Enum.sort(Enum.map(models, & &1["id"])) ==
            Enum.sort(
              Map.keys(a["battery_energy_wh"]) ++
                Map.keys(a["wheel_momentum_nms"] || %{}) ++
                Map.keys(a["thermal_temperature_k"] || %{})
            ) and
            Enum.all?(models, fn m ->
              Enum.all?(
                m["levels"],
                fn level ->
                  cond do
                    Map.has_key?(a["battery_energy_wh"], m["id"]) ->
                      abs(level["initial_state"]["energy_wh"] - a["battery_energy_wh"][m["id"]]) <=
                        1.0e-9

                    Map.has_key?(a["thermal_temperature_k"] || %{}, m["id"]) ->
                      abs(
                        level["initial_state"]["temperature_k"] -
                          a["thermal_temperature_k"][m["id"]]
                      ) <= 1.0e-9

                    true ->
                      level["initial_state"]
                      |> OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels.vector()
                      |> Tuple.to_list() == a["wheel_momentum_nms"][m["id"]]
                  end
                end
              )
            end)
        end)

      confirmed =
        MapSet.new(Enum.filter(closed, &(&1["status"] == "completed")), & &1["request"]["id"])

      base ++
        [
          check(
            "horizon_advances",
            new["study"]["horizon"]["starts_at_s"] == u["as_of_s"] and
              u["as_of_s"] > old["study"]["horizon"]["starts_at_s"]
          ),
          check("completed_costs_charged_once", budgets_ok),
          check("reported_energy_is_new_initial_energy", energy_ok),
          check(
            "executed_requests_archived",
            Enum.all?(u["completed_request_ids"], &MapSet.member?(confirmed, &1))
          ),
          check(
            "skipped_requests_not_completed",
            Enum.all?(u["not_executed_request_ids"], &(not MapSet.member?(confirmed, &1)))
          )
        ]
    end
  end

  defp check(id, passed), do: %{"id" => id, "passed" => passed}

  defp artifact(n, suffix),
    do: "step-#{n |> Integer.to_string() |> String.pad_leading(2, "0")}-#{suffix}.json"

  defp summary(report),
    do: %{
      "scheduled_value" => Enum.sum(Enum.map(report["activities"], & &1["value"])),
      "activities" =>
        Enum.map(
          report["activities"],
          &Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s value protected))
        ),
      "requests" =>
        Enum.map(
          report["requests"],
          &Map.take(&1, ~w(request_id status reasons scheduling_summary))
        ),
      "remaining_static_budgets" => report["remaining_resource_budgets"]
    }
end
