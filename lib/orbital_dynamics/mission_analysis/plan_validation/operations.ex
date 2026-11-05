defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Operations do
  @moduledoc "Independent accounting and lifecycle validation of a saved operations artifact chain."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Checker, as: C

  def validate(report, load) do
    try do
      require!(
        is_map(report) and report["format"] == "mission_operations_scenario.v2",
        "operations report format mission_operations_scenario.v2 required; regenerate older scenario artifacts"
      )

      steps = report["steps"]

      require!(
        is_list(steps) and length(steps) in 1..16,
        "bounded nonempty operations steps required"
      )

      specs = get_in(report, ["script", "steps"])

      require!(
        is_list(specs) and length(specs) in 1..16 and length(steps) <= length(specs),
        "original script steps required"
      )

      baseline = fetch!(load, "baseline_snapshot.json")
      checked = C.snapshot(baseline, "baseline_snapshot.json")

      initial = %{
        current: baseline,
        issues: checked["issues"],
        validations: [checked],
        completed: [],
        skipped: 0,
        stopped: false,
        pending: false,
        checkpoint: :null,
        checkpoint_artifact: :null,
        epoch: baseline["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]
      }

      state =
        steps
        |> Enum.with_index(1)
        |> Enum.reduce(initial, fn {row, n}, acc ->
          require!(is_map(row), "step object required")
          spec = Enum.at(specs, n - 1)
          require!(is_map(spec), "script step object required")
          row = Map.put(row, "validation_script_step", spec)
          parent = acc.current
          here = "step-#{n}"

          issues =
            C.check(
              not acc.stopped and (not acc.pending or row["kind"] == "retry") and
                row["index"] == n and
                row["baseline_snapshot_id"] == parent["snapshot_id"],
              "chain_order",
              here,
              "step continues a stopped run or references the wrong parent"
            )

          issues =
            issues ++
              C.check(
                row["id"] == spec["id"] and row["kind"] == spec["kind"],
                "script_step_binding",
                here,
                "chronology does not match original script"
              )

          next =
            case row["kind"] do
              "advance" -> advance(acc, row, n, load, issues)
              "revise" -> revise(acc, row, n, load, issues)
              "retry" -> retry(acc, row, n, load, issues)
              _ -> throw({:chain, "unsupported step kind"})
            end

          readiness =
            if next.pending,
              do: "stale_pending_replan",
              else:
                if(row["adopted"], do: "supported_at_declared_boundary", else: "review_required")

          cp_id = if is_map(next.checkpoint), do: next.checkpoint["checkpoint_id"], else: :null

          cp_epoch =
            if is_map(next.checkpoint),
              do: next.checkpoint["payload"]["state_update"]["as_of_s"],
              else: baseline["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]

          errors =
            C.check(
              row["plan_readiness"] == readiness and row["execution_checkpoint_id"] == cp_id and
                row["execution_checkpoint_artifact"] == next.checkpoint_artifact and
                row["accepted_execution_epoch_s"] == cp_epoch,
              "execution_plan_readiness",
              here,
              "checkpoint pointer, accepted state epoch or plan readiness contradicts independent state"
            )

          %{next | issues: next.issues ++ errors}
        end)

      current = state.current

      history =
        if is_map(state.checkpoint),
          do: state.checkpoint["payload"]["inputs"]["execution"],
          else: current["payload"]["inputs"]["execution"] || :null

      ledger = if is_map(history), do: history["closed_requests"], else: []
      completed_rows = Enum.filter(ledger, &(&1["status"] == "completed"))

      summary = %{
        "simulated_completion_count" => length(state.completed),
        "simulated_completed_value" => Enum.sum(Enum.map(state.completed, & &1["value"])),
        "scripted_skip_count" => state.skipped,
        "accepted_completion_count" => length(completed_rows),
        "accepted_expired_count" => Enum.count(ledger, &(&1["status"] == "expired"))
      }

      issues =
        state.issues ++
          C.check(
            report["baseline_snapshot_id"] == baseline["snapshot_id"] and
              report["final_snapshot_id"] == current["snapshot_id"],
            "chain_final_identity",
            "operations",
            "top-level snapshot identities contradict artifacts"
          ) ++
          C.check(
            report["execution_epoch_s"] == state.epoch and
              report["accepted_plan_epoch_s"] ==
                current["payload"]["inputs"]["study"]["horizon"]["starts_at_s"],
            "chain_epoch",
            "operations",
            "reported clock differs from replay/accepted plan"
          ) ++
          C.check(
            report["final_accepted_execution_history"] ==
              history and
              report["final_plan_bound_execution_history"] ==
                (current["payload"]["inputs"]["execution"] || :null) and
              report["latest_execution_checkpoint_id"] ==
                if(is_map(state.checkpoint), do: state.checkpoint["checkpoint_id"], else: :null) and
              report["latest_execution_checkpoint_artifact"] == state.checkpoint_artifact,
            "chain_final_ledger",
            "operations",
            "reported ledger differs from final accepted inputs"
          ) ++
          C.check(
            report["execution_summary"] == summary,
            "execution_summary",
            "operations",
            "completion or skip totals contradict independent accounting"
          )

      readiness =
        if state.pending,
          do: "stale_pending_replan",
          else:
            if(List.last(steps)["adopted"],
              do: "supported_at_declared_boundary",
              else: "review_required"
            )

      cp_epoch =
        if is_map(state.checkpoint),
          do: state.checkpoint["payload"]["state_update"]["as_of_s"],
          else: baseline["payload"]["inputs"]["study"]["horizon"]["starts_at_s"]

      issues =
        issues ++
          C.check(
            report["plan_readiness"] == readiness and
              report["accepted_execution_epoch_s"] == cp_epoch,
            "final_execution_readiness",
            "operations",
            "latest accepted execution and plan readiness are inconsistent"
          )

      unprocessed = Enum.drop(specs, length(steps)) |> Enum.map(& &1["id"])

      issues =
        issues ++
          C.check(
            report["unprocessed_step_ids"] == unprocessed and
              if(state.stopped or state.pending,
                do: report["run_status"] == "stopped_for_review",
                else: report["run_status"] == "completed" and unprocessed == []
              ),
            "chain_completeness",
            "operations",
            "reported run status or unprocessed steps contradict the actual chain"
          )

      issues =
        if state.stopped or state.pending,
          do:
            issues ++
              [
                C.issue(
                  "stopped_operations",
                  "operations",
                  "accepted prefix checked; there is no independently validated new operating plan at the stopped boundary",
                  "unsupported"
                )
              ],
          else: issues

      finish(issues, state.validations, summary)
    rescue
      e in [
        KeyError,
        BadMapError,
        FunctionClauseError,
        Protocol.UndefinedError,
        ArithmeticError,
        ArgumentError
      ] ->
        finish([C.issue("invalid_chain_schema", "operations", Exception.message(e))], [], %{})
    catch
      {:chain, message} ->
        finish([C.issue("invalid_chain_artifact", "operations", message)], [], %{})
    end
  end

  defp revise(acc, row, n, load, issues) do
    parent = acc.current
    change = script_step(row, n)["change"]

    issues =
      issues ++
        C.check(
          row["review"]["changes"] == change,
          "revision_script_binding",
          "step-#{n}",
          "recorded changes differ from original script"
        )

    require!(is_map(change), "revision changes missing")

    issues =
      issues ++
        C.check(
          not Map.has_key?(change, "expected_baseline_id") or
            change["expected_baseline_id"] == parent["snapshot_id"],
          "revision_parent",
          "step-#{n}",
          "revision expected a different baseline"
        )

    if row["adopted"] do
      child = fetch!(load, name(n, "revised_snapshot"))
      result = C.snapshot(child, name(n, "revised_snapshot"))
      old = parent["payload"]["inputs"]
      new = child["payload"]["inputs"]
      additions = change["add_requests"]
      require!(is_list(additions), "revision additions missing")

      mission =
        Map.update!(
          old["mission"],
          "requests",
          &(&1 ++ Enum.map(additions, fn a -> a["request"] end))
        )

      study =
        Enum.reduce(additions, old["study"], fn a, s ->
          Enum.reduce(a["activity_modes"], s, fn {id, mode}, s ->
            put_in(
              s,
              ["path_constraints", "assets", id, "activity_modes", a["request"]["id"]],
              mode
            )
          end)
        end)

      inherited = get_in(old, ["study", "scheduling", "protected_activities"]) || []

      selected =
        Enum.map(change["protect_request_ids"], &selected!(parent, &1))
        |> Enum.map(&C.placement/1)

      study =
        Map.put(
          study,
          "scheduling",
          Map.take(study["scheduling"] || %{}, [
            "maintenance",
            "work_budget",
            "availability",
            "command_delivery"
          ])
          |> Map.merge(change["scheduling"])
          |> Map.put("protected_activities", pins(inherited ++ selected))
        )

      expected =
        Map.merge(old, %{
          "mission" => mission,
          "study" => study,
          "service_unavailable_asset_ids" => change["unavailable_asset_ids"]
        })

      es =
        issues ++
          result["issues"] ++
          transition(parent, child, row, n) ++
          C.check(
            same_inputs?(new, expected),
            "unauthorized_revision_inputs",
            "step-#{n}",
            "revision changed frozen inputs or lost an inherited commitment/ledger"
          ) ++
          C.check(
            row["execution_epoch_s"] == acc.epoch,
            "revision_clock",
            "step-#{n}",
            "ordinary revision advanced execution time"
          )

      %{acc | current: child, issues: acc.issues ++ es, validations: acc.validations ++ [result]}
    else
      stop(acc, row, issues)
    end
  end

  defp advance(acc, row, n, load, issues) do
    u = row["state_update"]

    if not is_map(u) do
      stop(
        acc,
        row,
        issues ++
          C.check(
            row["execution_epoch_s"] == acc.epoch,
            "invalid_step_clock",
            "step-#{n}",
            "step without execution evidence advanced time"
          )
      )
    else
      parent = acc.current
      old = parent["payload"]["inputs"]
      t = u["as_of_s"]
      require!(is_number(t), "update epoch missing")
      skip = u["not_executed_request_ids"]
      require!(is_list(skip), "skip IDs missing")
      ended = Enum.filter(parent["payload"]["report"]["activities"], &(&1["ends_at_s"] <= t))
      executed = Enum.reject(ended, &(&1["request_id"] in skip))
      completed = Enum.map(executed, & &1["request_id"])
      replay = fetch!(load, name(n, "execution_snapshot"))
      replay_result = C.snapshot(replay, name(n, "execution_snapshot"))
      running = OrbitalDynamics.MissionAnalysis.PlanValidation.Continuations.active(parent, t)

      replay_acts =
        Enum.sort_by(
          executed ++ Enum.map(running, &(&1 |> Map.put("ends_at_s", t) |> Map.put("value", 0))),
          &{&1["starts_at_s"], &1["request_id"]}
        )

      replay_expected =
        OrbitalDynamics.MissionAnalysis.PlanValidation.Continuations.replay_inputs(
          old,
          parent,
          executed,
          running,
          t
        )

      actual_replay = replay["payload"]["inputs"]

      es =
        issues ++
          C.check(
            row["execution_replay"]["policy"] ==
              if(skip == [],
                do: "follow_saved_parent_motion",
                else: "replanned_counterfactual_for_declared_skips"
              ),
            "execution_motion_policy",
            "step-#{n}",
            "replay policy contradicts the scripted execution change"
          ) ++
          replay_result["issues"] ++
          C.check(
            t > acc.epoch and t < old["study"]["horizon"]["ends_at_s"] and
              row["execution_epoch_s"] == t,
            "advance_clock",
            "step-#{n}",
            "execution epoch does not strictly advance within horizon"
          ) ++
          C.check(
            Enum.sort(Map.get(u, "in_progress_request_ids", [])) ==
              Enum.sort(Enum.map(running, & &1["request_id"])),
            "in_progress_execution",
            "step-#{n}",
            "running activity declarations differ from the parent schedule"
          ) ++
          C.check(
            Enum.sort(u["completed_request_ids"]) == Enum.sort(completed) and
              length(Enum.uniq(skip)) == length(skip) and
              Enum.all?(skip, fn id -> Enum.any?(ended, &(&1["request_id"] == id)) end),
            "execution_outcomes",
            "step-#{n}",
            "completed or skipped IDs contradict parent plan"
          ) ++
          C.check(
            same_replay_inputs?(actual_replay, replay_expected, skip == []) and
              same_placements?(replay["payload"]["report"]["activities"], replay_acts),
            "execution_replay_binding",
            "step-#{n}",
            "replay is not exactly the executed prefix of parent inputs"
          ) ++
          C.check(
            replay["payload"]["parent_snapshot_id"] == parent["snapshot_id"] and
              row["execution_replay"]["snapshot_id"] == replay["snapshot_id"],
            "execution_replay_identity",
            "step-#{n}",
            "replay identity or parent mismatch"
          ) ++
          C.check(
            u["expected_baseline_id"] == parent["snapshot_id"] and u["time_scale"] == "utc" and
              u["frame"] == "eci_j2000",
            "state_update_binding",
            "step-#{n}",
            "state update parent/frame/time mismatch"
          )

      es =
        es ++
          C.check(
            if(skip == [],
              do: u["motion_source_snapshot_id"] == parent["snapshot_id"],
              else: not Map.has_key?(u, "motion_source_snapshot_id")
            ),
            "motion_execution_confirmation",
            "step-#{n}",
            "execution motion confirmation differs from the declared replay policy"
          )

      spec = script_step(row, n)
      losses = spec["energy_losses_wh"]
      require!(is_map(losses), "script energy losses missing")

      es =
        es ++
          C.check(
            spec["as_of_s"] == t and spec["not_executed_request_ids"] == skip and
              spec["protect_request_ids"] == u["protect_request_ids"] and
              spec["scheduling"] == u["scheduling"] and
              spec["horizon_extension"] == u["horizon_extension"] and
              row["execution_replay"]["energy_losses_wh"] == losses,
            "advance_script_binding",
            "step-#{n}",
            "state update differs from original scripted event"
          )

      es =
        es ++
          C.check(
            row["review"]["changes"] == u and row["review"]["change_sha256"] == C.digest(u),
            "advance_review_binding",
            "step-#{n}",
            "review changed the execution state packet"
          )

      es =
        es ++
          OrbitalDynamics.MissionAnalysis.PlanValidation.Commands.receipts(parent, u, "step-#{n}") ++
          state_accounting(old, u, executed ++ running, replay_result, losses, n)

      es =
        es ++
          C.check(
            Enum.sort(Map.keys(u["assets"])) ==
              Enum.sort(Enum.map(old["mission"]["assets"], & &1["id"])),
            "state_asset_identity",
            "step-#{n}",
            "state packet asset set differs from fleet"
          )

      expected_inputs = advance_inputs(old, parent, u) |> Map.delete("execution_checkpoint_id")

      quality =
        OrbitalDynamics.MissionAnalysis.PlanValidation.StateQuality.check(
          expected_inputs,
          "step-#{n}"
        )

      motion =
        OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.future(parent, t)["assets"]

      confirmed =
        u["motion_source_snapshot_id"] == parent["snapshot_id"] or
          not Enum.any?(motion, fn {_, c} -> is_map(c["committed"]) end)

      should_accept = quality == [] and confirmed

      es =
        es ++
          C.check(
            row["execution_checkpoint_accepted"] == should_accept,
            "execution_acceptance",
            "step-#{n}",
            "valid execution was discarded or invalid execution promoted"
          )

      {checkpoint, artifact, checkpoint_issues} =
        if should_accept do
          artifact = name(n, "execution_checkpoint")
          cp = fetch!(load, artifact)

          {errors, _} =
            OrbitalDynamics.MissionAnalysis.PlanValidation.ExecutionCheckpoint.check(
              cp,
              parent,
              u,
              artifact
            )

          {cp, artifact,
           errors ++
             C.check(
               row["execution_checkpoint_id"] == cp["checkpoint_id"] and
                 row["execution_checkpoint_artifact"] == artifact,
               "execution_checkpoint_pointer",
               "step-#{n}",
               "chronology references the wrong checkpoint"
             )}
        else
          {acc.checkpoint, acc.checkpoint_artifact, []}
        end

      base = %{
        acc
        | issues: acc.issues ++ es ++ checkpoint_issues,
          validations: acc.validations ++ [replay_result],
          completed: acc.completed ++ executed,
          skipped: acc.skipped + length(skip),
          epoch: t,
          checkpoint: checkpoint,
          checkpoint_artifact: artifact,
          pending: should_accept
      }

      attempt = %{"attempt_id" => u["revision_id"], "scheduling" => %{}}

      errors =
        C.check(
          row["review"]["planning_attempt"] == if(should_accept, do: attempt, else: nil),
          "planning_attempt_binding",
          "step-#{n}",
          "initial plan attempt differs from frozen execution intent"
        )

      base = %{base | issues: base.issues ++ errors}

      if should_accept,
        do: adopt_checkpoint(base, row, n, load, u, attempt),
        else: stop(base, row, [])
    end
  end

  defp retry(%{pending: false} = acc, row, n, _load, issues) do
    stop(
      acc,
      row,
      issues ++
        C.check(
          row["status"] == "invalid_step" and row["state_update"] == :null and
            row["execution_replay"] == :null and row["executed_services"] == [] and
            row["execution_epoch_s"] == acc.epoch,
          "invalid_retry_execution",
          "step-#{n}",
          "retry without a pending checkpoint changed execution"
        )
    )
  end

  defp retry(acc, row, n, load, issues) do
    require!(is_map(acc.checkpoint), "retry has no pending execution checkpoint")
    cp = acc.checkpoint
    u = cp["payload"]["state_update"]
    spec = script_step(row, n)
    attempt = %{"attempt_id" => spec["id"], "scheduling" => spec["scheduling"]}

    es =
      issues ++
        C.check(
          row["execution_checkpoint_id"] == cp["checkpoint_id"] and
            row["execution_checkpoint_artifact"] == acc.checkpoint_artifact and
            row["execution_checkpoint_accepted"] == false and row["state_update"] == :null and
            row["execution_replay"] == :null and row["executed_services"] == [] and
            row["execution_epoch_s"] == acc.epoch,
          "retry_execution_unchanged",
          "step-#{n}",
          "retry replays execution, changes checkpoint or advances the clock"
        ) ++
        C.check(
          row["review"]["planning_attempt"] == attempt and row["review"]["changes"] == u and
            row["review"]["change_sha256"] == C.digest(u),
          "retry_attempt_binding",
          "step-#{n}",
          "retry differs from scripted controls or original execution packet"
        )

    base = %{acc | issues: acc.issues ++ es}
    adopt_checkpoint(base, row, n, load, u, attempt)
  end

  defp adopt_checkpoint(base, row, n, load, u, attempt) do
    errors =
      C.check(
        row["review"]["execution_checkpoint_id"] == base.checkpoint["checkpoint_id"] and
          row["review"]["execution_checkpoint_status"] == "accepted" and
          row["review"]["revision_id"] == attempt["attempt_id"] and
          row["review"]["plan_readiness"] ==
            if(row["adopted"], do: "replacement_ready_for_review", else: "stale_pending_replan"),
        "planning_checkpoint_binding",
        "step-#{n}",
        "plan review is not bound to the accepted execution checkpoint and attempt"
      )

    base = %{base | issues: base.issues ++ errors}
    parent = base.current
    old = parent["payload"]["inputs"]

    if row["adopted"] do
      child = fetch!(load, name(n, "revised_snapshot"))
      checked = C.snapshot(child, name(n, "revised_snapshot"))

      expected =
        advance_inputs(old, parent, u)
        |> Map.delete("execution_checkpoint_id")
        |> OrbitalDynamics.MissionAnalysis.PlanValidation.ExecutionCheckpoint.attempt(
          base.checkpoint,
          attempt
        )
        |> OrbitalDynamics.MissionAnalysis.PlanValidation.Coverage.extend(u["horizon_extension"])

      coverage_errors =
        if u["horizon_extension"],
          do:
            OrbitalDynamics.MissionAnalysis.PlanValidation.Coverage.overlap(
              parent,
              child,
              "step-#{n}"
            ),
          else: []

      coverage_errors =
        coverage_errors ++
          if e = u["horizon_extension"] do
            C.check(
              e["provider"] == old["study"]["rolling_horizon"]["provider"] and
                e["ends_at_s"] > old["study"]["horizon"]["ends_at_s"] and
                e["coverage_ends_at_s"] >=
                  old["mission"]["epoch_s"] + old["mission"]["duration_s"],
              "extension_contract",
              "step-#{n}",
              "extension provider/end/coverage contradict saved policy"
            )
          else
            []
          end

      errors =
        coverage_errors ++
          checked["issues"] ++
          transition(parent, child, row, n) ++
          C.check(
            same_inputs?(child["payload"]["inputs"], expected),
            "advance_inputs_or_ledger",
            "step-#{n}",
            "remaining demand, balances, state, inherited commitments or ledger contradict independent reconstruction"
          )

      %{
        base
        | current: child,
          pending: false,
          issues: base.issues ++ errors,
          validations: base.validations ++ [checked]
      }
    else
      stop(base, row, [])
    end
  end

  # The original script is attached by validate/2, rather than trusting the review's copied changes.
  defp script_step(row, _n), do: row["validation_script_step"]

  defp state_accounting(old, u, executed, replay_result, losses, n) do
    assets = u["assets"]
    require!(is_map(assets), "state asset map missing")

    Enum.flat_map(old["mission"]["assets"], fn asset ->
      a = assets[asset["id"]]
      require!(is_map(a), "missing state spacecraft")

      expected =
        Enum.reduce(
          executed |> Enum.filter(&(&1["asset_id"] == asset["id"])),
          asset["resource_budgets"],
          fn act, b ->
            q = Enum.find(old["mission"]["requests"], &(&1["id"] == act["request_id"]))

            Enum.reduce(q["resource_costs"], b, fn {k, cost}, b ->
              if Map.has_key?(b, k), do: Map.update!(b, k, &(&1 - cost)), else: b
            end)
          end
        )

      es =
        C.check(
          a["resource_budgets"] == expected,
          "execution_static_balance",
          "step-#{n}/#{asset["id"]}",
          "completed costs were charged twice, refunded or charged for skipped services"
        )

      expected_battery = replay_result["expected_battery"][asset["id"]] || %{}

      wheel_issues =
        Enum.flat_map(get_in(replay_result, ["expected_wheels", asset["id"]]) || %{}, fn {id,
                                                                                          prediction} ->
          reported = get_in(a, ["wheel_momentum_nms", id])
          values = prediction["final_momentum_nms"]

          C.check(
            is_list(reported) and length(reported) == 3 and
              Enum.zip_with(reported, values, &C.near?/2) |> Enum.all?(),
            "execution_wheel_handoff",
            "step-#{n}/#{asset["id"]}/#{id}",
            "wheel state differs from independent executed-only momentum balance"
          )
        end)

      thermal_issues =
        Enum.flat_map(get_in(replay_result, ["expected_thermal", asset["id"]]) || %{}, fn {id,
                                                                                           prediction} ->
          C.check(
            C.near?(get_in(a, ["thermal_temperature_k", id]), prediction["temperature_k"]),
            "execution_thermal_handoff",
            "step-#{n}/#{asset["id"]}/#{id}",
            "temperature differs from independent executed-only heat balance"
          )
        end)

      es ++
        thermal_issues ++
        wheel_issues ++
        Enum.flat_map(expected_battery, fn {id, b} ->
          loss = get_in(losses, [asset["id"], id]) || 0

          C.check(
            is_number(loss) and loss >= 0 and loss <= b["energy_wh"] and
              C.near?(a["battery_energy_wh"][id], b["energy_wh"] - loss),
            "execution_energy_handoff",
            "step-#{n}/#{asset["id"]}/#{id}",
            "state energy differs from analytic executed-only balance minus declared loss"
          )
        end)
    end)
  end

  defp advance_inputs(old, parent, u),
    do:
      OrbitalDynamics.MissionAnalysis.PlanValidation.Continuations.advance_inputs(old, parent, u)

  defp transition(parent, child, row, n) do
    report = child["payload"]["report"]
    view = row["accepted_plan"]

    actual_activities =
      Enum.map(
        report["activities"],
        &Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s value protected))
      )

    C.check(
      child["payload"]["parent_snapshot_id"] == parent["snapshot_id"] and
        row["accepted_snapshot_id"] == child["snapshot_id"] and
        row["status"] == "ready_for_review",
      "accepted_transition",
      "step-#{n}",
      "accepted snapshot parent or status mismatch"
    ) ++
      C.check(
        row["review"]["baseline_snapshot_id"] == parent["snapshot_id"] and
          row["review"]["revised_snapshot_id"] == child["snapshot_id"] and
          row["accepted_plan_epoch_s"] ==
            child["payload"]["inputs"]["study"]["horizon"]["starts_at_s"],
        "review_snapshot_binding",
        "step-#{n}",
        "native review or accepted epoch differs from snapshot"
      ) ++
      C.check(
        is_map(view) and view["activities"] == actual_activities and
          view["scheduled_value"] == Enum.sum(Enum.map(report["activities"], & &1["value"])) and
          view["remaining_static_budgets"] == report["remaining_resource_budgets"],
        "accepted_plan_summary",
        "step-#{n}",
        "chronology's plan summary differs from checked snapshot"
      )
  end

  defp stop(acc, row, issues),
    do: %{
      acc
      | issues:
          acc.issues ++
            issues ++
            C.check(
              row["accepted_snapshot_id"] == acc.current["snapshot_id"] and
                row["status"] != "ready_for_review",
              "rejected_transition",
              "operations",
              "failed revision changed the accepted pointer or claims a ready plan"
            ),
        stopped: not acc.pending
    }

  defp same_replay_inputs?(a, b, true),
    do:
      OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory.same_replay_inputs?(
        normalized(a),
        normalized(b)
      )

  defp same_replay_inputs?(a, b, false), do: same_inputs?(a, b)

  defp same_inputs?(a, b), do: normalized(a) == normalized(b)

  defp normalized(i),
    do:
      update_in(i, ["study", "scheduling", "protected_activities"], fn xs ->
        Enum.sort_by(xs || [], & &1["request_id"])
      end)

  defp same_placements?(a, b),
    do: Enum.sort(Enum.map(a, &C.placement/1)) == Enum.sort(Enum.map(b, &C.placement/1))

  defp pins(xs), do: Enum.uniq_by(xs, & &1["request_id"])

  defp selected!(s, id),
    do:
      Enum.find(s["payload"]["report"]["activities"], &(&1["request_id"] == id)) ||
        throw({:chain, "commitment references an unscheduled request"})

  defp name(n, suffix),
    do: "step-#{n |> Integer.to_string() |> String.pad_leading(2, "0")}-#{suffix}.json"

  defp fetch!(load, name) do
    case load.(name) do
      {:ok, value} -> value
      {:error, message} -> throw({:chain, "#{name}: #{message}"})
    end
  end

  defp require!(true, _), do: :ok
  defp require!(false, message), do: throw({:chain, message})

  defp finish(issues, validations, summary),
    do: %{
      "format" => "independent_operations_validation.v1",
      "status" =>
        cond do
          Enum.any?(issues, &(&1["severity"] == "error")) -> "failed"
          issues != [] -> "partial"
          true -> "passed"
        end,
      "issues" => issues,
      "snapshots" => validations,
      "independent_execution_summary" => summary,
      "scope" =>
        "accepted artifact chain, phase-load battery and declared sampled wheel accounting; no physical trajectory/pointing or execution-truth validation"
    }
end
