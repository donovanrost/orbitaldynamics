defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewRowValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewRowReports

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "station_calendar_review"))
      |> Enum.map(&StationCalendarReviewRowValues.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    StationCalendarReviewRowReports.from_rows(
      "#{path}.rows.source_station_calendar_review",
      "operator_review_package.rows.source_station_calendar_review",
      rows,
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    rows =
      manifest
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(fn row ->
        row["source_review_type"] == "station_calendar_review" or
          row["import_action"] == "review_station_calendar"
      end)
      |> Enum.map(&StationCalendarReviewRowValues.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    StationCalendarReviewRowReports.from_rows(
      "#{path}.rows.source_station_calendar_review",
      "cadence_import_manifest.rows.source_station_calendar_review",
      rows,
      manifest
    )
  end

  defp stringify_keys(value), do: StationCalendarReviewRowValues.stringify_keys(value)
end
