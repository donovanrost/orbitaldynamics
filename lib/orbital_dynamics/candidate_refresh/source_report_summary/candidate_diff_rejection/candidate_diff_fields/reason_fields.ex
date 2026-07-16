defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.ReasonFields do
  @moduledoc false

  alias __MODULE__.ReasonCounts

  def fields(rows) do
    ReasonCounts.fields(rows)
  end

  def merge(reports, rows_fun) do
    ReasonCounts.merge(reports, rows_fun)
  end
end
