defmodule OrbitalDynamics.Schema.CampaignRepairObjectiveTradeoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, %{} = artifact) do
    case Map.get(artifact, "objective_tradeoff_report") do
      nil ->
        issues

      :null ->
        issues

      %{} = report ->
        issues
        |> validate_equal(
          "$.objective_tradeoff_report.model",
          Map.get(report, "model"),
          "repair_score_term_tradeoffs",
          "must identify repair score-term tradeoffs"
        )
        |> validate_equal(
          "$.objective_tradeoff_report.ranking_count",
          Map.get(report, "ranking_count"),
          1,
          "must describe the single repaired timeline"
        )
        |> validate_equal(
          "$.objective_tradeoff_report.score_term_keys",
          Map.get(report, "score_term_keys"),
          artifact |> Map.get("score_terms", %{}) |> map_keys(),
          "must match enclosing repair score-term keys"
        )
        |> validate_equal(
          "$.objective_tradeoff_report.policy",
          Map.get(report, "policy"),
          Map.get(artifact, "scoring_policy"),
          "must match enclosing repair scoring policy"
        )
        |> validate_tradeoffs(artifact, Map.get(report, "tradeoffs"))

      _report ->
        issues
    end
  end

  def validate(issues, _artifact), do: issues

  defp validate_tradeoffs(issues, artifact, [%{} = row]) do
    score_terms = Map.get(artifact, "score_terms", %{})
    activities = Map.get(artifact, "activities", [])

    activity_ids =
      activities
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, "id"))

    issues
    |> validate_equal(
      "$.objective_tradeoff_report.tradeoffs[0].rank",
      Map.get(row, "rank"),
      1,
      "must use rank 1 for the single repaired timeline"
    )
    |> validate_equal(
      "$.objective_tradeoff_report.tradeoffs[0].scenario_id",
      Map.get(row, "scenario_id"),
      Map.get(artifact, "source_plan_id"),
      "must match the enclosing repair source plan"
    )
    |> validate_number_equal(
      "$.objective_tradeoff_report.tradeoffs[0].score",
      Map.get(row, "score"),
      Map.get(artifact, "score"),
      "must match the enclosing repair score"
    )
    |> validate_number_equal(
      "$.objective_tradeoff_report.tradeoffs[0].score_delta_from_selected",
      Map.get(row, "score_delta_from_selected"),
      0.0,
      "must be zero for the single repaired timeline"
    )
    |> validate_equal(
      "$.objective_tradeoff_report.tradeoffs[0].activity_count",
      Map.get(row, "activity_count"),
      length(activity_ids),
      "must match enclosing repaired activity count"
    )
    |> validate_equal(
      "$.objective_tradeoff_report.tradeoffs[0].activity_ids",
      Map.get(row, "activity_ids"),
      activity_ids,
      "must match enclosing repaired activity IDs in order"
    )
    |> validate_equal(
      "$.objective_tradeoff_report.tradeoffs[0].score_terms",
      Map.get(row, "score_terms"),
      score_terms,
      "must match enclosing repair score terms"
    )
    |> validate_equal(
      "$.objective_tradeoff_report.tradeoffs[0].selected_observation_count",
      Map.get(row, "selected_observation_count"),
      map_value(score_terms, "selected_observation_count", 0),
      "must match producer-selected observation count"
    )
    |> validate_equal(
      "$.objective_tradeoff_report.tradeoffs[0].selected_contact_count",
      Map.get(row, "selected_contact_count"),
      map_value(score_terms, "selected_contact_count", 0),
      "must match producer-selected contact count"
    )
  end

  defp validate_tradeoffs(issues, _artifact, rows) when is_list(rows) do
    [
      error(
        "$.objective_tradeoff_report.tradeoffs",
        "must contain exactly one repaired timeline row"
      )
      | issues
    ]
  end

  defp validate_tradeoffs(issues, _artifact, _rows), do: issues

  defp map_keys(%{} = map), do: map |> Map.keys() |> Enum.sort()
  defp map_keys(_map), do: []

  defp map_value(%{} = map, key, default), do: Map.get(map, key, default)
  defp map_value(_map, _key, default), do: default

  defp validate_number_equal(issues, _path, left, right, _message)
       when not is_number(left) or not is_number(right),
       do: issues

  defp validate_number_equal(issues, path, left, right, message) do
    if abs(left - right) <= 1.0e-9,
      do: issues,
      else: [error(path, message) | issues]
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
