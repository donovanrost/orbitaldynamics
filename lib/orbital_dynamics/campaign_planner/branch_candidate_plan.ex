defmodule OrbitalDynamics.CampaignPlanner.BranchCandidatePlan do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    BranchRefreshGroundNetwork,
    CandidateDiffReplacementAddition,
    DownlinkCompletionStaging,
    PriorActivityContext,
    RepairCandidateDiff,
    UrgentTargetAdditions,
    ValueEncoding
  }

  defp branch_event_invalid?(event, reason) do
    reason in List.wrap(Map.get(event, "invalid_branch_event_input_reasons", []))
  end

  def build(repair_result, branch, request, deps) do
    source_candidate_activities = Map.get(repair_result, "source_candidate_activities", [])

    candidate_diff_by_replacement_id =
      repair_result
      |> Map.get("source_candidate_diff_report")
      |> candidate_diff_replacements_by_replacement_id()

    initial = %{
      "activities" => Map.get(repair_result, "activities", []),
      "strategic_additions" => [],
      "removed_activity_ids" => [],
      "capacity_adjustments" => []
    }

    Enum.reduce(branch["events"], {initial, []}, fn event, {candidate_plan, warnings} ->
      case event["type"] do
        type
        when type in [
               "urgent_target",
               "observation_success_feedback",
               "target_priority_feedback"
             ] ->
          stage_urgent_target(
            candidate_plan,
            warnings,
            event,
            branch,
            request,
            source_candidate_activities,
            candidate_diff_by_replacement_id
          )

        "downlink_completion_gap" ->
          stage_downlink_completion(
            candidate_plan,
            warnings,
            event,
            request,
            source_candidate_activities,
            candidate_diff_by_replacement_id
          )

        "candidate_diff_replacement" ->
          stage_candidate_diff_replacement(
            candidate_plan,
            warnings,
            event,
            request,
            source_candidate_activities,
            candidate_diff_by_replacement_id
          )

        "reduced_downlink_capacity" ->
          if branch_event_invalid?(event, "invalid_capacity_fraction") do
            {candidate_plan, warnings}
          else
            capacity_fraction = BranchRefreshGroundNetwork.ground_network_capacity_fraction(event)

            adjustment = %{
              "type" => "reduced_downlink_capacity",
              "ground_station_id" => Keyword.fetch!(deps, :event_ground_station_id).(event),
              "capacity_fraction" => capacity_fraction,
              "starts_at_s" => event["starts_at_s"],
              "ends_at_s" => event["ends_at_s"]
            }

            {Map.update!(candidate_plan, "capacity_adjustments", &[adjustment | &1]), warnings}
          end

        _type ->
          {candidate_plan, warnings}
      end
    end)
    |> then(fn {candidate_plan, warnings} ->
      {
        candidate_plan
        |> Map.update!(
          "activities",
          &Enum.sort_by(&1, fn activity ->
            {ActivityTiming.activity_start(activity), ActivityIdentity.activity_id(activity)}
          end)
        )
        |> Map.update!(
          "strategic_additions",
          &Enum.sort_by(&1, fn activity -> ActivityIdentity.activity_id(activity) end)
        )
        |> Map.update!("capacity_adjustments", &Enum.reverse/1),
        warnings
      }
    end)
  end

  defp stage_candidate_diff_replacement(
         candidate_plan,
         warnings,
         event,
         request,
         source_candidate_activities,
         candidate_diff_by_replacement_id
       ) do
    replacement_id = event["replacement_candidate_id"]

    replacement =
      (source_candidate_activities ++
         PriorActivityContext.candidate_activities(request.prior_plan))
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> dedupe_by_id()
      |> Enum.find(&(ActivityIdentity.activity_id(&1) == replacement_id))

    cond do
      replacement_id in [nil, ""] ->
        {candidate_plan,
         ["candidate diff replacement not staged: missing replacement id" | warnings]}

      is_nil(replacement) ->
        {candidate_plan,
         [
           "candidate diff replacement #{replacement_id} not staged: no validated replacement candidate"
           | warnings
         ]}

      Enum.any?(
        candidate_plan["activities"],
        &(ActivityIdentity.activity_id(&1) == replacement_id)
      ) ->
        {candidate_plan, warnings}

      Enum.any?(candidate_plan["activities"], &ActivityTiming.overlaps?(replacement, &1)) ->
        {candidate_plan,
         [
           "candidate diff replacement #{replacement_id} not staged: overlaps existing activity"
           | warnings
         ]}

      true ->
        candidate_diff =
          case Map.get(event, "source_candidate_diff") do
            %{} = source ->
              source

            _source ->
              candidate_diff_for_replacement(replacement, candidate_diff_by_replacement_id)
          end

        addition = CandidateDiffReplacementAddition.build(replacement, event, candidate_diff)

        candidate_plan =
          candidate_plan
          |> Map.update!("activities", &([addition] ++ &1))
          |> Map.update!("strategic_additions", &([addition] ++ &1))

        {candidate_plan, warnings}
    end
  end

  defp stage_urgent_target(
         candidate_plan,
         warnings,
         event,
         branch,
         request,
         source_candidate_activities,
         candidate_diff_by_replacement_id
       ) do
    UrgentTargetAdditions.stage(
      candidate_plan,
      warnings,
      event,
      branch,
      request,
      source_candidate_activities,
      candidate_diff_by_replacement_id
    )
  end

  defp stage_downlink_completion(
         candidate_plan,
         warnings,
         event,
         request,
         source_candidate_activities,
         candidate_diff_by_replacement_id
       ) do
    DownlinkCompletionStaging.stage(
      candidate_plan,
      warnings,
      event,
      request,
      source_candidate_activities,
      candidate_diff_by_replacement_id
    )
  end

  defp dedupe_by_id(items) do
    items
    |> Map.new(&{&1["id"], &1})
    |> Map.values()
    |> Enum.sort_by(& &1["id"])
  end

  defp candidate_diff_for_replacement(candidate, context) do
    context
    |> Map.get("candidate_diff_by_replacement_id", %{})
    |> Map.get(ActivityIdentity.activity_id(candidate))
    |> RepairCandidateDiff.match("replacement")
  end

  defp candidate_diff_replacements_by_replacement_id(nil), do: %{}

  defp candidate_diff_replacements_by_replacement_id(%{} = report) do
    RepairCandidateDiff.replacements_by_replacement_id(report)
  end
end
