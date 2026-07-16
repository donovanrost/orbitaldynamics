defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteValues.ReportFunctions.RouteMerges do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteValues.MergedValues

  def from_reports(reports, route_fun, row_ids_fun, field) when is_function(route_fun, 3) do
    MergedValues.from_reports(reports, &route_fun.(&1, row_ids_fun, field))
  end
end
