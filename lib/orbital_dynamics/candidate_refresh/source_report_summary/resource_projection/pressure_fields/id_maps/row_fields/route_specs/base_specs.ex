defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs.BaseSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities

  def values do
    [
      {"resource_pressure_ground_station_ids_by_type", :type,
       &RowIdentities.ground_station_ids/1},
      {"resource_pressure_source_window_ids_by_status", :status,
       &RowIdentities.source_window_ids/1},
      {"resource_pressure_source_window_ids_by_type", :type, &RowIdentities.source_window_ids/1}
    ]
  end
end
