defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes do
  @moduledoc false

  alias __MODULE__.MergedValues
  alias __MODULE__.RouteSpecs

  def fields(reports) do
    RouteSpecs.specs()
    |> Map.new(fn route_spec ->
      {field, values_fun} = RouteSpecs.field(route_spec)
      {field, MergedValues.from_reports(reports, values_fun)}
    end)
  end
end
