defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState.Summary do
  @moduledoc false

  def summary(state_summary, summary_source, replay_scope) do
    row_count = summary_integer(state_summary, "row_count")
    review_required_count = summary_integer(state_summary, "review_required_count")
    state_status_counts = Map.get(state_summary, "state_status_counts", %{})
    transition_decision_counts = Map.get(state_summary, "transition_decision_counts", %{})
    required_action_counts = Map.get(state_summary, "required_operator_action_counts", %{})
    import_action_counts = Map.get(state_summary, "import_action_counts", %{})
    activity_id_counts = Map.get(state_summary, "activity_id_counts", %{})
    timeline_id_counts = Map.get(state_summary, "timeline_id_counts", %{})
    review_activity_id_counts = Map.get(state_summary, "review_activity_id_counts", %{})
    action_routing = Map.get(state_summary, "action_routing", %{}) |> empty_map_if_nil()

    source_summary_model_counts =
      Map.get(state_summary, "source_summary_model_counts", %{}) |> non_empty_map()

    source_summary_schema_contract_counts =
      Map.get(state_summary, "source_summary_schema_contract_counts", %{})
      |> non_empty_map()

    review_action_counts =
      required_action_counts
      |> Enum.filter(fn {action, _count} ->
        is_binary(action) and String.starts_with?(action, "review")
      end)
      |> Map.new()

    review_pressure =
      review_required_count > 0 or map_size(review_action_counts) > 0 or
        map_size(review_activity_id_counts) > 0

    routing_pressure =
      map_size(activity_id_counts) > 0 or map_size(timeline_id_counts) > 0 or
        map_size(review_activity_id_counts) > 0 or map_size(action_routing) > 0

    %{
      "model" => "artifact_only_candidate_refresh_timeline_activity_state_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(state_summary, nil),
      "source_report_count" => summary_integer(state_summary, "count"),
      "source_report_row_count" => row_count,
      "source_report_paths" => Map.get(state_summary, "paths", []),
      "source_summary_model_counts" => source_summary_model_counts,
      "source_summary_schema_contract_counts" => source_summary_schema_contract_counts,
      "review_required_count" => review_required_count,
      "state_status_counts" => state_status_counts,
      "transition_decision_counts" => transition_decision_counts,
      "required_operator_action_counts" => required_action_counts,
      "import_action_counts" => import_action_counts,
      "activity_id_counts" => activity_id_counts,
      "timeline_id_counts" => timeline_id_counts,
      "review_activity_id_counts" => review_activity_id_counts,
      "action_routing" => action_routing,
      "trust_boundary_status" => Map.get(state_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(state_summary, "trust_boundaries", []),
      "branch_local_timeline_activity_state_pressure" =>
        row_count > 0 or map_size(state_status_counts) > 0 or
          map_size(transition_decision_counts) > 0 or map_size(import_action_counts) > 0 or
          review_pressure or routing_pressure,
      "branch_local_activity_state_review_pressure" => review_pressure,
      "branch_local_activity_state_action_pressure" => map_size(action_routing) > 0,
      "branch_local_activity_state_routing_pressure" => routing_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_activity_state_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "activity_state_application" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_activity_state_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
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

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
