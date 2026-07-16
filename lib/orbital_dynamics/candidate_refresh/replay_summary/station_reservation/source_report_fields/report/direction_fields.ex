defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.DirectionFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows,
    only: [
      direction_contact_pairs: 1,
      grouped_id_counts: 1,
      grouped_ids: 1,
      map_value_lists: 1,
      normalize_direction_count_map: 1
    ]

  def direction_counts(report) do
    report
    |> direction_contact_pairs()
    |> case do
      [] ->
        report
        |> Map.get("direction_counts")
        |> normalize_direction_count_map()

      pairs ->
        grouped_id_counts(pairs)
    end
  end

  def contact_ids_by_direction(report) do
    report
    |> direction_contact_pairs()
    |> case do
      [] ->
        report
        |> Map.get("contact_ids_by_direction")
        |> map_value_lists()

      pairs ->
        grouped_ids(pairs)
    end
  end
end
