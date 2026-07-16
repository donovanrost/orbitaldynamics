defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.EvidenceFields

  def fields(reports) do
    reports
    |> EvidenceFields.fields()
    |> Map.merge(CountFields.fields(reports))
  end
end
