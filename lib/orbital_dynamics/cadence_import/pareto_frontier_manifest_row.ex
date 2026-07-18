defmodule OrbitalDynamics.CadenceImport.ParetoFrontierManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:pareto_frontier:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_pareto_frontier",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "scenario_id" => row["scenario_id"],
      "branch_id" => row["branch_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "frontier" => row["frontier"],
      "objective_keys" => row["objective_keys"],
      "objective_values" => row["objective_values"],
      "dominated_by_ids" => row["dominated_by_ids"],
      "dominates_ids" => row["dominates_ids"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_pareto_frontier" => row["source_pareto_frontier"],
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
