defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.CapacityFields.ContactIdFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.Rows

  import Rows,
    only: [
      capacity_pack_group_key: 2,
      capacity_pack_rows: 1,
      contact_ids_by_field: 4,
      deferred_row?: 1,
      fallback_contact_count: 1,
      grouped_contact_ids: 1,
      map_value_lists: 1,
      rows_for_summary: 1,
      selected_capacity_pack_row?: 1,
      sorted_non_empty_values: 1,
      summary_contact_id: 1
    ]

  def required_capacity_contact_ids_by_source(report) do
    case rows_for_summary(report) do
      [] ->
        report
        |> Map.get("required_capacity_fraction_contact_ids_by_source")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {capacity_pack_group_key(row, "required_capacity_fraction_source"),
           summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end

  def contact_ids_by_status(report) do
    case rows_for_summary(report) do
      [] ->
        report
        |> Map.get("capacity_pack_contact_ids_by_status")
        |> map_value_lists()

      rows ->
        rows
        |> Enum.map(fn row ->
          {capacity_pack_group_key(row, "capacity_pack_status"), summary_contact_id(row)}
        end)
        |> grouped_contact_ids()
    end
  end

  def contact_count(report) do
    case capacity_pack_rows(report) do
      [] ->
        fallback_contact_count(report)

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> Enum.uniq()
        |> length()
    end
  end

  def selected_contact_ids_by_station(report) do
    contact_ids_by_field(
      report,
      "capacity_pack_selected_contact_ids_by_ground_station_id",
      "ground_station_id",
      &selected_capacity_pack_row?/1
    )
  end

  def deferred_contact_ids_by_station(report) do
    contact_ids_by_field(
      report,
      "capacity_pack_deferred_contact_ids_by_ground_station_id",
      "ground_station_id",
      &deferred_row?/1
    )
  end

  def contact_ids_by_station(report) do
    contact_ids_by_field(
      report,
      "capacity_pack_contact_ids_by_ground_station_id",
      "ground_station_id",
      fn _row -> true end
    )
  end

  def selected_contact_ids_by_direction(report) do
    contact_ids_by_field(
      report,
      "capacity_pack_selected_contact_ids_by_direction",
      "direction",
      &selected_capacity_pack_row?/1
    )
  end

  def deferred_contact_ids_by_direction(report) do
    contact_ids_by_field(
      report,
      "capacity_pack_deferred_contact_ids_by_direction",
      "direction",
      &deferred_row?/1
    )
  end

  def contact_ids_by_direction(report) do
    contact_ids_by_field(
      report,
      "capacity_pack_contact_ids_by_direction",
      "direction",
      fn _row -> true end
    )
  end

  def packed_contact_ids(report) do
    case rows_for_summary(report) do
      [] ->
        report
        |> Map.get("reduced_capacity_packed_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.filter(&Rows.packed_row?/1)
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def deferred_contact_ids(report) do
    case rows_for_summary(report) do
      [] ->
        report
        |> Map.get("reduced_capacity_deferred_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.filter(&deferred_row?/1)
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end
end
