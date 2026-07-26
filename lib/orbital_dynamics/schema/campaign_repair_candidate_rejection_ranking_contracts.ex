defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRejectionRankingContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports
  alias OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, %{} = artifact) do
    rejected_candidate_ids =
      artifact
      |> Map.get("source_candidate_rejection_report")
      |> rejected_candidate_ids()

    validate_activities(
      issues,
      Map.get(artifact, "activities", []),
      rejected_candidate_ids
    )
  end

  def validate(issues, _artifact), do: issues

  defp rejected_candidate_ids(%{} = report) do
    [report]
    |> RepairSourceReports.candidate_rejection_rejected_candidate_ids()
    |> MapSet.new()
  end

  defp rejected_candidate_ids(_report), do: MapSet.new()

  defp validate_activities(issues, activities, rejected_candidate_ids)
       when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      rows =
        case activity do
          %{"repair" => %{"replacement_ranking" => %{"rows" => rows}}} -> rows
          _activity -> nil
        end

      validate_rows(
        acc,
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        rows,
        rejected_candidate_ids
      )
    end)
  end

  defp validate_activities(issues, _activities, _rejected_candidate_ids), do: issues

  defp validate_rows(issues, path, rows, rejected_candidate_ids) when is_list(rows) do
    if CampaignRepairReplacementRankingVersion.current?(rows) do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn
        {%{} = row, index}, acc ->
          validate_candidate_id(
            acc,
            "#{path}[#{index}].candidate_id",
            row,
            rejected_candidate_ids
          )

        {_row, _index}, acc ->
          acc
      end)
    else
      issues
    end
  end

  defp validate_rows(issues, _path, _rows, _rejected_candidate_ids), do: issues

  defp validate_candidate_id(issues, path, row, rejected_candidate_ids) do
    if MapSet.member?(rejected_candidate_ids, Map.get(row, "candidate_id")) do
      [
        error(
          path,
          "must not identify a candidate rejected by source_candidate_rejection_report"
        )
        | issues
      ]
    else
      issues
    end
  end
end
