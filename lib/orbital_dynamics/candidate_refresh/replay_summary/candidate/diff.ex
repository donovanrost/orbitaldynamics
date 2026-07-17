defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Diff do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  def replay(refresh_or_artifact) do
    branch_diff_summary = source_report_summary_branch_family(refresh_or_artifact)

    diff_summary =
      branch_diff_summary ||
        refresh_or_artifact
        |> SourceReportSummary.build()
        |> get_in(["source_reports", "candidate_diff_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_diff_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.candidate_diff_report",
          "candidate_diff_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.candidate_diff_report",
          "candidate_diff_source_report_provenance_only"
        }
      end

    summary(diff_summary, summary_source, replay_scope)
  end

  def summary(diff_summary, summary_source, replay_scope) do
    retained_candidate_count = summary_integer(diff_summary, "retained_candidate_count")
    new_candidate_count = summary_integer(diff_summary, "new_candidate_count")
    invalidated_candidate_count = summary_integer(diff_summary, "invalidated_candidate_count")

    diff_reason_counts = Map.get(diff_summary, "diff_reason_counts", %{})
    invalidated_reason_counts = Map.get(diff_summary, "invalidated_reason_counts", %{})
    semantic_change_reason_counts = Map.get(diff_summary, "semantic_change_reason_counts", %{})

    changed_field_counts =
      Map.get(diff_summary, "candidate_diff_changed_field_counts", %{})

    candidate_id_counts = Map.get(diff_summary, "candidate_diff_candidate_id_counts", %{})
    ground_station_counts = Map.get(diff_summary, "candidate_diff_ground_station_counts", %{})

    diff_pressure =
      new_candidate_count + invalidated_candidate_count > 0 or
        map_size(diff_reason_counts) > 0 or map_size(invalidated_reason_counts) > 0 or
        map_size(semantic_change_reason_counts) > 0 or map_size(changed_field_counts) > 0 or
        map_size(candidate_id_counts) > 0 or map_size(ground_station_counts) > 0

    new_candidate_pressure =
      new_candidate_count > 0 or
        summary_integer(diff_reason_counts, "not_present_in_prior_candidate_set") > 0

    invalidated_candidate_pressure =
      invalidated_candidate_count > 0 or map_size(invalidated_reason_counts) > 0

    semantic_change_pressure =
      map_size(semantic_change_reason_counts) > 0 or map_size(changed_field_counts) > 0 or
        summary_integer(
          diff_reason_counts,
          "present_in_prior_candidate_set_with_semantic_changes"
        ) >
          0

    %{
      "model" => "artifact_only_candidate_refresh_candidate_diff_replay_summary",
      "source" => summary_source,
      "contract" => source_report_summary_contract(diff_summary, "candidate_diff_report.v1"),
      "source_report_count" => summary_integer(diff_summary, "count"),
      "source_report_row_count" => summary_integer(diff_summary, "row_count"),
      "source_report_paths" => Map.get(diff_summary, "paths", []),
      "retained_candidate_count" => retained_candidate_count,
      "new_candidate_count" => new_candidate_count,
      "invalidated_candidate_count" => invalidated_candidate_count,
      "diff_reason_counts" => diff_reason_counts,
      "invalidated_reason_counts" => invalidated_reason_counts,
      "semantic_change_reason_counts" => semantic_change_reason_counts,
      "candidate_diff_changed_field_counts" => changed_field_counts,
      "candidate_diff_candidate_id_counts" => candidate_id_counts,
      "candidate_diff_ground_station_counts" => ground_station_counts,
      "trust_boundary_status" => Map.get(diff_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(diff_summary, "trust_boundaries", []),
      "branch_local_diff_pressure" => diff_pressure,
      "branch_local_new_candidate_pressure" => new_candidate_pressure,
      "branch_local_invalidated_candidate_pressure" => invalidated_candidate_pressure,
      "branch_local_semantic_change_pressure" => semantic_change_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_candidate_diff_replay_summary",
        "candidate_selection" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> compact_map()
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "candidate_diff_report",
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
