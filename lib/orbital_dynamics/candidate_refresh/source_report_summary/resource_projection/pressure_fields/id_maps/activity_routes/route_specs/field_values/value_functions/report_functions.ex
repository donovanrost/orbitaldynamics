defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions.ReportFunctions do
  @moduledoc false

  alias __MODULE__.ReportCalls
  alias __MODULE__.RouteFunctions

  def by_status(field, source_activity_ids_fun) do
    ReportCalls.source(field, RouteFunctions.by_status(), source_activity_ids_fun)
  end

  def by_type(field, source_activity_ids_fun) do
    ReportCalls.source(field, RouteFunctions.by_type(), source_activity_ids_fun)
  end

  def by_key(field, key_fun, source_activity_ids_fun) do
    ReportCalls.key(field, RouteFunctions.by_key(), key_fun, source_activity_ids_fun)
  end
end
