defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.SchemaValidation do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.IdFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(IdFields.fields(reports))
    |> compact_map()
  end
end
