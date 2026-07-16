defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.StationSuppression.IdMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows,
    only: [
      nested_station_id: 1,
      row_availability: 1,
      row_station_calendar_entry_id: 1,
      row_station_calendar_provider_entry_id: 1,
      row_station_reservation_id: 1,
      row_status: 1,
      stable_id_or_nil: 1,
      station_suppression_contact_ids_by: 2,
      station_suppression_ids_by: 3,
      station_suppression_rows: 1
    ]

  def station_suppression_contact_ids_by_ground_station(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_contact_ids_by(fn row ->
      stable_id_or_nil(row["ground_station_id"] || nested_station_id(row))
    end)
  end

  def station_suppression_contact_ids_by_availability(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_contact_ids_by(&row_availability/1)
  end

  def station_suppression_contact_ids_by_status(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_contact_ids_by(&row_status/1)
  end

  def station_suppression_station_calendar_entry_ids_by_ground_station(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&ground_station_id/1, &row_station_calendar_entry_id/1)
  end

  def station_suppression_station_calendar_entry_ids_by_availability(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&row_availability/1, &row_station_calendar_entry_id/1)
  end

  def station_suppression_station_calendar_entry_ids_by_status(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&row_status/1, &row_station_calendar_entry_id/1)
  end

  def station_suppression_station_calendar_provider_entry_ids_by_ground_station(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&ground_station_id/1, &row_station_calendar_provider_entry_id/1)
  end

  def station_suppression_station_calendar_provider_entry_ids_by_availability(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&row_availability/1, &row_station_calendar_provider_entry_id/1)
  end

  def station_suppression_station_calendar_provider_entry_ids_by_status(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&row_status/1, &row_station_calendar_provider_entry_id/1)
  end

  def station_suppression_station_reservation_ids_by_ground_station(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&ground_station_id/1, &row_station_reservation_id/1)
  end

  def station_suppression_station_reservation_ids_by_availability(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&row_availability/1, &row_station_reservation_id/1)
  end

  def station_suppression_station_reservation_ids_by_status(report) do
    report
    |> station_suppression_rows()
    |> station_suppression_ids_by(&row_status/1, &row_station_reservation_id/1)
  end

  defp ground_station_id(row) do
    stable_id_or_nil(row["ground_station_id"] || nested_station_id(row))
  end
end
