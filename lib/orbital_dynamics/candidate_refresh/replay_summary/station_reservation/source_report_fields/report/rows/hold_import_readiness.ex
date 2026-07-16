defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.HoldImportReadiness do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.RowValues

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps

  def hold_import_readiness_row_count_map(report, fields) do
    if hold_import_readiness_report?(report) do
      report
      |> report_rows()
      |> Enum.flat_map(fn row ->
        row
        |> stringify_keys()
        |> row_values(fields)
      end)
      |> count_values()
    end
  end

  def hold_import_readiness_row_id_map(report, fields) do
    if hold_import_readiness_report?(report) do
      report
      |> report_rows()
      |> ids_by_values(fields)
    end
  end

  def hold_import_readiness_row_contact_id_map(report, fields) do
    if hold_import_readiness_report?(report) do
      report
      |> report_rows()
      |> contact_ids_by_values(fields)
    end
  end

  defp hold_import_readiness_report?(report) do
    report = stringify_keys(report)

    report["model"] == "preserved_station_reservation_hold_import_readiness_summary" or
      Map.has_key?(report, "reservation_hold_import_status_counts") or
      Map.has_key?(report, "required_import_action_counts") or
      Map.has_key?(report, "import_readiness_status") or
      Map.has_key?(report, "import_classification")
  end

  defp report_rows(report), do: RowValues.report_rows(report)

  defp row_values(row, fields), do: RowValues.row_values(row, fields)

  defp contact_ids_by_values(rows, fields), do: ValueMaps.contact_ids_by_values(rows, fields)

  defp ids_by_values(rows, fields), do: ValueMaps.ids_by_values(rows, fields)

  defp count_values(values), do: ValueMaps.count_values(values)

  defp stringify_keys(value), do: RowValues.stringify_keys(value)
end
