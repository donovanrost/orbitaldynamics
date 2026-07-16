defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps do
  @moduledoc false

  alias __MODULE__.ByValues
  alias __MODULE__.CapacityFractions
  alias __MODULE__.RowValues

  def contact_ids_by_values(rows, grouping_fields) do
    ByValues.contact_ids_by_values(rows, grouping_fields)
  end

  def entry_ids_by_values(rows, grouping_fields) do
    ByValues.entry_ids_by_values(rows, grouping_fields)
  end

  def reservation_ids_by_values(rows, grouping_fields) do
    ByValues.reservation_ids_by_values(rows, grouping_fields)
  end

  def capacity_fractions_by_values(rows, grouping_fields) do
    CapacityFractions.capacity_fractions_by_values(rows, grouping_fields)
  end

  def ids_by_reserved_by(rows, id_fun) do
    ByValues.ids_by_reserved_by(rows, id_fun)
  end

  defdelegate row_entry_ids(row), to: RowValues
  defdelegate row_capacity_fractions(row), to: RowValues
  defdelegate row_reserved_by_values(row), to: RowValues
  defdelegate row_reservation_ids(row), to: RowValues
end
