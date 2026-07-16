defmodule OrbitalDynamics.Schema.LintContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]
  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 5,
      expect_field_equals: 6,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  alias OrbitalDynamics.Schema.ValidationDiagnosticContracts

  @sha256_regex ~r/\A[0-9a-f]{64}\z/

  def validate_campaign_request(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "campaign_request_lint.v1")
    |> expect_equal(path, report, "validation_mode", "campaign_request_lint")
    |> expect_equal(
      path,
      report,
      "semantic_validator",
      "OrbitalDynamics.CampaignPlanner.request_validation_report/3"
    )
    |> expect_type(path, report, "lint_task", :binary)
    |> expect_one_of(path, report, "type", ["repair", "strategy"])
    |> expect_one_of(path, report, "status", ["pass", "fail"])
    |> expect_type(path, report, "error_count", :integer)
    |> expect_type(path, report, "errors", :list)
    |> expect_type(path, report, "request", :map)
    |> expect_optional_type(path, report, "source_plan", :map)
    |> validate_rows(
      path <> ".errors",
      Map.get(report, "errors", []),
      &ValidationDiagnosticContracts.validate_issue/3
    )
    |> expect_field_equals(
      path,
      report,
      "error_count",
      length(Map.get(report, "errors", []))
    )
    |> validate_campaign_request_status(path, report)
    |> validate_campaign_request_ref(
      path <> ".request",
      Map.get(report, "request", %{})
    )
    |> validate_campaign_source_plan_ref(
      path <> ".source_plan",
      Map.get(report, "source_plan")
    )
  end

  def validate_study_manifest(issues, path, report) do
    errors = Map.get(report, "errors", [])
    warnings = Map.get(report, "warnings", [])
    supported_codes = get_in(report, ["supported", "lint_error_codes"]) || []
    expected_status = if length(errors) == 0, do: "pass", else: "fail"

    issues
    |> expect_equal(path, report, "schema_contract", "study_manifest_lint.v1")
    |> expect_equal(path, report, "schema_version", 1)
    |> expect_type(path, report, "schema_id", :binary)
    |> expect_equal(path, report, "manifest_schema_contract", "study_manifest.v1")
    |> expect_type(path, report, "manifest_schema_id", :binary)
    |> expect_equal(path, report, "validation_mode", "study_manifest_lint")
    |> expect_equal(
      path,
      report,
      "semantic_validator",
      "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2"
    )
    |> expect_type(path, report, "lint_task", :binary)
    |> expect_type(path, report, "schema_export_command", :binary)
    |> expect_type(path, report, "supported", :map)
    |> expect_type(path, report, "manifest", :map)
    |> expect_one_of(path, report, "status", ["pass", "fail"])
    |> expect_type(path, report, "error_count", :integer)
    |> expect_type(path, report, "warning_count", :integer)
    |> expect_type(path, report, "errors", :list)
    |> expect_type(path, report, "warnings", :list)
    |> expect_optional_type(path, report, "study_id", :binary)
    |> expect_optional_type(path, report, "scenario_count", :integer)
    |> expect_optional_type(path, report, "outputs", :list)
    |> validate_study_manifest_supported(
      path <> ".supported",
      Map.get(report, "supported", %{})
    )
    |> validate_study_manifest_manifest(
      path <> ".manifest",
      Map.get(report, "manifest", %{})
    )
    |> validate_rows(path <> ".errors", errors, fn acc, row_path, issue ->
      validate_manifest_lint_issue(acc, row_path, issue)
    end)
    |> validate_rows(path <> ".warnings", warnings, fn acc, row_path, issue ->
      validate_manifest_lint_issue(acc, row_path, issue)
    end)
    |> validate_manifest_lint_issue_codes(path <> ".errors", errors, supported_codes)
    |> validate_manifest_lint_issue_codes(
      path <> ".warnings",
      warnings,
      supported_codes
    )
    |> validate_string_list_items(path, report, "outputs")
    |> validate_study_manifest_outputs(path, report)
    |> expect_field_equals(path, report, "status", expected_status)
    |> expect_field_equals(path, report, "error_count", length(errors))
    |> expect_field_equals(path, report, "warning_count", length(warnings))
  end

  defp validate_campaign_request_status(issues, path, report) do
    case Map.get(report, "error_count") do
      count when is_integer(count) and count == 0 ->
        expect_field_equals(
          issues,
          path,
          report,
          "status",
          "pass",
          "must be pass when error_count is zero"
        )

      count when is_integer(count) and count > 0 ->
        expect_field_equals(
          issues,
          path,
          report,
          "status",
          "fail",
          "must be fail when error_count is positive"
        )

      _count ->
        issues
    end
  end

  defp validate_campaign_request_ref(issues, path, request) do
    issues
    |> require_fields(path, request, ["path", "sha256"])
    |> expect_type(path, request, "path", :binary)
    |> expect_type(path, request, "sha256", :binary)
    |> validate_sha256_field(path, request, "sha256")
  end

  defp validate_campaign_source_plan_ref(issues, _path, nil), do: issues

  defp validate_campaign_source_plan_ref(issues, path, source_plan)
       when is_map(source_plan) do
    issues
    |> require_fields(path, source_plan, [
      "schema_contract",
      "status",
      "path",
      "sha256"
    ])
    |> expect_one_of(path, source_plan, "status", ["pass", "fail"])
    |> expect_type(path, source_plan, "schema_contract", :binary)
    |> expect_type(path, source_plan, "path", :binary)
    |> expect_type(path, source_plan, "sha256", :binary)
    |> validate_sha256_field(path, source_plan, "sha256")
    |> validate_stable_ids(path, source_plan, ["plan_id"])
  end

  defp validate_campaign_source_plan_ref(issues, path, _source_plan),
    do: [error(path, "must be an object") | issues]

  defp validate_sha256_field(issues, path, map, field) do
    case Map.get(map, field) do
      value when is_binary(value) ->
        if Regex.match?(@sha256_regex, value) do
          issues
        else
          [
            error("#{path}.#{field}", "must be a lowercase SHA-256 hex digest")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_study_manifest_outputs(issues, path, report) do
    outputs = list_value(report, "outputs")
    supported_outputs = get_in(report, ["supported", "outputs"]) || []

    issues
    |> reject_duplicate_strings(
      path <> ".outputs",
      outputs,
      "must not contain duplicate outputs"
    )
    |> validate_study_manifest_supported_outputs(path, outputs, supported_outputs)
  end

  defp validate_study_manifest_supported_outputs(
         issues,
         path,
         outputs,
         supported_outputs
       )
       when is_list(outputs) and is_list(supported_outputs) do
    unsupported_outputs =
      outputs
      |> Enum.filter(&(is_binary(&1) and &1 not in supported_outputs))
      |> Enum.sort()

    if unsupported_outputs == [] do
      issues
    else
      [error(path <> ".outputs", "must be included in supported.outputs") | issues]
    end
  end

  defp validate_study_manifest_supported_outputs(
         issues,
         _path,
         _outputs,
         _supported_outputs
       ),
       do: issues

  defp reject_duplicate_strings(issues, path, values, message) do
    duplicates =
      values
      |> Enum.filter(&is_binary/1)
      |> Enum.frequencies()
      |> Enum.filter(fn {_value, count} -> count > 1 end)

    if duplicates == [] do
      issues
    else
      [error(path, message) | issues]
    end
  end

  defp validate_study_manifest_supported(issues, path, supported)
       when is_map(supported) do
    issues
    |> require_fields(path, supported, ["lint_error_codes", "outputs", "propagators"])
    |> expect_type(path, supported, "lint_error_codes", :list)
    |> expect_type(path, supported, "outputs", :list)
    |> expect_type(path, supported, "propagators", :list)
    |> validate_string_list_items(path, supported, "lint_error_codes")
    |> validate_string_list_items(path, supported, "outputs")
    |> validate_string_list_items(path, supported, "propagators")
    |> validate_string_list_items(path, supported, "search_objectives")
  end

  defp validate_study_manifest_supported(issues, path, _supported),
    do: [error(path, "must be an object") | issues]

  defp validate_study_manifest_manifest(issues, path, manifest)
       when is_map(manifest) do
    issues
    |> require_fields(path, manifest, ["path"])
    |> expect_type(path, manifest, "path", :binary)
    |> expect_optional_type(path, manifest, "sha256", :binary)
  end

  defp validate_study_manifest_manifest(issues, path, _manifest),
    do: [error(path, "must be an object") | issues]

  defp validate_manifest_lint_issue(issues, path, issue) do
    issues
    |> require_fields(path, issue, ["code", "path", "message", "details"])
    |> expect_type(path, issue, "code", :binary)
    |> expect_type(path, issue, "path", :binary)
    |> expect_type(path, issue, "message", :binary)
    |> expect_type(path, issue, "details", :map)
  end

  defp validate_manifest_lint_issue_codes(issues, path, rows, supported_codes)
       when is_list(rows) and is_list(supported_codes) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      code = if is_map(row), do: Map.get(row, "code")

      if is_binary(code) and code not in supported_codes do
        [
          error("#{path}[#{index}].code", "must be one of #{inspect(supported_codes)}")
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_manifest_lint_issue_codes(issues, _path, _rows, _supported_codes),
    do: issues

  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []
end
