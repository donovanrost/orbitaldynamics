defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary.Rows do
  @moduledoc false

  alias __MODULE__.Aggregation
  alias __MODULE__.RowValues

  def rows(report) do
    RowValues.rows(report)
  end

  def review_row?(row) do
    RowValues.review_row?(row)
  end

  def contact_id_count(rows) do
    Aggregation.contact_id_count(rows)
  end

  def fallback_contact_count(report) do
    Aggregation.fallback_contact_count(report)
  end

  def fallback_review_contact_count(report) do
    Aggregation.fallback_review_contact_count(report)
  end

  def contact_ids_by_direction_and_station_from_rows(rows) do
    Aggregation.contact_ids_by_direction_and_station_from_rows(rows)
  end

  def availability_values(row) do
    RowValues.availability_values(row)
  end

  def summary_direction(row) do
    RowValues.summary_direction(row)
  end

  def group_key(row, field), do: RowValues.group_key(row, field)

  def summary_contact_id(row) do
    RowValues.summary_contact_id(row)
  end

  def id_map_counts(contact_ids_by_key), do: Aggregation.id_map_counts(contact_ids_by_key)

  def grouped_contact_counts(pairs) do
    Aggregation.grouped_contact_counts(pairs)
  end

  def grouped_contact_ids(pairs) do
    Aggregation.grouped_contact_ids(pairs)
  end

  def merge_string_list_maps(maps) do
    Aggregation.merge_string_list_maps(maps)
  end

  def map_value_lists(%{} = value_map) do
    Aggregation.map_value_lists(value_map)
  end

  def map_value_lists(value), do: Aggregation.map_value_lists(value)

  def nested_map_value_lists(%{} = value_map) do
    Aggregation.nested_map_value_lists(value_map)
  end

  def nested_map_value_lists(value_map), do: Aggregation.nested_map_value_lists(value_map)

  def sorted_non_empty_values(values) do
    Aggregation.sorted_non_empty_values(values)
  end
end
