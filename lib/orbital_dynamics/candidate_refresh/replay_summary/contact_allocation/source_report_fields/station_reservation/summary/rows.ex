defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Rows do
  @moduledoc false

  alias __MODULE__.RowValues

  def expiration_now_s(report), do: RowValues.expiration_now_s(report)

  def expiration_rows(report), do: RowValues.expiration_rows(report)

  def station_reservation_expires_at_s(station) do
    RowValues.station_reservation_expires_at_s(station)
  end

  def rows(report), do: RowValues.rows(report)

  def group_key(row, field), do: RowValues.group_key(row, field)

  def summary_contact_id(row), do: RowValues.summary_contact_id(row)

  def grouped_contact_ids(pairs), do: RowValues.grouped_contact_ids(pairs)

  def map_value_lists(value), do: RowValues.map_value_lists(value)

  def sorted_non_empty_values(values), do: RowValues.sorted_non_empty_values(values)

  def normalize_number_list(values), do: RowValues.normalize_number_list(values)

  def numeric_value(value), do: RowValues.numeric_value(value)

  def stable_id_or_nil(value), do: RowValues.stable_id_or_nil(value)
end
