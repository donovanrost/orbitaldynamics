defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions.ReportFunctions.ReportCalls do
  @moduledoc false

  def source(field, route_fun, source_activity_ids_fun) when is_function(route_fun, 3) do
    fn report -> route_fun.(report, source_activity_ids_fun, field) end
  end

  def key(field, route_fun, key_fun, source_activity_ids_fun)
      when is_function(route_fun, 4) do
    fn report -> route_fun.(report, key_fun, source_activity_ids_fun, field) end
  end
end
