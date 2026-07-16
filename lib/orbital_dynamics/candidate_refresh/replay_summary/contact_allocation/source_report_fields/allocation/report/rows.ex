defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows do
  @moduledoc false

  alias __MODULE__.RowValues

  def rows_for_summary(report), do: RowValues.rows_for_summary(report)

  def effective_status(row), do: RowValues.effective_status(row)

  def contact_ids_by_status(report, fallback_field, statuses) do
    case RowValues.rows_matching_status(report, statuses) do
      [] ->
        report
        |> Map.get(fallback_field, [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def contact_ids_by_status_and_station(report, fallback_fields, statuses) do
    case RowValues.rows_matching_status(report, statuses) do
      [] ->
        fallback_fields
        |> Enum.find_value(fn field ->
          report
          |> Map.get(field)
          |> map_value_lists()
        end)

      rows ->
        rows
        |> Enum.map(fn row -> {group_key(row, "ground_station_id"), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end

  def invalid_contact_input_rows(report), do: RowValues.invalid_contact_input_rows(report)

  def status_blocked_rows(report), do: RowValues.status_blocked_rows(report)

  def resource_blocked_rows(report), do: RowValues.resource_blocked_rows(report)

  def review_rows(report), do: RowValues.review_rows(report)

  def resource_blocked_contact_ids_by_field(report, fallback_field, row_field) do
    case resource_blocked_rows(report) do
      [] ->
        report
        |> Map.get(fallback_field)
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row -> {group_key(row, row_field), summary_contact_id(row)} end)
        |> grouped_contact_ids()
    end
  end

  def group_key(row, field), do: RowValues.group_key(row, field)

  def duplicate_contact_row?(row), do: RowValues.duplicate_contact_row?(row)

  def summary_contact_id(row), do: RowValues.summary_contact_id(row)

  def summary_direction(row), do: RowValues.summary_direction(row)

  def map_value_lists(value), do: RowValues.map_value_lists(value)

  def id_map_counts(contact_ids_by_key), do: RowValues.id_map_counts(contact_ids_by_key)

  def sorted_non_empty_values(values), do: RowValues.sorted_non_empty_values(values)

  def grouped_contact_ids(pairs), do: RowValues.grouped_contact_ids(pairs)

  def grouped_contact_counts(pairs), do: RowValues.grouped_contact_counts(pairs)

  def explicit_count_map(report, field), do: RowValues.explicit_count_map(report, field)

  def non_empty_map(map), do: RowValues.non_empty_map(map)
end
