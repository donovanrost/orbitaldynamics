defmodule OrbitalDynamics.MissionAnalysis.PlanRevision.Advance do
  @moduledoc "Advance the planning boundary using explicit state and execution declarations."
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.{
    Snapshot,
    Reference,
    ExecutionState,
    ExecutionCheckpoint
  }

  @placement ~w(request_id asset_id starts_at_s ends_at_s)

  def run!(snapshot, update, planner \\ nil) do
    accepted = accept!(snapshot, update)

    if accepted.execution_checkpoint == :null,
      do: accepted,
      else: plan!(snapshot, accepted.execution_checkpoint, %{}, planner)
  end

  @doc "Accept declared execution independently of any future planning result."
  def accept!(snapshot, update) do
    Snapshot.verify!(snapshot)
    source = Reference.source!(snapshot)
    u = ExecutionState.validate_update!(update, source, snapshot)
    baseline = snapshot["payload"]["report"]
    t = u["as_of_s"]
    declared = u["completed_request_ids"] ++ u["not_executed_request_ids"]

    in_progress =
      Enum.filter(baseline["activities"], &(&1["starts_at_s"] < t and t < &1["ends_at_s"]))

    unconfirmed =
      Enum.filter(
        baseline["activities"],
        &(&1["ends_at_s"] <= t and &1["request_id"] not in declared)
      )

    review = %{
      "format" => "mission_plan_revision.v1",
      "revision_id" => u["revision_id"],
      "baseline_snapshot_id" => snapshot["snapshot_id"],
      "change_sha256" => Snapshot.digest(u),
      "changes" => u,
      "protected_activities" => [],
      "previous_horizon" => source["study"]["horizon"],
      "horizon" => Map.put(source["study"]["horizon"], "starts_at_s", t),
      "initial_state_policy" => "restart_from_declared_common_epoch_state",
      "comparison_scope" => "future_baseline_activities_against_remaining_plan",
      "execution_update" => %{
        "as_of_s" => t,
        "source_id" => u["source_id"],
        "completed_request_ids" => u["completed_request_ids"],
        "not_executed_request_ids" => u["not_executed_request_ids"]
      },
      "service_availability_changes" => %{"newly_unavailable" => [], "restored" => []},
      "execution_boundary" => "analysis_only_no_approval_or_command_execution"
    }

    quality = OrbitalDynamics.MissionAnalysis.PlanRevision.StateQuality.review(u, source)
    review = if quality, do: Map.put(review, "state_quality", quality), else: review

    review =
      if in_progress == [],
        do: review,
        else:
          Map.put(review, "in_progress_request_ids", Enum.map(in_progress, & &1["request_id"]))

    cond do
      quality && quality["status"] != "supported" ->
        rejected(review, "state_quality_rejected", quality["issues"])

      in_progress != [] and
          Enum.sort(Map.get(u, "in_progress_request_ids", [])) !=
            Enum.sort(Enum.map(in_progress, & &1["request_id"])) ->
        rejected(
          review,
          "in_progress_state_incomplete",
          Enum.map(
            in_progress,
            &%{
              "kind" => "baseline_activity_straddles_new_boundary",
              "placement" => Map.take(&1, @placement)
            }
          )
        )

      OrbitalDynamics.MissionAnalysis.PlanRevision.MotionHistory.committed?(snapshot, t) and
          u["motion_source_snapshot_id"] != snapshot["snapshot_id"] ->
        rejected(review, "in_progress_motion_unconfirmed", [
          %{"kind" => "saved_maneuver_requires_execution_confirmation"}
        ])

      unconfirmed != [] ->
        rejected(
          review,
          "execution_history_incomplete",
          Enum.map(
            unconfirmed,
            &%{
              "kind" => "past_planned_activity_outcome_not_declared",
              "placement" => Map.take(&1, @placement)
            }
          )
        )

      true ->
        {inputs, comparison, protected, closed} = ExecutionState.prepare(source, snapshot, u)
        inherited = get_in(source, ["study", "scheduling", "protected_activities"]) || []
        missed = Enum.filter(inherited, &(&1["request_id"] in u["not_executed_request_ids"]))

        review =
          review
          |> Map.put("protected_activities", protected)
          |> Map.put("closed_requests", closed)
          |> Map.put("missed_past_commitments", missed)

        inputs = Map.delete(inputs, "execution_checkpoint_id")
        ExecutionState.validate_source!(inputs)
        checkpoint = ExecutionCheckpoint.new!(snapshot, u, inputs)

        review =
          review
          |> Map.put("execution_checkpoint_id", checkpoint["checkpoint_id"])
          |> Map.put("execution_checkpoint_status", "accepted")
          |> Map.put("status", "execution_checkpoint_accepted")

        %{
          review: review,
          execution_checkpoint: checkpoint,
          candidate_report: :null,
          revised_snapshot: :null,
          comparison: comparison
        }
    end
  end

  @doc "Plan from a frozen checkpoint; retry controls cannot change state, demand or constraints."
  def plan!(snapshot, checkpoint, attempt \\ %{}, planner \\ nil) do
    accepted = ExecutionCheckpoint.validate!(checkpoint, snapshot)
    u = checkpoint["payload"]["state_update"]

    inputs =
      Map.put(
        checkpoint["payload"]["inputs"],
        "execution_checkpoint_id",
        checkpoint["checkpoint_id"]
      )

    attempt = attempt!(attempt, u)
    scheduling = Map.merge(inputs["study"]["scheduling"], attempt["scheduling"])
    inputs = put_in(inputs, ["study", "scheduling"], scheduling)

    review =
      accepted.review
      |> Map.put("revision_id", attempt["attempt_id"])
      |> Map.put("planning_attempt", attempt)

    result =
      case OrbitalDynamics.MissionAnalysis.PlanRevision.HorizonExtension.apply(
             inputs,
             snapshot,
             u["horizon_extension"]
           ) do
        {:ok, inputs, evidence} ->
          review = Map.put(review, "horizon", inputs["study"]["horizon"])
          review = if evidence, do: Map.put(review, "horizon_extension", evidence), else: review

          if planner do
            Reference.evaluate_revision!(
              snapshot,
              accepted.comparison,
              inputs,
              review,
              review["protected_activities"],
              planner
            )
          else
            Reference.evaluate_revision!(
              snapshot,
              accepted.comparison,
              inputs,
              review,
              review["protected_activities"]
            )
          end

        {:error, reason} ->
          Reference.rejected(review, "horizon_extension_rejected", [
            %{"kind" => "unsupported_extension", "reason" => reason}
          ])
      end

    result =
      Map.update!(
        result,
        :review,
        &Map.put(
          &1,
          "plan_readiness",
          if(result.revised_snapshot == :null,
            do: "stale_pending_replan",
            else: "replacement_ready_for_review"
          )
        )
      )

    Map.put(result, :execution_checkpoint, checkpoint)
  end

  defp attempt!(attempt, u) do
    attempt = OrbitalDynamics.Schema.JsonSafety.normalize_input!(attempt, "planning attempt")

    if attempt == %{} do
      %{"attempt_id" => u["revision_id"], "scheduling" => %{}}
    else
      OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport.fields!(
        attempt,
        ~w(attempt_id scheduling),
        "planning attempt"
      )

      OrbitalDynamics.MissionAnalysis.Input.id!(attempt["attempt_id"])
      c = attempt["scheduling"]

      unless is_map(c) and Map.has_key?(c, "strategy") and Map.has_key?(c, "max_trials") and
               Map.keys(c) -- ~w(strategy max_trials work_budget) == [],
             do:
               raise(
                 ArgumentError,
                 "retry permits only strategy, max_trials and optional work_budget"
               )

      OrbitalDynamics.MissionAnalysis.Scheduling.Reference.policy!(c)
      attempt
    end
  end

  defp rejected(review, status, conflicts),
    do:
      Reference.rejected(
        Map.put(review, "execution_checkpoint_status", "rejected"),
        status,
        conflicts
      )
      |> Map.put(:execution_checkpoint, :null)
end
