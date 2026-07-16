defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctions do
  @moduledoc false

  alias __MODULE__.ReportFunctions

  def by_status(field, source_activity_ids_fun),
    do: ReportFunctions.by_status(field, source_activity_ids_fun)

  def by_type(field, source_activity_ids_fun),
    do: ReportFunctions.by_type(field, source_activity_ids_fun)

  def by_key(field, key_fun, source_activity_ids_fun),
    do: ReportFunctions.by_key(field, key_fun, source_activity_ids_fun)
end
