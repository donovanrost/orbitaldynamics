defmodule OrbitalDynamics.Schema.CampaignRepairCandidateValueContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityIdentity, ScalarValues}
  alias OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion
  alias OrbitalDynamics.Timeline

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    source_candidates_by_id =
      artifact
      |> Map.get("source_candidate_activities", [])
      |> source_candidates_by_id()

    source_plan_activities_by_id =
      artifact
      |> Map.get("source_timeline_feedback_report")
      |> source_plan_activities_by_id()

    validate_activities(
      issues,
      Map.get(artifact, "activities", []),
      source_candidates_by_id,
      source_plan_activities_by_id
    )
  end

  def validate(issues, _artifact), do: issues

  defp source_candidates_by_id(candidates) when is_list(candidates) do
    candidates
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&ActivityIdentity.activity_id/1)
  end

  defp source_candidates_by_id(_candidates), do: %{}

  defp source_plan_activities_by_id(%{"rows" => rows}) when is_list(rows) do
    rows
    |> Enum.flat_map(fn
      %{"planned_activity" => %{"id" => activity_id} = activity}
      when is_binary(activity_id) ->
        [activity]

      _row ->
        []
    end)
    |> Enum.group_by(&Map.get(&1, "id"))
  end

  defp source_plan_activities_by_id(_report), do: %{}

  defp validate_activities(
         issues,
         activities,
         source_candidates_by_id,
         source_plan_activities_by_id
       )
       when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      rows =
        case activity do
          %{"repair" => %{"replacement_ranking" => %{"rows" => rows}}} -> rows
          _activity -> nil
        end

      acc
      |> validate_rows(
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        rows,
        source_candidates_by_id
      )
      |> validate_current_selected_snapshot(
        "$.activities[#{activity_index}]",
        activity,
        rows,
        source_candidates_by_id
      )
      |> validate_current_source_context(
        "$.activities[#{activity_index}].repair.source_activity_context",
        activity,
        rows,
        source_plan_activities_by_id
      )
    end)
  end

  defp validate_activities(
         issues,
         _activities,
         _source_candidates_by_id,
         _source_plan_activities_by_id
       ),
       do: issues

  defp validate_rows(issues, path, rows, source_candidates_by_id) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(acc, "#{path}[#{index}]", row, source_candidates_by_id)
    end)
  end

  defp validate_rows(issues, _path, _rows, _source_candidates_by_id), do: issues

  defp validate_current_selected_snapshot(
         issues,
         path,
         %{} = activity,
         rows,
         source_candidates_by_id
       ) do
    if CampaignRepairReplacementRankingVersion.current?(rows) do
      activity_id = Map.get(activity, "id")

      case Map.get(source_candidates_by_id, activity_id, []) do
        [%{} = candidate] ->
          if base_snapshot(activity) == base_snapshot(candidate) do
            issues
          else
            [
              error(
                path,
                "must match the selected embedded source candidate snapshot outside repair metadata"
              )
              | issues
            ]
          end

        _missing_or_ambiguous_candidate ->
          issues
      end
    else
      issues
    end
  end

  defp validate_current_selected_snapshot(
         issues,
         _path,
         _activity,
         _rows,
         _source_candidates_by_id
       ),
       do: issues

  defp base_snapshot(activity), do: Map.delete(activity, "repair")

  defp validate_current_source_context(
         issues,
         path,
         %{
           "repair" => %{
             "source_activity_id" => source_activity_id,
             "source_activity_context" => %{} = source_context
           }
         },
         rows,
         source_plan_activities_by_id
       ) do
    if CampaignRepairReplacementRankingVersion.current?(rows) do
      case Map.get(source_plan_activities_by_id, source_activity_id, []) do
        [%{} = source_activity] ->
          if source_context == Timeline.activity_context(source_activity) do
            issues
          else
            [
              error(
                path,
                "must match the source-plan activity context projection"
              )
              | issues
            ]
          end

        _missing_or_ambiguous_source_activity ->
          issues
      end
    else
      issues
    end
  end

  defp validate_current_source_context(
         issues,
         _path,
         _activity,
         _rows,
         _source_plan_activities_by_id
       ),
       do: issues

  defp validate_row(issues, path, %{} = row, source_candidates_by_id) do
    candidate_id = Map.get(row, "candidate_id")

    case Map.get(source_candidates_by_id, candidate_id, []) do
      [%{} = candidate] ->
        source_score = ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0
        validate_score(issues, path, Map.get(row, "candidate_score"), source_score)

      [] ->
        [
          error(
            path <> ".candidate_id",
            "must identify exactly one embedded source candidate"
          )
          | issues
        ]

      _candidates ->
        [
          error(
            path <> ".candidate_id",
            "must identify exactly one embedded source candidate"
          )
          | issues
        ]
    end
  end

  defp validate_row(issues, _path, _row, _source_candidates_by_id), do: issues

  defp validate_score(issues, path, actual, expected) when is_number(actual) do
    if close?(actual, expected) do
      issues
    else
      [
        error(
          path <> ".candidate_score",
          "must match the exact embedded source candidate score"
        )
        | issues
      ]
    end
  end

  defp validate_score(issues, _path, _actual, _expected), do: issues

  defp close?(left, right), do: abs(left - right) <= @tolerance
end
