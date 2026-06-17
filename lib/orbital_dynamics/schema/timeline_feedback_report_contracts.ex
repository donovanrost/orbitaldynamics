defmodule OrbitalDynamics.Schema.TimelineFeedbackReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "timeline_feedback_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "planned_vs_realized_activity_reconciliation"
    )
    |> expect_non_negative_integer(callbacks, path, report, "planned_count")
    |> expect_non_negative_integer(callbacks, path, report, "realized_count")
    |> expect_non_negative_integer(callbacks, path, report, "row_count")
    |> expect_type(callbacks, path, report, "status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "feedback_kind_counts", :map)
    |> expect_optional_type(callbacks, path, report, "match_strategy_counts", :map)
    |> expect_optional_type(callbacks, path, report, "cadence_import_status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "planned_protection_decision_counts", :map)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "execution_uncertainty_declared_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "execution_uncertainty_missing_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "operational_feedback_excluded_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "ambiguous_timeline_match_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "ambiguous_timeline_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_realized_match_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_realized_feedback_count"
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      timeline_feedback_report_model_limits(callbacks),
      "must match timeline feedback report model limits"
    )
    |> expect_optional_type(callbacks, path, report, "operational_feedback", :map)
    |> validate_operational_feedback(callbacks, path, Map.get(report, "operational_feedback"))
    |> expect_optional_type(callbacks, path, report, "operational_feedback_provenance", :map)
    |> expect_optional_type(callbacks, path, report, "cadence_import_manifest", :map)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_counts(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_timeline_feedback_row(callbacks, acc, row_path, row) end
    )
    |> validate_optional_operator_review_package(
      callbacks,
      Map.get(report, "operator_review_package")
    )
  end

  defp validate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(report, "status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".feedback_kind_counts",
      Map.get(report, "feedback_kind_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".match_strategy_counts",
      Map.get(report, "match_strategy_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".cadence_import_status_counts",
      Map.get(report, "cadence_import_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".planned_protection_decision_counts",
      Map.get(report, "planned_protection_decision_counts")
    )
    |> expect_field_equals(callbacks, path, report, "row_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_counts",
      frequency_map(callbacks, rows, "status"),
      "must equal row-derived status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "feedback_kind_counts",
      frequency_map(callbacks, rows, "feedback_kind"),
      "must equal row-derived feedback_kind_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "match_strategy_counts",
      frequency_map(callbacks, rows, "match_strategy"),
      "must equal row-derived match_strategy_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "cadence_import_status_counts",
      frequency_map(callbacks, rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "planned_protection_decision_counts",
      frequency_map(callbacks, rows, "planned_protection_decision"),
      "must equal row-derived planned_protection_decision_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "execution_uncertainty_declared_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "declared"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "execution_uncertainty_missing_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "missing"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "operational_feedback_excluded_count",
      Enum.count(rows, &(&1["operational_feedback_excluded"] == true))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ambiguous_timeline_match_count",
      Enum.count(rows, &(&1["match_strategy"] == "ambiguous_timeline_id"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "ambiguous_timeline_feedback_count",
      sum_ambiguous_timeline_feedback_count(rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "duplicate_realized_match_count",
      Enum.count(rows, &(Map.get(&1, "realized_match_count", 0) > 1))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "duplicate_realized_feedback_count",
      sum_duplicate_realized_feedback_count(rows)
    )
  end

  defp sum_ambiguous_timeline_feedback_count(rows) do
    Enum.reduce(rows, 0, fn row, count ->
      case row["ambiguous_planned_match_count"] do
        match_count when is_integer(match_count) and match_count > 1 -> count + match_count
        _other -> count
      end
    end)
  end

  defp sum_duplicate_realized_feedback_count(rows) do
    Enum.reduce(rows, 0, fn row, count ->
      case row["realized_match_count"] do
        match_count when is_integer(match_count) and match_count > 1 -> count + match_count - 1
        _other -> count
      end
    end)
  end

  defp timeline_feedback_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_feedback_report_model_limits), [])

  defp frequency_map(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :frequency_map), [rows, field])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

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

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
      ])

  defp validate_operational_feedback(issues, callbacks, path, feedback),
    do:
      apply(Keyword.fetch!(callbacks, :validate_operational_feedback), [
        issues,
        path,
        feedback
      ])

  defp validate_optional_exact_model_limits(issues, callbacks, path, report, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        report,
        expected,
        message
      ])

  defp validate_optional_operator_review_package(issues, callbacks, package),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_operator_review_package), [
        issues,
        package
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_timeline_feedback_row(callbacks, issues, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_timeline_feedback_row), [issues, path, row])
end
