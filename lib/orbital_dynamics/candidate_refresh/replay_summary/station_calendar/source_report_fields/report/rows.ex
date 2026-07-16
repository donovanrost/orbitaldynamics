defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows do
  @moduledoc false

  alias __MODULE__.RowValues
  alias __MODULE__.ValueMaps

  def precedence_contact_ids(report), do: RowValues.precedence_contact_ids(report)

  def contact_ids_by_values(rows, grouping_fields) do
    ValueMaps.contact_ids_by_values(rows, grouping_fields)
  end

  def entry_ids_by_values(rows, grouping_fields) do
    ValueMaps.entry_ids_by_values(rows, grouping_fields)
  end

  def reservation_ids_by_values(rows, grouping_fields) do
    ValueMaps.reservation_ids_by_values(rows, grouping_fields)
  end

  def capacity_fractions_by_values(rows, grouping_fields) do
    ValueMaps.capacity_fractions_by_values(rows, grouping_fields)
  end

  def ids_by_reserved_by(rows, id_fun), do: ValueMaps.ids_by_reserved_by(rows, id_fun)

  def row_entry_ids(row), do: ValueMaps.row_entry_ids(row)

  def row_capacity_fractions(row), do: ValueMaps.row_capacity_fractions(row)

  def affected_contact_rows_with_directions(report) do
    RowValues.affected_contact_rows_with_directions(report)
  end

  def row_directions(row), do: RowValues.row_directions(row)

  def row_reserved_by_values(row), do: ValueMaps.row_reserved_by_values(row)

  def row_reservation_expires_at_s(row), do: RowValues.row_reservation_expires_at_s(row)

  def row_reservation_ids(row), do: ValueMaps.row_reservation_ids(row)

  def rows_with_ground_station_id(rows), do: RowValues.rows_with_ground_station_id(rows)

  def rows_with_availability(rows), do: RowValues.rows_with_availability(rows)

  def row_values(row, fields), do: RowValues.row_values(row, fields)

  def normalize_number_list(values), do: RowValues.normalize_number_list(values)

  def summary_integer(summary, field), do: RowValues.summary_integer(summary, field)

  def stringify_keys(value), do: RowValues.stringify_keys(value)
end
