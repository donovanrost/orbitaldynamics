defmodule OrbitalDynamics.CadenceImport.CandidateDiffManifestRow do
  @moduledoc false

  @candidate_diff_scoped_context_fields ~w(
    target_id
    target_ids
    collection_id
    collection_ids
    product_id
    product_ids
    payload_id
    payload_ids
    instrument_id
    instrument_ids
    objective_id
    objective_ids
    objective_type
    objective_types
    objective_status
    objective_statuses
    source_objective_status
    source_objective_statuses
    latency_objective
    max_latency_s
    planned_latency_s
    required_contacts
    planned_contacts
    required_downlink_mb
    planned_downlink_mb
    contact_result
    contact_results
    realized_status
    realized_statuses
    source_activity_id
    source_activity_ids
    missed_downlink_activity_id
    missed_downlink_activity_ids
    feedback_source
    feedback_sources
    feedback_scope
    feedback_scopes
    trust_boundary
    trust_boundaries
    derivation_reasons
    candidate_downlink_mb
    downlink_completion_ratio
    selected_downlink_shortfall_mb
    downlink_requirement_status
    downlink_completion_source
    downlink_completion_sources
  )
  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    semantic_change_reasons = semantic_change_reasons(row)
    changed_fields = candidate_diff_changed_fields(callbacks, row)

    %{
      "id" => "cadence_import:candidate_diff:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_candidate_diff",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "target_id" => row["target_id"],
      "source_target_id" => row["source_target_id"],
      "source_target" => row["source_target"],
      "target_latitude_deg" => row["target_latitude_deg"],
      "target_longitude_deg" => row["target_longitude_deg"],
      "target_minimum_elevation_deg" => row["target_minimum_elevation_deg"],
      "target_priority" => row["target_priority"],
      "target_priority_source" => row["target_priority_source"],
      "target_priority_objective_ids" => row["target_priority_objective_ids"],
      "target_priority_objective_type" => row["target_priority_objective_type"],
      "ground_station_id" => row["ground_station_id"],
      "direction" => row["direction"],
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "source_window" => row["source_window"],
      "source_window_lineage" => row["source_window_lineage"],
      "replacement_source_window_id" => row["replacement_source_window_id"],
      "replacement_source_window_type" => row["replacement_source_window_type"],
      "replacement_source_window" => row["replacement_source_window"],
      "replacement_source_window_lineage" => row["replacement_source_window_lineage"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "reason" => row["reason"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "refresh_gate" => "candidate_diff",
      "refresh_gate_status" => candidate_diff_gate_status(row),
      "candidate_diff_reason_count" => length(semantic_change_reasons),
      "candidate_diff" => row["candidate_diff"],
      "invalidated_candidate_id" => row["invalidated_candidate_id"],
      "invalidated_candidate_ids" => row["invalidated_candidate_ids"],
      "replacement_candidate_id" => row["replacement_candidate_id"],
      "invalidated_reason" => row["invalidated_reason"],
      "semantic_change_reasons" => semantic_change_reasons,
      "semantic_change_details" => row["semantic_change_details"],
      "changed_fields" => changed_fields,
      "candidate_diff_changed_fields" => changed_fields,
      "candidate_diff_changed_field_count" =>
        candidate_diff_changed_field_count(callbacks, changed_fields),
      "candidate_diff_match_status" => row["candidate_diff_match_status"],
      "candidate_diff_match_count" => row["candidate_diff_match_count"],
      "semantic_match_status" => row["semantic_match_status"],
      "semantic_match_candidate_count" => row["semantic_match_candidate_count"],
      "semantic_match_candidate_ids" => row["semantic_match_candidate_ids"],
      "candidate_budget_match_status" => row["candidate_budget_match_status"],
      "candidate_budget_match_count" => row["candidate_budget_match_count"],
      "budget_dropped_candidate_ids" => row["budget_dropped_candidate_ids"],
      "invalid_prior_candidate_input" => row["invalid_prior_candidate_input"],
      "invalid_prior_candidate_input_reason" => row["invalid_prior_candidate_input_reason"],
      "source_candidate" => row["source_candidate"],
      "source_candidate_diff" => row["source_candidate_diff"],
      "source_review_row" => row
    }
    |> Map.merge(candidate_diff_scoped_context(callbacks, row))
    |> compact_map(callbacks)
  end

  defp candidate_diff_scoped_context(callbacks, row) do
    row
    |> Map.take(@candidate_diff_scoped_context_fields)
    |> compact_map(callbacks)
  end

  defp candidate_diff_gate_status(row) do
    row["candidate_diff_match_status"] ||
      row["semantic_match_status"] ||
      row["candidate_budget_match_status"] ||
      row["invalidated_reason"] ||
      get_in(row, ["candidate_diff", "diff_reason"]) ||
      "candidate_invalidated"
  end

  defp semantic_change_reasons(row) do
    detail_reasons = semantic_change_detail_reasons(row["semantic_change_details"])

    case detail_reasons do
      [] ->
        row
        |> Map.get("semantic_change_reasons")
        |> List.wrap()
        |> Enum.filter(&is_binary/1)
        |> Enum.uniq()

      reasons ->
        reasons
    end
  end

  defp semantic_change_detail_reasons(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "reason"))
    |> Enum.filter(&is_binary/1)
  end

  defp candidate_diff_changed_fields(callbacks, row),
    do: invoke(callbacks, :candidate_diff_changed_fields, [row])

  defp candidate_diff_changed_field_count(callbacks, fields),
    do: invoke(callbacks, :candidate_diff_changed_field_count, [fields])

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
