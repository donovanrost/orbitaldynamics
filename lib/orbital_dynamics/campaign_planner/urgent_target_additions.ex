defmodule OrbitalDynamics.CampaignPlanner.UrgentTargetAdditions do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    CandidateDiffMetadata,
    EventFeasibilityContext,
    RepairCandidateDiff,
    ScalarValues,
    TargetObjectiveSchedule,
    UrgentTargetAdditionFields,
    UrgentTargetCandidateWindows,
    ValueEncoding
  }

  def stage(
        candidate_plan,
        warnings,
        event,
        branch,
        request,
        source_candidate_activities,
        candidate_diff_by_replacement_id
      ) do
    stage(
      candidate_plan,
      warnings,
      event,
      branch,
      request,
      source_candidate_activities,
      candidate_diff_by_replacement_id,
      callbacks()
    )
  end

  def stage(
        candidate_plan,
        warnings,
        event,
        branch,
        request,
        source_candidate_activities,
        candidate_diff_by_replacement_id,
        callbacks
      ) do
    scoped_target_observation_count = Keyword.fetch!(callbacks, :scoped_target_observation_count)
    target_id = event["target_id"] || event["id"] || "urgent_target"
    allow_placeholder? = Map.get(event, "allow_placeholder", true)
    required_observations = UrgentTargetAdditionFields.required_observations(event)
    planned_observations = scoped_target_observation_count.(candidate_plan["activities"], event)
    needed_observations = max(required_observations - planned_observations, 0)

    if needed_observations == 0 do
      {candidate_plan, warnings}
    else
      candidate_plan
      |> additions(
        event,
        branch,
        request,
        source_candidate_activities,
        %{
          "target_id" => target_id,
          "required_observations" => required_observations,
          "planned_observations" => planned_observations,
          "needed_observations" => needed_observations,
          "allow_placeholder" => allow_placeholder?,
          "candidate_diff_by_replacement_id" => candidate_diff_by_replacement_id
        },
        callbacks
      )
      |> apply_additions(candidate_plan, warnings)
    end
  end

  defp additions(
         candidate_plan,
         event,
         branch,
         request,
         source_candidate_activities,
         context,
         callbacks
       ) do
    event_priority = Keyword.fetch!(callbacks, :event_priority)
    urgent_target_candidate_windows = Keyword.fetch!(callbacks, :urgent_target_candidate_windows)
    within_remaining_horizon? = Keyword.fetch!(callbacks, :within_remaining_horizon?)
    default_strategy_horizon = Keyword.fetch!(callbacks, :default_strategy_horizon)
    overlaps? = Keyword.fetch!(callbacks, :overlaps?)
    urgent_target_spacecraft_match? = Keyword.fetch!(callbacks, :urgent_target_spacecraft_match?)

    select_non_overlapping_candidates =
      Keyword.fetch!(callbacks, :select_non_overlapping_candidates)

    target_id = context["target_id"]
    priority = event_priority.(event, 10.0)
    needed_observations = context["needed_observations"]
    remaining_horizon = request.remaining_horizon || default_strategy_horizon.(request)

    selected =
      event
      |> urgent_target_candidate_windows.(request, source_candidate_activities)
      |> Enum.filter(&within_remaining_horizon?.(&1, remaining_horizon))
      |> Enum.reject(fn activity ->
        Enum.any?(candidate_plan["activities"], &overlaps?.(activity, &1))
      end)
      |> Enum.filter(&urgent_target_spacecraft_match?.(&1, event))
      |> sort_candidates(priority, callbacks)
      |> select_non_overlapping_candidates.(candidate_plan["activities"], needed_observations)

    additions =
      selected
      |> Enum.with_index(1)
      |> Enum.map(fn {candidate, index} ->
        validated_addition(candidate, event, branch, context, index, length(selected), callbacks)
      end)

    missing_count = needed_observations - length(additions)

    cond do
      missing_count <= 0 ->
        {:ok, additions, []}

      context["allow_placeholder"] ->
        placeholder_index = length(additions) + 1
        placeholder_count = if needed_observations == 1, do: 1, else: needed_observations

        placeholder =
          event
          |> placeholder(
            branch,
            request,
            context,
            placeholder_index,
            placeholder_count,
            callbacks
          )
          |> placeholder_addition(
            event,
            context,
            placeholder_index,
            "no_validated_candidate_window",
            callbacks
          )

        warning =
          UrgentTargetAdditionFields.warning(
            target_id,
            missing_count,
            "staged as unvalidated placeholder"
          )

        {:ok, additions ++ [placeholder], [warning]}

      true ->
        warning =
          UrgentTargetAdditionFields.warning(
            target_id,
            missing_count,
            "not staged: no_validated_candidate_window"
          )

        {:ok, additions, [warning]}
    end
  end

  defp apply_additions({:ok, [], extra_warnings}, candidate_plan, warnings),
    do: {candidate_plan, extra_warnings ++ warnings}

  defp apply_additions({:ok, additions, extra_warnings}, candidate_plan, warnings) do
    candidate_plan =
      candidate_plan
      |> Map.update!("activities", &(additions ++ &1))
      |> Map.update!("strategic_additions", &(additions ++ &1))

    {candidate_plan, extra_warnings ++ warnings}
  end

  defp validated_addition(candidate, event, branch, context, index, selected_count, callbacks) do
    event_priority = Keyword.fetch!(callbacks, :event_priority)
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_end = Keyword.fetch!(callbacks, :activity_end)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    candidate_score = Keyword.fetch!(callbacks, :candidate_score)
    candidate_diff_for_replacement = Keyword.fetch!(callbacks, :candidate_diff_for_replacement)
    maybe_put_candidate_diff = Keyword.fetch!(callbacks, :maybe_put_candidate_diff)
    put_repair_metadata = Keyword.fetch!(callbacks, :put_repair_metadata)
    target_id = context["target_id"]
    priority = event_priority.(event, 10.0)
    duration_s = activity_end.(candidate) - activity_start.(candidate)
    candidate_diff = candidate_diff_for_replacement.(candidate, context)

    scoring_policy =
      Map.get(branch, "policy_overrides", %{}) |> Map.get("scoring_policy", %{})

    target_weight = numeric_policy_value.(scoring_policy, "target_value_weight", 1.0)
    score = max(candidate_score.(candidate), priority * duration_s * target_weight)
    source = Map.get(candidate, "source_window", %{"type" => "candidate_activity"})

    feasibility =
      %{
        "status" => "validated_candidate_window",
        "target_id" => target_id,
        "selected_scenario_id" => candidate["scenario_id"],
        "source_window" => source,
        "requires_approval" => true,
        "required_observations" => context["required_observations"],
        "planned_observations" => context["planned_observations"],
        "staged_observation_index" => index
      }
      |> Map.merge(EventFeasibilityContext.build(event))
      |> maybe_put_candidate_diff.(candidate_diff)

    candidate
    |> Map.put(
      "id",
      UrgentTargetAdditionFields.activity_id(event, branch, target_id, index, selected_count)
    )
    |> Map.put("type", "observe")
    |> Map.put("target_id", target_id)
    |> Map.put("score", score)
    |> Map.put("score_terms", %{"urgent_target_value" => score})
    |> Map.put("metadata", UrgentTargetAdditionFields.metadata(event, priority, context, index))
    |> put_repair_metadata.(
      %{
        "action" => "strategic_addition",
        "reason" => UrgentTargetAdditionFields.addition_reason(event),
        "requires_approval" => true
      }
      |> maybe_put_candidate_diff.(candidate_diff)
    )
    |> put_in(["feasibility"], feasibility)
  end

  defp placeholder_addition(activity, event, context, index, reason, callbacks) do
    put_repair_metadata = Keyword.fetch!(callbacks, :put_repair_metadata)

    activity
    |> put_repair_metadata.(%{
      "action" => "strategic_addition",
      "reason" => reason,
      "requires_approval" => true
    })
    |> put_in(
      ["feasibility"],
      %{
        "status" => "unvalidated_placeholder",
        "target_id" => context["target_id"],
        "selected_scenario_id" => activity["scenario_id"],
        "source_window" => activity["source_window"],
        "requires_approval" => true,
        "reason" => reason,
        "required_observations" => context["required_observations"],
        "planned_observations" => context["planned_observations"],
        "staged_observation_index" => index
      }
      |> Map.merge(EventFeasibilityContext.build(event))
    )
  end

  defp sort_candidates(candidates, priority, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    candidate_score = Keyword.fetch!(callbacks, :candidate_score)
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_id = Keyword.fetch!(callbacks, :activity_id)

    Enum.sort_by(candidates, fn candidate ->
      overlap_s = numeric_or_nil.(Map.get(candidate, "eclipse_overlap_s")) || 0.0

      {-priority, -candidate_score.(candidate), overlap_s, activity_start.(candidate),
       activity_id.(candidate)}
    end)
  end

  defp placeholder(event, branch, request, context, index, selected_count, callbacks) do
    event_priority = Keyword.fetch!(callbacks, :event_priority)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    first_scenario_id = Keyword.fetch!(callbacks, :first_scenario_id)
    target_id = context["target_id"]
    priority = event_priority.(event, 10.0)

    starts_at_s =
      numeric_or_nil.(event["starts_at_s"]) ||
        Map.get(request.remaining_horizon, "starts_at_s", 0.0)

    ends_at_s =
      numeric_or_nil.(event["ends_at_s"]) ||
        starts_at_s + (numeric_or_nil.(Map.get(event, "duration_s")) || 60.0)

    duration_s = ends_at_s - starts_at_s
    scoring_policy = Map.get(branch, "policy_overrides", %{}) |> Map.get("scoring_policy", %{})
    target_weight = numeric_policy_value.(scoring_policy, "target_value_weight", 1.0)
    score = priority * duration_s * target_weight

    %{
      "id" =>
        UrgentTargetAdditionFields.activity_id(event, branch, target_id, index, selected_count),
      "type" => "observe",
      "scenario_id" => event["scenario_id"] || first_scenario_id.(request),
      "target_id" => target_id,
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => duration_s,
      "score" => score,
      "score_terms" => %{"urgent_target_value" => score},
      "source_window" => %{"type" => "unvalidated_urgent_placeholder"},
      "metadata" => UrgentTargetAdditionFields.metadata(event, priority, context, index)
    }
  end

  defp callbacks do
    [
      event_priority: &event_priority/2,
      scoped_target_observation_count: &TargetObjectiveSchedule.scoped_observation_count/2,
      urgent_target_candidate_windows: &UrgentTargetCandidateWindows.windows/3,
      within_remaining_horizon?: &ActivityTiming.within_remaining_horizon?/2,
      default_strategy_horizon: &default_strategy_horizon/1,
      overlaps?: &ActivityTiming.overlaps?/2,
      urgent_target_spacecraft_match?: &UrgentTargetCandidateWindows.spacecraft_match?/2,
      select_non_overlapping_candidates: &select_non_overlapping_candidates/3,
      candidate_diff_for_replacement: &candidate_diff_for_replacement/2,
      numeric_policy_value: &numeric_policy_value/3,
      candidate_score: &candidate_score/1,
      activity_start: &ActivityTiming.activity_start/1,
      activity_end: &ActivityTiming.activity_end/1,
      activity_id: &ActivityIdentity.activity_id/1,
      put_repair_metadata: &put_repair_metadata/2,
      maybe_put_candidate_diff: &maybe_put_candidate_diff/2,
      first_scenario_id: &first_scenario_id/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]
  end

  defp default_strategy_horizon(request) do
    ActivityTiming.remaining_horizon(
      request.prior_plan,
      request.remaining_horizon,
      request.current_epoch_s
    )
  end

  defp select_non_overlapping_candidates(candidates, occupied_activities, needed_count) do
    candidates
    |> Enum.reduce_while({[], occupied_activities}, fn candidate, {selected, occupied} ->
      cond do
        length(selected) >= needed_count ->
          {:halt, {selected, occupied}}

        Enum.any?(occupied, &ActivityTiming.overlaps?(&1, candidate)) ->
          {:cont, {selected, occupied}}

        true ->
          {:cont, {[candidate | selected], [candidate | occupied]}}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp candidate_diff_for_replacement(candidate, context) do
    context
    |> Map.get("candidate_diff_by_replacement_id", %{})
    |> Map.get(ActivityIdentity.activity_id(candidate))
    |> candidate_diff_match("replacement")
  end

  defp candidate_diff_match(nil, _scope), do: nil
  defp candidate_diff_match([], _scope), do: nil
  defp candidate_diff_match(%{} = row, _scope), do: row
  defp candidate_diff_match([row], _scope), do: row

  defp candidate_diff_match(rows, scope) when is_list(rows) do
    RepairCandidateDiff.match(rows, scope)
  end

  defp maybe_put_candidate_diff(metadata, nil), do: metadata
  defp maybe_put_candidate_diff(metadata, row), do: CandidateDiffMetadata.put(metadata, row)

  defp put_repair_metadata(activity, metadata) do
    Map.update(activity, "repair", metadata, &Map.merge(&1, metadata))
  end

  defp first_scenario_id(request) do
    request.prior_plan
    |> Map.get("activities", [])
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.find_value(& &1["scenario_id"]) || "unspecified_spacecraft"
  end

  defp event_priority(event, default),
    do: ScalarValues.numeric_or_nil(Map.get(event, "priority")) || default

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0
end
