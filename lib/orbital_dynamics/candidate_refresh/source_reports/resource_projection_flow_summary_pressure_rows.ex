defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryPressureRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryProjectedResourceValues,
    as: ProjectedResourceValues

  def pressure_row(row, flow_rows) do
    activity_id = row["first_resource_pressure_activity_id"]

    Enum.find(flow_rows, fn flow_row ->
      (activity_id not in [nil, ""] and flow_row["activity_id"] == activity_id) or
        positive_number_value?(flow_row["downlink_shortfall_mb"])
    end)
  end

  def station_id(flow_row) do
    ProjectedResourceValues.stable_id_or_nil(
      flow_row["ground_station_id"] ||
        flow_row["station_id"] ||
        ProjectedResourceValues.nested_entity_id(flow_row, "source_window", [
          "ground_station_id",
          "station_id",
          "id"
        ])
    )
  end

  defp positive_number_value?(value), do: ProjectedResourceValues.positive_number_value?(value)
end
