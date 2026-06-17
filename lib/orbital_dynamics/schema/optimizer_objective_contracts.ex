defmodule OrbitalDynamics.Schema.OptimizerObjectiveContracts do
  @moduledoc false

  def validate_objective_tradeoff_report(issues, path, report, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "objective_tradeoff_report.v1")
    |> expect_one_of(
      callbacks,
      path,
      report,
      "model",
      objective_tradeoff_report_models(callbacks)
    )
    |> expect_type(callbacks, path, report, "objective", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "ranking_count")
    |> expect_type(callbacks, path, report, "score_term_keys", :list)
    |> expect_type(callbacks, path, report, "tradeoffs", :list)
    |> expect_optional_type(callbacks, path, report, "policy", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      score_report_model_limits(callbacks),
      "must match score report model limits"
    )
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(
      callbacks,
      "#{path}.tradeoffs",
      Map.get(report, "tradeoffs", []),
      fn acc, row_path, row -> validate_objective_tradeoff(acc, row_path, row, callbacks) end
    )
    |> validate_objective_tradeoff_report_counts(callbacks, path, report)
  end

  def validate_objective_satisfaction_report(issues, path, report, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      report,
      "schema_contract",
      "objective_satisfaction_report.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "campaign_v1_selected_activity_objective_summary"
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "objective_count")
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      objective_satisfaction_model_limits(callbacks),
      "must match objective satisfaction model limits"
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(
      callbacks,
      "#{path}.rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row ->
        validate_objective_satisfaction_row(acc, row_path, row, callbacks)
      end
    )
    |> validate_objective_satisfaction_report_counts(callbacks, path, report)
  end

  def validate_ranking_comparison_report(issues, path, report, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "ranking_comparison_report.v1")
    |> expect_equal(callbacks, path, report, "model", "scenario_ranking_pairwise_delta")
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_type(callbacks, path, report, "objective", :binary)
    |> expect_optional_type(callbacks, path, report, "objective_direction", :binary)
    |> expect_type(callbacks, path, report, "left_label", :binary)
    |> expect_type(callbacks, path, report, "right_label", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "left_count")
    |> expect_non_negative_integer(callbacks, path, report, "right_count")
    |> expect_non_negative_integer(callbacks, path, report, "matched_count")
    |> expect_non_negative_integer(callbacks, path, report, "left_only_count")
    |> expect_non_negative_integer(callbacks, path, report, "right_only_count")
    |> expect_non_negative_integer(callbacks, path, report, "row_count")
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      ranking_comparison_model_limits(callbacks),
      "must match ranking comparison model limits"
    )
    |> expect_type(callbacks, path, report, "winner", :map)
    |> validate_ranking_comparison_winner(
      callbacks,
      path <> ".winner",
      Map.get(report, "winner", %{})
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(
      callbacks,
      "#{path}.rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_ranking_comparison_row(acc, row_path, row, callbacks) end
    )
    |> validate_ranking_comparison_report_counts(callbacks, path, report)
  end

  def validate_score_term_report(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "score_term_report.v1")
    |> expect_one_of(callbacks, path, report, "model", score_term_report_models(callbacks))
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "row_count")
    |> expect_type(callbacks, path, report, "score_term_keys", :list)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      score_report_model_limits(callbacks),
      "must match score report model limits"
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(
      callbacks,
      "#{path}.rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_score_term_row(acc, row_path, row, callbacks) end
    )
    |> validate_score_term_report_counts(callbacks, path, report)
  end

  defp validate_objective_tradeoff_report_counts(issues, callbacks, path, report) do
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
    |> expect_field_equals(callbacks, path, report, "ranking_count", length(tradeoffs))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "score_term_keys",
      score_term_keys,
      "must equal row-derived score term keys"
    )
  end

  defp validate_objective_satisfaction_report_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    expect_field_equals(issues, callbacks, path, report, "objective_count", length(rows))
  end

  defp validate_ranking_comparison_report_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, report, "row_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "matched_count",
      Enum.count(rows, &(&1["status"] == "matched"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "left_only_count",
      Enum.count(rows, &(&1["status"] == "left_only"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "right_only_count",
      Enum.count(rows, &(&1["status"] == "right_only"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "left_count",
      Enum.count(rows, &(&1["status"] in ["matched", "left_only"]))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "right_count",
      Enum.count(rows, &(&1["status"] in ["matched", "right_only"]))
    )
  end

  defp validate_ranking_comparison_winner(issues, callbacks, path, winner) do
    issues
    |> require_fields(callbacks, path, winner, [
      "left_scenario_id",
      "right_scenario_id",
      "changed"
    ])
    |> validate_optional_stable_ids(callbacks, path, winner, [
      "left_scenario_id",
      "right_scenario_id"
    ])
    |> expect_optional_type(callbacks, path, winner, "left_scenario_id", :binary)
    |> expect_optional_type(callbacks, path, winner, "right_scenario_id", :binary)
    |> expect_type(callbacks, path, winner, "changed", :boolean)
  end

  defp validate_ranking_comparison_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "scenario_id",
      "status",
      "left_rank",
      "right_rank",
      "rank_delta",
      "left_value",
      "right_value",
      "value_delta"
    ])
    |> validate_stable_ids(callbacks, path, row, ["scenario_id"])
    |> expect_one_of(callbacks, path, row, "status", ["matched", "left_only", "right_only"])
    |> expect_optional_integer(callbacks, path, row, "left_rank")
    |> expect_optional_integer(callbacks, path, row, "right_rank")
    |> expect_optional_integer(callbacks, path, row, "rank_delta")
    |> expect_optional_number(callbacks, path, row, "left_value")
    |> expect_optional_number(callbacks, path, row, "right_value")
    |> expect_optional_number(callbacks, path, row, "value_delta")
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "rank_delta",
      numeric_delta(callbacks, Map.get(row, "left_rank"), Map.get(row, "right_rank")),
      "must equal left_rank minus right_rank"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "value_delta",
      numeric_delta(callbacks, Map.get(row, "right_value"), Map.get(row, "left_value")),
      "must equal right_value minus left_value"
    )
  end

  defp validate_objective_satisfaction_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "objective",
      "status",
      "candidate_count",
      "selected_count",
      "satisfied_count"
    ])
    |> validate_stable_ids(callbacks, path, row, ["id", "target_id"])
    |> expect_type(callbacks, path, row, "objective", :binary)
    |> expect_one_of(callbacks, path, row, "status", [
      "met",
      "partial",
      "unmet",
      "selected",
      "candidate_available",
      "no_candidate_window",
      "no_requirement"
    ])
    |> expect_optional_non_negative_integer(callbacks, path, row, "required_count")
    |> expect_non_negative_integer(callbacks, path, row, "candidate_count")
    |> expect_non_negative_integer(callbacks, path, row, "selected_count")
    |> expect_non_negative_integer(callbacks, path, row, "satisfied_count")
    |> expect_optional_number(callbacks, path, row, "candidate_downlink_mb")
    |> expect_optional_number(callbacks, path, row, "required_downlink_mb")
    |> expect_optional_number(callbacks, path, row, "satisfied_downlink_mb")
    |> expect_optional_number(callbacks, path, row, "selected_downlink_mb")
    |> expect_optional_type(callbacks, path, row, "candidate_target_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "candidate_target_ids")
    |> expect_optional_type(callbacks, path, row, "selected_target_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "selected_target_ids")
    |> expect_optional_type(callbacks, path, row, "selected_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "selected_contact_ids")
    |> expect_optional_type(callbacks, path, row, "selected_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "selected_activity_ids")
    |> validate_objective_satisfaction_row_counts(callbacks, path, row)
  end

  defp validate_objective_satisfaction_row_counts(issues, callbacks, path, row) do
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
      callbacks,
      path,
      row,
      "candidate_count",
      candidate_count,
      "must equal candidate target ID count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "selected_count",
      selected_count,
      "must equal selected ID count"
    )
  end

  defp validate_objective_tradeoff(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "rank",
      "scenario_id",
      "score",
      "score_delta_from_selected",
      "activity_count",
      "score_terms",
      "activity_ids"
    ])
    |> validate_stable_ids(callbacks, path, row, ["scenario_id"])
    |> expect_number(callbacks, path, row, "rank")
    |> expect_number(callbacks, path, row, "score")
    |> expect_number(callbacks, path, row, "score_delta_from_selected")
    |> expect_non_negative_integer(callbacks, path, row, "activity_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "selected_observation_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "selected_contact_count")
    |> expect_type(callbacks, path, row, "score_terms", :map)
    |> validate_numeric_map(callbacks, path <> ".score_terms", Map.get(row, "score_terms"))
    |> expect_type(callbacks, path, row, "activity_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".activity_ids",
      Map.get(row, "activity_ids", [])
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "activity_count",
      length(Map.get(row, "activity_ids", [])),
      "must equal activity_ids count"
    )
  end

  defp validate_score_term_report_counts(issues, callbacks, path, report) do
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
    |> expect_field_equals(callbacks, path, report, "row_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "score_term_keys",
      score_term_keys,
      "must equal row-derived score_term_keys"
    )
  end

  defp validate_score_term_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "rank",
      "scenario_id",
      "term_key",
      "value",
      "timeline_score",
      "selected"
    ])
    |> validate_stable_ids(callbacks, path, row, ["id", "scenario_id"])
    |> expect_number(callbacks, path, row, "rank")
    |> expect_number(callbacks, path, row, "value")
    |> expect_number(callbacks, path, row, "timeline_score")
    |> expect_type(callbacks, path, row, "term_key", :binary)
    |> expect_type(callbacks, path, row, "selected", :boolean)
  end

  defp objective_tradeoff_report_models(callbacks),
    do: apply(Keyword.fetch!(callbacks, :objective_tradeoff_report_models), [])

  defp score_term_report_models(callbacks),
    do: apply(Keyword.fetch!(callbacks, :score_term_report_models), [])

  defp score_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :score_report_model_limits), [])

  defp objective_satisfaction_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :objective_satisfaction_model_limits), [])

  defp ranking_comparison_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :ranking_comparison_model_limits), [])

  defp numeric_delta(callbacks, left, right),
    do: apply(Keyword.fetch!(callbacks, :numeric_delta), [left, right])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        artifact,
        expected,
        message
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_stable_ids(issues, callbacks, path, map, fields),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_ids), [issues, path, map, fields])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_numeric_map(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :validate_numeric_map), [issues, path, value])
end
