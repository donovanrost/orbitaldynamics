defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationReviewSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationReviewSummaryFields

  def review_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    summary["model"] == "artifact_only_station_reservation_review_summary" and
      summary["schema_contract"] in [nil, "station_reservation_review_summary.v1"] and
      is_list(summary["review_rows"])
  end

  def review_summary?(_summary), do: false

  def report_from_review_summary(%{} = summary) do
    summary = stringify_keys(summary)

    {affected_rows, provider_rows} =
      summary
      |> Map.get("review_rows", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.split_with(fn row ->
        row["reservation_review_row_type"] != "provider_calendar_contention_group"
      end)

    StationReservationReviewSummaryFields.from_summary(summary, affected_rows, provider_rows)
  end

  defp stringify_keys(value), do: StationReservationEncoding.stringify_keys(value)
end
