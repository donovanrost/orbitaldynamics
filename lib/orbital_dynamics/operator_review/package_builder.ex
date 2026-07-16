defmodule OrbitalDynamics.OperatorReview.PackageBuilder do
  @moduledoc false

  @cadence_import_statuses ~w(invalid missing not_applicable present)

  def build(
        rows,
        source_artifact_type,
        source_artifact_id,
        provenance,
        schema_contract,
        model_limits
      ) do
    rows =
      rows
      |> Enum.map(&normalize_cadence_import_statuses/1)
      |> Enum.map(&put_review_queue/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} -> Map.put(row, "rank", index) end)

    %{
      "schema_contract" => schema_contract,
      "model" => "artifact_only_operator_review_package",
      "source_artifact_type" => source_artifact_type,
      "source_artifact_id" => source_artifact_id,
      "review_count" => length(rows),
      "approval_requirement_count" =>
        Enum.count(rows, &(&1["review_type"] == "approval_requirement")),
      "policy_escalation_count" => Enum.count(rows, &(&1["review_type"] == "policy_escalation")),
      "operational_timeline_count" =>
        Enum.count(rows, &(&1["review_type"] == "operational_timeline_review")),
      "contact_suppression_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_suppression")),
      "resource_projection_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "resource_projection_review")),
      "resource_suppression_count" =>
        Enum.count(rows, &(&1["review_type"] == "resource_suppression")),
      "contention_recommendation_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_contention_recommendation")),
      "contention_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_contention_review")),
      "command_window_count" => Enum.count(rows, &(&1["review_type"] == "command_window_review")),
      "station_calendar_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "station_calendar_review")),
      "station_reservation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "station_reservation_review")),
      "link_capacity_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "link_capacity_review")),
      "contact_allocation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_allocation_review")),
      "contact_allocation_capacity_pack_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_allocation_capacity_pack_review")),
      "contact_intent_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "contact_intent_review")),
      "candidate_rejection_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "candidate_rejection_review")),
      "provider_counteroffer_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "provider_counteroffer_review")),
      "candidate_diff_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "candidate_diff_review")),
      "freshness_review_count" => Enum.count(rows, &(&1["review_type"] == "freshness_review")),
      "refresh_budget_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "refresh_budget_review")),
      "model_acceptance_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "model_acceptance_review")),
      "validation_safety_case_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "validation_safety_case_review")),
      "realized_feedback_count" => Enum.count(rows, &(&1["review_type"] == "realized_feedback")),
      "timeline_diff_count" => Enum.count(rows, &(&1["review_type"] == "timeline_diff_review")),
      "timeline_dependency_impact_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_dependency_impact_review")),
      "timeline_publication_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_publication_review")),
      "timeline_activity_precondition_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_activity_precondition_review")),
      "timeline_lifecycle_state_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_lifecycle_state_review")),
      "timeline_preservation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_preservation_review")),
      "timeline_integrity_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_integrity_review")),
      "maneuver_review_count" => Enum.count(rows, &(&1["review_type"] == "maneuver_review")),
      "plan_delta_count" => Enum.count(rows, &(&1["review_type"] == "plan_delta_review")),
      "timeline_protection_count" =>
        Enum.count(rows, &(&1["review_type"] == "timeline_protection")),
      "warning_count" => Enum.count(rows, &(&1["review_type"] == "warning")),
      "risk_count" => Enum.count(rows, &(&1["review_type"] == "risk_explanation")),
      "recommendation_count" =>
        Enum.count(rows, &(&1["review_type"] == "strategy_recommendation")),
      "tradeoff_count" => Enum.count(rows, &(&1["review_type"] == "strategy_tradeoff")),
      "score_term_review_count" => Enum.count(rows, &(&1["review_type"] == "score_term_review")),
      "objective_tradeoff_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "objective_tradeoff_review")),
      "ranking_comparison_count" =>
        Enum.count(rows, &(&1["review_type"] == "ranking_comparison_review")),
      "pareto_frontier_count" =>
        Enum.count(rows, &(&1["review_type"] == "pareto_frontier_review")),
      "constraint_review_count" => Enum.count(rows, &(&1["review_type"] == "constraint_review")),
      "objective_satisfaction_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "objective_satisfaction_review")),
      "schema_validation_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "schema_validation_review")),
      "execution_review_count" => Enum.count(rows, &(&1["review_type"] == "execution_review")),
      "operational_readiness_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "operational_readiness_review")),
      "quality_gate_review_count" =>
        Enum.count(rows, &(&1["review_type"] == "quality_gate_review")),
      "review_type_counts" => count_by(rows, "review_type"),
      "review_queue_counts" => count_by(rows, "review_queue_key"),
      "approval_status_counts" => count_by(rows, "approval_status"),
      "required_operator_action_counts" => count_by(rows, "required_operator_action"),
      "cadence_import_status_counts" => count_by(rows, "cadence_import_status"),
      "source_cadence_import_status_counts" => count_by(rows, "source_cadence_import_status"),
      "replacement_cadence_import_status_counts" =>
        count_by(rows, "replacement_cadence_import_status"),
      "rows" => rows,
      "provenance" => provenance,
      "model_limits" => model_limits,
      "assumptions" => %{
        "boundary" => "artifact_only_no_api_or_database_writes",
        "operator_review_model" =>
          "existing_approval_warning_risk_recommendation_and_tradeoff_fields_normalized_for_import"
      }
    }
  end

  defp normalize_cadence_import_statuses(%{} = row) do
    row
    |> normalize_cadence_import_status_field("cadence_import_status")
    |> normalize_cadence_import_status_field("source_cadence_import_status")
    |> normalize_cadence_import_status_field("replacement_cadence_import_status")
  end

  defp normalize_cadence_import_status_field(row, field) do
    case Map.fetch(row, field) do
      {:ok, status} ->
        normalized_status = encode_value(status)

        if normalized_status in @cadence_import_statuses do
          Map.put(row, field, normalized_status)
        else
          row
          |> Map.put(field, "invalid")
          |> Map.put("unsupported_#{field}", encode_value(status))
          |> maybe_mark_invalid_cadence_import(field)
        end

      :error ->
        row
    end
  end

  defp maybe_mark_invalid_cadence_import(row, "cadence_import_status") do
    row
    |> Map.put("invalid_cadence_import", true)
    |> Map.put("has_cadence_import", false)
    |> Map.put_new("invalid_cadence_import_reason", "unsupported_cadence_import_status")
  end

  defp maybe_mark_invalid_cadence_import(row, "source_cadence_import_status") do
    Map.put(row, "source_has_cadence_import", false)
  end

  defp maybe_mark_invalid_cadence_import(row, "replacement_cadence_import_status") do
    Map.put(row, "replacement_has_cadence_import", false)
  end

  defp maybe_mark_invalid_cadence_import(row, _field), do: row

  defp put_review_queue(row) do
    review_type = review_queue_value(row["review_type"], "review")

    review_action =
      review_queue_value(row["required_operator_action"] || row["action"], review_type)

    approval_status = review_queue_value(row["approval_status"], "unspecified")

    row
    |> Map.put("review_queue", review_action)
    |> Map.put("review_queue_key", Enum.join([review_type, review_action, approval_status], "|"))
  end

  defp review_queue_value(value, _default) when is_binary(value) and value != "", do: value
  defp review_queue_value(_value, default), do: default

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
