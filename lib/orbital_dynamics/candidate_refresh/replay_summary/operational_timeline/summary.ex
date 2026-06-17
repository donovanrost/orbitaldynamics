defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalTimeline.Summary do
  @moduledoc false

  def summary(timeline_summary, summary_source, replay_scope) do
    contact_count = summary_integer(timeline_summary, "contact_feedback_count")
    command_count = summary_integer(timeline_summary, "command_feedback_count")
    maneuver_count = summary_integer(timeline_summary, "maneuver_feedback_count")
    observation_count = summary_integer(timeline_summary, "observation_feedback_count")

    station_throughput_count =
      summary_integer(timeline_summary, "station_throughput_feedback_count")

    integrity_count = summary_integer(timeline_summary, "timeline_integrity_issue_count")
    dependency_count = summary_integer(timeline_summary, "dependency_integrity_issue_count")
    exclusivity_count = summary_integer(timeline_summary, "exclusivity_integrity_issue_count")

    operational_kind_counts = Map.get(timeline_summary, "operational_kind_counts", %{})
    activity_status_counts = Map.get(timeline_summary, "activity_status_counts", %{})
    approval_status_counts = Map.get(timeline_summary, "approval_status_counts", %{})

    required_action_counts =
      Map.get(timeline_summary, "required_operator_action_counts", %{})

    cadence_import_status_counts =
      Map.get(timeline_summary, "cadence_import_status_counts", %{})

    integrity_issue_type_counts =
      Map.get(timeline_summary, "timeline_integrity_issue_type_counts", %{})

    reservation_count =
      summary_integer(timeline_summary, "station_reservation_evidence_row_count")

    reservation_expiration_count =
      summary_integer(timeline_summary, "station_reservation_expiration_evidence_row_count")

    input_keys = Map.get(timeline_summary, "input_keys", [])
    feedback_count = contact_count + command_count + maneuver_count + observation_count
    integrity_pressure_count = integrity_count + dependency_count + exclusivity_count

    activity_id_counts = Map.get(timeline_summary, "activity_id_counts", %{})

    timeline_review_pressure =
      map_size(operational_kind_counts) > 0 or map_size(activity_status_counts) > 0 or
        map_size(approval_status_counts) > 0 or map_size(required_action_counts) > 0 or
        map_size(cadence_import_status_counts) > 0 or map_size(integrity_issue_type_counts) > 0

    %{
      "model" => "artifact_only_candidate_refresh_operational_timeline_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(timeline_summary, "operational_timeline_report.v1"),
      "source_report_count" => summary_integer(timeline_summary, "count"),
      "source_report_row_count" => summary_integer(timeline_summary, "row_count"),
      "source_report_paths" => Map.get(timeline_summary, "paths", []),
      "contact_feedback_count" => contact_count,
      "command_feedback_count" => command_count,
      "maneuver_feedback_count" => maneuver_count,
      "observation_feedback_count" => observation_count,
      "station_throughput_feedback_count" => station_throughput_count,
      "operational_kind_counts" => operational_kind_counts,
      "activity_id_counts" => activity_id_counts,
      "activity_status_counts" => activity_status_counts,
      "approval_status_counts" => approval_status_counts,
      "required_operator_action_counts" => required_action_counts,
      "cadence_import_status_counts" => cadence_import_status_counts,
      "timeline_integrity_issue_count" => integrity_count,
      "dependency_integrity_issue_count" => dependency_count,
      "exclusivity_integrity_issue_count" => exclusivity_count,
      "timeline_integrity_issue_type_counts" => integrity_issue_type_counts,
      "station_reservation_evidence_row_count" => reservation_count,
      "station_reservation_expiration_evidence_row_count" => reservation_expiration_count,
      "input_keys" => input_keys,
      "trust_boundary_status" => Map.get(timeline_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(timeline_summary, "trust_boundaries", []),
      "branch_local_operational_timeline_pressure" =>
        feedback_count + station_throughput_count + integrity_pressure_count > 0 or
          input_keys != [] or map_size(activity_id_counts) > 0 or
          reservation_count + reservation_expiration_count > 0 or timeline_review_pressure,
      "branch_local_feedback_pressure" => feedback_count + station_throughput_count > 0,
      "branch_local_activity_routing_pressure" => map_size(activity_id_counts) > 0,
      "branch_local_integrity_pressure" => integrity_pressure_count > 0,
      "branch_local_station_reservation_pressure" =>
        reservation_count + reservation_expiration_count > 0,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_operational_timeline_replay_summary",
        "operational_feedback_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_operational_timeline_replay_summary",
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
        case Integer.parse(value) do
          {parsed, ""} -> parsed
          _other -> 0
        end

      _other ->
        0
    end
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
