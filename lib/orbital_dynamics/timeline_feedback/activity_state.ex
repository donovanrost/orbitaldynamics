defmodule OrbitalDynamics.TimelineFeedback.ActivityState do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.ArtifactValue

  @schema_contract "timeline_activity_state.v1"

  def build(rows, lifecycle_state, model_limits)
      when is_list(rows) and is_map(lifecycle_state) and is_list(model_limits) do
    primary = primary_row(rows)

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_timeline_activity_state",
      "validation_level" => "artifact_contract",
      "state_status" => state_status(rows),
      "row_count" => length(rows),
      "status_counts" => status_counts(rows),
      "feedback_kind_counts" => count_by(rows, "feedback_kind"),
      "match_strategy_counts" => count_by(rows, "match_strategy"),
      "cadence_import_status_counts" => count_by(rows, "cadence_import_status"),
      "planned_protection_decision_counts" => count_by(rows, "planned_protection_decision"),
      "realized_provider_counts" => optional_count_by(rows, "realized_provider"),
      "realized_source_quality_counts" => optional_count_by(rows, "realized_source_quality"),
      "realized_trust_boundary_status" => realized_trust_boundary_status(rows),
      "realized_trust_boundaries" => realized_trust_boundaries(rows),
      "activity_id" => value(primary, "activity_id"),
      "activity_ids" => ids(rows, "activity_id"),
      "timeline_id" =>
        value(primary, "planned_timeline_id") || value(primary, "realized_timeline_id"),
      "planned_timeline_id" => value(primary, "planned_timeline_id"),
      "realized_timeline_id" => value(primary, "realized_timeline_id"),
      "timeline_identity" => value(primary, "timeline_identity"),
      "feedback_kind" => value(primary, "feedback_kind"),
      "match_strategy" => value(primary, "match_strategy"),
      "planned_status" => planned_status(primary),
      "realized_status" => realized_status(primary),
      "planned_status_category" => Map.get(lifecycle_state, "planned_status_category"),
      "realized_status_category" => Map.get(lifecycle_state, "realized_status_category"),
      "feedback_status" => value(primary, "feedback_status"),
      "status_transition" => value(primary, "status_transition"),
      "planned_approval_status" => Map.get(lifecycle_state, "planned_approval_status"),
      "realized_approval_status" => Map.get(lifecycle_state, "realized_approval_status"),
      "planned_approval_category" => Map.get(lifecycle_state, "planned_approval_category"),
      "realized_approval_category" => Map.get(lifecycle_state, "realized_approval_category"),
      "approval_transition" => Map.get(lifecycle_state, "approval_transition"),
      "planned_locked" => Map.get(lifecycle_state, "planned_locked"),
      "realized_locked" => Map.get(lifecycle_state, "realized_locked"),
      "planned_executed" => Map.get(lifecycle_state, "planned_executed"),
      "realized_executed" => Map.get(lifecycle_state, "realized_executed"),
      "planned_protection_decision" => value(primary, "planned_protection_decision"),
      "planned_protection_category" => value(primary, "planned_protection_category"),
      "planned_protection_reason" => value(primary, "planned_protection_reason"),
      "source_protection_decision" => value(primary, "source_protection_decision"),
      "realized_protection_decision" => Map.get(lifecycle_state, "realized_protection_decision"),
      "source_activity_context" => value(primary, "source_activity_context"),
      "realized_activity_context" => value(primary, "realized_activity_context"),
      "review_required" => review_required?(rows),
      "review_activity_ids" => review_ids(rows),
      "rows" => rows,
      "assumptions" => %{
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "source" => "timeline_feedback.reconcile"
      },
      "model_limits" => model_limits
    }
    |> ArtifactValue.compact_map()
  end

  defp primary_row(rows) do
    Enum.find(rows, &(&1["status"] == "matched")) ||
      Enum.find(rows, &(&1["status"] == "planned_only")) ||
      List.first(rows, %{})
  end

  defp state_status([]), do: "empty"
  defp state_status([%{"status" => status}]), do: status

  defp state_status(rows) do
    if Enum.any?(rows, &(&1["status"] == "matched")) do
      "matched"
    else
      "review_required"
    end
  end

  defp ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp review_required?(rows) do
    Enum.any?(rows, fn row ->
      Map.get(row, "status") != "matched" or
        Map.get(row, "planned_protection_decision") == "review_change" or
        present_review_action?(Map.get(row, "required_operator_action")) or
        present_review_action?(get_in(row, ["status_transition", "required_operator_action"]))
    end)
  end

  defp review_ids(rows) do
    rows
    |> Enum.filter(&review_required?([&1]))
    |> ids("activity_id")
  end

  defp present_review_action?(action) when action in [nil, "", "none"], do: false
  defp present_review_action?(_action), do: true

  defp optional_count_by(rows, field) do
    rows
    |> count_by(field)
    |> case do
      counts when map_size(counts) == 0 -> nil
      counts -> counts
    end
  end

  defp realized_trust_boundary_status(rows) do
    if realized_row_count(rows) == 0 do
      nil
    else
      case realized_trust_boundary_values(rows) do
        [] -> "missing"
        _boundaries -> "declared"
      end
    end
  end

  defp realized_trust_boundaries(rows) do
    case realized_trust_boundary_values(rows) do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp realized_trust_boundary_values(rows) do
    rows
    |> Enum.map(&Map.get(&1, "realized_trust_boundary"))
    |> Enum.filter(&ArtifactValue.present_string?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp realized_row_count(rows) do
    Enum.count(rows, fn row ->
      Map.get(row, "status") in ["matched", "realized_only"] or
        ArtifactValue.present_string?(Map.get(row, "realized_activity_id")) or
        ArtifactValue.present_string?(Map.get(row, "realized_status"))
    end)
  end

  defp planned_status(row) do
    value(row, "planned_status") || get_in(row, ["status_transition", "from"])
  end

  defp realized_status(row) do
    value(row, "realized_status") || get_in(row, ["status_transition", "to"])
  end

  defp count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {value, _count} -> value end)
    |> Map.new()
  end

  defp status_counts(rows) do
    rows
    |> Enum.group_by(& &1["status"])
    |> Map.new(fn {status, status_rows} -> {status, length(status_rows)} end)
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)
end
