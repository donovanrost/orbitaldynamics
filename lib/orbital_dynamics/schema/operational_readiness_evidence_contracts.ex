defmodule OrbitalDynamics.Schema.OperationalReadinessEvidenceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_optional_integer: 4,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  @scalar_fields [
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
    "schema_validation_remediation_count",
    "operator_training_requirement_count",
    "resource_availability_pressure_count",
    "resource_blocking_dimension_count",
    "dependency_impact_row_count",
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count"
  ]

  @count_map_fields [
    "import_status_counts",
    "cadence_import_status_counts",
    "freshness_status_counts",
    "schema_validation_status_counts",
    "operator_training_requirement_counts",
    "resource_availability_reason_counts",
    "station_availability_reason_counts",
    "resource_blocking_dimension_counts",
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts",
    "publication_status_counts",
    "downstream_invalidation_status_counts",
    "downstream_invalidation_reason_counts",
    "dependency_impact_status_counts",
    "publication_authority_counts",
    "source_artifact_type_counts",
    "changed_field_counts"
  ]

  @stable_id_array_map_fields [
    "resource_blocked_contact_ids_by_blocking_dimension",
    "resource_blocked_contact_ids_by_spacecraft_id",
    "timeline_ids_by_changed_field",
    "invalidated_downstream_product_ids_by_reason"
  ]

  @stable_id_array_fields [
    "publication_ids",
    "source_artifact_ids",
    "supersedes_artifact_ids",
    "downstream_product_ids",
    "invalidated_downstream_product_ids",
    "impacted_dependency_activity_ids",
    "impacted_dependency_timeline_ids",
    "impacted_exclusive_with_activity_ids",
    "impacted_exclusive_with_timeline_ids",
    "changed_timeline_ids",
    "review_timeline_ids"
  ]

  @evidence_count_map_fields [
    "approval_status_counts",
    "review_type_counts",
    "import_action_counts",
    "source_review_type_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "freshness_status_counts",
    "schema_validation_status_counts",
    "source_model_counts",
    "source_model_limit_counts",
    "policy_classification_counts",
    "adapter_boundary_status_counts",
    "operator_training_requirement_counts",
    "resource_availability_reason_counts",
    "station_availability_reason_counts",
    "resource_blocking_dimension_counts",
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts",
    "publication_status_counts",
    "downstream_invalidation_status_counts",
    "downstream_invalidation_reason_counts",
    "dependency_impact_status_counts",
    "publication_authority_counts",
    "source_artifact_type_counts",
    "changed_field_counts"
  ]

  @optional_scalar_fields [
    "review_row_count",
    "import_row_count",
    "review_required_count",
    "blocked_review_count",
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
    "schema_validation_remediation_count",
    "source_model_count",
    "source_model_limit_count",
    "policy_decision_count",
    "policy_auto_approvable_count",
    "policy_review_required_count",
    "policy_blocked_count",
    "adapter_context_count",
    "adapter_trust_boundary_declared_count",
    "adapter_trust_boundary_missing_count",
    "adapter_trust_boundary_untrusted_count",
    "operator_training_requirement_count",
    "resource_availability_pressure_count",
    "resource_blocking_dimension_count",
    "dependency_impact_row_count",
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count"
  ]

  @optional_count_map_type_fields [
    "approval_status_counts",
    "review_type_counts",
    "import_action_counts",
    "source_review_type_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "freshness_status_counts",
    "schema_validation_status_counts",
    "source_model_counts",
    "source_model_limit_counts",
    "policy_classification_counts",
    "adapter_boundary_status_counts",
    "operator_training_requirement_counts"
  ]

  @operator_requirement_list_fields [
    "required_operator_roles",
    "required_training_ids",
    "required_certification_ids",
    "required_qualification_ids"
  ]

  @resource_count_map_type_fields [
    "resource_blocking_dimension_counts",
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts"
  ]

  @keyed_count_checks [
    {"review_required_count", "approval_status_counts", ["operator_review_required", "pending"]},
    {"blocked_review_count", "approval_status_counts", ["blocked_by_policy"]},
    {"ready_for_import_count", "import_status_counts", ["ready_for_import"]},
    {"manifest_review_required_count", "import_status_counts", ["review_required_before_import"]},
    {"blocked_import_count", "import_status_counts", ["blocked_missing_cadence_import"]},
    {"missing_import_count", "cadence_import_status_counts", ["missing"]},
    {"invalid_cadence_import_count", "cadence_import_status_counts", ["invalid"]},
    {"current_freshness_count", "freshness_status_counts", ["current"]},
    {"stale_freshness_count", "freshness_status_counts", ["stale"]},
    {"unknown_freshness_count", "freshness_status_counts", ["unknown"]},
    {"schema_validation_pass_count", "schema_validation_status_counts", ["pass"]},
    {"schema_validation_fail_count", "schema_validation_status_counts", ["fail"]},
    {"policy_auto_approvable_count", "policy_classification_counts", ["auto_approvable"]},
    {"policy_review_required_count", "policy_classification_counts",
     ["operator_review_required"]},
    {"policy_blocked_count", "policy_classification_counts", ["blocked_by_policy"]},
    {"adapter_trust_boundary_declared_count", "adapter_boundary_status_counts", ["declared"]},
    {"adapter_trust_boundary_missing_count", "adapter_boundary_status_counts", ["missing"]},
    {"adapter_trust_boundary_untrusted_count", "adapter_boundary_status_counts", ["untrusted"]}
  ]

  @total_count_checks [
    {"source_model_count", "source_model_counts"},
    {"source_model_limit_count", "source_model_limit_counts"},
    {"policy_decision_count", "policy_classification_counts"},
    {"adapter_context_count", "adapter_boundary_status_counts"},
    {"operator_training_requirement_count", "operator_training_requirement_counts"},
    {"resource_availability_pressure_count", "resource_availability_reason_counts"},
    {"resource_blocking_dimension_count", "resource_blocking_dimension_counts"}
  ]

  def validate(issues, path, evidence, resource_validator, timeline_publication_validator)
      when is_map(evidence) and is_function(resource_validator, 3) and
             is_function(timeline_publication_validator, 3) do
    issues
    |> validate_optional_scalar_fields(path, evidence)
    |> validate_optional_count_map_type_fields(path, evidence)
    |> validate_operator_requirement_lists(path, evidence)
    |> resource_validator.(path, evidence)
    |> validate_resource_count_map_type_fields(path, evidence)
    |> timeline_publication_validator.(path, evidence)
    |> validate_evidence_count_maps(path, evidence)
    |> validate_scalar_count_maps_impl(path, evidence)
  end

  def validate(issues, path, _evidence, _resource_validator, _timeline_publication_validator) do
    [error(path, "must be an object") | issues]
  end

  def validate_gate_counts(issues, path, evidence, gates)
      when is_map(evidence) and is_list(gates) do
    issues
    |> validate_scalar_fields(path, evidence, gates)
    |> validate_count_map_fields(path, evidence, gates)
    |> validate_stable_id_array_map_fields(path, evidence, gates)
    |> validate_stable_id_array_fields(path, evidence, gates)
  end

  def validate_gate_counts(issues, _path, _evidence, _gates), do: issues

  def validate_count_maps(issues, path, evidence)
      when is_map(evidence) do
    validate_evidence_count_maps(issues, path, evidence)
  end

  def validate_count_maps(issues, _path, _evidence), do: issues

  def validate_scalar_count_maps(issues, path, evidence)
      when is_map(evidence) do
    validate_scalar_count_maps_impl(issues, path, evidence)
  end

  def validate_scalar_count_maps(issues, _path, _evidence), do: issues

  defp validate_optional_scalar_fields(issues, path, evidence) do
    Enum.reduce(@optional_scalar_fields, issues, fn field, acc ->
      acc
      |> expect_optional_integer(path, evidence, field)
      |> expect_field_at_least(path, evidence, field, 0)
    end)
  end

  defp validate_optional_count_map_type_fields(issues, path, evidence) do
    Enum.reduce(@optional_count_map_type_fields, issues, fn field, acc ->
      expect_optional_type(acc, path, evidence, field, :map)
    end)
  end

  defp validate_operator_requirement_lists(issues, path, evidence) do
    Enum.reduce(@operator_requirement_list_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, evidence, field, :list)
      |> validate_string_list_items(path, evidence, field)
    end)
  end

  defp validate_resource_count_map_type_fields(issues, path, evidence) do
    Enum.reduce(@resource_count_map_type_fields, issues, fn field, acc ->
      expect_optional_type(acc, path, evidence, field, :map)
    end)
  end

  defp validate_scalar_fields(issues, path, evidence, gates) do
    Enum.reduce(@scalar_fields, issues, fn field, acc ->
      expect_field_equals(
        acc,
        path,
        evidence,
        field,
        gate_numeric_sum(gates, field),
        "must equal gate-derived #{field}"
      )
    end)
  end

  defp validate_count_map_fields(issues, path, evidence, gates) do
    Enum.reduce(@count_map_fields, issues, fn field, acc ->
      expect_field_equals(
        acc,
        path,
        evidence,
        field,
        gate_count_map(gates, field),
        "must equal gate-derived #{field}"
      )
    end)
  end

  defp validate_stable_id_array_map_fields(issues, path, evidence, gates) do
    Enum.reduce(@stable_id_array_map_fields, issues, fn field, acc ->
      expect_field_equals(
        acc,
        path,
        evidence,
        field,
        gate_stable_id_array_map(gates, field),
        "must equal gate-derived #{field}"
      )
    end)
  end

  defp validate_stable_id_array_fields(issues, path, evidence, gates) do
    Enum.reduce(@stable_id_array_fields, issues, fn field, acc ->
      expect_field_equals(
        acc,
        path,
        evidence,
        field,
        gate_stable_id_array(gates, field),
        "must equal gate-derived #{field}"
      )
    end)
  end

  defp validate_evidence_count_maps(issues, path, evidence) do
    Enum.reduce(@evidence_count_map_fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(
        acc,
        "#{path}.#{field}",
        Map.get(evidence, field)
      )
    end)
  end

  defp validate_scalar_count_maps_impl(issues, path, evidence) do
    issues =
      Enum.reduce(@keyed_count_checks, issues, fn {field, count_map_field, keys}, acc ->
        expect_field_equals(
          acc,
          path,
          evidence,
          field,
          count_map_value_sum(Map.get(evidence, count_map_field), keys),
          "must equal #{count_map_field} count for #{Enum.join(keys, ",")}"
        )
      end)

    Enum.reduce(@total_count_checks, issues, fn {field, count_map_field}, acc ->
      expect_field_equals(
        acc,
        path,
        evidence,
        field,
        non_negative_integer_map_sum(Map.get(evidence, count_map_field)),
        "must equal #{count_map_field} total"
      )
    end)
  end

  defp gate_numeric_sum(gates, field) do
    values =
      gates
      |> Enum.filter(&(is_map(&1) and Map.has_key?(&1, field)))
      |> Enum.map(&Map.get(&1, field))

    if values == [] do
      nil
    else
      Enum.reduce(values, 0, fn
        value, acc when is_number(value) -> acc + value
        _value, acc -> acc
      end)
    end
  end

  defp gate_count_map(gates, field) do
    count_maps =
      gates
      |> Enum.filter(&(is_map(&1) and Map.has_key?(&1, field)))
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)

    if count_maps == [] do
      nil
    else
      merge_count_maps(count_maps)
    end
  end

  defp gate_stable_id_array_map(gates, field) do
    maps =
      gates
      |> Enum.filter(&(is_map(&1) and Map.has_key?(&1, field)))
      |> Enum.map(&Map.get(&1, field))
      |> Enum.filter(&is_map/1)

    if maps == [] do
      nil
    else
      merge_stable_id_array_maps(maps)
    end
  end

  defp gate_stable_id_array(gates, field) do
    ids =
      gates
      |> Enum.filter(&(is_map(&1) and Map.has_key?(&1, field)))
      |> Enum.flat_map(fn gate -> List.wrap(Map.get(gate, field)) end)
      |> stable_sorted_ids()

    if ids == [], do: nil, else: ids
  end

  defp merge_count_maps(count_maps) do
    Enum.reduce(count_maps, %{}, fn counts, acc ->
      Enum.reduce(counts, acc, fn {key, value}, inner_acc ->
        if is_number(value), do: Map.update(inner_acc, key, value, &(&1 + value)), else: inner_acc
      end)
    end)
  end

  defp merge_stable_id_array_maps(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {key, values}, inner_acc ->
        ids = stable_sorted_ids(List.wrap(values))

        if ids == [] do
          inner_acc
        else
          Map.update(inner_acc, to_string(key), ids, fn current ->
            stable_sorted_ids(current ++ ids)
          end)
        end
      end)
    end)
  end

  defp count_map_value_sum(counts, keys) when is_map(counts) do
    values = Enum.map(keys, &Map.get(counts, &1, 0))

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)),
      do: Enum.sum(values),
      else: nil
  end

  defp count_map_value_sum(_counts, _keys), do: nil

  defp non_negative_integer_map_sum(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)) do
      Enum.sum(values)
    end
  end

  defp non_negative_integer_map_sum(_counts), do: nil

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
