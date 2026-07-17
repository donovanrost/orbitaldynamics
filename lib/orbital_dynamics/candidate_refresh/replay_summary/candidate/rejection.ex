defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Rejection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  def replay(refresh_or_artifact) do
    branch_rejection_summary = source_report_summary_branch_family(refresh_or_artifact)

    rejection_summary =
      branch_rejection_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "candidate_rejection_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_rejection_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_rejection_report",
          "candidate_rejection_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.candidate_rejection_report",
          "candidate_rejection_source_report_provenance_only"
        }
      end

    summary(rejection_summary, summary_source, replay_scope)
  end

  def summary(rejection_summary, summary_source, replay_scope) do
    rejected_count = summary_integer(rejection_summary, "rejected_count")
    reviewable_count = summary_integer(rejection_summary, "reviewable_count")

    invalid_candidate_input_count =
      summary_integer(rejection_summary, "invalid_candidate_input_count")

    rejection_reason_counts = Map.get(rejection_summary, "rejection_reason_counts", %{})
    required_action_counts = Map.get(rejection_summary, "required_operator_action_counts", %{})

    candidate_id_counts =
      Map.get(rejection_summary, "candidate_rejection_candidate_id_counts", %{})

    ground_station_counts =
      Map.get(rejection_summary, "candidate_rejection_ground_station_counts", %{})

    rejection_pressure =
      rejected_count + reviewable_count + invalid_candidate_input_count > 0 or
        map_size(rejection_reason_counts) > 0 or map_size(required_action_counts) > 0 or
        map_size(candidate_id_counts) > 0 or map_size(ground_station_counts) > 0

    review_pressure = reviewable_count > 0 or map_size(required_action_counts) > 0

    invalid_input_pressure =
      invalid_candidate_input_count > 0 or
        summary_integer(rejection_reason_counts, "invalid_candidate_input") > 0

    %{
      "model" => "artifact_only_candidate_refresh_candidate_rejection_replay_summary",
      "source" => summary_source,
      "contract" =>
        source_report_summary_contract(rejection_summary, "candidate_rejection_report.v1"),
      "source_report_count" => summary_integer(rejection_summary, "count"),
      "source_report_row_count" => summary_integer(rejection_summary, "row_count"),
      "source_report_paths" => Map.get(rejection_summary, "paths", []),
      "rejected_count" => rejected_count,
      "reviewable_count" => reviewable_count,
      "invalid_candidate_input_count" => invalid_candidate_input_count,
      "rejection_reason_counts" => rejection_reason_counts,
      "required_operator_action_counts" => required_action_counts,
      "candidate_rejection_candidate_id_counts" => candidate_id_counts,
      "candidate_rejection_ground_station_counts" => ground_station_counts,
      "trust_boundary_status" => Map.get(rejection_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(rejection_summary, "trust_boundaries", []),
      "branch_local_rejection_pressure" => rejection_pressure,
      "branch_local_review_pressure" => review_pressure,
      "branch_local_invalid_input_pressure" => invalid_input_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_candidate_rejection_replay_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_candidate_rejection_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "candidate_rejection_report",
      &InputProvenance.build/1
    )
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
