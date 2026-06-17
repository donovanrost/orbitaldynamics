defmodule OrbitalDynamics.Schema.CommandWindowReportContracts do
  @moduledoc false

  @scalar_count_fields [
    "window_count",
    "command_count",
    "tracking_count",
    "uplink_count",
    "health_check_count",
    "review_required_count",
    "source_window_lineage_count"
  ]

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "command_window_report.v1")
    |> expect_equal(callbacks, path, report, "model", "artifact_only_command_window_report")
    |> expect_type(callbacks, path, report, "source", :binary)
    |> validate_scalar_counts(callbacks, path, report)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> expect_optional_type(callbacks, path, report, "activity_ids_by_window_type", :map)
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "review_activity_ids_by_required_operator_action",
      :map
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "activity_ids_by_window_type"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "review_activity_ids_by_required_operator_action"
    )
    |> validate_model_limits(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      &validate_row(&1, callbacks, &2, &3)
    )
    |> validate_counts(callbacks, path, report)
  end

  defp validate_scalar_counts(issues, callbacks, path, report) do
    Enum.reduce(@scalar_count_fields, issues, fn field, acc ->
      expect_non_negative_integer(acc, callbacks, path, report, field)
    end)
  end

  defp validate_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == command_window_report_model_limits(callbacks) do
          issues
        else
          [
            error(
              callbacks,
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

  defp validate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, report, "window_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "command_count",
      command_window_type_count(rows, "command_window")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "tracking_count",
      command_window_type_count(rows, "tracking_window")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "uplink_count",
      command_window_type_count(rows, "uplink_window")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "health_check_count",
      command_window_type_count(rows, "health_check_window")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_required_count",
      command_window_review_required_count(rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "activity_ids_by_window_type",
      row_ids_by_field(callbacks, rows, "window_type", "activity_id"),
      "must equal row-derived activity_ids_by_window_type"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "review_activity_ids_by_required_operator_action",
      command_window_review_activity_ids_by_required_operator_action(callbacks, rows),
      "must equal row-derived review_activity_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
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

  defp command_window_review_activity_ids_by_required_operator_action(callbacks, rows) do
    review_rows =
      Enum.filter(
        rows,
        &(Map.get(&1, "required_operator_action") not in command_window_no_review_actions())
      )

    row_ids_by_field(callbacks, review_rows, "required_operator_action", "activity_id")
  end

  defp validate_row(issues, callbacks, path, row) do
    issues
    |> require_fields(callbacks, path, row, [
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
    |> validate_stable_ids(callbacks, path, row, [
      "id",
      "activity_id",
      "timeline_id",
      "scenario_id",
      "ground_station_id"
    ])
    |> expect_number(callbacks, path, row, "rank")
    |> expect_type(callbacks, path, row, "activity_type", :binary)
    |> expect_one_of(callbacks, path, row, "window_type", [
      "command_window",
      "tracking_window",
      "uplink_window",
      "health_check_window",
      "command_context_window"
    ])
    |> expect_optional_type(callbacks, path, row, "direction", :binary)
    |> expect_optional_type(callbacks, path, row, "ground_station_id", :binary)
    |> expect_number(callbacks, path, row, "starts_at_s")
    |> expect_number(callbacks, path, row, "ends_at_s")
    |> expect_type(callbacks, path, row, "status", :binary)
    |> expect_type(callbacks, path, row, "approval_status", :binary)
    |> expect_type(callbacks, path, row, "locked", :boolean)
    |> expect_type(callbacks, path, row, "required_operator_action", :binary)
    |> expect_optional_type(callbacks, path, row, "operator_action_reason", :binary)
    |> expect_type(callbacks, path, row, "execution_boundary", :binary)
    |> expect_type(callbacks, path, row, "cadence_import_status", :binary)
    |> expect_optional_type(callbacks, path, row, "cadence_import_type", :binary)
    |> expect_optional_type(callbacks, path, row, "source_window_id", :binary)
    |> expect_optional_type(callbacks, path, row, "source_window_type", :binary)
    |> expect_optional_type(callbacks, path, row, "activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, row, "activity_context")
    |> expect_optional_type(callbacks, path, row, "dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "dependency_activity_ids")
    |> expect_optional_type(callbacks, path, row, "dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "dependency_timeline_ids")
    |> expect_optional_type(callbacks, path, row, "exclusive_with_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "exclusive_with_activity_ids")
    |> expect_optional_type(callbacks, path, row, "exclusive_with_timeline_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "exclusive_with_timeline_ids")
    |> expect_optional_type(callbacks, path, row, "approval_requirements", :list)
    |> expect_optional_type(callbacks, path, row, "approval_rule_matches", :list)
    |> expect_type(callbacks, path, row, "has_source_window", :boolean)
    |> expect_type(callbacks, path, row, "has_cadence_import", :boolean)
    |> expect_type(callbacks, path, row, "timeline_identity", :map)
    |> validate_interval(callbacks, path, row)
  end

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

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_array_map), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_optional_activity_context(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_activity_context), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_interval(issues, callbacks, path, row),
    do: apply(Keyword.fetch!(callbacks, :validate_interval), [issues, path, row])

  defp row_ids_by_field(callbacks, rows, group_field, id_field) do
    apply(Keyword.fetch!(callbacks, :row_ids_by_field), [rows, group_field, id_field])
  end

  defp command_window_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :command_window_report_model_limits), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
