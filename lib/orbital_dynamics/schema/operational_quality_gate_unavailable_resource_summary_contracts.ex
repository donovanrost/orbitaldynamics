defmodule OrbitalDynamics.Schema.OperationalQualityGateUnavailableResourceSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CollectionAggregation
  alias OrbitalDynamics.Schema.OperationalReadinessContextContracts, as: ReadinessContext

  alias OrbitalDynamics.Schema.OperationalQualityGateSummaryLineageValidation,
    as: SummaryLineage

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  def validate_summary(issues, path, summary, model_limits) when is_list(model_limits) do
    unavailable_counts = Map.get(summary, "unavailable_resource_reason_counts")
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    quality_gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status")

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "operational_quality_gate_unavailable_resource_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_quality_gate_unavailable_resource_summary"
    )
    |> expect_equal(path, summary, "source", "quality_gate_report.v1")
    |> expect_type(path, summary, "source_artifact_type", :binary)
    |> validate_stable_ids(path, summary, [
      "source_artifact_id",
      "source_quality_gate_report_id",
      "source_readiness_report_id"
    ])
    |> SummaryLineage.validate(path, summary)
    |> expect_non_negative_integer(path, summary, "resource_availability_row_count")
    |> expect_non_negative_integer(path, summary, "unavailable_resource_row_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "unavailable_resource_pressure_count"
    )
    |> expect_type(path, summary, "unavailable_resource_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".unavailable_resource_reason_counts",
      unavailable_counts
    )
    |> expect_type(path, summary, "unavailable_resource_reason_ids", :list)
    |> validate_string_list_items(path, summary, "unavailable_resource_reason_ids")
    |> expect_optional_type(path, summary, "station_availability_reason_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".station_availability_reason_counts",
      Map.get(summary, "station_availability_reason_counts")
    )
    |> expect_optional_type(path, summary, "station_availability_reason_ids", :list)
    |> validate_string_list_items(path, summary, "station_availability_reason_ids")
    |> expect_type(path, summary, "resource_blocking_dimension_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".resource_blocking_dimension_counts",
      Map.get(summary, "resource_blocking_dimension_counts")
    )
    |> expect_type(path, summary, "blocked_contact_ids_by_blocking_dimension", :map)
    |> validate_stable_id_array_map(
      path <> ".blocked_contact_ids_by_blocking_dimension",
      Map.get(summary, "blocked_contact_ids_by_blocking_dimension")
    )
    |> expect_type(path, summary, "blocked_contact_ids_by_spacecraft_id", :map)
    |> validate_stable_id_array_map(
      path <> ".blocked_contact_ids_by_spacecraft_id",
      Map.get(summary, "blocked_contact_ids_by_spacecraft_id")
    )
    |> expect_type(path, summary, "blocked_contact_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".blocked_contact_ids_by_status",
      Map.get(summary, "blocked_contact_ids_by_status")
    )
    |> expect_type(path, summary, "quality_gate_row_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".quality_gate_row_ids_by_status",
      quality_gate_row_ids_by_status
    )
    |> expect_type(path, summary, "quality_gate_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".quality_gate_ids_by_status",
      quality_gate_ids_by_status
    )
    |> expect_type(path, summary, "review_required_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_required_quality_gate_row_ids",
      Map.get(summary, "review_required_quality_gate_row_ids")
    )
    |> expect_type(path, summary, "blocked_quality_gate_row_ids", :list)
    |> validate_stable_id_list(
      path <> ".blocked_quality_gate_row_ids",
      Map.get(summary, "blocked_quality_gate_row_ids")
    )
    |> expect_type(path, summary, "resource_availability_gate_ids", :list)
    |> validate_stable_id_list(
      path <> ".resource_availability_gate_ids",
      Map.get(summary, "resource_availability_gate_ids")
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match quality gate unavailable-resource summary model limits"
    )
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
    |> validate_id_sets(path, summary)
  end

  defp validate_assumptions(issues, path, summary) do
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
          expect_equal(acc, path <> ".assumptions", assumptions, field, expected)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, summary) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "resource_availability_row_count",
      CollectionAggregation.stable_id_array_map_value_count(
        Map.get(summary, "quality_gate_row_ids_by_status")
      ),
      "must equal quality-gate row IDs by status count"
    )
    |> expect_field_equals(
      path,
      summary,
      "unavailable_resource_pressure_count",
      non_negative_integer_map_sum(Map.get(summary, "unavailable_resource_reason_counts")),
      "must equal unavailable_resource_reason_counts sum"
    )
    |> expect_field_equals(
      path,
      summary,
      "unavailable_resource_reason_ids",
      ReadinessContext.unavailable_resource_reason_ids(
        Map.get(summary, "unavailable_resource_reason_counts")
      ),
      "must equal unavailable resource reason IDs from unavailable_resource_reason_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "station_availability_reason_ids",
      ReadinessContext.resource_availability_reason_ids(
        Map.get(summary, "station_availability_reason_counts")
      ),
      "must equal station availability reason IDs from station_availability_reason_counts"
    )
  end

  defp validate_id_sets(issues, path, summary) do
    quality_gate_row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    issues
    |> expect_field_equals(
      path,
      summary,
      "review_required_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "review_required", [])
      ),
      "must equal review-required quality-gate row IDs by status"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_quality_gate_row_ids",
      if(is_map(quality_gate_row_ids_by_status),
        do: Map.get(quality_gate_row_ids_by_status, "blocked", [])
      ),
      "must equal blocked quality-gate row IDs by status"
    )
    |> expect_field_equals(
      path,
      summary,
      "resource_availability_gate_ids",
      CollectionAggregation.stable_id_array_map_ids(
        Map.get(summary, "quality_gate_ids_by_status")
      ),
      "must equal quality-gate IDs by status"
    )
  end

  defp non_negative_integer_map_sum(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)),
      do: Enum.sum(values),
      else: nil
  end

  defp non_negative_integer_map_sum(_counts), do: nil
end
