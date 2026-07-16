defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape do
  @moduledoc false

  alias __MODULE__.Applications
  alias __MODULE__.Counts
  alias __MODULE__.SourceContract
  alias __MODULE__.TrustBoundaries

  def source_row_count(report) do
    Counts.source_row_count(report, summary_source?(report))
  end

  def application_count(report) do
    Counts.application_count(report, summary_source?(report))
  end

  def summary_source?(%{} = report) do
    SourceContract.summary?(report)
  end

  def summary_source?(_report), do: false

  def count_matching_application(report, top_level_field, row_predicate) do
    Applications.count_matching(report, top_level_field, row_predicate)
  end

  def count_rows(rows, field) do
    Applications.count_rows(rows, field)
  end

  def application_rows(report) do
    Applications.rows(report)
  end

  def trust_boundary_status(reports) do
    TrustBoundaries.status(reports)
  end

  def trust_boundaries(reports) do
    TrustBoundaries.values(reports)
  end
end
