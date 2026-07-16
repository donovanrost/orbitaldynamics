defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.ReservationConflict.Rows do
  @moduledoc false

  alias __MODULE__.RowValues

  def rows(report), do: RowValues.rows(report)

  def fallback_contact_count(report), do: RowValues.fallback_contact_count(report)

  def contact_ids_by_direction_and_station_from_rows(rows) do
    RowValues.contact_ids_by_direction_and_station_from_rows(rows)
  end

  def summary_direction(row), do: RowValues.summary_direction(row)

  def group_key(row, field), do: RowValues.group_key(row, field)

  def summary_contact_id(row), do: RowValues.summary_contact_id(row)

  def id_map_counts(contact_ids_by_key), do: RowValues.id_map_counts(contact_ids_by_key)

  def grouped_contact_counts(pairs), do: RowValues.grouped_contact_counts(pairs)

  def grouped_contact_ids(pairs), do: RowValues.grouped_contact_ids(pairs)

  def map_value_lists(value), do: RowValues.map_value_lists(value)

  def sorted_non_empty_values(values), do: RowValues.sorted_non_empty_values(values)

  def stable_id_or_nil(value), do: RowValues.stable_id_or_nil(value)
end
