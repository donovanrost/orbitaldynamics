defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting do
  @moduledoc false

  alias __MODULE__.{PressureRows, RouteMaps}

  def activity_ids_by_status(report, source_activity_ids_fun, fallback_field)
      when is_function(source_activity_ids_fun, 1) do
    RouteMaps.activity_ids_by_status(report, source_activity_ids_fun, fallback_field)
  end

  def activity_ids_by_type(report, source_activity_ids_fun, fallback_field)
      when is_function(source_activity_ids_fun, 1) do
    RouteMaps.activity_ids_by_type(report, source_activity_ids_fun, fallback_field)
  end

  def activity_ids_by_key(report, key_fun, source_activity_ids_fun, fallback_field)
      when is_function(key_fun, 1) and is_function(source_activity_ids_fun, 1) do
    RouteMaps.activity_ids_by_key(report, key_fun, source_activity_ids_fun, fallback_field)
  end

  def row_ids_by_status(report, ids_fun, fallback_field) when is_function(ids_fun, 1) do
    RouteMaps.row_ids_by_status(report, ids_fun, fallback_field)
  end

  def row_ids_by_type(report, ids_fun, fallback_field) when is_function(ids_fun, 1) do
    RouteMaps.row_ids_by_type(report, ids_fun, fallback_field)
  end

  defdelegate normalized_projected_resource_rows(report), to: PressureRows
  defdelegate pressure_types(row), to: PressureRows
end
