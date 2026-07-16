defmodule OrbitalDynamics.Schema.OptimizerObjectiveContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_numeric_map: 3, validate_rows: 4]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_optional_stable_ids: 4,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  alias OrbitalDynamics.Schema.CollectionAggregation

  @objective_tradeoff_report_models [
    "ranked_timeline_score_term_tradeoffs",
    "repair_score_term_tradeoffs",
    "strategy_branch_score_term_tradeoffs"
  ]

  @score_term_report_models [
    "ranked_timeline_score_terms",
    "repair_score_terms",
    "strategy_branch_score_terms"
  ]

  def objective_tradeoff_report_models, do: @objective_tradeoff_report_models
  def score_term_report_models, do: @score_term_report_models

  def validate_objective_tradeoff_report(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "objective_tradeoff_report.v1")
    |> expect_one_of(
      path,
      report,
      "model",
      objective_tradeoff_report_models()
    )
    |> expect_type(path, report, "objective", :binary)
    |> expect_non_negative_integer(path, report, "ranking_count")
    |> expect_type(path, report, "score_term_keys", :list)
    |> expect_type(path, report, "tradeoffs", :list)
    |> expect_optional_type(path, report, "policy", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      score_report_model_limits(),
      "must match score report model limits"
    )
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(
      "#{path}.tradeoffs",
      Map.get(report, "tradeoffs", []),
      fn acc, row_path, row -> validate_objective_tradeoff(acc, row_path, row) end
    )
    |> validate_objective_tradeoff_report_counts(path, report)
  end

  def validate_objective_satisfaction_report(issues, path, report) do
    issues
    |> expect_equal(
      path,
      report,
      "schema_contract",
      "objective_satisfaction_report.v1"
    )
    |> expect_equal(
      path,
      report,
      "model",
      "campaign_v1_selected_activity_objective_summary"
    )
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "objective_count")
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      objective_satisfaction_model_limits(),
      "must match objective satisfaction model limits"
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(
      "#{path}.rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row ->
        validate_objective_satisfaction_row(acc, row_path, row)
      end
    )
    |> validate_objective_satisfaction_report_counts(path, report)
  end

  def validate_ranking_comparison_report(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "ranking_comparison_report.v1")
    |> expect_equal(path, report, "model", "scenario_ranking_pairwise_delta")
    |> expect_type(path, report, "source", :binary)
    |> expect_type(path, report, "objective", :binary)
    |> expect_optional_type(path, report, "objective_direction", :binary)
    |> expect_type(path, report, "left_label", :binary)
    |> expect_type(path, report, "right_label", :binary)
    |> expect_non_negative_integer(path, report, "left_count")
    |> expect_non_negative_integer(path, report, "right_count")
    |> expect_non_negative_integer(path, report, "matched_count")
    |> expect_non_negative_integer(path, report, "left_only_count")
    |> expect_non_negative_integer(path, report, "right_only_count")
    |> expect_non_negative_integer(path, report, "row_count")
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      ranking_comparison_model_limits(),
      "must match ranking comparison model limits"
    )
    |> expect_type(path, report, "winner", :map)
    |> validate_ranking_comparison_winner(
      path <> ".winner",
      Map.get(report, "winner", %{})
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(
      "#{path}.rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_ranking_comparison_row(acc, row_path, row) end
    )
    |> validate_ranking_comparison_report_counts(path, report)
  end

  def validate_score_term_report(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "score_term_report.v1")
    |> expect_one_of(path, report, "model", score_term_report_models())
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "row_count")
    |> expect_type(path, report, "score_term_keys", :list)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      score_report_model_limits(),
      "must match score report model limits"
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_rows(
      "#{path}.rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_score_term_row(acc, row_path, row) end
    )
    |> validate_score_term_report_counts(path, report)
  end

  defp validate_objective_tradeoff_report_counts(issues, path, report) do
    tradeoffs =
      report
      |> Map.get("tradeoffs", [])
      |> Enum.filter(&is_map/1)

    score_term_keys =
      tradeoffs
      |> Enum.flat_map(fn row ->
        row
        |> Map.get("score_terms", %{})
        |> case do
          terms when is_map(terms) -> Map.keys(terms)
          _terms -> []
        end
      end)
      |> Enum.uniq()
      |> Enum.sort()

    issues
    |> expect_field_equals(path, report, "ranking_count", length(tradeoffs))
    |> expect_field_equals(
      path,
      report,
      "score_term_keys",
      score_term_keys,
      "must equal row-derived score term keys"
    )
  end

  defp validate_objective_satisfaction_report_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    expect_field_equals(issues, path, report, "objective_count", length(rows))
  end

  defp validate_ranking_comparison_report_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, report, "row_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "matched_count",
      Enum.count(rows, &(&1["status"] == "matched"))
    )
    |> expect_field_equals(
      path,
      report,
      "left_only_count",
      Enum.count(rows, &(&1["status"] == "left_only"))
    )
    |> expect_field_equals(
      path,
      report,
      "right_only_count",
      Enum.count(rows, &(&1["status"] == "right_only"))
    )
    |> expect_field_equals(
      path,
      report,
      "left_count",
      Enum.count(rows, &(&1["status"] in ["matched", "left_only"]))
    )
    |> expect_field_equals(
      path,
      report,
      "right_count",
      Enum.count(rows, &(&1["status"] in ["matched", "right_only"]))
    )
  end

  defp validate_ranking_comparison_winner(issues, path, winner) do
    issues
    |> require_fields(path, winner, [
      "left_scenario_id",
      "right_scenario_id",
      "changed"
    ])
    |> validate_optional_stable_ids(path, winner, [
      "left_scenario_id",
      "right_scenario_id"
    ])
    |> expect_optional_type(path, winner, "left_scenario_id", :binary)
    |> expect_optional_type(path, winner, "right_scenario_id", :binary)
    |> expect_type(path, winner, "changed", :boolean)
  end

  defp validate_ranking_comparison_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "scenario_id",
      "status",
      "left_rank",
      "right_rank",
      "rank_delta",
      "left_value",
      "right_value",
      "value_delta"
    ])
    |> validate_stable_ids(path, row, ["scenario_id"])
    |> expect_one_of(path, row, "status", ["matched", "left_only", "right_only"])
    |> expect_optional_integer(path, row, "left_rank")
    |> expect_optional_integer(path, row, "right_rank")
    |> expect_optional_integer(path, row, "rank_delta")
    |> expect_optional_number(path, row, "left_value")
    |> expect_optional_number(path, row, "right_value")
    |> expect_optional_number(path, row, "value_delta")
    |> expect_field_equals(
      path,
      row,
      "rank_delta",
      numeric_delta(Map.get(row, "left_rank"), Map.get(row, "right_rank")),
      "must equal left_rank minus right_rank"
    )
    |> expect_field_equals(
      path,
      row,
      "value_delta",
      numeric_delta(Map.get(row, "right_value"), Map.get(row, "left_value")),
      "must equal right_value minus left_value"
    )
  end

  defp validate_objective_satisfaction_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "objective",
      "status",
      "candidate_count",
      "selected_count",
      "satisfied_count"
    ])
    |> validate_stable_ids(path, row, ["id", "target_id"])
    |> expect_type(path, row, "objective", :binary)
    |> expect_one_of(path, row, "status", [
      "met",
      "partial",
      "unmet",
      "selected",
      "candidate_available",
      "no_candidate_window",
      "no_requirement"
    ])
    |> expect_optional_non_negative_integer(path, row, "required_count")
    |> expect_non_negative_integer(path, row, "candidate_count")
    |> expect_non_negative_integer(path, row, "selected_count")
    |> expect_non_negative_integer(path, row, "satisfied_count")
    |> expect_optional_number(path, row, "candidate_downlink_mb")
    |> expect_optional_number(path, row, "required_downlink_mb")
    |> expect_optional_number(path, row, "satisfied_downlink_mb")
    |> expect_optional_number(path, row, "selected_downlink_mb")
    |> expect_optional_type(path, row, "candidate_target_ids", :list)
    |> validate_optional_stable_id_list(path, row, "candidate_target_ids")
    |> expect_optional_type(path, row, "selected_target_ids", :list)
    |> validate_optional_stable_id_list(path, row, "selected_target_ids")
    |> expect_optional_type(path, row, "selected_contact_ids", :list)
    |> validate_optional_stable_id_list(path, row, "selected_contact_ids")
    |> expect_optional_type(path, row, "selected_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "selected_activity_ids")
    |> validate_objective_satisfaction_row_counts(path, row)
  end

  defp validate_objective_satisfaction_row_counts(issues, path, row) do
    selected_count =
      cond do
        is_list(Map.get(row, "selected_target_ids")) ->
          length(Map.get(row, "selected_target_ids"))

        is_list(Map.get(row, "selected_contact_ids")) ->
          length(Map.get(row, "selected_contact_ids"))

        is_list(Map.get(row, "selected_activity_ids")) ->
          length(Map.get(row, "selected_activity_ids"))

        true ->
          nil
      end

    candidate_count =
      if is_list(Map.get(row, "candidate_target_ids")),
        do: length(Map.get(row, "candidate_target_ids"))

    issues
    |> expect_field_equals(
      path,
      row,
      "candidate_count",
      candidate_count,
      "must equal candidate target ID count"
    )
    |> expect_field_equals(
      path,
      row,
      "selected_count",
      selected_count,
      "must equal selected ID count"
    )
  end

  defp validate_objective_tradeoff(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "rank",
      "scenario_id",
      "score",
      "score_delta_from_selected",
      "activity_count",
      "score_terms",
      "activity_ids"
    ])
    |> validate_stable_ids(path, row, ["scenario_id"])
    |> expect_number(path, row, "rank")
    |> expect_number(path, row, "score")
    |> expect_number(path, row, "score_delta_from_selected")
    |> expect_non_negative_integer(path, row, "activity_count")
    |> expect_optional_non_negative_integer(path, row, "selected_observation_count")
    |> expect_optional_non_negative_integer(path, row, "selected_contact_count")
    |> expect_type(path, row, "score_terms", :map)
    |> validate_numeric_map(path <> ".score_terms", Map.get(row, "score_terms"))
    |> expect_type(path, row, "activity_ids", :list)
    |> validate_stable_id_list(
      path <> ".activity_ids",
      Map.get(row, "activity_ids", [])
    )
    |> expect_field_equals(
      path,
      row,
      "activity_count",
      length(Map.get(row, "activity_ids", [])),
      "must equal activity_ids count"
    )
  end

  defp validate_score_term_report_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    score_term_keys =
      rows
      |> Enum.map(&Map.get(&1, "term_key"))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    issues
    |> expect_field_equals(path, report, "row_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "score_term_keys",
      score_term_keys,
      "must equal row-derived score_term_keys"
    )
  end

  defp validate_score_term_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "rank",
      "scenario_id",
      "term_key",
      "value",
      "timeline_score",
      "selected"
    ])
    |> validate_stable_ids(path, row, ["id", "scenario_id"])
    |> expect_number(path, row, "rank")
    |> expect_number(path, row, "value")
    |> expect_number(path, row, "timeline_score")
    |> expect_type(path, row, "term_key", :binary)
    |> expect_type(path, row, "selected", :boolean)
  end

  defp score_report_model_limits,
    do: OrbitalDynamics.CampaignPlanner.score_report_model_limits()

  defp objective_satisfaction_model_limits,
    do: OrbitalDynamics.CampaignPlanner.objective_satisfaction_model_limits()

  defp ranking_comparison_model_limits,
    do: OrbitalDynamics.Optimizer.ranking_comparison_model_limits()

  defp numeric_delta(left, right), do: CollectionAggregation.numeric_delta(left, right)
end
