defmodule OrbitalDynamics.Schema.CampaignStrategyObjectiveTradeoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    DownlinkActivityNormalization,
    StrategyReport
  }

  @report_fields ~w(model objective ranking_count score_term_keys policy)
  @assumption_fields ~w(source scenario_id_represents score_delta_from_selected)
  @row_fields ~w(
    rank
    scenario_id
    branch_id
    score
    score_delta_from_selected
    activity_count
    selected_observation_count
    selected_contact_count
    score_terms
    activity_ids
    selected
  )

  def validate(
        issues,
        %{
          "branches" => branches,
          "recommendation" => %{"recommended_branch_id" => recommended_branch_id},
          "strategy_policy" => strategy_policy,
          "objective_tradeoff_report" => %{"tradeoffs" => rows} = report
        }
      )
      when is_list(branches) and is_binary(recommended_branch_id) and
             is_map(strategy_policy) and is_list(rows) do
    if Enum.all?(branches, &valid_branch?/1) and Enum.all?(rows, &is_map/1) do
      expected =
        StrategyReport.objective_tradeoff_report_from_artifact(
          branches,
          recommended_branch_id,
          strategy_policy,
          Map.get(report, "model_limits"),
          &ActivityIdentity.activity_id/1,
          &DownlinkActivityNormalization.downlink?/1
        )

      issues
      |> validate_report_fields(report, expected)
      |> validate_assumptions(report, expected)
      |> validate_rows(rows, expected["tradeoffs"])
    else
      issues
    end
  end

  def validate(issues, _artifact), do: issues

  defp valid_branch?(%{
         "branch_id" => branch_id,
         "score" => score,
         "score_terms" => score_terms,
         "repair_result" => %{"activities" => activities}
       })
       when is_binary(branch_id) and is_number(score) and is_map(score_terms) and
              is_list(activities) do
    Enum.all?(score_terms, fn {key, value} -> is_binary(key) and is_number(value) end) and
      Enum.all?(activities, &valid_activity?/1)
  end

  defp valid_branch?(_branch), do: false

  defp valid_activity?(%{"id" => id}) when is_binary(id), do: true
  defp valid_activity?(_activity), do: false

  defp validate_report_fields(issues, report, expected) do
    Enum.reduce(@report_fields, issues, fn field, acc ->
      validate_equal(
        acc,
        "$.objective_tradeoff_report.#{field}",
        Map.get(report, field),
        Map.get(expected, field),
        "must match the objective-tradeoff report replayed from branches"
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
          "$.objective_tradeoff_report.assumptions.#{field}",
          Map.get(assumptions, field),
          Map.get(expected_assumptions, field),
          "must match the objective-tradeoff assumptions replayed from branches"
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
        "$.objective_tradeoff_report.tradeoffs",
        "must match the objective-tradeoff rows replayed from branches"
      )
      | issues
    ]
  end

  defp validate_row(issues, expected, row, index) do
    Enum.reduce(@row_fields, issues, fn field, acc ->
      validate_equal(
        acc,
        "$.objective_tradeoff_report.tradeoffs[#{index}].#{field}",
        Map.get(row, field),
        Map.get(expected, field),
        "must match the objective-tradeoff row replayed from its branch"
      )
    end)
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
