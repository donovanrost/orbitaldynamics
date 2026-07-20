defmodule OrbitalDynamics.OperationalReadiness.ReadinessEvidence do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.AdapterBoundaryEvidence
  alias OrbitalDynamics.OperationalReadiness.EvidenceNormalization
  alias OrbitalDynamics.OperationalReadiness.OperatorTrainingEvidence
  alias OrbitalDynamics.OperationalReadiness.ResourceAvailabilityEvidence
  alias OrbitalDynamics.OperationalReadiness.TimelinePublicationContext

  def build(artifact, review_package, import_manifest) do
    review_rows = rows(review_package)
    import_rows = rows(import_manifest)
    review_type_counts = row_counts(review_rows, "review_type")
    approval_status_counts = row_counts(review_rows, "approval_status")
    import_action_counts = row_counts(import_rows, "import_action")
    source_review_type_counts = row_counts(import_rows, "source_review_type")
    import_status_counts = row_counts(import_rows, "import_status")
    cadence_import_status_counts = row_counts(import_rows, "cadence_import_status")
    freshness_status_counts = freshness_status_counts(artifact, review_rows, import_rows)

    schema_validation_status_counts =
      schema_validation_status_counts(artifact, review_rows, import_rows)

    source_model_counts = source_model_counts(artifact, review_rows, import_rows)
    source_model_limit_counts = source_model_limit_counts(artifact, review_rows, import_rows)

    policy_classification_counts =
      policy_classification_counts(artifact, review_rows, import_rows)

    adapter_boundary_status_counts =
      adapter_boundary_status_counts(artifact, review_rows, import_rows)

    operator_training_context =
      operator_training_context(artifact, review_rows, import_rows)

    resource_availability_reason_counts =
      resource_availability_reason_counts(review_rows, import_rows)

    resource_blocking_dimension_counts =
      resource_blocking_dimension_counts(review_rows, import_rows)

    resource_blocked_contact_ids_by_blocking_dimension =
      resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        "resource_blocked_contact_ids_by_blocking_dimension",
        "resource_blocking_dimension"
      )

    resource_blocked_contact_ids_by_spacecraft_id =
      resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        "resource_blocked_contact_ids_by_spacecraft_id",
        "spacecraft_id"
      )

    resource_source_quality_counts =
      resource_provenance_counts(review_rows, import_rows, "resource_source_quality")

    resource_trust_boundary_status_counts =
      resource_provenance_counts(review_rows, import_rows, "resource_trust_boundary_status")

    timeline_publication_context =
      timeline_publication_context(artifact, review_rows, import_rows)

    %{
      "review_row_count" => length(review_rows),
      "import_row_count" => length(import_rows),
      "review_required_count" =>
        count_values(approval_status_counts, ["operator_review_required", "pending"]),
      "blocked_review_count" => count_values(approval_status_counts, ["blocked_by_policy"]),
      "ready_for_import_count" => count_values(import_status_counts, ["ready_for_import"]),
      "manifest_review_required_count" =>
        count_values(import_status_counts, ["review_required_before_import"]),
      "blocked_import_count" =>
        count_values(import_status_counts, ["blocked_missing_cadence_import"]),
      "missing_import_count" => count_values(cadence_import_status_counts, ["missing"]),
      "invalid_cadence_import_count" => count_values(cadence_import_status_counts, ["invalid"]),
      "current_freshness_count" => count_values(freshness_status_counts, ["current"]),
      "stale_freshness_count" => count_values(freshness_status_counts, ["stale"]),
      "unknown_freshness_count" => count_values(freshness_status_counts, ["unknown"]),
      "schema_validation_pass_count" => count_values(schema_validation_status_counts, ["pass"]),
      "schema_validation_fail_count" => count_values(schema_validation_status_counts, ["fail"]),
      "schema_validation_error_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "error_count"),
      "schema_validation_warning_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "warning_count"),
      "schema_validation_remediation_count" =>
        schema_validation_issue_count(artifact, review_rows, import_rows, "remediation_count"),
      "source_model_count" => map_value_count(source_model_counts),
      "source_model_limit_count" => map_value_count(source_model_limit_counts),
      "policy_decision_count" => map_value_count(policy_classification_counts),
      "policy_auto_approvable_count" =>
        count_values(policy_classification_counts, ["auto_approvable"]),
      "policy_review_required_count" =>
        count_values(policy_classification_counts, ["operator_review_required"]),
      "policy_blocked_count" => count_values(policy_classification_counts, ["blocked_by_policy"]),
      "adapter_context_count" => map_value_count(adapter_boundary_status_counts),
      "adapter_trust_boundary_declared_count" =>
        count_values(adapter_boundary_status_counts, ["declared"]),
      "adapter_trust_boundary_missing_count" =>
        count_values(adapter_boundary_status_counts, ["missing"]),
      "adapter_trust_boundary_untrusted_count" =>
        count_values(adapter_boundary_status_counts, ["untrusted"]),
      "operator_training_requirement_count" =>
        operator_training_context["operator_training_requirement_count"],
      "resource_availability_pressure_count" =>
        map_value_count(resource_availability_reason_counts),
      "resource_blocking_dimension_count" => map_value_count(resource_blocking_dimension_counts),
      "review_type_counts" => review_type_counts,
      "approval_status_counts" => approval_status_counts,
      "import_action_counts" => import_action_counts,
      "source_review_type_counts" => source_review_type_counts,
      "import_status_counts" => import_status_counts,
      "cadence_import_status_counts" => cadence_import_status_counts,
      "freshness_status_counts" => freshness_status_counts,
      "schema_validation_status_counts" => schema_validation_status_counts,
      "source_model_counts" => source_model_counts,
      "source_model_limit_counts" => source_model_limit_counts,
      "policy_classification_counts" => policy_classification_counts,
      "adapter_boundary_status_counts" => adapter_boundary_status_counts,
      "operator_training_requirement_counts" =>
        operator_training_context["operator_training_requirement_counts"],
      "required_operator_roles" => operator_training_context["required_operator_roles"],
      "required_training_ids" => operator_training_context["required_training_ids"],
      "required_certification_ids" => operator_training_context["required_certification_ids"],
      "required_qualification_ids" => operator_training_context["required_qualification_ids"],
      "resource_availability_reason_counts" => resource_availability_reason_counts,
      "resource_availability_reason_ids" =>
        sorted_count_keys(resource_availability_reason_counts),
      "station_availability_reason_ids" =>
        station_availability_reason_ids(resource_availability_reason_counts),
      "station_availability_reason_counts" =>
        station_availability_reason_counts(resource_availability_reason_counts),
      "unavailable_resource_reason_ids" =>
        unavailable_resource_reason_ids(resource_availability_reason_counts),
      "resource_blocking_dimension_counts" => resource_blocking_dimension_counts,
      "resource_blocked_contact_ids_by_blocking_dimension" =>
        resource_blocked_contact_ids_by_blocking_dimension,
      "resource_blocked_contact_ids_by_spacecraft_id" =>
        resource_blocked_contact_ids_by_spacecraft_id,
      "resource_source_quality_counts" => resource_source_quality_counts,
      "resource_trust_boundary_status_counts" => resource_trust_boundary_status_counts
    }
    |> Map.merge(timeline_publication_context)
  end

  defp rows(artifact), do: EvidenceNormalization.rows(artifact)

  defp row_counts(rows, field), do: EvidenceNormalization.row_counts(rows, field)

  defp freshness_status_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.freshness_status_counts(artifact, review_rows, import_rows)

  defp schema_validation_status_counts(artifact, review_rows, import_rows),
    do:
      EvidenceNormalization.schema_validation_status_counts(
        artifact,
        review_rows,
        import_rows
      )

  defp schema_validation_issue_count(artifact, review_rows, import_rows, field),
    do:
      EvidenceNormalization.schema_validation_issue_count(
        artifact,
        review_rows,
        import_rows,
        field
      )

  defp source_model_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.source_model_counts(artifact, review_rows, import_rows)

  defp source_model_limit_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.source_model_limit_counts(artifact, review_rows, import_rows)

  defp map_value_count(counts), do: EvidenceNormalization.map_value_count(counts)

  defp policy_classification_counts(artifact, review_rows, import_rows),
    do: EvidenceNormalization.policy_classification_counts(artifact, review_rows, import_rows)

  defp operator_training_context(artifact, review_rows, import_rows),
    do: OperatorTrainingEvidence.context(artifact, review_rows, import_rows)

  defp timeline_publication_context(artifact, review_rows, import_rows),
    do: TimelinePublicationContext.build(artifact, review_rows, import_rows)

  defp resource_availability_reason_counts(review_rows, import_rows),
    do:
      ResourceAvailabilityEvidence.resource_availability_reason_counts(
        review_rows,
        import_rows
      )

  defp resource_blocking_dimension_counts(review_rows, import_rows),
    do:
      ResourceAvailabilityEvidence.resource_blocking_dimension_counts(
        review_rows,
        import_rows
      )

  defp resource_blocked_contact_id_map(review_rows, import_rows, map_field, group_field),
    do:
      ResourceAvailabilityEvidence.resource_blocked_contact_id_map(
        review_rows,
        import_rows,
        map_field,
        group_field
      )

  defp resource_provenance_counts(review_rows, import_rows, field),
    do:
      ResourceAvailabilityEvidence.resource_provenance_counts(
        review_rows,
        import_rows,
        field
      )

  defp adapter_boundary_status_counts(artifact, review_rows, import_rows),
    do: AdapterBoundaryEvidence.status_counts(artifact, review_rows, import_rows)

  defp count_values(counts, values) do
    values
    |> Enum.map(&Map.get(counts, &1, 0))
    |> Enum.sum()
  end

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp sorted_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> stable_sorted_ids()
  end

  defp unavailable_resource_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in unavailable_resource_reasons()))
    |> stable_sorted_ids()
  end

  defp station_availability_reason_ids(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> Enum.filter(&(&1 in station_availability_reasons()))
    |> stable_sorted_ids()
  end

  defp station_availability_reason_counts(counts) when is_map(counts) do
    counts
    |> positive_count_map()
    |> Map.filter(fn {reason, _count} -> reason in station_availability_reasons() end)
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

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
