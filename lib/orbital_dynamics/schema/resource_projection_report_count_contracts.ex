defmodule OrbitalDynamics.Schema.ResourceProjectionReportCountContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.ResourceProjectionPressureContracts

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [
      frequency_map: 2,
      integer_or_zero: 1,
      row_count_difference: 3,
      sorted_stable_values: 1,
      stable_values_by_key: 1
    ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_equals: 6,
      validate_non_negative_integer_count_map: 3
    ]

  def validate(issues, path, report) do
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
        integer_or_zero(Map.get(report, "valid_activity_count")) +
          length(invalid_activity_rows)
      end

    issues
    |> expect_field_equals(
      path,
      report,
      "input_resource_summary_count",
      length(projected_rows) + length(invalid_summary_rows)
    )
    |> expect_field_equals(
      path,
      report,
      "valid_resource_summary_count",
      length(projected_rows)
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_resource_summary_input_count",
      length(invalid_summary_rows)
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_resource_summary_input_ids",
      Enum.map(invalid_summary_rows, &Map.get(&1, "resource_summary_id")),
      "must equal row-derived invalid_resource_summary_input_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_activity_input_count",
      length(invalid_activity_rows)
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_activity_input_ids",
      Enum.map(invalid_activity_rows, &Map.get(&1, "activity_id")),
      "must equal row-derived invalid_activity_input_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "activity_count",
      activity_count,
      "must equal valid_activity_count plus invalid activity inputs"
    )
    |> expect_field_equals(
      path,
      report,
      "valid_activity_count",
      row_count_difference(report, "activity_count", length(invalid_activity_rows))
    )
    |> expect_field_equals(
      path,
      report,
      "warnings",
      projected_rows |> Enum.flat_map(&Map.get(&1, "warnings", [])) |> Enum.uniq() |> Enum.sort(),
      "must equal row-derived warnings"
    )
    |> expect_field_equals(
      path,
      report,
      "resource_pressure_count",
      length(resource_pressure_rows),
      "must equal row-derived resource_pressure_count"
    )
    |> expect_field_equals(
      path,
      report,
      "resource_pressure_types",
      resource_projection_pressure_types(projected_rows),
      "must equal row-derived resource_pressure_types"
    )
    |> expect_field_equals(
      path,
      report,
      "resource_pressure_spacecraft_ids",
      resource_pressure_rows
      |> Enum.map(&Map.get(&1, "spacecraft_id"))
      |> sorted_stable_values(),
      "must equal row-derived resource_pressure_spacecraft_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "resource_pressure_spacecraft_ids_by_type",
      resource_projection_pressure_spacecraft_ids_by_type(projected_rows, flow_rows),
      "must equal row-derived resource_pressure_spacecraft_ids_by_type"
    )
    |> expect_field_equals(
      path,
      report,
      "resource_pressure_activity_ids_by_type",
      resource_projection_pressure_activity_ids_by_type(flow_rows),
      "must equal row-derived resource_pressure_activity_ids_by_type"
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.resource_source_quality_counts",
      Map.get(report, "resource_source_quality_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.resource_trust_boundary_status_counts",
      Map.get(report, "resource_trust_boundary_status_counts")
    )
    |> expect_field_equals(
      path,
      report,
      "resource_source_quality_counts",
      frequency_map(projected_rows, "resource_source_quality"),
      "must equal row-derived resource_source_quality_counts"
    )
    |> expect_field_equals(
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
      path,
      report,
      "resource_trust_boundary_status_counts",
      frequency_map(projected_rows, "resource_trust_boundary_status"),
      "must equal row-derived resource_trust_boundary_status_counts"
    )
    |> expect_field_equals(
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

  defp expect_field_equals(issues, path, map, field, expected) do
    PrimitiveValidation.expect_field_equals(
      issues,
      path,
      map,
      field,
      expected,
      "must equal #{expected}"
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
      |> Enum.map(&ResourceProjectionPressureContracts.first_kind/1)
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
        Enum.map(
          ResourceProjectionPressureContracts.kinds(row),
          &{&1, Map.get(row, "spacecraft_id")}
        )
      end)

    stable_values_by_key(projected_pairs ++ flow_pairs)
  end

  defp resource_projection_pressure_activity_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(ResourceProjectionPressureContracts.kinds(row), &{&1, Map.get(row, "activity_id")})
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
end
