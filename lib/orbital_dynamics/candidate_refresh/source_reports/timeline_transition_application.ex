defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplication do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationEntries

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationTimelineDiffReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportReports

  def entries(path, value) do
    TimelineTransitionApplicationEntries.entries(path, value)
  end

  def operator_review_entries(path, value) do
    TimelineTransitionApplicationReviewImportReports.operator_review_entries(path, value)
  end

  def cadence_import_entries(path, value) do
    TimelineTransitionApplicationReviewImportReports.cadence_import_entries(path, value)
  end

  def timeline_diff_entries(path, values, row_builder) when is_list(values) do
    TimelineTransitionApplicationTimelineDiffReports.entries(path, values, row_builder)
  end

  def timeline_diff_entries(path, %{} = value, row_builder) do
    TimelineTransitionApplicationTimelineDiffReports.entries(path, value, row_builder)
  end

  def timeline_diff_entries(path, value, row_builder) do
    TimelineTransitionApplicationTimelineDiffReports.entries(path, value, row_builder)
  end

  def report?(%{} = report) do
    TimelineTransitionApplicationReports.report?(report)
  end

  def report?(_report), do: false
end
