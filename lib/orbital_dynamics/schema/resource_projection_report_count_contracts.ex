defmodule OrbitalDynamics.Schema.ResourceProjectionReportCountContracts do
  @moduledoc false

  @availability_pressure_reasons [
    "spacecraft_unavailable",
    "payload_unavailable",
    "spacecraft_degraded_payload_unavailable",
    "activity_type_suppressed_by_resource_summary",
    "activity_type_incompatible_with_resource_summary",
    "antenna_unavailable"
  ]

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    projected_rows =
      report
      |> Map.get("projected_resources", [])
      |> Enum.filter(&is_map/1)

    invalid_summary_rows =
      report
      |> Map.get("invalid_resource_summary_inputs", [])
      |> case do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    invalid_activity_rows =
      report
      |> Map.get("invalid_activity_inputs", [])
      |> case do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    resource_pressure_rows =
      Enum.filter(projected_rows, &(resource_projection_pressure_types([&1]) != []))

    flow_rows = Enum.flat_map(projected_rows, &resource_projection_flow_rows/1)

    activity_count =
      if Map.has_key?(report, "valid_activity_count") do
        integer_or_zero(callbacks, Map.get(report, "valid_activity_count")) +
          length(invalid_activity_rows)
      end

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "input_resource_summary_count",
      length(projected_rows) + length(invalid_summary_rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "valid_resource_summary_count",
      length(projected_rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_resource_summary_input_count",
      length(invalid_summary_rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_resource_summary_input_ids",
      Enum.map(invalid_summary_rows, &Map.get(&1, "resource_summary_id")),
      "must equal row-derived invalid_resource_summary_input_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_activity_input_count",
      length(invalid_activity_rows)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_activity_input_ids",
      Enum.map(invalid_activity_rows, &Map.get(&1, "activity_id")),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "activity_count",
      activity_count,
      "must equal valid_activity_count plus invalid activity inputs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "valid_activity_count",
      row_count_difference(callbacks, report, "activity_count", length(invalid_activity_rows))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "warnings",
      projected_rows |> Enum.flat_map(&Map.get(&1, "warnings", [])) |> Enum.uniq() |> Enum.sort(),
      "must equal row-derived warnings"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_pressure_count",
      length(resource_pressure_rows),
      "must equal row-derived resource_pressure_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_pressure_types",
      resource_projection_pressure_types(projected_rows),
      "must equal row-derived resource_pressure_types"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_pressure_spacecraft_ids",
      resource_pressure_rows
      |> Enum.map(&Map.get(&1, "spacecraft_id"))
      |> sorted_stable_values(),
      "must equal row-derived resource_pressure_spacecraft_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_pressure_spacecraft_ids_by_type",
      resource_projection_pressure_spacecraft_ids_by_type(projected_rows, flow_rows),
      "must equal row-derived resource_pressure_spacecraft_ids_by_type"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_pressure_activity_ids_by_type",
      resource_projection_pressure_activity_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_activity_ids_by_type"
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.resource_source_quality_counts",
      Map.get(report, "resource_source_quality_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.resource_trust_boundary_status_counts",
      Map.get(report, "resource_trust_boundary_status_counts")
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_source_quality_counts",
      frequency_map(callbacks, projected_rows, "resource_source_quality"),
      "must equal row-derived resource_source_quality_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_spacecraft_ids_by_source_quality",
      stable_values_by_key(
        Enum.map(
          projected_rows,
          &{Map.get(&1, "resource_source_quality"), Map.get(&1, "spacecraft_id")}
        )
      ),
      "must equal row-derived resource_spacecraft_ids_by_source_quality"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_trust_boundary_status_counts",
      frequency_map(callbacks, projected_rows, "resource_trust_boundary_status"),
      "must equal row-derived resource_trust_boundary_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "resource_spacecraft_ids_by_trust_boundary_status",
      stable_values_by_key(
        Enum.map(
          projected_rows,
          &{Map.get(&1, "resource_trust_boundary_status"), Map.get(&1, "spacecraft_id")}
        )
      ),
      "must equal row-derived resource_spacecraft_ids_by_trust_boundary_status"
    )
  end

  defp resource_projection_pressure_types(projected_rows) do
    projection_pressure_types =
      projected_rows
      |> Enum.flat_map(fn
        %{} = row -> Map.get(row, "resource_pressure_types", [])
        _row -> []
      end)

    flow_pressure_types =
      projected_rows
      |> Enum.flat_map(&resource_projection_flow_rows/1)
      |> Enum.map(&resource_projection_pressure_kind/1)
      |> Enum.reject(&is_nil/1)

    (projection_pressure_types ++ flow_pressure_types)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_projection_pressure_spacecraft_ids_by_type(projected_rows, flow_rows) do
    projected_pairs =
      Enum.flat_map(projected_rows, fn
        %{} = row ->
          row
          |> Map.get("resource_pressure_types", [])
          |> Enum.map(&{&1, Map.get(row, "spacecraft_id")})

        _row ->
          []
      end)

    flow_pairs =
      Enum.flat_map(flow_rows, fn row ->
        Enum.map(resource_projection_pressure_kinds(row), &{&1, Map.get(row, "spacecraft_id")})
      end)

    stable_values_by_key(projected_pairs ++ flow_pairs)
  end

  defp resource_projection_pressure_activity_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_projection_pressure_kinds(row), &{&1, Map.get(row, "activity_id")})
    end)
    |> stable_values_by_key()
  end

  defp resource_projection_flow_rows(%{
         "activity_resource_flow" => flow_rows,
         "spacecraft_id" => id
       })
       when is_list(flow_rows) do
    Enum.map(flow_rows, fn
      %{} = row -> Map.put_new(row, "spacecraft_id", id)
      row -> row
    end)
  end

  defp resource_projection_flow_rows(_row), do: []

  defp resource_projection_pressure_kind(%{"storage_overflow_mb" => value})
       when is_number(value) and value > 0.0,
       do: "storage_overflow"

  defp resource_projection_pressure_kind(%{"downlink_shortfall_mb" => value})
       when is_number(value) and value > 0.0,
       do: "downlink_shortfall"

  defp resource_projection_pressure_kind(%{"battery_overuse_wh" => value})
       when is_number(value) and value > 0.0,
       do: "battery_depletion"

  defp resource_projection_pressure_kind(%{"resource_effect_reason" => reason})
       when reason in @availability_pressure_reasons,
       do: reason

  defp resource_projection_pressure_kind(_row), do: nil

  defp resource_projection_pressure_kinds(row) do
    []
    |> maybe_add_resource_projection_pressure_kind(row, "storage_overflow", "storage_overflow_mb")
    |> maybe_add_resource_projection_pressure_kind(
      row,
      "downlink_shortfall",
      "downlink_shortfall_mb"
    )
    |> maybe_add_resource_projection_pressure_kind(row, "battery_depletion", "battery_overuse_wh")
    |> maybe_add_resource_projection_availability_pressure_kind(row)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_add_resource_projection_pressure_kind(types, row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 -> [type | types]
      _value -> types
    end
  end

  defp maybe_add_resource_projection_availability_pressure_kind(
         types,
         %{"resource_effect_reason" => reason}
       )
       when reason in @availability_pressure_reasons,
       do: [reason | types]

  defp maybe_add_resource_projection_availability_pressure_kind(types, _row), do: types

  defp stable_values_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_stable_values(values)} end)
  end

  defp sorted_stable_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp expect_field_equals(issues, callbacks, path, report, field, expected) do
    callback!(callbacks, :expect_field_equals).(issues, path, report, field, expected)
  end

  defp expect_field_equals(issues, callbacks, path, report, field, expected, message) do
    callback!(callbacks, :expect_field_equals_with_message).(
      issues,
      path,
      report,
      field,
      expected,
      message
    )
  end

  defp frequency_map(callbacks, rows, field) do
    callback!(callbacks, :frequency_map).(rows, field)
  end

  defp integer_or_zero(callbacks, value) do
    callback!(callbacks, :integer_or_zero).(value)
  end

  defp row_count_difference(callbacks, report, field, subtract) do
    callback!(callbacks, :row_count_difference).(report, field, subtract)
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    callback!(callbacks, :validate_non_negative_integer_count_map).(issues, path, counts)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
