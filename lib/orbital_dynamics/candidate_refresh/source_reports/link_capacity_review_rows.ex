defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRowSource

  def row_from_review_or_import_row(%{} = row) do
    embedded = LinkCapacityReviewRowSource.embedded_source(row)

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("ground_station_id", row["ground_station_id"] || row["subject_id"])
    |> Map.put_new("required_downlink_mb", row["required_downlink_mb"])
    |> Map.put_new("selected_downlink_shortfall_mb", row["selected_downlink_shortfall_mb"])
    |> Map.put_new("actual_downlink_shortfall_mb", row["actual_downlink_shortfall_mb"])
    |> Map.put_new("downlink_requirement_status", row["downlink_requirement_status"])
    |> Map.put_new(
      "actual_downlink_requirement_status",
      row["actual_downlink_requirement_status"]
    )
    |> compact_map()
  end

  def row_from_review_or_import_row(_row), do: nil

  def normalized_source_report_token(value) do
    value
    |> LinkCapacityReviewRowSource.encode_value()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end

  def stringify_keys(value), do: LinkCapacityReviewRowSource.stringify_keys(value)
end
