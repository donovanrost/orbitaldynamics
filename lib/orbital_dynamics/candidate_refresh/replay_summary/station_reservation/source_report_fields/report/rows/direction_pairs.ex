defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs do
  @moduledoc false

  alias __MODULE__.HoldRows
  alias __MODULE__.Normalization
  alias __MODULE__.RowValues

  def hold_ids_by_direction_from_rows(report) do
    HoldRows.hold_ids_by_direction_from_rows(report)
  end

  def hold_contact_ids_by_direction_from_rows(report) do
    HoldRows.hold_contact_ids_by_direction_from_rows(report)
  end

  def direction_contact_pairs(report) do
    report
    |> Map.get("affected_contacts", [])
    |> Enum.flat_map(fn row ->
      row = stringify_keys(row)
      directions = row_directions(row)
      contact_ids = row_contact_ids(row)

      for direction <- directions,
          contact_id <- contact_ids,
          direction not in [nil, ""],
          contact_id not in [nil, ""] do
        {direction, contact_id}
      end
    end)
    |> Enum.uniq()
  end

  defp row_directions(row), do: RowValues.row_directions(row)

  defp row_contact_ids(row), do: RowValues.row_contact_ids(row)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
