defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Diff.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Diff
  alias __MODULE__.Detail

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("candidate_diff_report", %{})
      |> Diff.summary(
        "candidate_refresh.source_report_provenance.candidate_diff_report",
        "candidate_diff_source_report_provenance_only"
      )

    %{
      "source_report_candidate_diff_branch_local_diff_pressure" =>
        Map.get(summary, "branch_local_diff_pressure"),
      "source_report_candidate_diff_branch_local_new_candidate_pressure" =>
        Map.get(summary, "branch_local_new_candidate_pressure"),
      "source_report_candidate_diff_branch_local_invalidated_candidate_pressure" =>
        Map.get(summary, "branch_local_invalidated_candidate_pressure"),
      "source_report_candidate_diff_branch_local_semantic_change_pressure" =>
        Map.get(summary, "branch_local_semantic_change_pressure")
    }
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(Detail.fields(source_reports))
  end
end
