defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.RowCountFields
  alias __MODULE__.RowValues

  def fields(reports) do
    CountFields.fields(reports)
    |> Map.merge(RowCountFields.fields(reports))
  end

  def row_trust_boundaries(reports) do
    RowValues.trust_boundaries(reports)
  end
end
