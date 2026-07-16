defmodule OrbitalDynamics.Schema.ManeuverReviewReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation, only: [frequency_map: 2]
  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_number_vector: 3,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, report, maneuver_review_report_model_limits)
      when is_list(maneuver_review_report_model_limits) do
    issues
    |> expect_equal(path, report, "schema_contract", "maneuver_review_report.v1")
    |> expect_equal(path, report, "model", "artifact_only_maneuver_review_report")
    |> expect_type(path, report, "source", :binary)
    |> validate_stable_ids(path, report, ["source_artifact_id"])
    |> expect_non_negative_integer(path, report, "maneuver_count")
    |> expect_non_negative_integer(path, report, "review_required_count")
    |> expect_number(path, report, "total_delta_v_km_s")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_maneuver_recommendation_count"
    )
    |> expect_optional_type(path, report, "invalid_maneuver_recommendation_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      report,
      "invalid_maneuver_recommendation_ids"
    )
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
    |> expect_optional_type(path, report, "approval_status_counts", :map)
    |> expect_optional_type(path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_model_limits(path, report, maneuver_review_report_model_limits)
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_counts(path, report)
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_row/3
    )
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    invalid_ids =
      rows
      |> Enum.filter(&(&1["invalid_maneuver_recommendation"] == true))
      |> Enum.map(&Map.get(&1, "maneuver_id"))

    issues
    |> expect_field_equals(path, report, "maneuver_count", length(rows))
    |> expect_field_equals(path, report, "review_required_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "invalid_maneuver_recommendation_count",
      length(invalid_ids)
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_maneuver_recommendation_ids",
      invalid_ids,
      "must match invalid maneuver recommendation row IDs"
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
      "total_delta_v_km_s",
      total_delta_v(rows),
      "must equal row-derived total_delta_v_km_s"
    )
    |> expect_field_equals(
      path,
      report,
      "approval_status_counts",
      frequency_map(rows, "approval_status"),
      "must equal row-derived approval_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
  end

  defp validate_model_limits(issues, path, report, maneuver_review_report_model_limits) do
    expect_field_equals(
      issues,
      path,
      report,
      "model_limits",
      maneuver_review_report_model_limits,
      "must match maneuver review report model limits"
    )
  end

  defp total_delta_v(rows) do
    rows
    |> Enum.map(&Map.get(&1, "delta_v_magnitude_km_s"))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "rank",
      "maneuver_id",
      "scenario_id",
      "maneuver_type",
      "epoch_s",
      "frame",
      "delta_v_km_s",
      "maneuver_model",
      "approval_status",
      "required_operator_action",
      "reason",
      "execution_boundary",
      "source_recommendation"
    ])
    |> validate_stable_ids(path, row, ["id", "maneuver_id", "scenario_id"])
    |> expect_number(path, row, "rank")
    |> expect_type(path, row, "maneuver_type", :binary)
    |> expect_number(path, row, "epoch_s")
    |> expect_optional_type(path, row, "epoch_scale", :binary)
    |> expect_type(path, row, "frame", :binary)
    |> expect_number_vector(path <> ".delta_v_km_s", Map.get(row, "delta_v_km_s"))
    |> expect_optional_number(path, row, "delta_v_magnitude_km_s")
    |> expect_type(path, row, "maneuver_model", :binary)
    |> expect_one_of(path, row, "approval_status", [
      "operator_review_required",
      "auto_approvable",
      "blocked_by_policy"
    ])
    |> expect_optional_type(path, row, "execution_uncertainty_status", :binary)
    |> expect_type(path, row, "required_operator_action", :binary)
    |> expect_type(path, row, "reason", :binary)
    |> expect_type(path, row, "execution_boundary", :binary)
    |> expect_type(path, row, "source_recommendation", :map)
  end
end
