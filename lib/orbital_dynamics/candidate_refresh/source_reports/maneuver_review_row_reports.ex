defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewRowReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewEmbeddedRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewReportRows

  def row_from_review_or_import_row(%{} = row) do
    ManeuverReviewEmbeddedRows.row_from_review_or_import_row(row)
  end

  def from_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_rows(
      path,
      source,
      rows,
      artifact,
      &ManeuverReviewReportRows.from_rows/4
    )
  end
end
