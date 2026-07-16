defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.Freshness do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.Common

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields.Freshness,
    as: SourceReportFields

  def from_refresh(
        refresh_or_artifact,
        source_report_summary
      )
      when is_function(source_report_summary, 1) do
    branch_freshness_summary = source_report_summary_branch_family(refresh_or_artifact)

    freshness_summary =
      branch_freshness_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "freshness_report"]) ||
        %{}

    {summary_source, replay_scope} = replay_context(branch_freshness_summary)

    summary(freshness_summary, summary_source, replay_scope)
  end

  def source_report_fields(
        refresh_or_artifact,
        source_reports
      ) do
    branch_freshness_summary = source_report_summary_branch_family(refresh_or_artifact)

    freshness_summary =
      branch_freshness_summary || Map.get(source_reports, "freshness_report", %{})

    {summary_source, replay_scope} = replay_context(branch_freshness_summary)

    summary = summary(freshness_summary, summary_source, replay_scope)

    %{
      "source_report_freshness_branch_local_stale_pressure" =>
        Map.get(summary, "branch_local_stale_pressure"),
      "source_report_freshness_branch_local_unknown_pressure" =>
        Map.get(summary, "branch_local_unknown_pressure"),
      "source_report_freshness_branch_local_freshness_pressure" =>
        Map.get(summary, "branch_local_freshness_pressure")
    }
    |> Map.merge(SourceReportFields.fields(source_reports))
  end

  def summary(freshness_summary, summary_source, replay_scope) do
    status_counts = Map.get(freshness_summary, "status_counts", %{})
    stale_reason_count = Common.summary_integer(freshness_summary, "stale_reason_count")
    unknown_reason_count = Common.summary_integer(freshness_summary, "unknown_reason_count")
    stale_reasons = Map.get(freshness_summary, "stale_reasons", [])
    unknown_reasons = Map.get(freshness_summary, "unknown_reasons", [])
    stale_reason_counts = Map.get(freshness_summary, "stale_reason_counts", %{})
    unknown_reason_counts = Map.get(freshness_summary, "unknown_reason_counts", %{})

    stale_status_count = Common.summary_integer(status_counts, "stale")
    unknown_status_count = Common.summary_integer(status_counts, "unknown")

    stale_pressure =
      stale_status_count + stale_reason_count > 0 or stale_reasons != [] or
        map_size(stale_reason_counts) > 0

    unknown_pressure =
      unknown_status_count + unknown_reason_count > 0 or unknown_reasons != [] or
        map_size(unknown_reason_counts) > 0

    %{
      "model" => "artifact_only_candidate_refresh_freshness_replay_summary",
      "source" => summary_source,
      "contract" =>
        Common.source_report_summary_contract(freshness_summary, "freshness_report.v1"),
      "source_report_count" => Common.summary_integer(freshness_summary, "count"),
      "source_report_row_count" => Common.summary_integer(freshness_summary, "row_count"),
      "source_report_paths" => Map.get(freshness_summary, "paths", []),
      "status_counts" => status_counts,
      "stale_reason_count" => stale_reason_count,
      "stale_reasons" => stale_reasons,
      "stale_reason_counts" => stale_reason_counts,
      "unknown_reason_count" => unknown_reason_count,
      "unknown_reasons" => unknown_reasons,
      "unknown_reason_counts" => unknown_reason_counts,
      "trust_boundary_status" => Map.get(freshness_summary, "trust_boundary_status"),
      "trust_boundaries" => Map.get(freshness_summary, "trust_boundaries", []),
      "branch_local_stale_pressure" => stale_pressure,
      "branch_local_unknown_pressure" => unknown_pressure,
      "branch_local_freshness_pressure" => stale_pressure or unknown_pressure,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => replay_scope,
        "operator_authority" => "not_granted_by_freshness_replay_summary",
        "import_approval" => "not_granted_by_freshness_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }
    |> Common.compact_map()
  end

  defp replay_context(branch_freshness_summary) do
    if branch_freshness_summary do
      {
        "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.freshness_report",
        "freshness_candidate_source_report_summary_only"
      }
    else
      {
        "candidate_refresh.source_report_provenance.freshness_report",
        "freshness_source_report_provenance_only"
      }
    end
  end

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "freshness_report",
      &InputProvenance.build/1
    )
  end
end
