defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.ReasonValues

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(ReasonValues.fields(reports))
  end
end
