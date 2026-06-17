defmodule OrbitalDynamics.Schema.ConstraintReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "constraint_report.v1")
    |> expect_type(callbacks, path, report, "model", :binary)
    |> expect_one_of(callbacks, path, report, "model", constraint_report_models(callbacks))
    |> expect_non_negative_integer(callbacks, path, report, "constraint_count")
    |> expect_non_negative_integer(callbacks, path, report, "row_count")
    |> expect_one_of(callbacks, path, report, "status", ["pass", "fail", "warning"])
    |> expect_type(callbacks, path, report, "status_counts", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_model_limits(callbacks, path, report)
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
    |> validate_counts(callbacks, path, report)
  end

  defp validate_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        expected_limits =
          Map.get(constraint_report_model_limits_by_model(callbacks), report["model"])

        if is_nil(expected_limits) or limits == expected_limits do
          issues
        else
          [
            error(callbacks, "#{path}.model_limits", "must match constraint report model limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, report, "constraint_count", constraint_id_count(rows))
    |> expect_field_equals(callbacks, path, report, "row_count", length(rows))
    |> expect_field_equals(callbacks, path, report, "status", report_status(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_counts",
      status_counts(callbacks, rows),
      "must equal row-derived status_counts"
    )
  end

  defp constraint_id_count(rows) do
    rows
    |> Enum.map(&Map.get(&1, "constraint_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp report_status(rows) do
    statuses = Enum.map(rows, &Map.get(&1, "status"))

    cond do
      "fail" in statuses -> "fail"
      "warning" in statuses -> "warning"
      true -> "pass"
    end
  end

  defp status_counts(callbacks, rows) do
    callbacks
    |> frequency_map(rows, "status")
    |> Map.put_new("pass", 0)
    |> Map.put_new("fail", 0)
    |> Map.put_new("warning", 0)
  end

  defp validate_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "constraint_id",
      "scenario_id",
      "metric",
      "operator",
      "threshold",
      "status"
    ])
    |> validate_stable_ids(callbacks, path, row, ["constraint_id", "scenario_id"])
    |> expect_one_of(callbacks, path, row, "operator", ["<", "<=", "==", ">=", ">"])
    |> expect_number(callbacks, path, row, "threshold")
    |> expect_optional_number(callbacks, path, row, "value")
    |> expect_optional_number(callbacks, path, row, "score")
    |> expect_one_of(callbacks, path, row, "status", ["pass", "fail", "warning"])
  end

  defp constraint_report_models(callbacks),
    do: apply(Keyword.fetch!(callbacks, :constraint_report_models), [])

  defp constraint_report_model_limits_by_model(callbacks),
    do: apply(Keyword.fetch!(callbacks, :constraint_report_model_limits_by_model), [])

  defp frequency_map(callbacks, rows, field),
    do: apply(Keyword.fetch!(callbacks, :frequency_map), [rows, field])

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

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
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

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
