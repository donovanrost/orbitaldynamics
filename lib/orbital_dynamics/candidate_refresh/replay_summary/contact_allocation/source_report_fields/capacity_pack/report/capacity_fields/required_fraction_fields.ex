defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.CapacityFields.RequiredFractionFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.Rows

  import Rows,
    only: [
      deferred_row?: 1,
      required_fraction: 3,
      required_fraction_by_field: 4,
      selected_capacity_pack_row?: 1
    ]

  def required_fraction(report) do
    required_fraction(report, "capacity_pack_required_capacity_fraction", fn _row -> true end)
  end

  def selected_required_fraction(report) do
    required_fraction(
      report,
      "capacity_pack_selected_required_capacity_fraction",
      &selected_capacity_pack_row?/1
    )
  end

  def deferred_required_fraction(report) do
    required_fraction(
      report,
      "capacity_pack_deferred_required_capacity_fraction",
      &deferred_row?/1
    )
  end

  def required_fraction_by_status(report) do
    required_fraction_by_field(
      report,
      "capacity_pack_required_capacity_fraction_by_status",
      "capacity_pack_status",
      fn _row -> true end
    )
  end

  def required_fraction_by_station(report) do
    required_fraction_by_field(
      report,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      "ground_station_id",
      fn _row -> true end
    )
  end

  def selected_required_fraction_by_station(report) do
    required_fraction_by_field(
      report,
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      "ground_station_id",
      &selected_capacity_pack_row?/1
    )
  end

  def deferred_required_fraction_by_station(report) do
    required_fraction_by_field(
      report,
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      "ground_station_id",
      &deferred_row?/1
    )
  end

  def required_fraction_by_direction(report) do
    required_fraction_by_field(
      report,
      "capacity_pack_required_capacity_fraction_by_direction",
      "direction",
      fn _row -> true end
    )
  end

  def selected_required_fraction_by_direction(report) do
    required_fraction_by_field(
      report,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      "direction",
      &selected_capacity_pack_row?/1
    )
  end

  def deferred_required_fraction_by_direction(report) do
    required_fraction_by_field(
      report,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      "direction",
      &deferred_row?/1
    )
  end
end
