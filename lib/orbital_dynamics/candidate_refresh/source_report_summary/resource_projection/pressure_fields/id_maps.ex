defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps do
  @moduledoc false

  alias __MODULE__.ActivityRoutes
  alias __MODULE__.RowFields

  def fields(reports) do
    ActivityRoutes.fields(reports)
    |> Map.merge(RowFields.fields(reports))
  end
end
