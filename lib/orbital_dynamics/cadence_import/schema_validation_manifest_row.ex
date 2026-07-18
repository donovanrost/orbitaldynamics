defmodule OrbitalDynamics.CadenceImport.SchemaValidationManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    issue_count = (row["error_count"] || 0) + (row["warning_count"] || 0)

    %{
      "id" => "cadence_import:schema_validation:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_schema_validation",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "schema_validation_gate" => "artifact_contract_validation",
      "schema_validation_gate_status" => row["validation_status"],
      "schema_validation_issue_count" => issue_count,
      "validation_status" => row["validation_status"],
      "validation_mode" => row["validation_mode"],
      "validated_contract" => row["validated_contract"],
      "validated_artifact_family" => row["validated_artifact_family"],
      "artifact_path" => row["artifact_path"],
      "issue_severity" => row["issue_severity"],
      "issue_path" => row["issue_path"],
      "issue_message" => row["issue_message"],
      "error_count" => row["error_count"],
      "warning_count" => row["warning_count"],
      "remediation_count" => row["remediation_count"],
      "remediation_category" => row["remediation_category"],
      "remediation_action" => row["remediation_action"],
      "source_validation_issue" => row["source_validation_issue"],
      "source_validation_remediation" => row["source_validation_remediation"],
      "source_schema_validation_report" => row["source_schema_validation_report"],
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
