defmodule OrbitalDynamics.Schema.OperationalReadinessContextContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3]

  @operator_requirement_list_fields [
    "required_operator_roles",
    "required_training_ids",
    "required_certification_ids",
    "required_qualification_ids"
  ]

  @cadence_import_scalar_fields [
    "ready_for_import_count",
    "manifest_review_required_count",
    "blocked_import_count",
    "missing_import_count",
    "invalid_cadence_import_count",
    "current_freshness_count",
    "stale_freshness_count",
    "unknown_freshness_count",
    "schema_validation_pass_count",
    "schema_validation_fail_count",
    "schema_validation_error_count",
    "schema_validation_warning_count",
    "schema_validation_remediation_count"
  ]

  @cadence_import_count_map_fields [
    "freshness_status_counts",
    "schema_validation_status_counts",
    "import_status_counts",
    "cadence_import_status_counts"
  ]

  def validate_operator_training_context(issues, path, row) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      row,
      "operator_training_requirement_count"
    )
    |> expect_optional_type(path, row, "operator_training_requirement_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".operator_training_requirement_counts",
      Map.get(row, "operator_training_requirement_counts")
    )
    |> expect_field_equals(
      path,
      row,
      "operator_training_requirement_count",
      non_negative_integer_map_sum(Map.get(row, "operator_training_requirement_counts")),
      "must equal operator_training_requirement_counts sum"
    )
    |> validate_operator_requirement_lists(path, row)
  end

  def validate_resource_context(issues, path, row) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      row,
      "resource_availability_pressure_count"
    )
    |> expect_optional_type(path, row, "resource_availability_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_availability_reason_counts",
      Map.get(row, "resource_availability_reason_counts")
    )
    |> expect_field_equals(
      path,
      row,
      "resource_availability_pressure_count",
      non_negative_integer_map_sum(Map.get(row, "resource_availability_reason_counts")),
      "must equal resource_availability_reason_counts sum"
    )
    |> expect_optional_type(path, row, "resource_availability_reason_ids", :list)
    |> validate_string_list_items(path, row, "resource_availability_reason_ids")
    |> expect_field_equals(
      path,
      row,
      "resource_availability_reason_ids",
      resource_availability_reason_ids(Map.get(row, "resource_availability_reason_counts")),
      "must equal resource_availability_reason_counts keys with positive counts"
    )
    |> expect_optional_type(path, row, "unavailable_resource_reason_ids", :list)
    |> validate_string_list_items(path, row, "unavailable_resource_reason_ids")
    |> expect_field_equals(
      path,
      row,
      "unavailable_resource_reason_ids",
      unavailable_resource_reason_ids(Map.get(row, "resource_availability_reason_counts")),
      "must equal unavailable resource reason IDs from resource_availability_reason_counts"
    )
    |> expect_optional_type(path, row, "station_availability_reason_ids", :list)
    |> validate_string_list_items(path, row, "station_availability_reason_ids")
    |> expect_field_equals(
      path,
      row,
      "station_availability_reason_ids",
      station_availability_reason_ids(Map.get(row, "resource_availability_reason_counts")),
      "must equal station availability reason IDs from resource_availability_reason_counts"
    )
    |> expect_optional_type(path, row, "station_availability_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".station_availability_reason_counts",
      Map.get(row, "station_availability_reason_counts")
    )
    |> expect_field_equals(
      path,
      row,
      "station_availability_reason_counts",
      station_availability_reason_counts(Map.get(row, "resource_availability_reason_counts")),
      "must equal station availability reason counts from resource_availability_reason_counts"
    )
    |> expect_optional_type(path, row, "resource_blocking_dimension_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_blocking_dimension_counts",
      Map.get(row, "resource_blocking_dimension_counts")
    )
    |> validate_optional_stable_id_array_map(
      path,
      row,
      "resource_blocked_contact_ids_by_blocking_dimension"
    )
    |> validate_optional_stable_id_array_map(
      path,
      row,
      "resource_blocked_contact_ids_by_spacecraft_id"
    )
    |> expect_optional_type(path, row, "resource_source_quality_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_source_quality_counts",
      Map.get(row, "resource_source_quality_counts")
    )
    |> expect_optional_type(path, row, "resource_trust_boundary_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_trust_boundary_status_counts",
      Map.get(row, "resource_trust_boundary_status_counts")
    )
  end

  def validate_adapter_boundary_context(issues, path, row) do
    issues
    |> expect_optional_non_negative_integer(path, row, "adapter_context_count")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "adapter_trust_boundary_declared_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "adapter_trust_boundary_missing_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "adapter_trust_boundary_untrusted_count"
    )
    |> expect_optional_type(path, row, "adapter_boundary_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".adapter_boundary_status_counts",
      Map.get(row, "adapter_boundary_status_counts")
    )
  end

  def validate_cadence_import_context(issues, path, row) do
    issues
    |> validate_cadence_import_scalar_fields(path, row)
    |> validate_cadence_import_count_map_fields(path, row)
  end

  def resource_availability_reason_ids(counts) when is_map(counts) do
    if Enum.all?(counts, fn {_reason, count} -> is_integer(count) and count >= 0 end) do
      counts
      |> Enum.filter(fn {_reason, count} -> count > 0 end)
      |> Enum.map(fn {reason, _count} -> reason end)
      |> Enum.sort()
    end
  end

  def resource_availability_reason_ids(_counts), do: nil

  def unavailable_resource_reason_ids(counts) when is_map(counts) do
    case resource_availability_reason_ids(counts) do
      nil ->
        nil

      reason_ids ->
        reason_ids
        |> Enum.filter(&(&1 in unavailable_resource_reasons()))
        |> Enum.sort()
    end
  end

  def unavailable_resource_reason_ids(_counts), do: nil

  def station_availability_reason_ids(counts) when is_map(counts) do
    case resource_availability_reason_ids(counts) do
      nil ->
        nil

      reason_ids ->
        reason_ids
        |> Enum.filter(&(&1 in station_availability_reasons()))
        |> Enum.sort()
    end
  end

  def station_availability_reason_ids(_counts), do: nil

  def station_availability_reason_counts(counts) when is_map(counts) do
    if Enum.all?(counts, fn {_reason, count} -> is_integer(count) and count >= 0 end) do
      counts
      |> Enum.filter(fn {reason, count} ->
        reason in station_availability_reasons() and count > 0
      end)
      |> Map.new()
    end
  end

  def station_availability_reason_counts(_counts), do: nil

  defp validate_operator_requirement_lists(issues, path, row) do
    Enum.reduce(@operator_requirement_list_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, row, field, :list)
      |> validate_string_list_items(path, row, field)
    end)
  end

  defp validate_cadence_import_scalar_fields(issues, path, row) do
    Enum.reduce(@cadence_import_scalar_fields, issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, row, field)
    end)
  end

  defp validate_cadence_import_count_map_fields(issues, path, row) do
    Enum.reduce(@cadence_import_count_map_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, row, field, :map)
      |> validate_non_negative_integer_count_map(
        path <> ".#{field}",
        Map.get(row, field)
      )
    end)
  end

  defp unavailable_resource_reasons do
    ~w(
      antenna_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      spacecraft_unavailable
    )
  end

  defp station_availability_reasons do
    ~w(
      ground_station_capacity_zero
      ground_station_reduced_capacity_insufficient
      ground_station_reserved
      ground_station_unavailable
    )
  end

  defp non_negative_integer_map_sum(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)) do
      Enum.sum(values)
    end
  end

  defp non_negative_integer_map_sum(_counts), do: nil

  defp validate_optional_stable_id_array_map(issues, path, row, field) do
    issues
    |> expect_optional_type(path, row, field, :map)
    |> validate_stable_id_array_map("#{path}.#{field}", Map.get(row, field))
  end
end
