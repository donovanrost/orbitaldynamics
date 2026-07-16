defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.SpecValues.KeySpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities

  def values do
    [
      {"resource_pressure_activity_ids_by_ground_station", :key, &RowIdentities.station_id/1,
       &RowIdentities.source_activity_ids/1},
      {"resource_pressure_activity_ids_by_spacecraft", :key, &RowIdentities.spacecraft_id/1,
       &RowIdentities.source_activity_ids/1}
    ]
  end
end
