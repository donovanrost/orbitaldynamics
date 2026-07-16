defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.TimelinePublication do
  @moduledoc false

  alias __MODULE__.{DependencyImpactFields, PublicationFields, TimelineDiffFields}

  def fields(reports) do
    reports
    |> PublicationFields.fields()
    |> Map.merge(DependencyImpactFields.fields(reports))
    |> Map.merge(TimelineDiffFields.fields(reports))
  end
end
