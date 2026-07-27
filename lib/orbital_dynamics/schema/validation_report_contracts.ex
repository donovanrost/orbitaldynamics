defmodule OrbitalDynamics.Schema.ValidationReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_one_of: 5,
      expect_optional_field_equals: 6,
      expect_optional_integer: 4,
      expect_optional_list: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3
    ]

  alias OrbitalDynamics.Schema.{RegistryCapability, ValidationDiagnosticContracts}

  def validate_report(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "schema_validation_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "executable_artifact_contract_validation"
    )
    |> expect_one_of(path, report, "validation_mode", ["artifact_map", "artifact_file"])
    |> expect_type(path, report, "validated_contract", :binary)
    |> expect_one_of(path, report, "status", schema_validation_statuses())
    |> expect_type(path, report, "error_count", :integer)
    |> expect_type(path, report, "warning_count", :integer)
    |> expect_optional_integer(path, report, "remediation_count")
    |> expect_type(path, report, "errors", :list)
    |> expect_type(path, report, "warnings", :list)
    |> expect_optional_type(path, report, "remediation", :list)
    |> expect_optional_list(path, report, "model_limits")
    |> expect_type(path, report, "assumptions", :map)
    |> expect_optional_type(path, report, "artifact_path", :binary)
    |> expect_optional_type(path, report, "validated_artifact_family", :binary)
    |> expect_optional_integer(path, report, "validated_schema_version")
    |> validate_model_limits(path, report)
    |> validate_rows(
      path <> ".errors",
      Map.get(report, "errors", []),
      &ValidationDiagnosticContracts.validate_issue/3
    )
    |> validate_rows(
      path <> ".warnings",
      Map.get(report, "warnings", []),
      &ValidationDiagnosticContracts.validate_issue/3
    )
    |> validate_rows(
      path <> ".remediation",
      Map.get(report, "remediation", []),
      &ValidationDiagnosticContracts.validate_remediation/3
    )
    |> validate_report_counts(path, report)
  end

  def validate_batch(issues, path, report) do
    issues
    |> expect_equal(
      path,
      report,
      "schema_contract",
      "schema_validation_batch_report.v1"
    )
    |> expect_one_of(path, report, "validation_mode", ["artifact_directory"])
    |> expect_one_of(path, report, "status", ["pass", "fail"])
    |> expect_type(path, report, "input_dir", :binary)
    |> expect_optional_field_equals(
      path,
      report,
      "model",
      "executable_artifact_contract_batch_validation",
      "must equal \"executable_artifact_contract_batch_validation\""
    )
    |> expect_optional_list(path, report, "model_limits")
    |> validate_model_limits(path, report)
    |> expect_type(path, report, "file_count", :integer)
    |> expect_type(path, report, "artifact_count", :integer)
    |> expect_type(path, report, "skipped_count", :integer)
    |> expect_type(path, report, "error_count", :integer)
    |> expect_type(path, report, "warning_count", :integer)
    |> expect_optional_integer(path, report, "remediation_count")
    |> expect_optional_type(path, report, "status_counts", :map)
    |> expect_type(path, report, "skipped_artifacts", :list)
    |> expect_type(path, report, "reports", :list)
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(report, "status_counts", %{})
    )
    |> validate_rows(
      path <> ".skipped_artifacts",
      Map.get(report, "skipped_artifacts", []),
      fn acc, row_path, entry -> validate_skipped_artifact(acc, row_path, entry) end
    )
    |> validate_rows(
      path <> ".reports",
      Map.get(report, "reports", []),
      fn acc, row_path, entry -> validate_batch_entry(acc, row_path, entry) end
    )
    |> validate_batch_counts(path, report)
  end

  defp validate_batch_entry(issues, path, entry) do
    issues
    |> require_fields(path, entry, ["path", "report"])
    |> expect_type(path, entry, "path", :binary)
    |> validate_nested_report(path <> ".report", Map.get(entry, "report"))
  end

  defp validate_nested_report(issues, path, %{} = report) do
    validate_report(issues, path, report)
  end

  defp validate_nested_report(issues, path, _report) do
    [error(path, "must be an object") | issues]
  end

  defp validate_skipped_artifact(issues, path, entry) do
    issues
    |> require_fields(path, entry, ["path", "reason"])
    |> expect_type(path, entry, "path", :binary)
    |> expect_type(path, entry, "reason", :binary)
  end

  defp validate_model_limits(issues, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      limits when is_list(limits) ->
        if limits == model_limits() do
          issues
        else
          [
            error(
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

  defp validate_report_counts(issues, path, report) do
    error_count = report |> Map.get("errors") |> list_or_empty() |> length()
    expected_status = if error_count == 0, do: "pass", else: "fail"

    issues
    |> expect_field_equals(path, report, "status", expected_status)
    |> expect_field_equals(path, report, "error_count", error_count)
    |> expect_field_equals(
      path,
      report,
      "warning_count",
      report |> Map.get("warnings") |> list_or_empty() |> length()
    )
    |> expect_field_equals(
      path,
      report,
      "remediation_count",
      report |> Map.get("remediation") |> list_or_empty() |> length()
    )
  end

  defp validate_batch_counts(issues, path, report) do
    reports = report |> Map.get("reports") |> list_or_empty()
    skipped_artifacts = report |> Map.get("skipped_artifacts") |> list_or_empty()

    nested_reports =
      reports
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, "report"))
      |> Enum.filter(&is_map/1)

    {error_count, warning_count, remediation_count} =
      nested_reports
      |> Enum.reduce({0, 0, 0}, fn nested_report, {errors, warnings, remediation} ->
        {
          errors + integer_or_zero(Map.get(nested_report, "error_count")),
          warnings + integer_or_zero(Map.get(nested_report, "warning_count")),
          remediation + integer_or_zero(Map.get(nested_report, "remediation_count"))
        }
      end)

    status_counts =
      nested_reports
      |> Enum.map(&Map.get(&1, "status"))
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()

    issues
    |> expect_field_equals(
      path,
      report,
      "file_count",
      length(reports) + length(skipped_artifacts)
    )
    |> expect_field_equals(path, report, "artifact_count", length(reports))
    |> expect_field_equals(path, report, "skipped_count", length(skipped_artifacts))
    |> expect_field_equals(
      path,
      report,
      "status",
      if(error_count == 0, do: "pass", else: "fail")
    )
    |> expect_field_equals(
      path,
      report,
      "status_counts",
      status_counts,
      "must equal nested schema-validation report status counts"
    )
    |> expect_field_equals(path, report, "error_count", error_count)
    |> expect_field_equals(path, report, "warning_count", warning_count)
    |> expect_field_equals(path, report, "remediation_count", remediation_count)
  end

  defp schema_validation_statuses, do: ["pass", "fail"]
  defp model_limits, do: RegistryCapability.model_limits()

  defp integer_or_zero(value) when is_integer(value), do: value
  defp integer_or_zero(_value), do: 0

  defp list_or_empty(value) when is_list(value), do: value
  defp list_or_empty(_value), do: []

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
