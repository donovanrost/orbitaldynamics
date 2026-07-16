defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  import OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowValues,
    only: [row_values: 2, stable_id_or_nil: 1]

  def contact_ids(row, contact_id_fields) do
    row
    |> row_values(contact_id_fields)
    |> sorted_string_values()
  end

  def reservation_ids(row, reservation_id_fields) do
    row
    |> row_values(reservation_id_fields)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def group_values(row, grouping_fields) do
    row
    |> row_values(grouping_fields)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end
end
