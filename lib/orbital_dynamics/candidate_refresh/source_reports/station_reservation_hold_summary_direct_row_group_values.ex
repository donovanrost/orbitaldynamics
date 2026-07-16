defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryDirectRowGroupValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  import OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowValues,
    only: [
      count_values: 1,
      row_values: 2,
      stable_id_or_nil: 1,
      stringify_keys: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupFields

  def status_counts(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> stringify_keys()
      |> row_values(StationReservationHoldSummaryRowGroupFields.reservation_status_fields())
    end)
    |> count_values()
  end

  def reservation_hold_ids(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> stringify_keys()
      |> row_values(StationReservationHoldSummaryRowGroupFields.reservation_id_fields())
    end)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def affected_contact_ids(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> stringify_keys()
      |> row_values(StationReservationHoldSummaryRowGroupFields.contact_id_fields())
    end)
    |> sorted_string_values()
  end
end
