defmodule OrbitalDynamics.Schema.OperationalReadinessContextContracts do
  @moduledoc false

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

  def validate_operator_training_context(issues, path, row, callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      row,
      "operator_training_requirement_count",
      callbacks
    )
    |> expect_optional_type(path, row, "operator_training_requirement_counts", :map, callbacks)
    |> validate_non_negative_integer_count_map(
      path <> ".operator_training_requirement_counts",
      Map.get(row, "operator_training_requirement_counts"),
      callbacks
    )
    |> expect_field_equals(
      path,
      row,
      "operator_training_requirement_count",
      non_negative_integer_map_sum(
        Map.get(row, "operator_training_requirement_counts"),
        callbacks
      ),
      "must equal operator_training_requirement_counts sum",
      callbacks
    )
    |> validate_operator_requirement_lists(path, row, callbacks)
  end

  def validate_resource_context(issues, path, row, callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      path,
      row,
      "resource_availability_pressure_count",
      callbacks
    )
    |> expect_optional_type(path, row, "resource_availability_reason_counts", :map, callbacks)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_availability_reason_counts",
      Map.get(row, "resource_availability_reason_counts"),
      callbacks
    )
    |> expect_field_equals(
      path,
      row,
      "resource_availability_pressure_count",
      non_negative_integer_map_sum(
        Map.get(row, "resource_availability_reason_counts"),
        callbacks
      ),
      "must equal resource_availability_reason_counts sum",
      callbacks
    )
    |> expect_optional_type(path, row, "resource_availability_reason_ids", :list, callbacks)
    |> validate_string_list_items(path, row, "resource_availability_reason_ids", callbacks)
    |> expect_field_equals(
      path,
      row,
      "resource_availability_reason_ids",
      resource_availability_reason_ids(Map.get(row, "resource_availability_reason_counts")),
      "must equal resource_availability_reason_counts keys with positive counts",
      callbacks
    )
    |> expect_optional_type(path, row, "unavailable_resource_reason_ids", :list, callbacks)
    |> validate_string_list_items(path, row, "unavailable_resource_reason_ids", callbacks)
    |> expect_field_equals(
      path,
      row,
      "unavailable_resource_reason_ids",
      unavailable_resource_reason_ids(Map.get(row, "resource_availability_reason_counts")),
      "must equal unavailable resource reason IDs from resource_availability_reason_counts",
      callbacks
    )
    |> expect_optional_type(path, row, "station_availability_reason_ids", :list, callbacks)
    |> validate_string_list_items(path, row, "station_availability_reason_ids", callbacks)
    |> expect_field_equals(
      path,
      row,
      "station_availability_reason_ids",
      station_availability_reason_ids(Map.get(row, "resource_availability_reason_counts")),
      "must equal station availability reason IDs from resource_availability_reason_counts",
      callbacks
    )
    |> expect_optional_type(path, row, "station_availability_reason_counts", :map, callbacks)
    |> validate_non_negative_integer_count_map(
      path <> ".station_availability_reason_counts",
      Map.get(row, "station_availability_reason_counts"),
      callbacks
    )
    |> expect_field_equals(
      path,
      row,
      "station_availability_reason_counts",
      station_availability_reason_counts(Map.get(row, "resource_availability_reason_counts")),
      "must equal station availability reason counts from resource_availability_reason_counts",
      callbacks
    )
    |> expect_optional_type(path, row, "resource_blocking_dimension_counts", :map, callbacks)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_blocking_dimension_counts",
      Map.get(row, "resource_blocking_dimension_counts"),
      callbacks
    )
    |> validate_optional_stable_id_array_map(
      path,
      row,
      "resource_blocked_contact_ids_by_blocking_dimension",
      callbacks
    )
    |> validate_optional_stable_id_array_map(
      path,
      row,
      "resource_blocked_contact_ids_by_spacecraft_id",
      callbacks
    )
    |> expect_optional_type(path, row, "resource_source_quality_counts", :map, callbacks)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_source_quality_counts",
      Map.get(row, "resource_source_quality_counts"),
      callbacks
    )
    |> expect_optional_type(path, row, "resource_trust_boundary_status_counts", :map, callbacks)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_trust_boundary_status_counts",
      Map.get(row, "resource_trust_boundary_status_counts"),
      callbacks
    )
  end

  def validate_adapter_boundary_context(issues, path, row, callbacks) do
    issues
    |> expect_optional_non_negative_integer(path, row, "adapter_context_count", callbacks)
    |> expect_optional_non_negative_integer(
      path,
      row,
      "adapter_trust_boundary_declared_count",
      callbacks
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "adapter_trust_boundary_missing_count",
      callbacks
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "adapter_trust_boundary_untrusted_count",
      callbacks
    )
    |> expect_optional_type(path, row, "adapter_boundary_status_counts", :map, callbacks)
    |> validate_non_negative_integer_count_map(
      path <> ".adapter_boundary_status_counts",
      Map.get(row, "adapter_boundary_status_counts"),
      callbacks
    )
  end

  def validate_cadence_import_context(issues, path, row, callbacks) do
    issues
    |> validate_cadence_import_scalar_fields(path, row, callbacks)
    |> validate_cadence_import_count_map_fields(path, row, callbacks)
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

  defp validate_operator_requirement_lists(issues, path, row, callbacks) do
    Enum.reduce(@operator_requirement_list_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, row, field, :list, callbacks)
      |> validate_string_list_items(path, row, field, callbacks)
    end)
  end

  defp validate_cadence_import_scalar_fields(issues, path, row, callbacks) do
    Enum.reduce(@cadence_import_scalar_fields, issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, row, field, callbacks)
    end)
  end

  defp validate_cadence_import_count_map_fields(issues, path, row, callbacks) do
    Enum.reduce(@cadence_import_count_map_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, row, field, :map, callbacks)
      |> validate_non_negative_integer_count_map(
        path <> ".#{field}",
        Map.get(row, field),
        callbacks
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

  defp expect_optional_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp validate_non_negative_integer_count_map(issues, path, counts, callbacks),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
      ])

  defp expect_field_equals(issues, path, map, field, expected, message, callbacks),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp non_negative_integer_map_sum(counts, callbacks),
    do: apply(require_callback(callbacks, :non_negative_integer_map_sum), [counts])

  defp validate_string_list_items(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_stable_id_array_map(issues, path, row, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_array_map), [
        issues,
        path,
        row,
        field
      ])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
