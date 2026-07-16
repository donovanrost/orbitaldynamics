defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewEmbeddedRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRowValues

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_resource_projection"]) ->
          row["source_resource_projection"]

        is_map(get_in(row, ["source_review_row", "source_resource_projection"])) ->
          get_in(row, ["source_review_row", "source_resource_projection"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = projection_row -> ResourceProjectionReviewRowValues.stringify_keys(projection_row)
        _projection_row -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("spacecraft_id", row["spacecraft_id"] || row["subject_id"])
    |> Map.put_new("resource_pressure_status", row["resource_pressure_status"])
    |> Map.put_new("resource_pressure_types", row["resource_pressure_types"])
    |> Map.put_new("projected_downlink_shortfall_mb", row["projected_downlink_shortfall_mb"])
    |> Map.put_new(
      "first_resource_pressure_ground_station_id",
      row["first_resource_pressure_ground_station_id"]
    )
    |> Map.put_new(
      "first_resource_pressure_activity_id",
      row["first_resource_pressure_activity_id"]
    )
    |> compact_map()
  end
end
