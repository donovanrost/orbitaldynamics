defmodule OrbitalDynamics.Schema.ValidationReportContracts do
  @moduledoc false

  def validate_report(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "schema_validation_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "executable_artifact_contract_validation"
    )
    |> expect_one_of(callbacks, path, report, "validation_mode", ["artifact_map", "artifact_file"])
    |> expect_type(callbacks, path, report, "validated_contract", :binary)
    |> expect_one_of(callbacks, path, report, "status", schema_validation_statuses(callbacks))
    |> expect_type(callbacks, path, report, "error_count", :integer)
    |> expect_type(callbacks, path, report, "warning_count", :integer)
    |> expect_optional_integer(callbacks, path, report, "remediation_count")
    |> expect_type(callbacks, path, report, "errors", :list)
    |> expect_type(callbacks, path, report, "warnings", :list)
    |> expect_optional_type(callbacks, path, report, "remediation", :list)
    |> expect_optional_list(callbacks, path, report, "model_limits")
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> expect_optional_type(callbacks, path, report, "artifact_path", :binary)
    |> expect_optional_type(callbacks, path, report, "validated_artifact_family", :binary)
    |> expect_optional_integer(callbacks, path, report, "validated_schema_version")
    |> validate_model_limits(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".errors",
      Map.get(report, "errors", []),
      validation_issue_fun(callbacks)
    )
    |> validate_rows(
      callbacks,
      path <> ".warnings",
      Map.get(report, "warnings", []),
      validation_issue_fun(callbacks)
    )
    |> validate_rows(
      callbacks,
      path <> ".remediation",
      Map.get(report, "remediation", []),
      validation_remediation_fun(callbacks)
    )
    |> validate_report_counts(callbacks, path, report)
  end

  def validate_batch(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      report,
      "schema_contract",
      "schema_validation_batch_report.v1"
    )
    |> expect_one_of(callbacks, path, report, "validation_mode", ["artifact_directory"])
    |> expect_one_of(callbacks, path, report, "status", ["pass", "fail"])
    |> expect_type(callbacks, path, report, "input_dir", :binary)
    |> expect_optional_field_equals(
      callbacks,
      path,
      report,
      "model",
      "executable_artifact_contract_batch_validation",
      "must equal \"executable_artifact_contract_batch_validation\""
    )
    |> expect_optional_list(callbacks, path, report, "model_limits")
    |> validate_model_limits(callbacks, path, report)
    |> expect_type(callbacks, path, report, "file_count", :integer)
    |> expect_type(callbacks, path, report, "artifact_count", :integer)
    |> expect_type(callbacks, path, report, "skipped_count", :integer)
    |> expect_type(callbacks, path, report, "error_count", :integer)
    |> expect_type(callbacks, path, report, "warning_count", :integer)
    |> expect_optional_integer(callbacks, path, report, "remediation_count")
    |> expect_optional_type(callbacks, path, report, "status_counts", :map)
    |> expect_type(callbacks, path, report, "skipped_artifacts", :list)
    |> expect_type(callbacks, path, report, "reports", :list)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(report, "status_counts", %{})
    )
    |> validate_rows(
      callbacks,
      path <> ".skipped_artifacts",
      Map.get(report, "skipped_artifacts", []),
      fn acc, row_path, entry -> validate_skipped_artifact(acc, row_path, entry, callbacks) end
    )
    |> validate_rows(
      callbacks,
      path <> ".reports",
      Map.get(report, "reports", []),
      fn acc, row_path, entry -> validate_batch_entry(acc, row_path, entry, callbacks) end
    )
    |> validate_batch_counts(callbacks, path, report)
  end

  defp validate_batch_entry(issues, path, entry, callbacks) do
    issues
    |> require_fields(callbacks, path, entry, ["path", "report"])
    |> expect_type(callbacks, path, entry, "path", :binary)
    |> validate_nested_report(callbacks, path <> ".report", Map.get(entry, "report"))
  end

  defp validate_nested_report(issues, callbacks, path, %{} = report) do
    validate_report(issues, path, report, callbacks)
  end

  defp validate_nested_report(issues, callbacks, path, _report) do
    [error(callbacks, path, "must be an object") | issues]
  end

  defp validate_skipped_artifact(issues, path, entry, callbacks) do
    issues
    |> require_fields(callbacks, path, entry, ["path", "reason"])
    |> expect_type(callbacks, path, entry, "path", :binary)
    |> expect_type(callbacks, path, entry, "reason", :binary)
  end

  defp validate_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      limits when is_list(limits) ->
        if limits == model_limits(callbacks) do
          issues
        else
          [
            error(
              callbacks,
              path <> ".model_limits",
              "must match schema validation model limits"
            )
            | issues
          ]
        end

      _limits ->
        issues
    end
  end

  defp validate_report_counts(issues, callbacks, path, report) do
    error_count = length(Map.get(report, "errors", []))
    expected_status = if error_count == 0, do: "pass", else: "fail"

    issues
    |> expect_field_equals(callbacks, path, report, "status", expected_status)
    |> expect_field_equals(callbacks, path, report, "error_count", error_count)
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "warning_count",
      length(Map.get(report, "warnings", []))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "remediation_count",
      length(Map.get(report, "remediation", []))
    )
  end

  defp validate_batch_counts(issues, callbacks, path, report) do
    reports = Map.get(report, "reports", [])
    skipped_artifacts = Map.get(report, "skipped_artifacts", [])

    {error_count, warning_count, remediation_count} =
      reports
      |> Enum.map(&Map.get(&1, "report"))
      |> Enum.filter(&is_map/1)
      |> Enum.reduce({0, 0, 0}, fn nested_report, {errors, warnings, remediation} ->
        {
          errors + integer_or_zero(Map.get(nested_report, "error_count")),
          warnings + integer_or_zero(Map.get(nested_report, "warning_count")),
          remediation + integer_or_zero(Map.get(nested_report, "remediation_count"))
        }
      end)

    status_counts =
      reports
      |> Enum.map(&get_in(&1, ["report", "status"]))
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "file_count",
      length(reports) + length(skipped_artifacts)
    )
    |> expect_field_equals(callbacks, path, report, "artifact_count", length(reports))
    |> expect_field_equals(callbacks, path, report, "skipped_count", length(skipped_artifacts))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status",
      if(error_count == 0, do: "pass", else: "fail")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_counts",
      status_counts,
      "must equal nested schema-validation report status counts"
    )
    |> expect_field_equals(callbacks, path, report, "error_count", error_count)
    |> expect_field_equals(callbacks, path, report, "warning_count", warning_count)
    |> expect_field_equals(callbacks, path, report, "remediation_count", remediation_count)
  end

  defp validation_issue_fun(callbacks), do: Keyword.fetch!(callbacks, :validate_validation_issue)

  defp validation_remediation_fun(callbacks),
    do: Keyword.fetch!(callbacks, :validate_validation_remediation)

  defp schema_validation_statuses(callbacks) do
    callbacks
    |> Keyword.fetch!(:schema_validation_statuses)
    |> then(& &1.())
  end

  defp model_limits(callbacks) do
    callbacks
    |> Keyword.fetch!(:schema_validation_model_limits)
    |> then(& &1.())
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_list(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_list), [issues, path, map, field])

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
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

  defp validate_non_negative_integer_count_map(issues, callbacks, path, values),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        values
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])

  defp integer_or_zero(value) when is_integer(value), do: value
  defp integer_or_zero(_value), do: 0
end
