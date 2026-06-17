defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow.Summary do
  @moduledoc false

  def summary(command_summary, summary_source, replay_scope) do
    command_feedback_count = summary_integer(command_summary, "command_feedback_count")
    input_keys = Map.get(command_summary, "input_keys", [])
    direction_counts = Map.get(command_summary, "direction_counts", %{})
    activity_ids_by_direction = Map.get(command_summary, "activity_ids_by_direction", %{})
    window_ids_by_direction = Map.get(command_summary, "window_ids_by_direction", %{})
    direction_routing = Map.get(command_summary, "direction_routing", %{})
    required_action_counts = Map.get(command_summary, "required_operator_action_counts", %{})

    %{
      "model" => "artifact_only_candidate_refresh_command_window_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(command_summary, "command_window_report.v1"),
      "source_report_count" => summary_integer(command_summary, "count"),
      "source_report_row_count" => summary_integer(command_summary, "row_count"),
      "source_report_paths" => Map.get(command_summary, "paths", []),
      "command_feedback_count" => command_feedback_count,
      "input_keys" => input_keys,
      "direction_counts" => direction_counts,
      "activity_ids_by_direction" => activity_ids_by_direction,
      "window_ids_by_direction" => window_ids_by_direction,
      "direction_routing" => direction_routing,
      "required_operator_action_counts" => required_action_counts,
      "trust_boundary_status" => Map.get(command_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(command_summary, "trust_boundaries", []),
      "branch_local_command_window_pressure" =>
        command_feedback_count > 0 or input_keys != [] or map_size(direction_counts) > 0 or
          map_size(activity_ids_by_direction) > 0 or map_size(window_ids_by_direction) > 0 or
          map_size(direction_routing) > 0 or map_size(required_action_counts) > 0,
      "branch_local_command_feedback_pressure" => command_feedback_count > 0 or input_keys != [],
      "branch_local_command_window_action_pressure" => map_size(required_action_counts) > 0,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_command_window_replay_summary",
        "command_execution" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_command_window_replay_summary",
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
