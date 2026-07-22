defmodule OrbitalDynamics.Schema.CampaignRepairCandidateDiffRankingContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    RepairActivityIdentity,
    RepairCandidateDiff
  }

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, artifact) when is_map(artifact) do
    replacement_rows = replacement_rows(Map.get(artifact, "source_candidate_diff_report"))

    validate_activities(issues, Map.get(artifact, "activities", []), replacement_rows)
  end

  def validate(issues, _artifact), do: issues

  defp replacement_rows(%{"invalidated_candidates" => rows} = report)
       when is_list(rows) do
    report
    |> Map.put("invalidated_candidates", Enum.filter(rows, &is_map/1))
    |> RepairCandidateDiff.replacement_rows()
  end

  defp replacement_rows(_report), do: []

  defp validate_activities(issues, activities, replacement_rows) when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      {source_activity_id, source_window_id, rows} = ranking_context(activity)

      validate_rows(
        acc,
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        rows,
        replacement_rows,
        source_activity_id,
        source_window_id
      )
    end)
  end

  defp validate_activities(issues, _activities, _replacement_rows), do: issues

  defp ranking_context(%{
         "repair" => %{"replacement_ranking" => %{"rows" => rows}} = repair
       }) do
    source_context = Map.get(repair, "source_activity_context")

    source_window_id =
      if is_map(source_context), do: RepairActivityIdentity.source_window_id(source_context)

    {Map.get(repair, "source_activity_id"), source_window_id, rows}
  end

  defp ranking_context(_activity), do: {nil, nil, nil}

  defp validate_rows(
         issues,
         path,
         rows,
         replacement_rows,
         source_activity_id,
         source_window_id
       )
       when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(
        acc,
        "#{path}[#{index}]",
        row,
        replacement_rows,
        source_activity_id,
        source_window_id
      )
    end)
  end

  defp validate_rows(
         issues,
         _path,
         _rows,
         _replacement_rows,
         _source_activity_id,
         _source_window_id
       ),
       do: issues

  defp validate_row(
         issues,
         path,
         %{} = row,
         replacement_rows,
         source_activity_id,
         source_window_id
       ) do
    expected =
      Enum.any?(replacement_rows, fn replacement ->
        replacement["replacement_candidate_id"] == row["candidate_id"] and
          (replacement["id"] == source_activity_id or
             (not is_nil(source_window_id) and
                replacement["source_window_id"] == source_window_id))
      end)

    case Map.get(row, "semantic_candidate_diff_match") do
      actual when is_boolean(actual) and actual != expected ->
        [
          error(
            path <> ".semantic_candidate_diff_match",
            "must match embedded source candidate-diff replacement evidence"
          )
          | issues
        ]

      _actual ->
        issues
    end
  end

  defp validate_row(
         issues,
         _path,
         _row,
         _replacement_rows,
         _source_activity_id,
         _source_window_id
       ),
       do: issues
end
