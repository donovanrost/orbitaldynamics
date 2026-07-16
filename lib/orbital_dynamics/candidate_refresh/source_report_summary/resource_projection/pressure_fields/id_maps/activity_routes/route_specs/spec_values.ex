defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.SpecValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities
  alias __MODULE__.KeySpecs

  def values do
    [
      {"resource_pressure_activity_ids_by_status", :status, &RowIdentities.source_activity_ids/1},
      {"resource_pressure_activity_ids_by_type", :type, &RowIdentities.source_activity_ids/1}
    ] ++ KeySpecs.values()
  end
end
