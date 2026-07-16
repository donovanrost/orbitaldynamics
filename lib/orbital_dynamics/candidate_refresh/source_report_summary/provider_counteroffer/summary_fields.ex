defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields do
  @moduledoc false

  alias __MODULE__.ImportReadiness
  alias __MODULE__.PlanImpactFields
  alias __MODULE__.ReviewFields

  def fields(reports) do
    %{}
    |> Map.merge(ImportReadiness.fields(reports))
    |> Map.merge(PlanImpactFields.fields(reports))
    |> Map.merge(ReviewFields.fields(reports))
  end
end
