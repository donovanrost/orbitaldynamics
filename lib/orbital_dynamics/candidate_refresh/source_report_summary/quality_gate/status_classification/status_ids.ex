defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds do
  @moduledoc false

  alias __MODULE__.{IdMaps, NonPassed, StatusFields}

  def fields(reports) do
    IdMaps.fields(reports)
    |> Map.merge(StatusFields.fields(reports))
    |> Map.merge(NonPassed.fields(reports))
  end
end
