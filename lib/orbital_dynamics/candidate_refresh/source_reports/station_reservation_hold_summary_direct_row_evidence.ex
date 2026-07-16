defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryDirectRowEvidence do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowValues,
    only: [
      normalize_number_list: 1,
      row_values: 2,
      stable_id_or_nil: 1,
      stringify_keys: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupFields

  def hold_row_count(rows) do
    rows
    |> Enum.filter(fn row ->
      row
      |> stringify_keys()
      |> row_reservation_ids()
      |> Enum.any?()
    end)
    |> length()
  end

  def expiration_evidence_count(rows), do: Enum.count(rows, &expiration_evidence_row?/1)

  def expires_at_s(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> stringify_keys()
      |> row_values(StationReservationHoldSummaryRowGroupFields.reservation_expires_at_fields())
    end)
    |> normalize_number_list()
  end

  defp row_reservation_ids(row) do
    row
    |> row_values(StationReservationHoldSummaryRowGroupFields.reservation_id_fields())
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp expiration_evidence_row?(row) do
    row
    |> stringify_keys()
    |> row_values(StationReservationHoldSummaryRowGroupFields.reservation_expires_at_fields())
    |> Enum.any?(&(&1 not in [nil, ""]))
  end
end
