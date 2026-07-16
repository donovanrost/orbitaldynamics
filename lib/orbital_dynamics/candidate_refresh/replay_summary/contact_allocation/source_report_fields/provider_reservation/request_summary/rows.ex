defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows do
  @moduledoc false

  alias __MODULE__.RowValues

  def candidate_rows(report), do: RowValues.candidate_rows(report)

  def request_rows(report), do: RowValues.request_rows(report)

  def review_rows(report), do: RowValues.review_rows(report)

  def candidate_row?(row), do: RowValues.candidate_row?(row)

  def request_row?(row), do: RowValues.request_row?(row)

  def request_ready_row?(row), do: RowValues.request_ready_row?(row)

  def request_summary_rows?(report), do: RowValues.request_summary_rows?(report)

  def no_request_rows(rows), do: RowValues.no_request_rows(rows)

  def rows_for_summary(report), do: RowValues.rows_for_summary(report)

  def contact_ids_by_direction_and_station(rows) do
    RowValues.contact_ids_by_direction_and_station(rows)
  end

  def group_key(row, field), do: RowValues.group_key(row, field)

  def station_reservation_ids(row), do: RowValues.station_reservation_ids(row)

  def summary_contact_id(row), do: RowValues.summary_contact_id(row)

  def summary_direction(row), do: RowValues.summary_direction(row)

  def grouped_contact_ids(pairs), do: RowValues.grouped_contact_ids(pairs)

  def map_value_lists(value), do: RowValues.map_value_lists(value)

  def nested_map_value_lists(value), do: RowValues.nested_map_value_lists(value)

  def sorted_non_empty_values(values), do: RowValues.sorted_non_empty_values(values)
end
