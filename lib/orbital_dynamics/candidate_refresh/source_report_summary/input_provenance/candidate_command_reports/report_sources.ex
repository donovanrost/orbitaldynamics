defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.CandidateCommandReports.ReportSources do
  @moduledoc false

  alias __MODULE__.CollectionFunctions
  alias __MODULE__.InheritedReports

  def source?(source), do: CollectionFunctions.source?(source)

  def reports(refresh, :source_candidate_diff_reports) do
    inherited_reports(refresh, :source_candidate_diff_reports)
  end

  def reports(refresh, :source_candidate_rejection_reports) do
    inherited_reports(refresh, :source_candidate_rejection_reports)
  end

  def reports(refresh, :source_command_window_reports) do
    inherited_reports(refresh, :source_command_window_reports)
  end

  def reports(refresh, :source_maneuver_review_reports) do
    inherited_reports(refresh, :source_maneuver_review_reports)
  end

  defp inherited_reports(refresh, source) do
    InheritedReports.reports(refresh, CollectionFunctions.function_for(source))
  end
end
