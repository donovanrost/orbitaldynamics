defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryProjectedResources do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryProjectedResourceValues,
    as: ProjectedResourceValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryPressureRows,
    as: PressureRows

  def enrich(projected_resources, flow_rows)
      when is_list(projected_resources) and is_list(flow_rows) do
    flow_rows = Enum.map(flow_rows, &ProjectedResourceValues.stringify_keys/1)

    Enum.map(projected_resources, fn row ->
      row = ProjectedResourceValues.stringify_keys(row)

      case PressureRows.pressure_row(row, flow_rows) do
        nil ->
          row

        %{} = flow_row ->
          row
          |> Map.put_new(
            "first_resource_pressure_ground_station_id",
            PressureRows.station_id(flow_row)
          )
          |> Map.put_new("source_window_id", flow_row["source_window_id"])
          |> Map.put_new("source_window_type", flow_row["source_window_type"])
          |> Map.put_new("source_window", flow_row["source_window"])
          |> compact_map()
      end
    end)
  end

  def enrich(projected_resources, _flow_rows), do: projected_resources
end
