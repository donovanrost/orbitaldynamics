defmodule OrbitalDynamics.CadenceImport.StationOperationsImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization
  alias OrbitalDynamics.OperatorReview

  def from_command_window_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &(Map.get(&1, "operator_review_package") ||
          OperatorReview.from_command_window_report(&1)),
      "command_window_report.v1",
      &(&1["id"] || &1["source"]),
      "command_window_report"
    )
  end

  def from_station_calendar_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &(Map.get(&1, "operator_review_package") ||
          OperatorReview.from_station_calendar_report(&1)),
      "station_calendar_report.v1",
      &(&1["id"] || get_in(&1, ["assumptions", "source"])),
      "station_calendar_report"
    )
  end

  def from_station_reservation_report(report, opts, import) do
    from_review_report(
      report,
      opts,
      import,
      &OperatorReview.from_station_reservation_report/1,
      "station_reservation_report.v1",
      &(&1["id"] || &1["source"]),
      "station_reservation_report"
    )
  end

  defp from_review_report(
         report,
         opts,
         import,
         review_package,
         source_type,
         source_id,
         fallback
       ) do
    report = JsonNormalization.stringify_keys(report)
    selected_source_id = Keyword.get(opts, :source_artifact_id, source_id.(report)) || fallback

    import.(review_package.(report), opts, source_type, selected_source_id)
  end
end
