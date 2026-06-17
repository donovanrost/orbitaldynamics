defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Rejection.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Candidate.Rejection
  alias __MODULE__.Detail

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("candidate_rejection_report", %{})
      |> Rejection.summary(
        "candidate_refresh.source_report_provenance.candidate_rejection_report",
        "candidate_rejection_source_report_provenance_only"
      )

    %{
      "source_report_candidate_rejection_branch_local_rejection_pressure" =>
        Map.get(summary, "branch_local_rejection_pressure"),
      "source_report_candidate_rejection_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_review_pressure"),
      "source_report_candidate_rejection_branch_local_invalid_input_pressure" =>
        Map.get(summary, "branch_local_invalid_input_pressure")
    }
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(source_report_detail_fields(source_reports))
  end

  def source_report_detail_fields(source_reports) do
    Detail.fields(source_reports)
  end
end
