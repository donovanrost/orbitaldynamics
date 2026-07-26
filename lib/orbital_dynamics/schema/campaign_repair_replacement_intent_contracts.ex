defmodule OrbitalDynamics.Schema.CampaignRepairReplacementIntentContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityIdentity, RepairReplacementIntent}
  alias OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, %{} = artifact) do
    source_candidates_by_id =
      artifact
      |> Map.get("source_candidate_activities", [])
      |> source_candidates_by_id()

    validate_activities(
      issues,
      Map.get(artifact, "activities", []),
      source_candidates_by_id
    )
  end

  def validate(issues, _artifact), do: issues

  defp source_candidates_by_id(candidates) when is_list(candidates) do
    candidates
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&ActivityIdentity.activity_id/1)
  end

  defp source_candidates_by_id(_candidates), do: %{}

  defp validate_activities(issues, activities, source_candidates_by_id)
       when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      {source_context, rows} = ranking_context(activity)

      validate_rows(
        acc,
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        rows,
        source_context,
        source_candidates_by_id
      )
    end)
  end

  defp validate_activities(issues, _activities, _source_candidates_by_id), do: issues

  defp ranking_context(%{
         "repair" => %{
           "source_activity_context" => source_context,
           "replacement_ranking" => %{"rows" => rows}
         }
       }),
       do: {source_context, rows}

  defp ranking_context(_activity), do: {nil, nil}

  defp validate_rows(issues, path, rows, %{} = source_context, source_candidates_by_id)
       when is_list(rows) do
    if CampaignRepairReplacementRankingVersion.current?(rows) do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn
        {%{} = row, index}, acc ->
          validate_row(
            acc,
            "#{path}[#{index}]",
            row,
            source_context,
            source_candidates_by_id
          )

        {_row, _index}, acc ->
          acc
      end)
    else
      issues
    end
  end

  defp validate_rows(issues, _path, _rows, _source_context, _source_candidates_by_id),
    do: issues

  defp validate_row(issues, path, row, source_context, source_candidates_by_id) do
    case Map.get(source_candidates_by_id, Map.get(row, "candidate_id"), []) do
      [%{} = candidate] ->
        if RepairReplacementIntent.matches?(source_context, candidate) do
          issues
        else
          [
            error(
              path <> ".candidate_id",
              "must identify an embedded source candidate within the preserved repair intent"
            )
            | issues
          ]
        end

      _missing_or_ambiguous_candidate ->
        issues
    end
  end
end
