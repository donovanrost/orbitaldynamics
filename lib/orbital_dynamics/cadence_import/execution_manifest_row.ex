defmodule OrbitalDynamics.CadenceImport.ExecutionManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:execution:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_execution",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "scenario_index" => row["scenario_index"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "execution_status" => row["execution_status"],
      "execution_mode" => row["execution_mode"],
      "execution_stage" => row["execution_stage"],
      "execution_error" => row["execution_error"],
      "resumability" => row["resumability"],
      "retry_recommendation" => row["retry_recommendation"],
      "study_id" => row["study_id"],
      "run_id" => row["run_id"],
      "failed_scenario_count" => row["failed_scenario_count"],
      "completed_scenario_count" => row["completed_scenario_count"],
      "scenario_count" => row["scenario_count"],
      "source_execution_failure" => row["source_execution_failure"],
      "source_execution_report" => row["source_execution_report"],
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
