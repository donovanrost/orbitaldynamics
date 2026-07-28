defmodule OrbitalDynamics.Schema.CampaignRepairReplacementCompletenessContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    RepairPolicySemantics,
    RepairReplacementIntent,
    RepairSourceReports
  }

  alias OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_policy_list_fields [
    "degraded_payload_activity_types",
    "command_health_activity_types"
  ]

  def validate(issues, %{} = artifact) do
    source_candidates = Map.get(artifact, "source_candidate_activities", [])

    {degraded_modes, repair_policy} =
      degraded_context(
        Map.get(artifact, "realized_state_snapshot"),
        Map.get(artifact, "repair_policy")
      )

    issues
    |> validate_isolated_ranking_completeness(
      artifact,
      source_candidates,
      degraded_modes,
      repair_policy
    )
    |> validate_multi_ranking_completeness(
      artifact,
      source_candidates,
      degraded_modes,
      repair_policy
    )
  end

  def validate(issues, _artifact), do: issues

  defp degraded_context(%{} = realized_state, %{} = repair_policy) do
    spacecraft_states = Map.get(realized_state, "spacecraft_states", [])

    if is_list(spacecraft_states) and Enum.all?(spacecraft_states, &is_map/1) and
         valid_repair_policy_lists?(repair_policy) do
      repair_policy = RepairPolicySemantics.normalize(repair_policy)

      {
        RepairPolicySemantics.degraded_modes_by_scenario(realized_state, repair_policy),
        repair_policy
      }
    else
      {%{}, nil}
    end
  end

  defp degraded_context(_realized_state, _repair_policy), do: {%{}, nil}

  defp valid_repair_policy_lists?(repair_policy) do
    Enum.all?(@repair_policy_list_fields, fn field ->
      not Map.has_key?(repair_policy, field) or is_list(Map.get(repair_policy, field))
    end)
  end

  defp ranking_context(
         %{
           "repair" => %{
             "source_activity_context" => source_context,
             "replacement_ranking" => %{"rows" => rows}
           }
         } = activity
       ),
       do: {get_in(activity, ["repair", "source_activity_id"]), source_context, rows}

  defp ranking_context(_activity), do: {nil, nil, nil}

  defp validate_isolated_ranking_completeness(
         issues,
         artifact,
         source_candidates,
         degraded_modes,
         repair_policy
       ) do
    with {:ok, path, source_activity_id, source_context, rows, remaining_horizon, current_epoch_s} <-
           isolated_ranking_context(artifact, repair_policy),
         {:ok, source_plan_context} <-
           source_plan_context(artifact, [source_activity_id]),
         true <- replayable_source_candidates?(source_candidates),
         {:ok, rejected_candidate_ids} <- rejected_candidate_ids(artifact) do
      expected_candidate_ids =
        eligible_candidate_ids(
          source_candidates,
          source_plan_context.activity_ids,
          source_context,
          remaining_horizon,
          current_epoch_s,
          degraded_modes,
          repair_policy,
          rejected_candidate_ids,
          [],
          MapSet.new()
        )

      validate_complete_candidate_ids(issues, path, rows, expected_candidate_ids)
    else
      _not_replayable -> issues
    end
  end

  defp validate_multi_ranking_completeness(
         issues,
         artifact,
         source_candidates,
         degraded_modes,
         repair_policy
       ) do
    with {:ok, source_plan_context} <- source_plan_context(artifact, []),
         true <- replayable_source_candidates?(source_candidates),
         {:ok, rejected_candidate_ids} <- rejected_candidate_ids(artifact),
         {:ok, output_contexts, ranking_contexts, remaining_horizon, current_epoch_s} <-
           multi_ranking_context(artifact, source_plan_context, repair_policy) do
      Enum.reduce(ranking_contexts, issues, fn ranking, acc ->
        prior_output_contexts =
          Enum.filter(
            output_contexts,
            &(&1.source_sort_key < ranking.source_sort_key)
          )

        accumulator_activities = Enum.map(prior_output_contexts, & &1.activity)

        used_replacement_ids =
          prior_output_contexts
          |> Enum.filter(&replacement_output?/1)
          |> Enum.map(&ActivityIdentity.activity_id(&1.activity))
          |> MapSet.new()

        expected_candidate_ids =
          eligible_candidate_ids(
            source_candidates,
            source_plan_context.activity_ids,
            ranking.source_context,
            remaining_horizon,
            current_epoch_s,
            degraded_modes,
            repair_policy,
            rejected_candidate_ids,
            accumulator_activities,
            used_replacement_ids
          )

        validate_complete_candidate_ids(
          acc,
          ranking.path,
          ranking.rows,
          expected_candidate_ids
        )
      end)
    else
      _not_replayable -> issues
    end
  end

  defp isolated_ranking_context(artifact, repair_policy) do
    case {
      Map.get(artifact, "activities"),
      Map.get(artifact, "deltas"),
      Map.get(artifact, "preserved_activities"),
      Map.get(artifact, "remaining_horizon"),
      Map.get(artifact, "current_epoch_s")
    } do
      {[%{} = activity], [%{} = delta], [],
       %{"starts_at_s" => horizon_start, "ends_at_s" => horizon_end} = remaining_horizon,
       current_epoch_s}
      when is_number(horizon_start) and is_number(horizon_end) and
             is_number(current_epoch_s) and not is_nil(repair_policy) ->
        {source_activity_id, source_context, rows} = ranking_context(activity)

        if is_binary(source_activity_id) and Map.get(delta, "activity_id") == source_activity_id and
             is_map(source_context) and is_list(rows) and Enum.all?(rows, &is_map/1) and
             CampaignRepairReplacementRankingVersion.current?(rows) do
          {:ok, "$.activities[0].repair.replacement_ranking.rows", source_activity_id,
           source_context, rows, remaining_horizon, current_epoch_s}
        else
          :not_replayable
        end

      _other ->
        :not_replayable
    end
  end

  defp replayable_source_candidates?(candidates) when is_list(candidates) do
    Enum.all?(candidates, fn
      %{} = candidate ->
        is_binary(Map.get(candidate, "id")) and
          is_number(Map.get(candidate, "starts_at_s")) and
          is_number(Map.get(candidate, "ends_at_s"))

      _candidate ->
        false
    end)
  end

  defp replayable_source_candidates?(_candidates), do: false

  defp source_plan_context(artifact, required_source_activity_ids) do
    case Map.get(artifact, "source_timeline_feedback_report") do
      %{"planned_count" => planned_count, "rows" => rows}
      when is_integer(planned_count) and planned_count >= 0 and is_list(rows) ->
        planned_activities =
          Enum.flat_map(rows, fn
            %{"planned_activity" => %{"id" => activity_id} = planned_activity}
            when is_binary(activity_id) ->
              [planned_activity]

            _row ->
              []
          end)

        planned_activity_ids = Enum.map(planned_activities, &Map.get(&1, "id"))
        selected_activity_ids = MapSet.new(planned_activity_ids)

        if length(planned_activities) == planned_count and
             MapSet.size(selected_activity_ids) == planned_count and
             Enum.all?(required_source_activity_ids, &MapSet.member?(selected_activity_ids, &1)) do
          {:ok,
           %{
             activities: planned_activities,
             activity_ids: selected_activity_ids
           }}
        else
          :not_replayable
        end

      _report ->
        :not_replayable
    end
  end

  defp multi_ranking_context(artifact, source_plan_context, repair_policy) do
    with activities when is_list(activities) <- Map.get(artifact, "activities"),
         true <- activities != [],
         true <- length(source_plan_context.activities) > 1,
         %{"starts_at_s" => horizon_start, "ends_at_s" => horizon_end} = remaining_horizon
         when is_number(horizon_start) and is_number(horizon_end) <-
           Map.get(artifact, "remaining_horizon"),
         current_epoch_s when is_number(current_epoch_s) <-
           Map.get(artifact, "current_epoch_s"),
         true <- not is_nil(repair_policy),
         true <- replayable_source_plan_activities?(source_plan_context.activities),
         {:ok, output_contexts} <- output_contexts(activities, source_plan_context),
         {:ok, ranking_contexts} <- current_multi_ranking_contexts(output_contexts),
         true <- ranking_contexts != [] do
      {:ok, output_contexts, ranking_contexts, remaining_horizon, current_epoch_s}
    else
      _not_replayable -> :not_replayable
    end
  end

  defp replayable_source_plan_activities?(activities) do
    Enum.all?(activities, fn activity ->
      is_number(ActivityTiming.activity_raw_start(activity)) and
        is_number(ActivityTiming.activity_raw_end(activity))
    end)
  end

  defp output_contexts(activities, source_plan_context) do
    source_activities_by_id = Map.new(source_plan_context.activities, &{Map.get(&1, "id"), &1})

    result =
      activities
      |> Enum.with_index()
      |> Enum.reduce_while({:ok, []}, fn
        {%{} = activity, activity_index}, {:ok, acc} ->
          source_activity_id = output_source_activity_id(activity)

          case Map.fetch(source_activities_by_id, source_activity_id) do
            {:ok, source_activity} ->
              if replayable_output_activity?(activity) do
                output_context = %{
                  activity: activity,
                  activity_index: activity_index,
                  source_activity_id: source_activity_id,
                  source_sort_key: activity_sort_key(source_activity)
                }

                {:cont, {:ok, [output_context | acc]}}
              else
                {:halt, :not_replayable}
              end

            :error ->
              {:halt, :not_replayable}
          end

        {_activity, _activity_index}, _acc ->
          {:halt, :not_replayable}
      end)

    case result do
      {:ok, reversed_output_contexts} ->
        output_contexts = Enum.reverse(reversed_output_contexts)
        source_activity_ids = Enum.map(output_contexts, & &1.source_activity_id)

        if length(Enum.uniq(source_activity_ids)) == length(source_activity_ids) do
          {:ok, output_contexts}
        else
          :not_replayable
        end

      :not_replayable ->
        :not_replayable
    end
  end

  defp replayable_output_activity?(activity) do
    is_binary(Map.get(activity, "id")) and
      is_number(Map.get(activity, "starts_at_s")) and
      is_number(Map.get(activity, "ends_at_s"))
  end

  defp output_source_activity_id(activity) do
    case Map.get(activity, "repair") do
      %{"action" => action, "source_activity_id" => source_activity_id}
      when action in ["moved", "replaced"] and is_binary(source_activity_id) ->
        source_activity_id

      _repair ->
        Map.get(activity, "id")
    end
  end

  defp current_multi_ranking_contexts(output_contexts) do
    result =
      Enum.reduce_while(output_contexts, {:ok, []}, fn output_context, {:ok, acc} ->
        case get_in(output_context.activity, ["repair", "replacement_ranking"]) do
          nil ->
            {:cont, {:ok, acc}}

          %{} ->
            {source_activity_id, source_context, rows} =
              ranking_context(output_context.activity)

            if source_activity_id == output_context.source_activity_id and
                 is_map(source_context) and is_list(rows) and Enum.all?(rows, &is_map/1) and
                 CampaignRepairReplacementRankingVersion.current?(rows) do
              ranking = %{
                path:
                  "$.activities[#{output_context.activity_index}].repair.replacement_ranking.rows",
                rows: rows,
                source_context: source_context,
                source_sort_key: output_context.source_sort_key
              }

              {:cont, {:ok, [ranking | acc]}}
            else
              {:halt, :not_replayable}
            end

          _ranking ->
            {:halt, :not_replayable}
        end
      end)

    case result do
      {:ok, ranking_contexts} -> {:ok, Enum.reverse(ranking_contexts)}
      :not_replayable -> :not_replayable
    end
  end

  defp replacement_output?(output_context) do
    case Map.get(output_context.activity, "repair") do
      %{"action" => action, "source_activity_id" => source_activity_id}
      when action in ["moved", "replaced"] and is_binary(source_activity_id) ->
        true

      _repair ->
        false
    end
  end

  defp activity_sort_key(activity) do
    {ActivityTiming.activity_start(activity), ActivityIdentity.activity_id(activity)}
  end

  defp rejected_candidate_ids(artifact) do
    case Map.get(artifact, "source_candidate_rejection_report") do
      nil ->
        {:ok, MapSet.new()}

      %{"rows" => rows} = report when is_list(rows) ->
        if Enum.all?(rows, &is_map/1) do
          rejected_candidate_ids =
            [report]
            |> RepairSourceReports.candidate_rejection_rejected_candidate_ids()
            |> MapSet.new()

          {:ok, rejected_candidate_ids}
        else
          :not_replayable
        end

      _report ->
        :not_replayable
    end
  end

  defp eligible_candidate_ids(
         source_candidates,
         selected_activity_ids,
         source_context,
         remaining_horizon,
         current_epoch_s,
         degraded_modes,
         repair_policy,
         rejected_candidate_ids,
         accumulator_activities,
         used_replacement_ids
       ) do
    source_candidates
    |> Enum.reject(&MapSet.member?(selected_activity_ids, ActivityIdentity.activity_id(&1)))
    |> Enum.reject(&MapSet.member?(used_replacement_ids, ActivityIdentity.activity_id(&1)))
    |> Enum.filter(&RepairReplacementIntent.eligible?(source_context, &1))
    |> Enum.filter(fn candidate ->
      ActivityTiming.within_remaining_horizon?(candidate, remaining_horizon)
    end)
    |> Enum.filter(fn candidate ->
      ActivityTiming.activity_start(candidate) >= current_epoch_s
    end)
    |> Enum.reject(fn candidate ->
      RepairPolicySemantics.degraded_incompatible?(candidate, degraded_modes, repair_policy)
    end)
    |> Enum.reject(fn candidate ->
      MapSet.member?(rejected_candidate_ids, ActivityIdentity.activity_id(candidate))
    end)
    |> Enum.reject(fn candidate ->
      Enum.any?(accumulator_activities, &ActivityTiming.overlaps?(candidate, &1))
    end)
    |> Enum.group_by(&ActivityIdentity.activity_id/1)
    |> Enum.flat_map(fn
      {candidate_id, [_candidate]} -> [candidate_id]
      {_candidate_id, _duplicate_candidates} -> []
    end)
    |> Enum.sort()
  end

  defp validate_complete_candidate_ids(issues, path, rows, expected_candidate_ids) do
    ranked_candidate_ids =
      rows
      |> Enum.map(&Map.get(&1, "candidate_id"))
      |> Enum.sort()

    if ranked_candidate_ids == expected_candidate_ids do
      issues
    else
      [
        error(
          path,
          "must contain exactly the uniquely identified viable source candidates in the replayable repair intent"
        )
        | issues
      ]
    end
  end
end
