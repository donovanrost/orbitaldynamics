defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity.Summary do
  @moduledoc false

  def summary(integrity_summary, summary_source, replay_scope) do
    issue_count = summary_integer(integrity_summary, "timeline_integrity_issue_count")
    review_count = summary_integer(integrity_summary, "timeline_integrity_review_count")
    dependency_issue_count = summary_integer(integrity_summary, "dependency_issue_count")
    exclusivity_issue_count = summary_integer(integrity_summary, "exclusivity_issue_count")

    status_counts = Map.get(integrity_summary, "timeline_integrity_status_counts", %{})
    issue_type_counts = Map.get(integrity_summary, "timeline_integrity_issue_type_counts", %{})
    required_action_counts = Map.get(integrity_summary, "required_operator_action_counts", %{})

    operator_action_reason_counts =
      Map.get(integrity_summary, "operator_action_reason_counts", %{})

    review_activity_id_counts = Map.get(integrity_summary, "review_activity_id_counts", %{})
    review_timeline_id_counts = Map.get(integrity_summary, "review_timeline_id_counts", %{})

    missing_dependency_activity_id_counts =
      Map.get(integrity_summary, "missing_dependency_activity_id_counts", %{})

    missing_dependency_timeline_id_counts =
      Map.get(integrity_summary, "missing_dependency_timeline_id_counts", %{})

    self_dependency_activity_id_counts =
      Map.get(integrity_summary, "self_dependency_activity_id_counts", %{})

    self_dependency_timeline_id_counts =
      Map.get(integrity_summary, "self_dependency_timeline_id_counts", %{})

    dependency_cycle_activity_id_counts =
      Map.get(integrity_summary, "dependency_cycle_activity_id_counts", %{})

    dependency_cycle_timeline_id_counts =
      Map.get(integrity_summary, "dependency_cycle_timeline_id_counts", %{})

    dependency_order_violation_activity_id_counts =
      Map.get(integrity_summary, "dependency_order_violation_activity_id_counts", %{})

    dependency_order_violation_timeline_id_counts =
      Map.get(integrity_summary, "dependency_order_violation_timeline_id_counts", %{})

    exclusivity_violation_activity_id_counts =
      Map.get(integrity_summary, "exclusivity_violation_activity_id_counts", %{})

    exclusivity_violation_timeline_id_counts =
      Map.get(integrity_summary, "exclusivity_violation_timeline_id_counts", %{})

    exclusivity_violation_group_counts =
      Map.get(integrity_summary, "exclusivity_violation_group_counts", %{})

    dependency_routing_pressure =
      dependency_issue_count > 0 or map_size(missing_dependency_activity_id_counts) > 0 or
        map_size(missing_dependency_timeline_id_counts) > 0 or
        map_size(self_dependency_activity_id_counts) > 0 or
        map_size(self_dependency_timeline_id_counts) > 0 or
        map_size(dependency_cycle_activity_id_counts) > 0 or
        map_size(dependency_cycle_timeline_id_counts) > 0 or
        map_size(dependency_order_violation_activity_id_counts) > 0 or
        map_size(dependency_order_violation_timeline_id_counts) > 0

    exclusivity_routing_pressure =
      exclusivity_issue_count > 0 or map_size(exclusivity_violation_activity_id_counts) > 0 or
        map_size(exclusivity_violation_timeline_id_counts) > 0 or
        map_size(exclusivity_violation_group_counts) > 0

    review_routing_pressure =
      review_count > 0 or map_size(required_action_counts) > 0 or
        map_size(review_activity_id_counts) > 0 or map_size(review_timeline_id_counts) > 0

    %{
      "model" => "artifact_only_candidate_refresh_timeline_integrity_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(integrity_summary, "timeline_integrity_report.v1"),
      "source_report_count" => summary_integer(integrity_summary, "count"),
      "source_report_row_count" => summary_integer(integrity_summary, "row_count"),
      "source_report_paths" => Map.get(integrity_summary, "paths", []),
      "timeline_integrity_issue_count" => issue_count,
      "timeline_integrity_review_count" => review_count,
      "dependency_issue_count" => dependency_issue_count,
      "exclusivity_issue_count" => exclusivity_issue_count,
      "timeline_integrity_status_counts" => status_counts,
      "timeline_integrity_issue_type_counts" => issue_type_counts,
      "required_operator_action_counts" => required_action_counts,
      "operator_action_reason_counts" => operator_action_reason_counts,
      "review_activity_id_counts" => review_activity_id_counts,
      "review_timeline_id_counts" => review_timeline_id_counts,
      "missing_dependency_activity_id_counts" => missing_dependency_activity_id_counts,
      "missing_dependency_timeline_id_counts" => missing_dependency_timeline_id_counts,
      "self_dependency_activity_id_counts" => self_dependency_activity_id_counts,
      "self_dependency_timeline_id_counts" => self_dependency_timeline_id_counts,
      "dependency_cycle_activity_id_counts" => dependency_cycle_activity_id_counts,
      "dependency_cycle_timeline_id_counts" => dependency_cycle_timeline_id_counts,
      "dependency_order_violation_activity_id_counts" =>
        dependency_order_violation_activity_id_counts,
      "dependency_order_violation_timeline_id_counts" =>
        dependency_order_violation_timeline_id_counts,
      "exclusivity_violation_activity_id_counts" => exclusivity_violation_activity_id_counts,
      "exclusivity_violation_timeline_id_counts" => exclusivity_violation_timeline_id_counts,
      "exclusivity_violation_group_counts" => exclusivity_violation_group_counts,
      "trust_boundary_status" => Map.get(integrity_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(integrity_summary, "trust_boundaries", []),
      "branch_local_timeline_integrity_pressure" =>
        issue_count > 0 or map_size(status_counts) > 0 or map_size(issue_type_counts) > 0 or
          review_routing_pressure or dependency_routing_pressure or exclusivity_routing_pressure,
      "branch_local_timeline_integrity_review_pressure" => review_routing_pressure,
      "branch_local_dependency_integrity_pressure" => dependency_routing_pressure,
      "branch_local_exclusivity_integrity_pressure" => exclusivity_routing_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_integrity_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_integrity_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp source_report_summary_contract(summary, default_contract) when map_size(summary) > 0 do
    case Map.get(summary, "contract", default_contract) do
      contract when is_binary(contract) and contract != "" -> contract
      _contract -> nil
    end
  end

  defp source_report_summary_contract(_summary, _default_contract), do: nil

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
