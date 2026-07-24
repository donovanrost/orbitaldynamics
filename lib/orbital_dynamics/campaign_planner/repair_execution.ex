defmodule OrbitalDynamics.CampaignPlanner.RepairExecution do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    ContactIntentPressureBranches,
    DownlinkActivityNormalization,
    RepairActivityDispatch,
    RepairCandidateDiff,
    RepairCandidateInputs,
    RepairContactContentionResolutionPressure,
    RepairManeuverTransitions,
    RepairPolicySemantics,
    RepairRealizedState,
    RepairSourceReports,
    RepairStationPressure,
    ValueEncoding
  }

  def run(%{} = request, link_capacity_policy, source_resource_summaries) do
    planned_activities = planned_activities(request.prior_plan)

    source_candidates =
      RepairCandidateInputs.candidates(request.prior_plan, request.candidate_refresh)

    {candidates, station_calendar_report} =
      apply_station_calendar(source_candidates, request)

    context =
      repair_context(
        request,
        planned_activities,
        candidates,
        station_calendar_report,
        link_capacity_policy,
        source_resource_summaries
      )

    repaired =
      planned_activities
      |> Enum.sort_by(&activity_sort_key/1)
      |> Enum.reduce(initial_accumulator(), fn activity, acc ->
        RepairActivityDispatch.repair(activity, acc, context)
      end)
      |> RepairManeuverTransitions.mark_downstream_effects()

    %{
      planned_activities: planned_activities,
      candidates: candidates,
      station_calendar_report: station_calendar_report,
      activities: Enum.sort_by(repaired.activities, &activity_sort_key/1),
      deltas: Enum.sort_by(repaired.deltas, &{&1.activity_id, &1.status}),
      approval_requirements: Enum.sort_by(repaired.approval_requirements, & &1["activity_id"]),
      warnings: repaired.warnings
    }
  end

  defp planned_activities(prior_plan) do
    prior_plan
    |> Map.get("activities", [])
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.map(&DownlinkActivityNormalization.normalize/1)
  end

  defp apply_station_calendar(candidates, %{ground_network: nil}), do: {candidates, nil}

  defp apply_station_calendar(candidates, %{ground_network: ground_network} = request) do
    StationCalendar.overlay_contacts(candidates, ground_network,
      source: "repair.ground_network",
      approval_policy: request.approval_policy
    )
  end

  defp initial_accumulator do
    %{
      activities: [],
      deltas: [],
      approval_requirements: [],
      warnings: [],
      used_replacement_ids: MapSet.new(),
      delayed_maneuvers: []
    }
  end

  defp repair_context(
         request,
         planned_activities,
         candidates,
         station_calendar_report,
         link_capacity_policy,
         source_resource_summaries
       ) do
    %{
      candidates: candidates,
      planned_activities: planned_activities,
      current_epoch_s: request.current_epoch_s,
      remaining_horizon: request.remaining_horizon,
      realized_by_id: RepairRealizedState.activities_by_id(request.realized_state),
      degraded_modes:
        RepairPolicySemantics.degraded_modes_by_scenario(
          request.realized_state,
          request.repair_policy
        ),
      rejected_replacement_candidate_ids: RepairSourceReports.rejected_candidate_ids(request),
      selected_activity_ids: selected_activity_ids(planned_activities),
      repair_policy: request.repair_policy,
      scoring_policy: request.scoring_policy,
      link_capacity_policy: link_capacity_policy,
      source_resource_summaries: source_resource_summaries,
      candidate_diff_replacements: candidate_diff_replacements(request.candidate_refresh),
      contact_intent_pressure_by_candidate_id:
        contact_intent_pressure_by_candidate_id(request.candidate_refresh),
      contact_contention_resolution_group_ids_by_candidate_id:
        contact_contention_resolution_group_ids_by_candidate_id(request.candidate_refresh),
      station_pressure_sources_by_candidate_id:
        RepairStationPressure.sources_by_candidate_id(
          station_calendar_report,
          RepairSourceReports.contact_allocation(request.candidate_refresh)
        )
    }
  end

  defp contact_intent_pressure_by_candidate_id(nil), do: %{}

  defp contact_intent_pressure_by_candidate_id(%{} = candidate_refresh) do
    candidate_refresh
    |> RepairCandidateInputs.contact_intents()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&{&1, "campaign_repair.source_contact_intents"})
    |> ContactIntentPressureBranches.pressure_statuses_by_contact_id()
  end

  defp contact_contention_resolution_group_ids_by_candidate_id(candidate_refresh) do
    candidate_refresh
    |> RepairSourceReports.contact_contention_resolution()
    |> RepairContactContentionResolutionPressure.group_ids_by_candidate_id()
  end

  defp candidate_diff_replacements(nil), do: %{}

  defp candidate_diff_replacements(%{} = candidate_refresh) do
    RepairCandidateDiff.replacements(candidate_refresh)
  end

  defp selected_activity_ids(planned_activities) do
    planned_activities
    |> Enum.map(&ActivityIdentity.activity_id/1)
    |> MapSet.new()
  end

  defp activity_sort_key(activity) do
    {ActivityTiming.activity_start(activity), ActivityIdentity.activity_id(activity)}
  end
end
