defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions.ReportFunctions.RouteFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting

  def by_status, do: &PressureIdRouting.activity_ids_by_status/3

  def by_type, do: &PressureIdRouting.activity_ids_by_type/3

  def by_key, do: &PressureIdRouting.activity_ids_by_key/4
end
