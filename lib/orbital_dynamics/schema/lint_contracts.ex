defmodule OrbitalDynamics.Schema.LintContracts do
  @moduledoc false

  @sha256_regex ~r/\A[0-9a-f]{64}\z/

  def validate_campaign_request(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "campaign_request_lint.v1")
    |> expect_equal(callbacks, path, report, "validation_mode", "campaign_request_lint")
    |> expect_equal(
      callbacks,
      path,
      report,
      "semantic_validator",
      "OrbitalDynamics.CampaignPlanner.request_validation_report/3"
    )
    |> expect_type(callbacks, path, report, "lint_task", :binary)
    |> expect_one_of(callbacks, path, report, "type", ["repair", "strategy"])
    |> expect_one_of(callbacks, path, report, "status", ["pass", "fail"])
    |> expect_type(callbacks, path, report, "error_count", :integer)
    |> expect_type(callbacks, path, report, "errors", :list)
    |> expect_type(callbacks, path, report, "request", :map)
    |> expect_optional_type(callbacks, path, report, "source_plan", :map)
    |> validate_rows(
      callbacks,
      path <> ".errors",
      Map.get(report, "errors", []),
      validation_issue_fun(callbacks)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "error_count",
      length(Map.get(report, "errors", []))
    )
    |> validate_campaign_request_status(callbacks, path, report)
    |> validate_campaign_request_ref(
      callbacks,
      path <> ".request",
      Map.get(report, "request", %{})
    )
    |> validate_campaign_source_plan_ref(
      callbacks,
      path <> ".source_plan",
      Map.get(report, "source_plan")
    )
  end

  def validate_study_manifest(issues, path, report, callbacks) when is_list(callbacks) do
    errors = Map.get(report, "errors", [])
    warnings = Map.get(report, "warnings", [])
    supported_codes = get_in(report, ["supported", "lint_error_codes"]) || []
    expected_status = if length(errors) == 0, do: "pass", else: "fail"

    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "study_manifest_lint.v1")
    |> expect_equal(callbacks, path, report, "schema_version", 1)
    |> expect_type(callbacks, path, report, "schema_id", :binary)
    |> expect_equal(callbacks, path, report, "manifest_schema_contract", "study_manifest.v1")
    |> expect_type(callbacks, path, report, "manifest_schema_id", :binary)
    |> expect_equal(callbacks, path, report, "validation_mode", "study_manifest_lint")
    |> expect_equal(
      callbacks,
      path,
      report,
      "semantic_validator",
      "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2"
    )
    |> expect_type(callbacks, path, report, "lint_task", :binary)
    |> expect_type(callbacks, path, report, "schema_export_command", :binary)
    |> expect_type(callbacks, path, report, "supported", :map)
    |> expect_type(callbacks, path, report, "manifest", :map)
    |> expect_one_of(callbacks, path, report, "status", ["pass", "fail"])
    |> expect_type(callbacks, path, report, "error_count", :integer)
    |> expect_type(callbacks, path, report, "warning_count", :integer)
    |> expect_type(callbacks, path, report, "errors", :list)
    |> expect_type(callbacks, path, report, "warnings", :list)
    |> expect_optional_type(callbacks, path, report, "study_id", :binary)
    |> expect_optional_type(callbacks, path, report, "scenario_count", :integer)
    |> expect_optional_type(callbacks, path, report, "outputs", :list)
    |> validate_study_manifest_supported(
      callbacks,
      path <> ".supported",
      Map.get(report, "supported", %{})
    )
    |> validate_study_manifest_manifest(
      callbacks,
      path <> ".manifest",
      Map.get(report, "manifest", %{})
    )
    |> validate_rows(callbacks, path <> ".errors", errors, fn acc, row_path, issue ->
      validate_manifest_lint_issue(acc, row_path, issue, callbacks)
    end)
    |> validate_rows(callbacks, path <> ".warnings", warnings, fn acc, row_path, issue ->
      validate_manifest_lint_issue(acc, row_path, issue, callbacks)
    end)
    |> validate_manifest_lint_issue_codes(callbacks, path <> ".errors", errors, supported_codes)
    |> validate_manifest_lint_issue_codes(
      callbacks,
      path <> ".warnings",
      warnings,
      supported_codes
    )
    |> validate_string_list_items(callbacks, path, report, "outputs")
    |> validate_study_manifest_outputs(callbacks, path, report)
    |> expect_field_equals(callbacks, path, report, "status", expected_status)
    |> expect_field_equals(callbacks, path, report, "error_count", length(errors))
    |> expect_field_equals(callbacks, path, report, "warning_count", length(warnings))
  end

  defp validate_campaign_request_status(issues, callbacks, path, report) do
    case Map.get(report, "error_count") do
      count when is_integer(count) and count == 0 ->
        expect_field_equals(
          issues,
          callbacks,
          path,
          report,
          "status",
          "pass",
          "must be pass when error_count is zero"
        )

      count when is_integer(count) and count > 0 ->
        expect_field_equals(
          issues,
          callbacks,
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

  defp validate_campaign_request_ref(issues, callbacks, path, request) do
    issues
    |> require_fields(callbacks, path, request, ["path", "sha256"])
    |> expect_type(callbacks, path, request, "path", :binary)
    |> expect_type(callbacks, path, request, "sha256", :binary)
    |> validate_sha256_field(callbacks, path, request, "sha256")
  end

  defp validate_campaign_source_plan_ref(issues, _callbacks, _path, nil), do: issues

  defp validate_campaign_source_plan_ref(issues, callbacks, path, source_plan)
       when is_map(source_plan) do
    issues
    |> require_fields(callbacks, path, source_plan, [
      "schema_contract",
      "status",
      "path",
      "sha256"
    ])
    |> expect_one_of(callbacks, path, source_plan, "status", ["pass", "fail"])
    |> expect_type(callbacks, path, source_plan, "schema_contract", :binary)
    |> expect_type(callbacks, path, source_plan, "path", :binary)
    |> expect_type(callbacks, path, source_plan, "sha256", :binary)
    |> validate_sha256_field(callbacks, path, source_plan, "sha256")
    |> validate_stable_ids(callbacks, path, source_plan, ["plan_id"])
  end

  defp validate_campaign_source_plan_ref(issues, callbacks, path, _source_plan),
    do: [error(callbacks, path, "must be an object") | issues]

  defp validate_sha256_field(issues, callbacks, path, map, field) do
    case Map.get(map, field) do
      value when is_binary(value) ->
        if Regex.match?(@sha256_regex, value) do
          issues
        else
          [
            error(callbacks, "#{path}.#{field}", "must be a lowercase SHA-256 hex digest")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_study_manifest_outputs(issues, callbacks, path, report) do
    outputs = list_value(callbacks, report, "outputs")
    supported_outputs = get_in(report, ["supported", "outputs"]) || []

    issues
    |> reject_duplicate_strings(
      callbacks,
      path <> ".outputs",
      outputs,
      "must not contain duplicate outputs"
    )
    |> validate_study_manifest_supported_outputs(callbacks, path, outputs, supported_outputs)
  end

  defp validate_study_manifest_supported_outputs(
         issues,
         callbacks,
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
      [error(callbacks, path <> ".outputs", "must be included in supported.outputs") | issues]
    end
  end

  defp validate_study_manifest_supported_outputs(
         issues,
         _callbacks,
         _path,
         _outputs,
         _supported_outputs
       ),
       do: issues

  defp reject_duplicate_strings(issues, callbacks, path, values, message) do
    duplicates =
      values
      |> Enum.filter(&is_binary/1)
      |> Enum.frequencies()
      |> Enum.filter(fn {_value, count} -> count > 1 end)

    if duplicates == [] do
      issues
    else
      [error(callbacks, path, message) | issues]
    end
  end

  defp validate_study_manifest_supported(issues, callbacks, path, supported)
       when is_map(supported) do
    issues
    |> require_fields(callbacks, path, supported, ["lint_error_codes", "outputs", "propagators"])
    |> expect_type(callbacks, path, supported, "lint_error_codes", :list)
    |> expect_type(callbacks, path, supported, "outputs", :list)
    |> expect_type(callbacks, path, supported, "propagators", :list)
    |> validate_string_list_items(callbacks, path, supported, "lint_error_codes")
    |> validate_string_list_items(callbacks, path, supported, "outputs")
    |> validate_string_list_items(callbacks, path, supported, "propagators")
    |> validate_string_list_items(callbacks, path, supported, "search_objectives")
  end

  defp validate_study_manifest_supported(issues, callbacks, path, _supported),
    do: [error(callbacks, path, "must be an object") | issues]

  defp validate_study_manifest_manifest(issues, callbacks, path, manifest)
       when is_map(manifest) do
    issues
    |> require_fields(callbacks, path, manifest, ["path"])
    |> expect_type(callbacks, path, manifest, "path", :binary)
    |> expect_optional_type(callbacks, path, manifest, "sha256", :binary)
  end

  defp validate_study_manifest_manifest(issues, callbacks, path, _manifest),
    do: [error(callbacks, path, "must be an object") | issues]

  defp validate_manifest_lint_issue(issues, path, issue, callbacks) do
    issues
    |> require_fields(callbacks, path, issue, ["code", "path", "message", "details"])
    |> expect_type(callbacks, path, issue, "code", :binary)
    |> expect_type(callbacks, path, issue, "path", :binary)
    |> expect_type(callbacks, path, issue, "message", :binary)
    |> expect_type(callbacks, path, issue, "details", :map)
  end

  defp validate_manifest_lint_issue_codes(issues, callbacks, path, rows, supported_codes)
       when is_list(rows) and is_list(supported_codes) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      code = if is_map(row), do: Map.get(row, "code")

      if is_binary(code) and code not in supported_codes do
        [
          error(callbacks, "#{path}[#{index}].code", "must be one of #{inspect(supported_codes)}")
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_manifest_lint_issue_codes(issues, _callbacks, _path, _rows, _supported_codes),
    do: issues

  defp validation_issue_fun(callbacks), do: Keyword.fetch!(callbacks, :validate_validation_issue)

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

  defp list_value(callbacks, map, key),
    do: apply(Keyword.fetch!(callbacks, :list_value), [map, key])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
