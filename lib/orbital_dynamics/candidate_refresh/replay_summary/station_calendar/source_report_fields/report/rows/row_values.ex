defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.Annotations
  alias __MODULE__.Directions
  alias __MODULE__.Normalization
  alias __MODULE__.PrecedenceContacts
  alias __MODULE__.ReservationExpirations

  def precedence_contact_ids(report) do
    PrecedenceContacts.precedence_contact_ids(report)
  end

  def affected_contact_rows_with_directions(report) do
    Directions.affected_contact_rows_with_directions(report)
  end

  def row_directions(row) do
    Directions.row_directions(row)
  end

  def row_reservation_expires_at_s(row) do
    ReservationExpirations.row_reservation_expires_at_s(row)
  end

  def rows_with_ground_station_id(rows) do
    Annotations.rows_with_ground_station_id(rows)
  end

  def rows_with_availability(rows) do
    Annotations.rows_with_availability(rows)
  end

  def row_values(row, fields) do
    fields
    |> Enum.flat_map(fn field ->
      row
      |> Map.get(field)
      |> List.wrap()
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  def normalize_number_list(value), do: Normalization.normalize_number_list(value)

  def summary_integer(summary, field), do: Normalization.summary_integer(summary, field)

  def stringify_keys(value), do: Normalization.stringify_keys(value)

  defp encode_value(value), do: Normalization.encode_value(value)
end
