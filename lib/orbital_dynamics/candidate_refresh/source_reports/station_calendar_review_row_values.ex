defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewRowValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewRowEncoding

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_station_calendar_review"]) ->
          row["source_station_calendar_review"]

        is_map(get_in(row, ["source_review_row", "source_station_calendar_review"])) ->
          get_in(row, ["source_review_row", "source_station_calendar_review"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = station_row -> stringify_keys(station_row)
        _station_row -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("contact_id", row["contact_id"] || row["subject_id"])
    |> Map.put_new("contact_type", row["activity_type"])
    |> compact_map()
  end

  defdelegate stringify_keys(value), to: StationCalendarReviewRowEncoding
end
