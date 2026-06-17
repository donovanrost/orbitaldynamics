defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDiff.Summary do
  @moduledoc false

  def summary(diff_summary, summary_source, replay_scope) do
    duplicate_count = summary_integer(diff_summary, "duplicate_timeline_identity_count")

    duplicate_source_count =
      summary_integer(diff_summary, "duplicate_source_timeline_identity_count")

    duplicate_replacement_count =
      summary_integer(diff_summary, "duplicate_replacement_timeline_identity_count")

    removed_downlink_count = summary_integer(diff_summary, "removed_downlink_count")
    removed_observation_count = summary_integer(diff_summary, "removed_observation_count")

    changed_downlink_shortfall_count =
      summary_integer(diff_summary, "changed_downlink_shortfall_count")

    changed_contact_feedback_count =
      summary_integer(diff_summary, "changed_contact_feedback_count")

    changed_observation_count = summary_integer(diff_summary, "changed_observation_count")

    changed_observation_quality_feedback_count =
      summary_integer(diff_summary, "changed_observation_quality_feedback_count")

    changed_command_feedback_count =
      summary_integer(diff_summary, "changed_command_feedback_count")

    changed_maneuver_feedback_count =
      summary_integer(diff_summary, "changed_maneuver_feedback_count")

    status_counts = Map.get(diff_summary, "diff_status_counts", %{})
    required_action_counts = Map.get(diff_summary, "required_operator_action_counts", %{})

    duplicate_scope_counts =
      Map.get(diff_summary, "duplicate_timeline_identity_scope_counts", %{})

    source_activity_id_counts = Map.get(diff_summary, "source_activity_id_counts", %{})
    replacement_activity_id_counts = Map.get(diff_summary, "replacement_activity_id_counts", %{})

    removed_count = removed_downlink_count + removed_observation_count

    changed_feedback_count =
      changed_downlink_shortfall_count + changed_contact_feedback_count +
        changed_observation_count + changed_observation_quality_feedback_count +
        changed_command_feedback_count + changed_maneuver_feedback_count

    duplicate_identity_pressure =
      duplicate_count + duplicate_source_count + duplicate_replacement_count > 0 or
        map_size(duplicate_scope_counts) > 0

    %{
      "model" => "artifact_only_candidate_refresh_timeline_diff_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(diff_summary, "timeline_diff_report.v1"),
      "source_report_count" => summary_integer(diff_summary, "count"),
      "source_report_row_count" => summary_integer(diff_summary, "row_count"),
      "source_report_paths" => Map.get(diff_summary, "paths", []),
      "duplicate_timeline_identity_count" => duplicate_count,
      "duplicate_source_timeline_identity_count" => duplicate_source_count,
      "duplicate_replacement_timeline_identity_count" => duplicate_replacement_count,
      "removed_downlink_count" => removed_downlink_count,
      "removed_observation_count" => removed_observation_count,
      "changed_downlink_shortfall_count" => changed_downlink_shortfall_count,
      "changed_contact_feedback_count" => changed_contact_feedback_count,
      "changed_observation_count" => changed_observation_count,
      "changed_observation_quality_feedback_count" => changed_observation_quality_feedback_count,
      "changed_command_feedback_count" => changed_command_feedback_count,
      "changed_maneuver_feedback_count" => changed_maneuver_feedback_count,
      "diff_status_counts" => status_counts,
      "required_operator_action_counts" => required_action_counts,
      "duplicate_timeline_identity_scope_counts" => duplicate_scope_counts,
      "source_activity_id_counts" => source_activity_id_counts,
      "replacement_activity_id_counts" => replacement_activity_id_counts,
      "trust_boundary_status" => Map.get(diff_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(diff_summary, "trust_boundaries", []),
      "branch_local_timeline_diff_pressure" =>
        duplicate_identity_pressure or removed_count + changed_feedback_count > 0 or
          map_size(status_counts) > 0 or map_size(required_action_counts) > 0 or
          map_size(source_activity_id_counts) > 0 or map_size(replacement_activity_id_counts) > 0,
      "branch_local_duplicate_identity_pressure" => duplicate_identity_pressure,
      "branch_local_removed_activity_pressure" => removed_count > 0,
      "branch_local_changed_activity_pressure" => changed_feedback_count > 0,
      "branch_local_activity_routing_pressure" =>
        map_size(source_activity_id_counts) > 0 or map_size(replacement_activity_id_counts) > 0,
      "branch_local_operator_review_pressure" => map_size(required_action_counts) > 0,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_diff_replay_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_diff_replay_summary",
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
