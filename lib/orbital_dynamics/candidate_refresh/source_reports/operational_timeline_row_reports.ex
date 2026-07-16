defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineRowReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineEmbeddedRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReportRows

  def row_from_review_or_import_row(%{} = row) do
    OperationalTimelineEmbeddedRows.row_from_review_or_import_row(row)
  end

  def from_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_rows(
      path,
      source,
      rows,
      artifact,
      &OperationalTimelineReportRows.from_rows/4
    )
  end
end
