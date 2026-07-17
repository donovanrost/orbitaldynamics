defmodule OrbitalDynamics.CampaignPlanner.RepairReplacementTransitions do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    CandidateDiffMetadata,
    RepairAccumulator,
    RepairActivityIdentity,
    RepairReplacementSelection
  }

  def move_missed_downlink(activity, realized, acc, context) do
    case RepairReplacementSelection.downlink_candidate(activity, acc, context) do
      nil ->
        reason = "missed_contact_no_viable_later_access_window"

        acc
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "missed",
          "canceled",
          reason,
          nil,
          true
        )
        |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
        |> RepairAccumulator.add_warning(
          "missed downlink #{ActivityIdentity.activity_id(activity)} could not be repaired"
        )

      replacement ->
        reason = "missed_contact_rescheduled_to_next_viable_access_window"
        candidate_diff = RepairReplacementSelection.candidate_diff(activity, replacement, context)

        replacement =
          put_repair_metadata(
            replacement,
            %{
              "action" => "moved",
              "source_activity_id" => ActivityIdentity.activity_id(activity),
              "source_timeline_id" => RepairActivityIdentity.timeline_id(activity),
              "replacement_timeline_id" => RepairActivityIdentity.timeline_id(replacement),
              "timeline_link" => RepairActivityIdentity.timeline_link(activity, replacement),
              "source_activity_context" => RepairActivityIdentity.context(activity),
              "reason" => reason,
              "requires_approval" => true,
              "schedule_churn_s" =>
                abs(
                  ActivityTiming.activity_start(replacement) -
                    ActivityTiming.activity_start(activity)
                )
            }
            |> maybe_put_candidate_diff(candidate_diff)
          )

        acc
        |> RepairAccumulator.add_activity(replacement)
        |> RepairAccumulator.use_replacement(replacement)
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "missed",
          "moved",
          reason,
          ActivityIdentity.activity_id(replacement),
          true,
          replacement
        )
        |> RepairAccumulator.add_approval_requirement(
          replacement,
          "approve_moved_contact",
          reason
        )
    end
  end

  def replace_failed_observation(activity, realized, acc, context) do
    case RepairReplacementSelection.candidate(activity, "observe", acc, context) do
      nil ->
        reason = "failed_observation_no_viable_replacement_window"

        acc
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "failed",
          "canceled",
          reason,
          nil,
          true
        )
        |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
        |> RepairAccumulator.add_warning(
          "failed observation #{ActivityIdentity.activity_id(activity)} could not be reassigned"
        )

      replacement ->
        reason = "failed_observation_reassigned_to_viable_spacecraft_or_later_window"
        candidate_diff = RepairReplacementSelection.candidate_diff(activity, replacement, context)

        replacement =
          put_repair_metadata(
            replacement,
            %{
              "action" => "replaced",
              "source_activity_id" => ActivityIdentity.activity_id(activity),
              "source_timeline_id" => RepairActivityIdentity.timeline_id(activity),
              "replacement_timeline_id" => RepairActivityIdentity.timeline_id(replacement),
              "timeline_link" => RepairActivityIdentity.timeline_link(activity, replacement),
              "source_activity_context" => RepairActivityIdentity.context(activity),
              "reason" => reason,
              "requires_approval" => true,
              "schedule_churn_s" =>
                abs(
                  ActivityTiming.activity_start(replacement) -
                    ActivityTiming.activity_start(activity)
                )
            }
            |> maybe_put_candidate_diff(candidate_diff)
          )

        acc
        |> RepairAccumulator.add_activity(replacement)
        |> RepairAccumulator.use_replacement(replacement)
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "failed",
          "replaced",
          reason,
          ActivityIdentity.activity_id(replacement),
          true,
          replacement
        )
        |> RepairAccumulator.add_approval_requirement(
          replacement,
          "approve_reassigned_observation",
          reason
        )
    end
  end

  defp maybe_put_candidate_diff(metadata, nil), do: metadata

  defp maybe_put_candidate_diff(metadata, row) do
    CandidateDiffMetadata.put(metadata, row)
  end

  defp put_repair_metadata(activity, metadata) do
    Map.update(activity, "repair", metadata, &Map.merge(&1, metadata))
  end
end
