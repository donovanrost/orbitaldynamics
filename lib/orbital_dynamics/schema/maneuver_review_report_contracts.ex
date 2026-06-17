defmodule OrbitalDynamics.Schema.ManeuverReviewReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "maneuver_review_report.v1")
    |> expect_equal(callbacks, path, report, "model", "artifact_only_maneuver_review_report")
    |> expect_type(callbacks, path, report, "source", :binary)
    |> validate_stable_ids(callbacks, path, report, ["source_artifact_id"])
    |> expect_non_negative_integer(callbacks, path, report, "maneuver_count")
    |> expect_non_negative_integer(callbacks, path, report, "review_required_count")
    |> expect_number(callbacks, path, report, "total_delta_v_km_s")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_maneuver_recommendation_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_maneuver_recommendation_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "invalid_maneuver_recommendation_ids"
    )
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
    |> expect_optional_type(callbacks, path, report, "approval_status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_model_limits(callbacks, path, report)
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_counts(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
  end

  defp validate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    invalid_ids =
      rows
      |> Enum.filter(&(&1["invalid_maneuver_recommendation"] == true))
      |> Enum.map(&Map.get(&1, "maneuver_id"))

    issues
    |> expect_field_equals(callbacks, path, report, "maneuver_count", length(rows))
    |> expect_field_equals(callbacks, path, report, "review_required_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_maneuver_recommendation_count",
      length(invalid_ids)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_maneuver_recommendation_ids",
      invalid_ids,
      "must match invalid maneuver recommendation row IDs"
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
      "total_delta_v_km_s",
      total_delta_v(rows),
      "must equal row-derived total_delta_v_km_s"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "approval_status_counts",
      frequency_map(callbacks, rows, "approval_status"),
      "must equal row-derived approval_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_operator_action_counts",
      frequency_map(callbacks, rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
  end

  defp validate_model_limits(issues, callbacks, path, report) do
    expect_field_equals(
      issues,
      callbacks,
      path,
      report,
      "model_limits",
      maneuver_review_report_model_limits(callbacks),
      "must match maneuver review report model limits"
    )
  end

  defp total_delta_v(rows) do
    rows
    |> Enum.map(&Map.get(&1, "delta_v_magnitude_km_s"))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp validate_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
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
    |> validate_stable_ids(callbacks, path, row, ["id", "maneuver_id", "scenario_id"])
    |> expect_number(callbacks, path, row, "rank")
    |> expect_type(callbacks, path, row, "maneuver_type", :binary)
    |> expect_number(callbacks, path, row, "epoch_s")
    |> expect_optional_type(callbacks, path, row, "epoch_scale", :binary)
    |> expect_type(callbacks, path, row, "frame", :binary)
    |> expect_number_vector(callbacks, path <> ".delta_v_km_s", Map.get(row, "delta_v_km_s"))
    |> expect_optional_number(callbacks, path, row, "delta_v_magnitude_km_s")
    |> expect_type(callbacks, path, row, "maneuver_model", :binary)
    |> expect_one_of(callbacks, path, row, "approval_status", [
      "operator_review_required",
      "auto_approvable",
      "blocked_by_policy"
    ])
    |> expect_optional_type(callbacks, path, row, "execution_uncertainty_status", :binary)
    |> expect_type(callbacks, path, row, "required_operator_action", :binary)
    |> expect_type(callbacks, path, row, "reason", :binary)
    |> expect_type(callbacks, path, row, "execution_boundary", :binary)
    |> expect_type(callbacks, path, row, "source_recommendation", :map)
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp maneuver_review_report_model_limits(callbacks),
    do: apply(require_callback(callbacks, :maneuver_review_report_model_limits), [])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_number_vector(issues, callbacks, path, value),
    do: apply(require_callback(callbacks, :expect_number_vector), [issues, path, value])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp frequency_map(callbacks, rows, field),
    do: apply(require_callback(callbacks, :frequency_map), [rows, field])
end
