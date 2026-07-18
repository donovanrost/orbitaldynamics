defmodule OrbitalDynamics.CadenceImport.FreshnessManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    stale_reasons = List.wrap(row["stale_reasons"])
    unknown_reasons = List.wrap(row["unknown_reasons"])

    %{
      "id" => "cadence_import:freshness_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_refresh_freshness",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "source" => row["source"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "refresh_gate" => "accepted_state_freshness",
      "refresh_gate_status" => row["freshness_status"],
      "freshness_reason_count" => length(stale_reasons) + length(unknown_reasons),
      "freshness_status" => row["freshness_status"],
      "generated_at" => row["generated_at"],
      "accepted_at" => row["accepted_at"],
      "accepted_state_quality_level" => row["accepted_state_quality_level"],
      "allowed_state_quality_levels" => row["allowed_state_quality_levels"],
      "state_quality_status" => row["state_quality_status"],
      "current_epoch_s" => row["current_epoch_s"],
      "horizon_starts_at_s" => row["horizon_starts_at_s"],
      "accepted_snapshot_age_s" => row["accepted_snapshot_age_s"],
      "horizon_start_offset_s" => row["horizon_start_offset_s"],
      "max_snapshot_age_s" => row["max_snapshot_age_s"],
      "max_horizon_start_offset_s" => row["max_horizon_start_offset_s"],
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => unknown_reasons,
      "source_freshness_report" => row["source_freshness_report"],
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
