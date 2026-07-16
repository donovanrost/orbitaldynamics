defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.HoldImportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows,
    only: [
      hold_contact_ids_by_direction_from_rows: 1,
      hold_import_readiness_row_contact_id_map: 2,
      hold_import_readiness_row_count_map: 2,
      hold_import_readiness_row_id_map: 2,
      hold_ids_by_direction_from_rows: 1,
      map_value_lists: 1
    ]

  def hold_import_status_counts(report) do
    case hold_import_readiness_row_count_map(report, ["station_reservation_hold_import_status"]) do
      nil -> Map.get(report, "reservation_hold_import_status_counts")
      counts -> counts
    end
  end

  def hold_required_import_action_counts(report) do
    case hold_import_readiness_row_count_map(report, [
           "required_operator_action",
           "required_import_action"
         ]) do
      nil -> Map.get(report, "required_import_action_counts")
      counts -> counts
    end
  end

  def hold_ids_by_direction(report) do
    case hold_ids_by_direction_from_rows(report) do
      nil -> Map.get(report, "reservation_hold_ids_by_direction") |> map_value_lists()
      values -> values
    end
  end

  def hold_ids_by_import_status(report) do
    case hold_import_readiness_row_id_map(report, ["station_reservation_hold_import_status"]) do
      nil -> Map.get(report, "reservation_hold_ids_by_import_status")
      values -> values
    end
  end

  def hold_ids_by_required_import_action(report) do
    case hold_import_readiness_row_id_map(report, [
           "required_operator_action",
           "required_import_action"
         ]) do
      nil -> Map.get(report, "reservation_hold_ids_by_required_import_action")
      values -> values
    end
  end

  def hold_contact_ids_by_direction(report) do
    case hold_contact_ids_by_direction_from_rows(report) do
      nil -> Map.get(report, "reservation_hold_contact_ids_by_direction") |> map_value_lists()
      values -> values
    end
  end

  def hold_contact_ids_by_import_status(report) do
    case hold_import_readiness_row_contact_id_map(report, [
           "station_reservation_hold_import_status"
         ]) do
      nil -> Map.get(report, "reservation_hold_contact_ids_by_import_status")
      values -> values
    end
  end
end
