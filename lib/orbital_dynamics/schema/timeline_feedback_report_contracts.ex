defmodule OrbitalDynamics.Schema.TimelineFeedbackReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    OperationalFeedbackContracts,
    TimelineFeedbackRowContracts
  }

  import OrbitalDynamics.Schema.CollectionAggregation, only: [frequency_map: 2]
  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  def validate(
        issues,
        path,
        report,
        timeline_feedback_report_model_limits,
        optional_operator_review_package_validator
      )
      when is_list(timeline_feedback_report_model_limits) and
             is_function(optional_operator_review_package_validator, 2) do
    issues
    |> expect_equal(path, report, "schema_contract", "timeline_feedback_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "planned_vs_realized_activity_reconciliation"
    )
    |> expect_non_negative_integer(path, report, "planned_count")
    |> expect_non_negative_integer(path, report, "realized_count")
    |> expect_non_negative_integer(path, report, "row_count")
    |> expect_type(path, report, "status_counts", :map)
    |> expect_optional_type(path, report, "feedback_kind_counts", :map)
    |> expect_optional_type(path, report, "match_strategy_counts", :map)
    |> expect_optional_type(path, report, "cadence_import_status_counts", :map)
    |> expect_optional_type(path, report, "planned_protection_decision_counts", :map)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "execution_uncertainty_declared_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "execution_uncertainty_missing_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "operational_feedback_excluded_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "ambiguous_timeline_match_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "ambiguous_timeline_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_realized_match_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_realized_feedback_count"
    )
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      timeline_feedback_report_model_limits,
      "must match timeline feedback report model limits"
    )
    |> expect_optional_type(path, report, "operational_feedback", :map)
    |> OperationalFeedbackContracts.validate(path, Map.get(report, "operational_feedback"))
    |> expect_optional_type(path, report, "operational_feedback_provenance", :map)
    |> expect_optional_type(path, report, "cadence_import_manifest", :map)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_counts(path, report)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> TimelineFeedbackRowContracts.validate(acc, row_path, row) end
    )
    |> optional_operator_review_package_validator.(Map.get(report, "operator_review_package"))
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(report, "status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".feedback_kind_counts",
      Map.get(report, "feedback_kind_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".match_strategy_counts",
      Map.get(report, "match_strategy_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".cadence_import_status_counts",
      Map.get(report, "cadence_import_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".planned_protection_decision_counts",
      Map.get(report, "planned_protection_decision_counts")
    )
    |> expect_field_equals(path, report, "row_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "status_counts",
      frequency_map(rows, "status"),
      "must equal row-derived status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "feedback_kind_counts",
      frequency_map(rows, "feedback_kind"),
      "must equal row-derived feedback_kind_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "match_strategy_counts",
      frequency_map(rows, "match_strategy"),
      "must equal row-derived match_strategy_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "cadence_import_status_counts",
      frequency_map(rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "planned_protection_decision_counts",
      frequency_map(rows, "planned_protection_decision"),
      "must equal row-derived planned_protection_decision_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "execution_uncertainty_declared_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "declared"))
    )
    |> expect_field_equals(
      path,
      report,
      "execution_uncertainty_missing_count",
      Enum.count(rows, &(&1["execution_uncertainty_status"] == "missing"))
    )
    |> expect_field_equals(
      path,
      report,
      "operational_feedback_excluded_count",
      Enum.count(rows, &(&1["operational_feedback_excluded"] == true))
    )
    |> expect_field_equals(
      path,
      report,
      "ambiguous_timeline_match_count",
      Enum.count(rows, &(&1["match_strategy"] == "ambiguous_timeline_id"))
    )
    |> expect_field_equals(
      path,
      report,
      "ambiguous_timeline_feedback_count",
      sum_ambiguous_timeline_feedback_count(rows)
    )
    |> expect_field_equals(
      path,
      report,
      "duplicate_realized_match_count",
      Enum.count(rows, &(Map.get(&1, "realized_match_count", 0) > 1))
    )
    |> expect_field_equals(
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

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
