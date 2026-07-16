defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.RowRoutes do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.KeyFunctions

  alias __MODULE__.RouteValues

  def by_status(report, ids_fun, fallback_field) when is_function(ids_fun, 1) do
    by_key(report, KeyFunctions.pressure_status(), ids_fun, fallback_field)
  end

  def by_type(report, ids_fun, fallback_field) when is_function(ids_fun, 1) do
    by_key(report, KeyFunctions.pressure_types(), ids_fun, fallback_field)
  end

  def by_key(report, key_fun, ids_fun, fallback_field)
      when is_function(key_fun, 1) and is_function(ids_fun, 1) do
    RouteValues.by_key(report, key_fun, ids_fun, fallback_field)
  end
end
