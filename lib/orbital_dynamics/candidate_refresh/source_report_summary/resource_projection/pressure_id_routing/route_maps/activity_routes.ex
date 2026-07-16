defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.ActivityRoutes do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.KeyFunctions

  alias __MODULE__.RouteValues

  def by_status(report, source_activity_ids_fun, fallback_field)
      when is_function(source_activity_ids_fun, 1) do
    by_key(report, KeyFunctions.pressure_status(), source_activity_ids_fun, fallback_field)
  end

  def by_type(report, source_activity_ids_fun, fallback_field)
      when is_function(source_activity_ids_fun, 1) do
    by_key(report, KeyFunctions.pressure_types(), source_activity_ids_fun, fallback_field)
  end

  def by_key(report, key_fun, source_activity_ids_fun, fallback_field)
      when is_function(key_fun, 1) and is_function(source_activity_ids_fun, 1) do
    RouteValues.by_key(report, key_fun, source_activity_ids_fun, fallback_field)
  end
end
