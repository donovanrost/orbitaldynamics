defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldDispatch do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues

  def from_spec({field, :status, source_activity_ids_fun}) do
    FieldValues.by_status(field, source_activity_ids_fun)
  end

  def from_spec({field, :type, source_activity_ids_fun}) do
    FieldValues.by_type(field, source_activity_ids_fun)
  end

  def from_spec({field, :key, key_fun, source_activity_ids_fun}) do
    FieldValues.by_key(field, key_fun, source_activity_ids_fun)
  end
end
