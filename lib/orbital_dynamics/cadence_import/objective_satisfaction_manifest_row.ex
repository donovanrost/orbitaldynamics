defmodule OrbitalDynamics.CadenceImport.ObjectiveSatisfactionManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:objective_satisfaction:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_objective_satisfaction",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "objective" => row["objective"],
      "objective_status" => row["objective_status"],
      "target_id" => row["target_id"],
      "required_count" => row["required_count"],
      "candidate_count" => row["candidate_count"],
      "selected_count" => row["selected_count"],
      "satisfied_count" => row["satisfied_count"],
      "candidate_target_ids" => row["candidate_target_ids"],
      "selected_target_ids" => row["selected_target_ids"],
      "selected_activity_ids" => row["selected_activity_ids"],
      "selected_contact_ids" => row["selected_contact_ids"],
      "required_downlink_mb" => row["required_downlink_mb"],
      "candidate_downlink_mb" => row["candidate_downlink_mb"],
      "selected_downlink_mb" => row["selected_downlink_mb"],
      "satisfied_downlink_mb" => row["satisfied_downlink_mb"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_objective_satisfaction" => row["source_objective_satisfaction"],
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
