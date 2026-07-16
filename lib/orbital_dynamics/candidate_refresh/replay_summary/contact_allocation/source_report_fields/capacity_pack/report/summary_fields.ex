defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.SummaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  import Rows,
    only: [
      capacity_pack_rows: 1,
      contact_status_row_counts: 1,
      explicit_count_map: 2,
      group_ids_by_status_from_groups: 1,
      id_map_counts: 1,
      map_value_lists: 1,
      pack_group_id: 1,
      reduced_groups: 1,
      rows_for_summary: 1,
      sorted_non_empty_values: 1
    ]

  def status_counts(report) do
    case rows_for_summary(report) do
      [] ->
        explicit_count_map(report, "capacity_pack_status_counts")

      rows ->
        Counts.normalized_rows(rows, "capacity_pack_status")
    end
  end

  def contact_status_counts(report) do
    case contact_status_row_counts(report) do
      nil ->
        report
        |> Map.get("capacity_pack_contact_ids_by_status")
        |> id_map_counts()

      counts ->
        counts
    end
  end

  def reduced_group_count(report) do
    case reduced_groups(report) do
      [] -> numeric_report_count(report, "reduced_capacity_pack_group_count")
      groups -> length(groups)
    end
  end

  def reduced_status_counts(report) do
    case reduced_groups(report) do
      [] -> Map.get(report, "reduced_capacity_pack_status_counts")
      groups -> Counts.normalized_rows(groups, "pack_status")
    end
  end

  def group_ids(report) do
    case reduced_groups(report) do
      [] ->
        report
        |> Map.get("capacity_pack_group_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      groups ->
        groups
        |> Enum.map(&pack_group_id/1)
        |> sorted_non_empty_values()
    end
  end

  def group_ids_by_status(report) do
    case reduced_groups(report) do
      [] ->
        report
        |> Map.get("capacity_pack_group_ids_by_status")
        |> map_value_lists()

      groups ->
        group_ids_by_status_from_groups(groups)
    end
  end

  def required_capacity_source_counts(report) do
    case capacity_pack_rows(report) do
      [] ->
        explicit_count_map(report, "required_capacity_fraction_source_counts")

      rows ->
        Counts.normalized_rows(rows, "required_capacity_fraction_source")
    end
  end
end
