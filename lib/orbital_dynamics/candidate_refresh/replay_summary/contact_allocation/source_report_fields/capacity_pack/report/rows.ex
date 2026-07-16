defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.Rows do
  @moduledoc false

  alias __MODULE__.RowValues

  def contact_status_row_counts(report), do: RowValues.contact_status_row_counts(report)

  def reduced_groups(report), do: RowValues.reduced_groups(report)

  def pack_group_id(group), do: RowValues.pack_group_id(group)

  def group_ids_by_status_from_groups(groups),
    do: RowValues.group_ids_by_status_from_groups(groups)

  def capacity_pack_group_key(row, field), do: RowValues.capacity_pack_group_key(row, field)

  def packed_row?(row), do: RowValues.packed_row?(row)

  def deferred_row?(row), do: RowValues.deferred_row?(row)

  def selected_capacity_pack_row?(row), do: RowValues.selected_capacity_pack_row?(row)

  def contact_ids_by_field(report, fallback_field, row_field, filter) do
    case report |> capacity_pack_rows() |> Enum.filter(filter) do
      [] ->
        report
        |> Map.get(fallback_field)
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {capacity_pack_group_key(row, row_field), summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end

  def required_fraction(report, fallback_field, filter) do
    case report |> capacity_pack_rows() |> Enum.filter(filter) do
      [] ->
        report
        |> Map.get(fallback_field)
        |> RowValues.numeric_value()

      rows ->
        rows
        |> Enum.map(&RowValues.numeric_value(&1["required_capacity_fraction"]))
        |> Enum.sum()
    end
  end

  def required_fraction_by_field(report, fallback_field, row_field, filter) do
    case report |> capacity_pack_rows() |> Enum.filter(filter) do
      [] ->
        report
        |> Map.get(fallback_field)
        |> RowValues.numeric_map()

      rows ->
        rows
        |> Enum.reduce(%{}, fn row, totals ->
          key = capacity_pack_group_key(row, row_field)
          required_fraction = RowValues.numeric_value(row["required_capacity_fraction"])

          if key in [nil, ""] or is_nil(required_fraction) do
            totals
          else
            Map.update(totals, key, required_fraction, &(&1 + required_fraction))
          end
        end)
        |> RowValues.non_empty_map()
    end
  end

  def rows_for_summary(report), do: RowValues.rows_for_summary(report)

  def capacity_pack_rows(report), do: RowValues.capacity_pack_rows(report)

  def summary_contact_id(row), do: RowValues.summary_contact_id(row)

  def id_map_counts(contact_ids_by_key), do: RowValues.id_map_counts(contact_ids_by_key)

  def grouped_contact_counts(pairs), do: RowValues.grouped_contact_counts(pairs)

  def grouped_contact_ids(pairs), do: RowValues.grouped_contact_ids(pairs)

  def map_value_lists(value), do: RowValues.map_value_lists(value)

  def fallback_contact_count(report), do: RowValues.fallback_contact_count(report)

  def sorted_non_empty_values(values), do: RowValues.sorted_non_empty_values(values)

  def explicit_count_map(report, field), do: RowValues.explicit_count_map(report, field)
end
