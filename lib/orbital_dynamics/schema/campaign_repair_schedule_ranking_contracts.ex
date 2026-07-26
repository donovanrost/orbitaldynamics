defmodule OrbitalDynamics.Schema.CampaignRepairScheduleRankingContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    ScalarValues
  }

  alias OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @tolerance 1.0e-9
  def validate(issues, artifact) when is_map(artifact) do
    policy = Map.get(artifact, "scoring_policy", %{})

    churn_cost = numeric_policy_value(policy, "schedule_churn_cost_weight", 100.0)
    move_cost = numeric_policy_value(policy, "schedule_move_cost_weight", 0.01)

    source_candidates_by_id =
      artifact
      |> Map.get("source_candidate_activities", [])
      |> source_candidates_by_id()

    validate_activities(
      issues,
      Map.get(artifact, "activities", []),
      source_candidates_by_id,
      churn_cost,
      move_cost
    )
  end

  def validate(issues, _artifact), do: issues

  defp source_candidates_by_id(candidates) when is_list(candidates) do
    candidates
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&ActivityIdentity.activity_id/1)
  end

  defp source_candidates_by_id(_candidates), do: %{}

  defp validate_activities(
         issues,
         activities,
         source_candidates_by_id,
         churn_cost,
         move_cost
       )
       when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      {source_context, rows} =
        case activity do
          %{"repair" => %{"replacement_ranking" => %{"rows" => rows}} = repair} ->
            {Map.get(repair, "source_activity_context"), rows}

          _activity ->
            {nil, nil}
        end

      validate_rows(
        acc,
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        "$.activities[#{activity_index}].repair.source_activity_context",
        rows,
        source_context,
        source_candidates_by_id,
        churn_cost,
        move_cost
      )
    end)
  end

  defp validate_activities(
         issues,
         _activities,
         _source_candidates_by_id,
         _churn_cost,
         _move_cost
       ),
       do: issues

  defp validate_rows(
         issues,
         path,
         source_context_path,
         rows,
         source_context,
         source_candidates_by_id,
         churn_cost,
         move_cost
       )
       when is_list(rows) do
    issues =
      issues
      |> validate_current_source_context(source_context_path, rows, source_context)
      |> validate_current_row_order(path, rows, source_candidates_by_id)

    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(
        acc,
        "#{path}[#{index}]",
        row,
        source_context,
        source_candidates_by_id,
        churn_cost,
        move_cost
      )
    end)
  end

  defp validate_rows(
         issues,
         _path,
         _source_context_path,
         _rows,
         _source_context,
         _source_candidates_by_id,
         _churn_cost,
         _move_cost
       ),
       do: issues

  defp validate_current_source_context(issues, path, rows, source_context) do
    if CampaignRepairReplacementRankingVersion.current?(rows) and not is_map(source_context) do
      [error(path, "must be present on current replacement rankings") | issues]
    else
      issues
    end
  end

  defp validate_current_row_order(issues, path, rows, source_candidates_by_id) do
    if CampaignRepairReplacementRankingVersion.current?(rows) do
      sort_keys = Enum.map(rows, &row_sort_key(&1, source_candidates_by_id))

      if Enum.all?(sort_keys, &match?({:ok, _sort_key}, &1)) do
        replayed_sort_keys = Enum.map(sort_keys, fn {:ok, sort_key} -> sort_key end)

        if replayed_sort_keys == Enum.sort(replayed_sort_keys) do
          issues
        else
          [
            error(
              path,
              "must follow producer tie-break order by candidate-diff priority, ranking score, schedule churn, candidate start, and candidate ID"
            )
            | issues
          ]
        end
      else
        issues
      end
    else
      issues
    end
  end

  defp row_sort_key(%{} = row, source_candidates_by_id) do
    candidate_id = Map.get(row, "candidate_id")

    with priority when is_integer(priority) <- Map.get(row, "candidate_diff_priority"),
         score when is_number(score) <- Map.get(row, "ranking_score"),
         churn_s when is_number(churn_s) <- Map.get(row, "schedule_churn_s"),
         id when is_binary(id) <- candidate_id,
         [%{} = candidate] <- Map.get(source_candidates_by_id, candidate_id, []),
         candidate_start when is_number(candidate_start) <-
           ActivityTiming.activity_raw_start(candidate) do
      {:ok, {priority, -score, churn_s, candidate_start, id}}
    else
      _unreplayable -> :unreplayable
    end
  end

  defp row_sort_key(_row, _source_candidates_by_id), do: :unreplayable

  defp validate_row(
         issues,
         path,
         %{} = row,
         source_context,
         source_candidates_by_id,
         churn_cost,
         move_cost
       ) do
    churn_s = Map.get(row, "schedule_churn_s")

    issues
    |> validate_number(
      path <> ".schedule_churn_penalty",
      Map.get(row, "schedule_churn_penalty"),
      -churn_cost,
      "must equal negative schedule_churn_cost_weight"
    )
    |> validate_move_penalty(path, row, churn_s, move_cost)
    |> validate_churn_seconds(
      path,
      row,
      churn_s,
      source_context,
      source_candidates_by_id
    )
  end

  defp validate_row(
         issues,
         _path,
         _row,
         _source_context,
         _source_candidates_by_id,
         _churn_cost,
         _move_cost
       ),
       do: issues

  defp validate_move_penalty(issues, path, row, churn_s, move_cost)
       when is_number(churn_s) do
    validate_number(
      issues,
      path <> ".schedule_move_penalty",
      Map.get(row, "schedule_move_penalty"),
      -(churn_s * move_cost),
      "must equal negative schedule_churn_s times schedule_move_cost_weight"
    )
  end

  defp validate_move_penalty(issues, _path, _row, _churn_s, _move_cost), do: issues

  defp validate_churn_seconds(
         issues,
         path,
         row,
         actual,
         %{} = source_context,
         source_candidates_by_id
       )
       when is_number(actual) do
    candidate_id = Map.get(row, "candidate_id")

    with source_start when is_number(source_start) <-
           ActivityTiming.activity_raw_start(source_context),
         [%{} = candidate] <- Map.get(source_candidates_by_id, candidate_id, []),
         candidate_start when is_number(candidate_start) <-
           ActivityTiming.activity_raw_start(candidate) do
      validate_number(
        issues,
        path <> ".schedule_churn_s",
        actual,
        abs(candidate_start - source_start),
        "must equal absolute source-to-candidate start-time delta"
      )
    else
      _unreplayable -> issues
    end
  end

  defp validate_churn_seconds(
         issues,
         _path,
         _row,
         _actual,
         _source_context,
         _source_candidates_by_id
       ),
       do: issues

  defp validate_number(issues, _path, actual, expected, _message)
       when is_number(actual) and abs(actual - expected) <= @tolerance,
       do: issues

  defp validate_number(issues, path, actual, _expected, message) when is_number(actual),
    do: [error(path, message) | issues]

  defp validate_number(issues, _path, _actual, _expected, _message), do: issues

  defp numeric_policy_value(%{} = policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp numeric_policy_value(_policy, _key, default), do: default
end
