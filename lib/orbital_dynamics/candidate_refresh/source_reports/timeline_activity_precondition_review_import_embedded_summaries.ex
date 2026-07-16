defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEmbeddedSummaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaryFields

  def summary_from_embedded_rows(_path, _source, [], _artifact), do: nil

  def summary_from_embedded_rows(path, source, rows, artifact) do
    {path, TimelineActivityPreconditionReviewImportSummaryFields.summary(source, rows, artifact)}
  end
end
