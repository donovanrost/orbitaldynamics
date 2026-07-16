defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.IdMaps
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting

  def fields(reports) do
    IdMaps.fields(reports)
    |> Map.merge(CountFields.fields(reports))
    |> Map.merge(DirectionRouting.fields(reports))
  end
end
