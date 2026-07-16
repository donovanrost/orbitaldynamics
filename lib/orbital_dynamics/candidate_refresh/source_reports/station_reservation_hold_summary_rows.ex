defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowValues,
    only: [stringify_keys: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowAggregates

  def report_fields(%{} = summary) do
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

    %{
      "affected_contacts" => affected_rows,
      "provider_calendar_contention_groups" => provider_rows
    }
    |> Map.merge(StationReservationHoldSummaryRowAggregates.fields(affected_rows, provider_rows))
  end
end
