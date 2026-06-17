defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineFeedback.Summary do
  @moduledoc false

  def summary(feedback_summary, summary_source, replay_scope) do
    input_keys = Map.get(feedback_summary, "input_keys", [])
    status_counts = Map.get(feedback_summary, "status_counts", %{})
    feedback_kind_counts = Map.get(feedback_summary, "feedback_kind_counts", %{})
    match_strategy_counts = Map.get(feedback_summary, "match_strategy_counts", %{})
    activity_id_counts = Map.get(feedback_summary, "activity_id_counts", %{})

    cadence_import_status_counts =
      Map.get(feedback_summary, "cadence_import_status_counts", %{})

    reservation_count =
      summary_integer(feedback_summary, "station_reservation_evidence_row_count")

    reservation_expiration_count =
      summary_integer(feedback_summary, "station_reservation_expiration_evidence_row_count")

    %{
      "model" => "artifact_only_candidate_refresh_timeline_feedback_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(feedback_summary, "timeline_feedback_report.v1"),
      "source_report_count" => summary_integer(feedback_summary, "count"),
      "source_report_row_count" => summary_integer(feedback_summary, "row_count"),
      "source_report_paths" => Map.get(feedback_summary, "paths", []),
      "input_keys" => input_keys,
      "status_counts" => status_counts,
      "feedback_kind_counts" => feedback_kind_counts,
      "match_strategy_counts" => match_strategy_counts,
      "activity_id_counts" => activity_id_counts,
      "cadence_import_status_counts" => cadence_import_status_counts,
      "station_reservation_evidence_row_count" => reservation_count,
      "station_reservation_expiration_evidence_row_count" => reservation_expiration_count,
      "trust_boundary_status" => Map.get(feedback_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(feedback_summary, "trust_boundaries", []),
      "branch_local_timeline_feedback_pressure" =>
        input_keys != [] or map_size(status_counts) > 0 or map_size(feedback_kind_counts) > 0 or
          map_size(match_strategy_counts) > 0 or map_size(activity_id_counts) > 0 or
          map_size(cadence_import_status_counts) > 0 or
          reservation_count + reservation_expiration_count > 0,
      "branch_local_feedback_input_pressure" => input_keys != [],
      "branch_local_activity_routing_pressure" => map_size(activity_id_counts) > 0,
      "branch_local_match_review_pressure" => map_size(match_strategy_counts) > 0,
      "branch_local_import_review_pressure" => map_size(cadence_import_status_counts) > 0,
      "branch_local_station_reservation_pressure" =>
        reservation_count + reservation_expiration_count > 0,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_timeline_feedback_replay_summary",
        "operational_feedback_application" => "not_performed_by_summary",
        "timeline_mutation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_timeline_feedback_replay_summary",
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
