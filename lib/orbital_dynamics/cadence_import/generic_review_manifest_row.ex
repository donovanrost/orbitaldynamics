defmodule OrbitalDynamics.CadenceImport.GenericReviewManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    cadence_import_status = Map.get(row, "cadence_import_status", "present")
    has_cadence_import = cadence_import_present?(callbacks, row, cadence_import_status)

    %{
      "id" => "cadence_import:#{row["review_type"] || "review"}:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => generic_review_import_action(callbacks, row["review_type"]),
      "import_status" => adapter_import_status(callbacks, cadence_import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => cadence_import_status,
      "has_cadence_import" => has_cadence_import,
      "source_review_row" => row,
      "timeline_identity" => row["timeline_identity"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "timeline_link" => row["timeline_link"],
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          callbacks,
          generic_review_activity_context(callbacks, row)
        )
    }
    |> Map.merge(
      row
      |> Map.take(OrbitalDynamics.CadenceImport.GenericReviewPassthroughFields.fields())
      |> Map.delete("has_cadence_import")
    )
    |> compact_map(callbacks)
  end

  defp cadence_import_present?(callbacks, row, status),
    do: invoke(callbacks, :cadence_import_present?, [row, status])

  defp generic_review_import_action(callbacks, review_type),
    do: invoke(callbacks, :generic_review_import_action, [review_type])

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp generic_review_activity_context(callbacks, row),
    do: invoke(callbacks, :generic_review_activity_context, [row])

  defp normalize_provider_result_artifact_fields(callbacks, value),
    do: invoke(callbacks, :normalize_provider_result_artifact_fields, [value])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
