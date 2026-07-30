defmodule OrbitalDynamics.Schema.CampaignStrategyScoreTermContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  alias OrbitalDynamics.CampaignPlanner.StrategyReport

  @report_fields ~w(model source row_count score_term_keys)
  @assumption_fields ~w(score_term_source scenario_id_represents policy)
  @row_fields ~w(id rank scenario_id branch_id term_key value timeline_score selected)

  def validate(
        issues,
        %{
          "branches" => branches,
          "recommendation" => %{"recommended_branch_id" => recommended_branch_id},
          "strategy_policy" => strategy_policy,
          "score_term_report" => %{"rows" => rows} = report
        }
      )
      when is_list(branches) and is_binary(recommended_branch_id) and
             is_map(strategy_policy) and is_list(rows) do
    if Enum.all?(branches, &valid_branch?/1) and Enum.all?(rows, &is_map/1) do
      expected =
        StrategyReport.score_term_report_from_artifact(
          branches,
          recommended_branch_id,
          strategy_policy,
          Map.get(report, "model_limits")
        )

      issues
      |> validate_report_fields(report, expected)
      |> validate_assumptions(report, expected)
      |> validate_rows(rows, expected["rows"])
    else
      issues
    end
  end

  def validate(issues, _artifact), do: issues

  defp valid_branch?(%{
         "branch_id" => branch_id,
         "score" => score,
         "score_terms" => score_terms
       })
       when is_binary(branch_id) and is_number(score) and is_map(score_terms) do
    Enum.all?(score_terms, fn {key, value} -> is_binary(key) and is_number(value) end)
  end

  defp valid_branch?(_branch), do: false

  defp validate_report_fields(issues, report, expected) do
    Enum.reduce(@report_fields, issues, fn field, acc ->
      validate_equal(
        acc,
        "$.score_term_report.#{field}",
        Map.get(report, field),
        Map.get(expected, field),
        "must match the score-term report replayed from branches"
      )
    end)
  end

  defp validate_assumptions(issues, report, expected) do
    assumptions = Map.get(report, "assumptions")
    expected_assumptions = Map.fetch!(expected, "assumptions")

    if is_map(assumptions) do
      Enum.reduce(@assumption_fields, issues, fn field, acc ->
        validate_equal(
          acc,
          "$.score_term_report.assumptions.#{field}",
          Map.get(assumptions, field),
          Map.get(expected_assumptions, field),
          "must match the score-term assumptions replayed from strategy policy"
        )
      end)
    else
      issues
    end
  end

  defp validate_rows(issues, rows, expected_rows) when length(rows) == length(expected_rows) do
    expected_rows
    |> Enum.zip(rows)
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {{expected_row, row}, index}, acc ->
      validate_row(acc, expected_row, row, index)
    end)
  end

  defp validate_rows(issues, _rows, _expected_rows) do
    [
      error(
        "$.score_term_report.rows",
        "must match the score-term rows replayed from branches"
      )
      | issues
    ]
  end

  defp validate_row(issues, expected, row, index) do
    Enum.reduce(@row_fields, issues, fn field, acc ->
      validate_equal(
        acc,
        "$.score_term_report.rows[#{index}].#{field}",
        Map.get(row, field),
        Map.get(expected, field),
        "must match the score-term row replayed from its branch"
      )
    end)
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
