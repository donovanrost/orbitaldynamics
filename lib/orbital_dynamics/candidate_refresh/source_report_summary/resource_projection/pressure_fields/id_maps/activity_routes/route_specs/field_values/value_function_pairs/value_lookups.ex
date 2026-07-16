defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctionPairs.ValueLookups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions

  def by_status(field, source_activity_ids_fun) do
    ValueFunctions.by_status(field, source_activity_ids_fun)
  end

  def by_type(field, source_activity_ids_fun) do
    ValueFunctions.by_type(field, source_activity_ids_fun)
  end

  def by_key(field, key_fun, source_activity_ids_fun) do
    ValueFunctions.by_key(field, key_fun, source_activity_ids_fun)
  end
end
