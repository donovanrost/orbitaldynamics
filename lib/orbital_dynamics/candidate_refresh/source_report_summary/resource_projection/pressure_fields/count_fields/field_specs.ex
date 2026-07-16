defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps

  def values do
    [
      {"resource_pressure_status_counts", &CountMaps.status_counts/1},
      {"ground_station_counts", &CountMaps.ground_station_counts/1},
      {"resource_projection_spacecraft_counts", &CountMaps.spacecraft_counts/1},
      {"resource_pressure_type_counts", &CountMaps.type_counts/1},
      {"resource_pressure_activity_id_counts", &CountMaps.activity_id_counts/1}
    ]
  end
end
