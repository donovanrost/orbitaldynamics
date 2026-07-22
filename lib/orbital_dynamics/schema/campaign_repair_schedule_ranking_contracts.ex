defmodule OrbitalDynamics.Schema.CampaignRepairScheduleRankingContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    ScalarValues
  }

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
         rows,
         source_context,
         source_candidates_by_id,
         churn_cost,
         move_cost
       )
       when is_list(rows) do
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
         _rows,
         _source_context,
         _source_candidates_by_id,
         _churn_cost,
         _move_cost
       ),
       do: issues

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
