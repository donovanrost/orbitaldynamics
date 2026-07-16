defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.RowRoutes.RouteValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.RouteValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RoutePairs

  def by_key(report, key_fun, ids_fun, fallback_field)
      when is_function(key_fun, 1) and is_function(ids_fun, 1) do
    RouteValues.by_key(
      report,
      key_fun,
      ids_fun,
      fallback_field,
      &RoutePairs.row_ids/5
    )
  end
end
