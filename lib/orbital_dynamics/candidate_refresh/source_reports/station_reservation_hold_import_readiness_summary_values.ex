defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldImportReadinessSummaryValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldImportReadinessSummaryEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldImportReadinessSummaryFields

  def hold_import_readiness_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_hold_import_readiness_summary" and
      is_list(summary["import_readiness_rows"])
  end

  def hold_import_readiness_summary?(_summary), do: false

  def report_from_hold_import_readiness_summary(%{} = summary) do
    summary = stringify_keys(summary)

    {affected_rows, provider_rows} =
      summary
      |> Map.get("import_readiness_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.split_with(fn row ->
        row["reservation_review_row_type"] != "provider_calendar_contention_group"
      end)

    StationReservationHoldImportReadinessSummaryFields.from_summary(
      summary,
      affected_rows,
      provider_rows
    )
  end

  defp stringify_keys(value),
    do: StationReservationHoldImportReadinessSummaryEncoding.stringify_keys(value)
end
