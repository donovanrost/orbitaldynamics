defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ValidationSafetyCase do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_safety_case_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "validation_safety_case_summary")

    safety_case_summary =
      branch_safety_case_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "validation_safety_case_summary"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_safety_case_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.validation_safety_case_summary",
          "validation_safety_case_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.validation_safety_case_summary",
          "validation_safety_case_source_report_provenance_only"
        }
      end

    summary(safety_case_summary, summary_source, replay_scope)
  end

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    SourceReportFields.source_report_fields(refresh_or_artifact, source_reports, callbacks)
  end

  def pressure_fields(safety_case_summary) do
    Summary.pressure_fields(safety_case_summary)
  end

  def summary(safety_case_summary, summary_source, replay_scope) do
    Summary.summary(safety_case_summary, summary_source, replay_scope)
  end
end
