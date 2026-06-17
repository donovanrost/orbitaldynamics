defmodule OrbitalDynamics.Schema.OperationalQualityGateUnavailableResourceSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    unavailable_counts = Map.get(summary, "unavailable_resource_reason_counts")
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    quality_gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status")

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_unavailable_resource_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_quality_gate_unavailable_resource_summary"
    )
    |> expect_equal(callbacks, path, summary, "source", "quality_gate_report.v1")
    |> expect_type(callbacks, path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(callbacks, path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> expect_non_negative_integer(callbacks, path, summary, "resource_availability_row_count")
    |> expect_non_negative_integer(callbacks, path, summary, "unavailable_resource_row_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "unavailable_resource_pressure_count"
    )
    |> expect_type(callbacks, path, summary, "unavailable_resource_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".unavailable_resource_reason_counts",
      unavailable_counts
    )
    |> expect_type(callbacks, path, summary, "unavailable_resource_reason_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "unavailable_resource_reason_ids")
    |> expect_optional_type(callbacks, path, summary, "station_availability_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".station_availability_reason_counts",
      Map.get(summary, "station_availability_reason_counts")
    )
    |> expect_optional_type(callbacks, path, summary, "station_availability_reason_ids", :list)
    |> validate_string_list_items(callbacks, path, summary, "station_availability_reason_ids")
    |> expect_type(callbacks, path, summary, "resource_blocking_dimension_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".resource_blocking_dimension_counts",
      Map.get(summary, "resource_blocking_dimension_counts")
    )
    |> expect_type(callbacks, path, summary, "blocked_contact_ids_by_blocking_dimension", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".blocked_contact_ids_by_blocking_dimension",
      Map.get(summary, "blocked_contact_ids_by_blocking_dimension")
    )
    |> expect_type(callbacks, path, summary, "blocked_contact_ids_by_spacecraft_id", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".blocked_contact_ids_by_spacecraft_id",
      Map.get(summary, "blocked_contact_ids_by_spacecraft_id")
    )
    |> expect_type(callbacks, path, summary, "blocked_contact_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".blocked_contact_ids_by_status",
      Map.get(summary, "blocked_contact_ids_by_status")
    )
    |> expect_type(callbacks, path, summary, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_row_ids_by_status",
      quality_gate_row_ids_by_status
    )
    |> expect_type(callbacks, path, summary, "quality_gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".quality_gate_ids_by_status",
      quality_gate_ids_by_status
    )
    |> expect_type(callbacks, path, summary, "review_required_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_required_quality_gate_row_ids",
      Map.get(summary, "review_required_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "blocked_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".blocked_quality_gate_row_ids",
      Map.get(summary, "blocked_quality_gate_row_ids")
    )
    |> expect_type(callbacks, path, summary, "resource_availability_gate_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".resource_availability_gate_ids",
      Map.get(summary, "resource_availability_gate_ids")
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      quality_gate_unavailable_resource_summary_model_limits(callbacks),
      "must match quality gate unavailable-resource summary model limits"
    )
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
    |> validate_id_sets(callbacks, path, summary)
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        [
          {"source", "quality_gate_report.v1"},
          {"execution_boundary", "artifact_only_no_cadence_write"},
          {"operator_authority", "not_granted_by_unavailable_resource_summary"},
          {"cadence_write", "not_performed_by_summary"},
          {"command_execution", "not_performed_by_summary"}
        ]
        |> Enum.reduce(issues, fn {field, expected}, acc ->
          expect_equal(acc, callbacks, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, summary) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_availability_row_count",
      stable_id_array_map_value_count(
        callbacks,
        Map.get(summary, "quality_gate_row_ids_by_status")
      ),
      "must equal quality-gate row IDs by status count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "unavailable_resource_pressure_count",
      non_negative_integer_map_sum(
        callbacks,
        Map.get(summary, "unavailable_resource_reason_counts")
      ),
      "must equal unavailable_resource_reason_counts sum"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "unavailable_resource_reason_ids",
      unavailable_resource_reason_ids(
        callbacks,
        Map.get(summary, "unavailable_resource_reason_counts")
      ),
      "must equal unavailable resource reason IDs from unavailable_resource_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "station_availability_reason_ids",
      resource_availability_reason_ids(
        callbacks,
        Map.get(summary, "station_availability_reason_counts")
      ),
      "must equal station availability reason IDs from station_availability_reason_counts"
    )
  end

  defp validate_id_sets(issues, callbacks, path, summary) do
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_required_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "review_required", [])
      ),
      "must equal review-required quality-gate row IDs by status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "blocked", [])
      ),
      "must equal blocked quality-gate row IDs by status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "resource_availability_gate_ids",
      stable_id_array_map_ids(callbacks, Map.get(summary, "quality_gate_ids_by_status")),
      "must equal quality-gate IDs by status"
    )
  end

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])

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

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp quality_gate_unavailable_resource_summary_model_limits(callbacks) do
    apply(Keyword.fetch!(callbacks, :quality_gate_unavailable_resource_summary_model_limits), [])
  end

  defp stable_id_array_map_value_count(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :stable_id_array_map_value_count), [values])

  defp stable_id_array_map_ids(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :stable_id_array_map_ids), [values])

  defp non_negative_integer_map_sum(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :non_negative_integer_map_sum), [values])

  defp unavailable_resource_reason_ids(callbacks, counts),
    do: apply(Keyword.fetch!(callbacks, :unavailable_resource_reason_ids), [counts])

  defp resource_availability_reason_ids(callbacks, counts),
    do: apply(Keyword.fetch!(callbacks, :resource_availability_reason_ids), [counts])
end
