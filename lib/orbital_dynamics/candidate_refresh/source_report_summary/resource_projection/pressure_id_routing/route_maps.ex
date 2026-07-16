defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps do
  @moduledoc false

  alias __MODULE__.ActivityRoutes
  alias __MODULE__.RowRoutes

  def activity_ids_by_status(report, source_activity_ids_fun, fallback_field)
      when is_function(source_activity_ids_fun, 1) do
    ActivityRoutes.by_status(report, source_activity_ids_fun, fallback_field)
  end

  def activity_ids_by_type(report, source_activity_ids_fun, fallback_field)
      when is_function(source_activity_ids_fun, 1) do
    ActivityRoutes.by_type(report, source_activity_ids_fun, fallback_field)
  end

  def activity_ids_by_key(report, key_fun, source_activity_ids_fun, fallback_field)
      when is_function(key_fun, 1) and is_function(source_activity_ids_fun, 1) do
    ActivityRoutes.by_key(report, key_fun, source_activity_ids_fun, fallback_field)
  end

  def row_ids_by_status(report, ids_fun, fallback_field) when is_function(ids_fun, 1) do
    RowRoutes.by_status(report, ids_fun, fallback_field)
  end

  def row_ids_by_type(report, ids_fun, fallback_field) when is_function(ids_fun, 1) do
    RowRoutes.by_type(report, ids_fun, fallback_field)
  end
end
