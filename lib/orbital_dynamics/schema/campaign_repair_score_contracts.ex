defmodule OrbitalDynamics.Schema.CampaignRepairScoreContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    LinkCapacityPressureBranches,
    RepairReadinessPressure,
    RepairRefreshPressure,
    RepairSourceFilterPressure,
    ResourceProjectionRisk,
    ScalarValues
  }

  @churn_actions ["moved", "replaced", "canceled", "suppressed"]

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_numeric_map: 3]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_number: 4, expect_type: 5]

  def validate(issues, artifact) when is_map(artifact) do
    score_terms = Map.get(artifact, "score_terms")

    issues
    |> expect_number("$", artifact, "score")
    |> expect_type("$", artifact, "score_terms", :map)
    |> validate_numeric_map("$.score_terms", score_terms)
    |> validate_activity_score(artifact, score_terms)
    |> validate_schedule_terms(artifact, score_terms)
    |> validate_report_pressure_terms(artifact, score_terms)
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

  defp validate_activity_score(
         issues,
         %{"activities" => activities},
         %{"activity_score" => actual}
       )
       when is_list(activities) and is_number(actual) do
    expected =
      activities
      |> Enum.filter(&is_map/1)
      |> Enum.map(&(ScalarValues.numeric_or_nil(Map.get(&1, "score")) || 0.0))
      |> Enum.sum()

    if close?(actual, expected) do
      issues
    else
      [
        error(
          "$.score_terms.activity_score",
          "must equal the sum of repaired activity scores"
        )
        | issues
      ]
    end
  end

  defp validate_activity_score(issues, _artifact, _score_terms), do: issues

  defp validate_schedule_terms(issues, artifact, score_terms)
       when is_map(artifact) and is_map(score_terms) do
    churn_count =
      artifact
      |> Map.get("deltas", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.count(&(Map.get(&1, "repair_action") in @churn_actions))

    moved_seconds =
      artifact
      |> Map.get("activities", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&activity_schedule_churn_s/1)
      |> Enum.sum()

    scoring_policy = Map.get(artifact, "scoring_policy", %{})

    issues
    |> validate_optional_derived_term(
      score_terms,
      "schedule_churn_penalty",
      -churn_count * numeric_policy_value(scoring_policy, "schedule_churn_cost_weight", 100.0),
      "must match repair-action churn count and schedule_churn_cost_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "schedule_move_penalty",
      -moved_seconds * numeric_policy_value(scoring_policy, "schedule_move_cost_weight", 0.01),
      "must match repaired activity churn seconds and schedule_move_cost_weight"
    )
  end

  defp validate_schedule_terms(issues, _artifact, _score_terms), do: issues

  defp validate_report_pressure_terms(issues, artifact, score_terms)
       when is_map(artifact) and is_map(score_terms) do
    risk_weight =
      artifact
      |> Map.get("scoring_policy", %{})
      |> numeric_policy_value("risk_weight", 1.0)

    link_capacity_pressure_count =
      case Map.get(artifact, "link_capacity_report") do
        %{} = report ->
          if LinkCapacityPressureBranches.selected_shortfall_pressure?(report), do: 1, else: 0

        _report ->
          0
      end

    resource_projection_pressure_count =
      artifact
      |> Map.get("source_resource_projection_report")
      |> resource_projection_risk_indicators()
      |> length()

    candidate_diff_pressure_count =
      artifact
      |> Map.get("source_candidate_diff_report")
      |> RepairRefreshPressure.candidate_diff_count()

    refresh_freshness_pressure_count =
      artifact
      |> Map.get("source_freshness_report")
      |> RepairRefreshPressure.freshness_count()

    refresh_budget_pressure_count =
      artifact
      |> Map.get("source_refresh_budget_report")
      |> RepairRefreshPressure.budget_count()

    operational_readiness_pressure_count =
      artifact
      |> Map.get("source_operational_readiness_report")
      |> RepairReadinessPressure.operational_count()

    quality_gate_pressure_count =
      artifact
      |> Map.get("source_quality_gate_report")
      |> RepairReadinessPressure.quality_gate_count()

    contact_filter_pressure_count =
      artifact
      |> Map.get("source_contact_filter_report")
      |> RepairSourceFilterPressure.suppressed_count()

    resource_filter_pressure_count =
      artifact
      |> Map.get("source_resource_filter_report")
      |> RepairSourceFilterPressure.suppressed_count()

    candidate_rejection_pressure_count =
      artifact
      |> Map.get("source_candidate_rejection_report")
      |> RepairSourceFilterPressure.candidate_rejection_count()

    issues
    |> validate_optional_derived_term(
      score_terms,
      "link_capacity_pressure_penalty",
      -link_capacity_pressure_count * risk_weight,
      "must match final selected link-capacity shortfall status and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "resource_projection_pressure_penalty",
      -resource_projection_pressure_count * risk_weight,
      "must match source resource-projection risk-indicator count and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "candidate_diff_pressure_penalty",
      -candidate_diff_pressure_count * risk_weight,
      "must match source candidate-diff replay pressure and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "refresh_freshness_pressure_penalty",
      -refresh_freshness_pressure_count * risk_weight,
      "must match stale or unknown source freshness status and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "refresh_budget_pressure_penalty",
      -refresh_budget_pressure_count * risk_weight,
      "must match source refresh-budget dropped-candidate count and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "operational_readiness_pressure_penalty",
      -operational_readiness_pressure_count * risk_weight,
      "must match source operational-readiness reviewable-row count and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "quality_gate_pressure_penalty",
      -quality_gate_pressure_count * risk_weight,
      "must match source quality-gate reviewable-row count and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "contact_filter_pressure_penalty",
      -contact_filter_pressure_count * risk_weight,
      "must match source contact-filter suppressed-candidate count and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "resource_filter_pressure_penalty",
      -resource_filter_pressure_count * risk_weight,
      "must match source resource-filter suppressed-candidate count and risk_weight"
    )
    |> validate_optional_derived_term(
      score_terms,
      "candidate_rejection_pressure_penalty",
      -candidate_rejection_pressure_count * risk_weight,
      "must match source candidate-rejection rejected-candidate count and risk_weight"
    )
  end

  defp validate_report_pressure_terms(issues, _artifact, _score_terms), do: issues

  defp resource_projection_risk_indicators(%{"projected_resources" => rows} = report)
       when is_list(rows) do
    report
    |> Map.put("projected_resources", Enum.filter(rows, &is_map/1))
    |> ResourceProjectionRisk.risk_indicators()
  end

  defp resource_projection_risk_indicators(report),
    do: ResourceProjectionRisk.risk_indicators(report)

  defp activity_schedule_churn_s(%{"repair" => %{} = repair}),
    do: ScalarValues.numeric_or_nil(Map.get(repair, "schedule_churn_s")) || 0.0

  defp activity_schedule_churn_s(_activity), do: 0.0

  defp validate_optional_derived_term(issues, score_terms, key, expected, message) do
    if Map.has_key?(score_terms, key) do
      case Map.get(score_terms, key) do
        actual when is_number(actual) ->
          if close?(actual, expected) do
            issues
          else
            [error("$.score_terms." <> key, message) | issues]
          end

        _actual ->
          issues
      end
    else
      issues
    end
  end

  defp numeric_policy_value(%{} = policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp numeric_policy_value(_policy, _key, default), do: default

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
