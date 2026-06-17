defmodule OrbitalDynamics.Schema.ResourceProjectionReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, report, [
      "schema_contract",
      "model",
      "input_resource_summary_count",
      "activity_count",
      "projected_resources",
      "assumptions"
    ])
    |> expect_equal(callbacks, path, report, "schema_contract", "resource_projection_report.v1")
    |> expect_one_of(
      callbacks,
      path,
      report,
      "model",
      resource_projection_report_models(callbacks)
    )
    |> expect_optional_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "input_resource_summary_count")
    |> expect_non_negative_integer(callbacks, path, report, "activity_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "valid_resource_summary_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_resource_summary_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_resource_summary_input_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "invalid_resource_summary_input_ids"
    )
    |> expect_optional_non_negative_integer(callbacks, path, report, "valid_activity_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "invalid_activity_input_ids")
    |> expect_optional_type(callbacks, path, report, "invalid_activity_inputs", :list)
    |> expect_optional_type(callbacks, path, report, "resource_source_quality_counts", :map)
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "resource_spacecraft_ids_by_source_quality",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".resource_spacecraft_ids_by_source_quality",
      Map.get(report, "resource_spacecraft_ids_by_source_quality")
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "resource_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "resource_spacecraft_ids_by_trust_boundary_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".resource_spacecraft_ids_by_trust_boundary_status",
      Map.get(report, "resource_spacecraft_ids_by_trust_boundary_status")
    )
    |> expect_optional_non_negative_integer(callbacks, path, report, "resource_pressure_count")
    |> expect_optional_type(callbacks, path, report, "resource_pressure_types", :list)
    |> validate_string_list_items(callbacks, path, report, "resource_pressure_types")
    |> expect_optional_type(callbacks, path, report, "resource_pressure_spacecraft_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "resource_pressure_spacecraft_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "resource_pressure_spacecraft_ids_by_type",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".resource_pressure_spacecraft_ids_by_type",
      Map.get(report, "resource_pressure_spacecraft_ids_by_type")
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "resource_pressure_activity_ids_by_type",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".resource_pressure_activity_ids_by_type",
      Map.get(report, "resource_pressure_activity_ids_by_type")
    )
    |> expect_optional_type(callbacks, path, report, "warnings", :list)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      resource_projection_report_model_limits(callbacks),
      "must match resource projection model limits"
    )
    |> expect_type(callbacks, path, report, "projected_resources", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_resource_projection_subsystem_model_assumptions(callbacks, path, report)
    |> validate_optional_rows(
      callbacks,
      path <> ".invalid_resource_summary_inputs",
      Map.get(report, "invalid_resource_summary_inputs"),
      fn acc, row_path, row ->
        validate_invalid_resource_summary_input(callbacks, acc, row_path, row)
      end
    )
    |> validate_optional_rows(
      callbacks,
      path <> ".invalid_activity_inputs",
      Map.get(report, "invalid_activity_inputs"),
      fn acc, row_path, row -> validate_invalid_activity_input(callbacks, acc, row_path, row) end
    )
    |> validate_rows(
      callbacks,
      path <> ".projected_resources",
      Map.get(report, "projected_resources", []),
      fn acc, row_path, row -> validate_resource_projection_row(callbacks, acc, row_path, row) end
    )
    |> validate_resource_projection_report_counts(callbacks, path, report)
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, values),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, values])

  defp resource_projection_report_models(callbacks),
    do: apply(require_callback(callbacks, :resource_projection_report_models), [])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, map, expected, message),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        expected,
        message
      ])

  defp resource_projection_report_model_limits(callbacks),
    do: apply(require_callback(callbacks, :resource_projection_report_model_limits), [])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp validate_resource_projection_subsystem_model_assumptions(issues, callbacks, path, report),
    do:
      apply(
        require_callback(callbacks, :validate_resource_projection_subsystem_model_assumptions),
        [issues, path, report]
      )

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp validate_invalid_resource_summary_input(callbacks, issues, path, row),
    do:
      apply(require_callback(callbacks, :validate_invalid_resource_summary_input), [
        issues,
        path,
        row
      ])

  defp validate_invalid_activity_input(callbacks, issues, path, row),
    do: apply(require_callback(callbacks, :validate_invalid_activity_input), [issues, path, row])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_resource_projection_row(callbacks, issues, path, row),
    do: apply(require_callback(callbacks, :validate_resource_projection_row), [issues, path, row])

  defp validate_resource_projection_report_counts(issues, callbacks, path, report),
    do:
      apply(require_callback(callbacks, :validate_resource_projection_report_counts), [
        issues,
        path,
        report
      ])
end
