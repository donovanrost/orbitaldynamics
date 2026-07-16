defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.CandidateCommandReports do
  @moduledoc false

  alias __MODULE__.Definitions
  alias __MODULE__.ReportSources
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary

  def build(refresh) do
    Summary.from_definitions(refresh, Definitions.definitions())
  end

  def source?(source), do: ReportSources.source?(source)

  def reports(refresh, :source_candidate_diff_reports) do
    ReportSources.reports(refresh, :source_candidate_diff_reports)
  end

  def reports(refresh, :source_candidate_rejection_reports) do
    ReportSources.reports(refresh, :source_candidate_rejection_reports)
  end

  def reports(refresh, :source_command_window_reports) do
    ReportSources.reports(refresh, :source_command_window_reports)
  end

  def reports(refresh, :source_maneuver_review_reports) do
    ReportSources.reports(refresh, :source_maneuver_review_reports)
  end
end
