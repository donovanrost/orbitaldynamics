defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields do
  @moduledoc false

  alias __MODULE__.{ImportReadiness, OperatorTraining, SchemaValidation}

  def fields(reports) do
    reports
    |> ImportReadiness.fields()
    |> Map.merge(OperatorTraining.fields(reports))
    |> Map.merge(SchemaValidation.fields(reports))
  end
end
