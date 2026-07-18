defmodule OrbitalDynamics.CadenceImport.OperationalReadinessManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:operational_readiness_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => generic_review_import_action(callbacks, "operational_readiness_review"),
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "source" => row["source"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_artifact_type" => row["source_artifact_type"],
      "source_artifact_id" => row["source_artifact_id"],
      "readiness_level" => row["readiness_level"],
      "import_classification" => row["import_classification"],
      "operational_readiness_status" => row["operational_readiness_status"],
      "readiness_gate_id" => row["readiness_gate_id"],
      "readiness_gate_status" => row["readiness_gate_status"],
      "readiness_gate_classification" => row["readiness_gate_classification"],
      "readiness_gate_reason" => row["readiness_gate_reason"],
      "analysis_mode" => row["analysis_mode"],
      "analysis_mode_source" => row["analysis_mode_source"],
      "gate_count" => row["gate_count"],
      "passed_gate_count" => row["passed_gate_count"],
      "review_gate_count" => row["review_gate_count"],
      "analysis_gate_count" => row["analysis_gate_count"],
      "blocked_gate_count" => row["blocked_gate_count"],
      "gates" => row["gates"],
      "evidence" => row["evidence"],
      "source_operational_readiness_gate" => row["source_operational_readiness_gate"],
      "source_operational_readiness_report" => row["source_operational_readiness_report"],
      "source_review_row" => row
    }
    |> Map.merge(operational_readiness_resource_context(callbacks, row))
    |> Map.merge(operational_readiness_adapter_boundary_context(callbacks, row))
    |> Map.merge(operational_readiness_operator_training_context(callbacks, row))
    |> Map.merge(operational_readiness_cadence_import_context(callbacks, row))
    |> compact_map(callbacks)
  end

  defp generic_review_import_action(callbacks, review_type),
    do: invoke(callbacks, :generic_review_import_action, [review_type])

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp operational_readiness_resource_context(callbacks, row),
    do: invoke(callbacks, :operational_readiness_resource_context, [row])

  defp operational_readiness_adapter_boundary_context(callbacks, row),
    do: invoke(callbacks, :operational_readiness_adapter_boundary_context, [row])

  defp operational_readiness_operator_training_context(callbacks, row),
    do: invoke(callbacks, :operational_readiness_operator_training_context, [row])

  defp operational_readiness_cadence_import_context(callbacks, row),
    do: invoke(callbacks, :operational_readiness_cadence_import_context, [row])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
