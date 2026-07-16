defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.StationSuppression.CountFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows,
    only: [
      count_rows: 2,
      nested_station_id: 1,
      row_availability: 1,
      row_status: 1,
      stable_id_or_nil: 1,
      station_suppression_rows: 1
    ]

  def station_suppression_count(report) do
    report
    |> station_suppression_rows()
    |> length()
  end

  def station_suppression_ground_station_counts(report) do
    report
    |> station_suppression_rows()
    |> Enum.map(fn row ->
      Map.put(
        row,
        "ground_station_id",
        stable_id_or_nil(row["ground_station_id"] || nested_station_id(row))
      )
    end)
    |> count_rows("ground_station_id")
  end

  def station_suppression_availability_counts(report) do
    report
    |> station_suppression_rows()
    |> Enum.map(&Map.put(&1, "station_suppression_availability", row_availability(&1)))
    |> count_rows("station_suppression_availability")
  end

  def station_suppression_status_counts(report) do
    report
    |> station_suppression_rows()
    |> Enum.map(&Map.put(&1, "station_suppression_status", row_status(&1)))
    |> count_rows("station_suppression_status")
  end
end
