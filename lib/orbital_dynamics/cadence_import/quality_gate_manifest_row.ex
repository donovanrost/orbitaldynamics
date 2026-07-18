defmodule OrbitalDynamics.CadenceImport.QualityGateManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:quality_gate_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_quality_gate",
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
      "quality_gate_report_id" => row["quality_gate_report_id"],
      "quality_gate_id" => row["quality_gate_id"],
      "quality_gate_status" => row["quality_gate_status"],
      "quality_gate_classification" => row["quality_gate_classification"],
      "quality_gate_reason" => row["quality_gate_reason"],
      "readiness_gate_id" => row["readiness_gate_id"],
      "readiness_gate_status" => row["readiness_gate_status"],
      "readiness_gate_classification" => row["readiness_gate_classification"],
      "readiness_gate_reason" => row["readiness_gate_reason"],
      "analysis_mode" => row["analysis_mode"],
      "analysis_mode_source" => row["analysis_mode_source"],
      "source_quality_gate_row" => row["source_quality_gate_row"],
      "source_quality_gate_report" => row["source_quality_gate_report"],
      "source_review_row" => row
    }
    |> Map.merge(operational_readiness_cadence_import_context(callbacks, row))
    |> Map.merge(operational_readiness_resource_context(callbacks, row))
    |> compact_map(callbacks)
  end

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp operational_readiness_cadence_import_context(callbacks, row),
    do: invoke(callbacks, :operational_readiness_cadence_import_context, [row])

  defp operational_readiness_resource_context(callbacks, row),
    do: invoke(callbacks, :operational_readiness_resource_context, [row])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
