defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterRowReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterEmbeddedRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  def from_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_rows(
      path,
      source,
      rows,
      artifact,
      &ContactFilterReportRows.from_rows/4
    )
  end

  def row_from_review_or_import_row(%{} = row) do
    ContactFilterEmbeddedRows.row_from_review_or_import_row(row)
  end
end
