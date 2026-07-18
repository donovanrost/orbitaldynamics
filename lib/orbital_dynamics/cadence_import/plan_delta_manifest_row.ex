defmodule OrbitalDynamics.CadenceImport.PlanDeltaManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    import_side = import_side(row)
    import_status = Map.get(row, "#{import_side}_cadence_import_status", "not_applicable")
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => import_action(row),
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => import_side,
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "target_id" => row["target_id"],
      "repair_action" => row["repair_action"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "source_timeline_id" => row["source_timeline_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "replacement_timeline_id" => row["replacement_timeline_id"],
      "timeline_link" => row["timeline_link"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "cadence_import_status" => import_status,
      "cadence_import_type" => row["#{import_side}_cadence_import_type"],
      "cadence_import_id" => row["#{import_side}_cadence_import_id"],
      "cadence_import_contract" => row["#{import_side}_cadence_import_contract"],
      "has_cadence_import" => row["#{import_side}_has_cadence_import"],
      "source_cadence_import_status" => row["source_cadence_import_status"],
      "replacement_cadence_import_status" => row["replacement_cadence_import_status"],
      "invalid_cadence_import" => row["invalid_cadence_import"],
      "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
      "source_cadence_import" => row["source_cadence_import"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          callbacks,
          row["#{import_side}_activity_context"]
        ),
      "source_delta" => row["source_delta"]
    }
    |> compact_map(callbacks)
  end

  defp import_side(%{"replacement_activity_id" => replacement_id} = row)
       when is_binary(replacement_id) and replacement_id != "" do
    if Map.has_key?(row, "replacement_cadence_import_status"), do: "replacement", else: "source"
  end

  defp import_side(_row), do: "source"

  defp import_action(%{"repair_action" => action})
       when action in ["moved", "replaced"] do
    "import_replacement_activity"
  end

  defp import_action(%{"repair_action" => "canceled"}), do: "cancel_source_activity"
  defp import_action(%{"repair_action" => "suppressed"}), do: "suppress_source_activity"

  defp import_action(%{"repair_action" => "preserved_executed"}),
    do: "record_preserved_executed_activity"

  defp import_action(%{"repair_action" => "preserved"}) do
    "record_preserved_activity"
  end

  defp import_action(_row), do: "review_plan_delta"

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp normalize_provider_result_artifact_fields(callbacks, value),
    do: invoke(callbacks, :normalize_provider_result_artifact_fields, [value])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
