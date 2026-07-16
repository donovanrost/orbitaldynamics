defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEmbeddedSummaries

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEmbeddedSource

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportRowSummary

  def summary_from_review_or_import_row(%{} = row, summary?) do
    embedded = TimelineActivityPreconditionReviewImportEmbeddedSource.summary(row)

    row
    |> TimelineActivityPreconditionReviewImportRowSummary.from_row(embedded)
    |> case do
      summary when is_map(summary) ->
        if summary?.(summary), do: summary

      _summary ->
        nil
    end
  end

  def summary_from_embedded_rows(path, source, rows, artifact) do
    TimelineActivityPreconditionReviewImportEmbeddedSummaries.summary_from_embedded_rows(
      path,
      source,
      rows,
      artifact
    )
  end

  def stringify_keys(value),
    do: TimelineActivityPreconditionReviewImportEncoding.stringify_keys(value)
end
