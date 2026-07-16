defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.RouteValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.PressureRows

  def by_key(report, key_fun, ids_fun, fallback_field, route_fun)
      when is_function(key_fun, 1) and is_function(ids_fun, 1) and is_function(route_fun, 5) do
    route_fun.(
      report,
      &PressureRows.normalized_projected_resource_rows/1,
      key_fun,
      ids_fun,
      fallback_field
    )
  end
end
