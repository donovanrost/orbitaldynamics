defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields do
  @moduledoc false

  alias __MODULE__.RouteValues
  alias __MODULE__.RouteSpecs

  def fields(reports) do
    Map.new(RouteSpecs.values(), fn {field, route, row_ids_fun} ->
      {field, RouteValues.pressure_ids(reports, route, row_ids_fun, field)}
    end)
  end
end
