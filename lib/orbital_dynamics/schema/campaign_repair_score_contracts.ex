defmodule OrbitalDynamics.Schema.CampaignRepairScoreContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_numeric_map: 3]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_number: 4, expect_type: 5]

  def validate(issues, artifact) when is_map(artifact) do
    score_terms = Map.get(artifact, "score_terms")

    issues
    |> expect_number("$", artifact, "score")
    |> expect_type("$", artifact, "score_terms", :map)
    |> validate_numeric_map("$.score_terms", score_terms)
    |> validate_score_sum(artifact, score_terms)
    |> validate_score_term_report(artifact, Map.get(artifact, "score_term_report"))
  end

  defp validate_score_sum(issues, %{"score" => score}, score_terms)
       when is_number(score) and is_map(score_terms) do
    values = Map.values(score_terms)

    if Enum.all?(values, &is_number/1) and close?(score, Enum.sum(values)) do
      issues
    else
      if Enum.all?(values, &is_number/1),
        do: [error("$.score", "must equal the sum of score_terms") | issues],
        else: issues
    end
  end

  defp validate_score_sum(issues, _artifact, _score_terms), do: issues

  defp validate_score_term_report(issues, _artifact, nil), do: issues
  defp validate_score_term_report(issues, _artifact, :null), do: issues

  defp validate_score_term_report(
         issues,
         %{"score" => score, "score_terms" => score_terms},
         %{"rows" => rows} = report
       )
       when is_number(score) and is_map(score_terms) and is_list(rows) do
    if Enum.all?(rows, &is_map/1) do
      term_keys = Enum.map(rows, &Map.get(&1, "term_key"))
      expected_term_keys = score_terms |> Map.keys() |> Enum.sort()

      issues
      |> validate_equal(
        "$.score_term_report.source",
        Map.get(report, "source"),
        "campaign_repair.score_terms",
        "must identify campaign_repair.score_terms"
      )
      |> validate_equal(
        "$.score_term_report.score_term_keys",
        Map.get(report, "score_term_keys"),
        expected_term_keys,
        "must match enclosing repair score_terms keys"
      )
      |> validate_equal(
        "$.score_term_report.rows",
        length(Enum.uniq(term_keys)),
        length(term_keys),
        "must contain unique term keys"
      )
      |> validate_equal(
        "$.score_term_report.rows",
        Enum.sort(term_keys),
        expected_term_keys,
        "must contain exactly one row for each enclosing repair score term"
      )
      |> validate_report_rows(score, score_terms, rows)
    else
      issues
    end
  end

  defp validate_score_term_report(issues, _artifact, _report), do: issues

  defp validate_report_rows(issues, score, score_terms, rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      path = "$.score_term_report.rows[#{index}]"
      term_key = Map.get(row, "term_key")

      acc
      |> validate_number_equal(
        path <> ".value",
        Map.get(row, "value"),
        Map.get(score_terms, term_key),
        "must match the enclosing repair score term"
      )
      |> validate_number_equal(
        path <> ".timeline_score",
        Map.get(row, "timeline_score"),
        score,
        "must match the enclosing repair score"
      )
      |> validate_equal(
        path <> ".selected",
        Map.get(row, "selected"),
        true,
        "must be selected for the single repair score timeline"
      )
      |> validate_equal(
        path <> ".rank",
        Map.get(row, "rank"),
        1,
        "must use rank 1 for the single repair score timeline"
      )
    end)
  end

  defp validate_number_equal(issues, _path, left, right, _message)
       when not is_number(left) or not is_number(right),
       do: issues

  defp validate_number_equal(issues, path, left, right, message) do
    if close?(left, right), do: issues, else: [error(path, message) | issues]
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]

  defp close?(left, right), do: abs(left - right) <= 1.0e-9
end
