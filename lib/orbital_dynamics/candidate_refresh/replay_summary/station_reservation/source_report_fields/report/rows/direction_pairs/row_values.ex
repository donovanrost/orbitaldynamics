defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.DirectionPairs.Normalization
  alias __MODULE__.Directions

  def row_directions(row), do: Directions.row_directions(row)

  def row_contact_ids(row) do
    row = stringify_keys(row)

    [
      row["contact_id"],
      row["source_contact_id"],
      row["candidate_id"],
      row["activity_id"],
      get_in(row, ["activity_context", "id"]),
      get_in(row, ["activity_context", "activity_id"]),
      row["source_contact"],
      row["contact"],
      row["source_contact_candidate"],
      row["contact_candidate"]
    ]
    |> List.flatten()
    |> Enum.map(&contact_id/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def row_reservation_ids(row) do
    row
    |> row_values([
      "station_reservation_id",
      "station_calendar_reservation_ids",
      "reservation_id",
      "reservation_ids"
    ])
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp contact_id(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["contact_id"],
      contact["source_contact_id"],
      contact["candidate_id"],
      contact["id"],
      contact["activity_id"],
      get_in(contact, ["activity_context", "id"]),
      get_in(contact, ["activity_context", "activity_id"])
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp contact_id(value), do: stable_id_or_nil(value)

  defp row_values(row, fields) do
    fields
    |> Enum.flat_map(fn field ->
      row
      |> Map.get(field)
      |> List.wrap()
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)

  defp encode_value(value), do: Normalization.encode_value(value)
end
