defmodule OrbitalDynamics.CadenceImport.RefreshBudgetManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    dropped_count =
      row["dropped_candidate_count"] || length(List.wrap(row["dropped_candidate_ids"]))

    %{
      "id" => "cadence_import:refresh_budget_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_refresh_budget",
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
      "refresh_gate" => "candidate_budget",
      "refresh_gate_status" => refresh_budget_gate_status(row),
      "refresh_budget_overflow_count" => dropped_count,
      "input_candidate_count" => row["input_candidate_count"],
      "kept_candidate_count" => row["kept_candidate_count"],
      "dropped_candidate_count" => row["dropped_candidate_count"],
      "max_candidate_activities" => row["max_candidate_activities"],
      "invalid_candidate_limit_policy" => row["invalid_candidate_limit_policy"],
      "invalid_candidate_limit_policy_reason" => row["invalid_candidate_limit_policy_reason"],
      "source_candidate_limit_policy" => row["source_candidate_limit_policy"],
      "selection_order" => row["selection_order"],
      "kept_candidate_ids" => row["kept_candidate_ids"],
      "dropped_candidate_ids" => row["dropped_candidate_ids"],
      "source_refresh_budget_report" => row["source_refresh_budget_report"],
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp refresh_budget_gate_status(%{"invalid_candidate_limit_policy" => true}),
    do: "invalid_candidate_limit_policy"

  defp refresh_budget_gate_status(_row), do: "candidate_budget_exceeded"

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
