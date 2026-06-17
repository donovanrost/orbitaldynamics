defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_model_acceptance_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "model_acceptance_report")

    model_acceptance_summary =
      branch_model_acceptance_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "model_acceptance_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_model_acceptance_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.model_acceptance_report",
          "model_acceptance_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.model_acceptance_report",
          "model_acceptance_source_report_provenance_only"
        }
      end

    summary(model_acceptance_summary, summary_source, replay_scope)
  end

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_model_acceptance_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "model_acceptance_report")

    model_acceptance_summary =
      branch_model_acceptance_summary || Map.get(source_reports, "model_acceptance_report", %{})

    pressure_fields = pressure_fields(model_acceptance_summary)

    SourceReportFields.source_report_fields(source_reports, pressure_fields)
  end

  def pressure_fields(model_acceptance_summary) do
    Summary.pressure_fields(model_acceptance_summary)
  end

  def summary(model_acceptance_summary, summary_source, replay_scope) do
    Summary.summary(model_acceptance_summary, summary_source, replay_scope)
  end
end
