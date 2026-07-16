defmodule OrbitalDynamics.Schema.CommandWindowReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_interval: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    CollectionAggregation,
    CollectionValidation
  }

  @scalar_count_fields [
    "window_count",
    "command_count",
    "tracking_count",
    "uplink_count",
    "health_check_count",
    "review_required_count",
    "source_window_lineage_count"
  ]

  def validate(issues, path, report, model_limits) when is_list(model_limits) do
    issues
    |> expect_equal(path, report, "schema_contract", "command_window_report.v1")
    |> expect_equal(path, report, "model", "artifact_only_command_window_report")
    |> expect_type(path, report, "source", :binary)
    |> validate_scalar_counts(path, report)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> expect_optional_type(path, report, "activity_ids_by_window_type", :map)
    |> expect_optional_type(
      path,
      report,
      "review_activity_ids_by_required_operator_action",
      :map
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_stable_id_array_map(
      path,
      report,
      "activity_ids_by_window_type"
    )
    |> validate_optional_stable_id_array_map(
      path,
      report,
      "review_activity_ids_by_required_operator_action"
    )
    |> validate_model_limits(path, report, model_limits)
    |> CollectionValidation.validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_row(&1, &2, &3)
    )
    |> validate_counts(path, report)
  end

  defp validate_scalar_counts(issues, path, report) do
    Enum.reduce(@scalar_count_fields, issues, fn field, acc ->
      expect_non_negative_integer(acc, path, report, field)
    end)
  end

  defp validate_model_limits(issues, path, report, model_limits) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == model_limits do
          issues
        else
          [
            error(
              "#{path}.model_limits",
              "must match command window report model limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, report, "window_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "command_count",
      command_window_type_count(rows, "command_window")
    )
    |> expect_field_equals(
      path,
      report,
      "tracking_count",
      command_window_type_count(rows, "tracking_window")
    )
    |> expect_field_equals(
      path,
      report,
      "uplink_count",
      command_window_type_count(rows, "uplink_window")
    )
    |> expect_field_equals(
      path,
      report,
      "health_check_count",
      command_window_type_count(rows, "health_check_window")
    )
    |> expect_field_equals(
      path,
      report,
      "review_required_count",
      command_window_review_required_count(rows)
    )
    |> expect_field_equals(
      path,
      report,
      "activity_ids_by_window_type",
      CollectionAggregation.row_ids_by_field(rows, "window_type", "activity_id"),
      "must equal row-derived activity_ids_by_window_type"
    )
    |> expect_field_equals(
      path,
      report,
      "review_activity_ids_by_required_operator_action",
      command_window_review_activity_ids_by_required_operator_action(rows),
      "must equal row-derived review_activity_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      path,
      report,
      "source_window_lineage_count",
      Enum.count(rows, &(Map.get(&1, "has_source_window") == true))
    )
  end

  defp command_window_type_count(rows, window_type) do
    Enum.count(rows, &(Map.get(&1, "window_type") == window_type))
  end

  defp command_window_review_required_count(rows) do
    Enum.count(
      rows,
      &(Map.get(&1, "required_operator_action") not in command_window_no_review_actions())
    )
  end

  defp command_window_no_review_actions do
    ["monitor_activity", "none_locked_activity", "none_terminal_activity"]
  end

  defp command_window_review_activity_ids_by_required_operator_action(rows) do
    review_rows =
      Enum.filter(
        rows,
        &(Map.get(&1, "required_operator_action") not in command_window_no_review_actions())
      )

    CollectionAggregation.row_ids_by_field(
      review_rows,
      "required_operator_action",
      "activity_id"
    )
  end

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "rank",
      "activity_id",
      "timeline_id",
      "activity_type",
      "window_type",
      "starts_at_s",
      "ends_at_s",
      "status",
      "approval_status",
      "locked",
      "required_operator_action",
      "execution_boundary",
      "cadence_import_status",
      "has_source_window",
      "has_cadence_import",
      "timeline_identity"
    ])
    |> validate_stable_ids(path, row, [
      "id",
      "activity_id",
      "timeline_id",
      "scenario_id",
      "ground_station_id"
    ])
    |> expect_number(path, row, "rank")
    |> expect_type(path, row, "activity_type", :binary)
    |> expect_one_of(path, row, "window_type", [
      "command_window",
      "tracking_window",
      "uplink_window",
      "health_check_window",
      "command_context_window"
    ])
    |> expect_optional_type(path, row, "direction", :binary)
    |> expect_optional_type(path, row, "ground_station_id", :binary)
    |> expect_number(path, row, "starts_at_s")
    |> expect_number(path, row, "ends_at_s")
    |> expect_type(path, row, "status", :binary)
    |> expect_type(path, row, "approval_status", :binary)
    |> expect_type(path, row, "locked", :boolean)
    |> expect_type(path, row, "required_operator_action", :binary)
    |> expect_optional_type(path, row, "operator_action_reason", :binary)
    |> expect_type(path, row, "execution_boundary", :binary)
    |> expect_type(path, row, "cadence_import_status", :binary)
    |> expect_optional_type(path, row, "cadence_import_type", :binary)
    |> expect_optional_type(path, row, "source_window_id", :binary)
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> expect_optional_type(path, row, "activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, row, "activity_context")
    |> expect_optional_type(path, row, "dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "dependency_activity_ids")
    |> expect_optional_type(path, row, "dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(path, row, "dependency_timeline_ids")
    |> expect_optional_type(path, row, "exclusive_with_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "exclusive_with_activity_ids")
    |> expect_optional_type(path, row, "exclusive_with_timeline_ids", :list)
    |> validate_optional_stable_id_list(path, row, "exclusive_with_timeline_ids")
    |> expect_optional_type(path, row, "approval_requirements", :list)
    |> expect_optional_type(path, row, "approval_rule_matches", :list)
    |> expect_type(path, row, "has_source_window", :boolean)
    |> expect_type(path, row, "has_cadence_import", :boolean)
    |> expect_type(path, row, "timeline_identity", :map)
    |> validate_interval(path, row)
  end

  defp validate_optional_stable_id_array_map(issues, path, map, field) do
    issues
    |> expect_optional_type(path, map, field, :map)
    |> validate_stable_id_array_map("#{path}.#{field}", Map.get(map, field))
  end

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
