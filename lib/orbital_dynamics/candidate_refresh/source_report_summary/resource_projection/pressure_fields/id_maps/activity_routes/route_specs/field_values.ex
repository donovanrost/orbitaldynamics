defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues do
  @moduledoc false

  alias __MODULE__.ValueFunctionPairs

  def by_status(field, source_activity_ids_fun) do
    ValueFunctionPairs.by_status(field, source_activity_ids_fun)
  end

  def by_type(field, source_activity_ids_fun) do
    ValueFunctionPairs.by_type(field, source_activity_ids_fun)
  end

  def by_key(field, key_fun, source_activity_ids_fun) do
    ValueFunctionPairs.by_key(field, key_fun, source_activity_ids_fun)
  end
end
