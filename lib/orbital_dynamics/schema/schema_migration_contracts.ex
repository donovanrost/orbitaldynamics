defmodule OrbitalDynamics.Schema.SchemaMigrationContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "schema_migration_report.v1")
    |> expect_equal(callbacks, path, report, "schema_version", 1)
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "executable_schema_migration_and_deprecation_report"
    )
    |> expect_equal(callbacks, path, report, "source", "orbital_dynamics.schema_registry")
    |> expect_one_of(callbacks, path, report, "status", ["current", "review_required"])
    |> expect_non_negative_integer(callbacks, path, report, "compatibility_policy_version")
    |> expect_non_negative_integer(callbacks, path, report, "compatible_change_rule_count")
    |> expect_non_negative_integer(callbacks, path, report, "breaking_change_rule_count")
    |> expect_non_negative_integer(callbacks, path, report, "contract_count")
    |> expect_non_negative_integer(callbacks, path, report, "current_contract_count")
    |> expect_non_negative_integer(callbacks, path, report, "deprecated_contract_count")
    |> expect_non_negative_integer(callbacks, path, report, "future_contract_count")
    |> expect_non_negative_integer(callbacks, path, report, "migration_row_count")
    |> expect_non_negative_integer(callbacks, path, report, "deprecation_warning_count")
    |> expect_type(callbacks, path, report, "status_counts", :map)
    |> expect_type(callbacks, path, report, "migration_action_counts", :map)
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> expect_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      model_limits(callbacks),
      "must match schema migration report model limits"
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(report, "status_counts", %{})
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".migration_action_counts",
      Map.get(report, "migration_action_counts", %{})
    )
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
    |> validate_report_counts(callbacks, path, report)
  end

  defp validate_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "schema_contract",
      "artifact_family",
      "schema_version",
      "status",
      "migration_action",
      "required_field_count",
      "optional_field_count",
      "nested_contract_count"
    ])
    |> expect_type(callbacks, path, row, "schema_contract", :binary)
    |> expect_type(callbacks, path, row, "artifact_family", :binary)
    |> expect_non_negative_integer(callbacks, path, row, "schema_version")
    |> expect_one_of(callbacks, path, row, "status", migration_row_statuses())
    |> expect_one_of(callbacks, path, row, "migration_action", migration_actions())
    |> expect_optional_type(callbacks, path, row, "replacement_contract", :binary)
    |> expect_optional_type(callbacks, path, row, "deprecation_warning", :binary)
    |> expect_non_negative_integer(callbacks, path, row, "required_field_count")
    |> expect_non_negative_integer(callbacks, path, row, "optional_field_count")
    |> expect_non_negative_integer(callbacks, path, row, "nested_contract_count")
    |> validate_row_action(callbacks, path, row)
  end

  defp validate_row_action(issues, callbacks, path, %{"status" => "deprecated"} = row) do
    if Map.has_key?(row, "replacement_contract") or
         Map.get(row, "migration_action") == "review_deprecated_contract" do
      issues
    else
      [
        error(
          callbacks,
          path <> ".replacement_contract",
          "is required unless deprecated rows use review_deprecated_contract"
        )
        | issues
      ]
    end
  end

  defp validate_row_action(issues, _callbacks, _path, _row), do: issues

  defp validate_report_counts(issues, callbacks, path, report) do
    rows = Map.get(report, "rows", [])
    status_counts = frequency_map(rows, "status")
    action_counts = frequency_map(rows, "migration_action")
    deprecated_count = Map.get(status_counts, "deprecated", 0)
    future_count = Map.get(status_counts, "future", 0)

    expected_status =
      if deprecated_count > 0 or future_count > 0, do: "review_required", else: "current"

    issues
    |> expect_field_equals(callbacks, path, report, "status", expected_status)
    |> expect_field_equals(callbacks, path, report, "contract_count", length(rows))
    |> expect_field_equals(callbacks, path, report, "migration_row_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "current_contract_count",
      Map.get(status_counts, "current", 0)
    )
    |> expect_field_equals(callbacks, path, report, "deprecated_contract_count", deprecated_count)
    |> expect_field_equals(callbacks, path, report, "future_contract_count", future_count)
    |> expect_field_equals(callbacks, path, report, "deprecation_warning_count", deprecated_count)
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "status_counts",
      status_counts,
      "must equal row status counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "migration_action_counts",
      action_counts,
      "must equal row migration-action counts"
    )
  end

  defp migration_row_statuses,
    do: OrbitalDynamics.Validation.capabilities().schema_migration_row_statuses

  defp migration_actions,
    do: OrbitalDynamics.Validation.capabilities().schema_migration_actions

  defp model_limits(callbacks) do
    callbacks
    |> Keyword.fetch!(:schema_migration_report_model_limits)
    |> then(& &1.())
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

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

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, map, model_limits, message),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        model_limits,
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
end
