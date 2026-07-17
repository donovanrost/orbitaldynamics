defmodule OrbitalDynamics.Schema.SchemaMigrationContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  @model_limits [
    "artifact_only_schema_registry_snapshot",
    "deprecation_hints_are_caller_declared",
    "no_automatic_artifact_migration",
    "no_backward_compatibility_certification"
  ]

  def model_limits, do: @model_limits

  def validate(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "schema_migration_report.v1")
    |> expect_equal(path, report, "schema_version", 1)
    |> expect_equal(
      path,
      report,
      "model",
      "executable_schema_migration_and_deprecation_report"
    )
    |> expect_equal(path, report, "source", "orbital_dynamics.schema_registry")
    |> expect_one_of(path, report, "status", ["current", "review_required"])
    |> expect_non_negative_integer(path, report, "compatibility_policy_version")
    |> expect_non_negative_integer(path, report, "compatible_change_rule_count")
    |> expect_non_negative_integer(path, report, "breaking_change_rule_count")
    |> expect_non_negative_integer(path, report, "contract_count")
    |> expect_non_negative_integer(path, report, "current_contract_count")
    |> expect_non_negative_integer(path, report, "deprecated_contract_count")
    |> expect_non_negative_integer(path, report, "future_contract_count")
    |> expect_non_negative_integer(path, report, "migration_row_count")
    |> expect_non_negative_integer(path, report, "deprecation_warning_count")
    |> expect_type(path, report, "status_counts", :map)
    |> expect_type(path, report, "migration_action_counts", :map)
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> expect_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits(),
      "must match schema migration report model limits"
    )
    |> validate_non_negative_integer_count_map(
      path <> ".status_counts",
      Map.get(report, "status_counts", %{})
    )
    |> validate_non_negative_integer_count_map(
      path <> ".migration_action_counts",
      Map.get(report, "migration_action_counts", %{})
    )
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_row/3
    )
    |> validate_report_counts(path, report)
  end

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "schema_contract",
      "artifact_family",
      "schema_version",
      "status",
      "migration_action",
      "required_field_count",
      "optional_field_count",
      "nested_contract_count"
    ])
    |> expect_type(path, row, "schema_contract", :binary)
    |> expect_type(path, row, "artifact_family", :binary)
    |> expect_non_negative_integer(path, row, "schema_version")
    |> expect_one_of(path, row, "status", migration_row_statuses())
    |> expect_one_of(path, row, "migration_action", migration_actions())
    |> expect_optional_type(path, row, "replacement_contract", :binary)
    |> expect_optional_type(path, row, "deprecation_warning", :binary)
    |> expect_non_negative_integer(path, row, "required_field_count")
    |> expect_non_negative_integer(path, row, "optional_field_count")
    |> expect_non_negative_integer(path, row, "nested_contract_count")
    |> validate_row_action(path, row)
  end

  defp validate_row_action(issues, path, %{"status" => "deprecated"} = row) do
    if Map.has_key?(row, "replacement_contract") or
         Map.get(row, "migration_action") == "review_deprecated_contract" do
      issues
    else
      [
        error(
          path <> ".replacement_contract",
          "is required unless deprecated rows use review_deprecated_contract"
        )
        | issues
      ]
    end
  end

  defp validate_row_action(issues, _path, _row), do: issues

  defp validate_report_counts(issues, path, report) do
    rows = Map.get(report, "rows", [])
    status_counts = frequency_map(rows, "status")
    action_counts = frequency_map(rows, "migration_action")
    deprecated_count = Map.get(status_counts, "deprecated", 0)
    future_count = Map.get(status_counts, "future", 0)

    expected_status =
      if deprecated_count > 0 or future_count > 0, do: "review_required", else: "current"

    issues
    |> expect_field_equals(path, report, "status", expected_status)
    |> expect_field_equals(path, report, "contract_count", length(rows))
    |> expect_field_equals(path, report, "migration_row_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "current_contract_count",
      Map.get(status_counts, "current", 0)
    )
    |> expect_field_equals(path, report, "deprecated_contract_count", deprecated_count)
    |> expect_field_equals(path, report, "future_contract_count", future_count)
    |> expect_field_equals(path, report, "deprecation_warning_count", deprecated_count)
    |> expect_field_equals(
      path,
      report,
      "status_counts",
      status_counts,
      "must equal row status counts"
    )
    |> expect_field_equals(
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

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
