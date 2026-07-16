defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.RequiredCapacity.FractionFields.FieldValues.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report

  def numeric_sums do
    [
      {"capacity_pack_required_capacity_fraction", &Report.required_fraction/1},
      {"capacity_pack_selected_required_capacity_fraction", &Report.selected_required_fraction/1},
      {"capacity_pack_deferred_required_capacity_fraction", &Report.deferred_required_fraction/1}
    ]
  end

  def numeric_maps do
    [
      {"capacity_pack_required_capacity_fraction_by_status",
       &Report.required_fraction_by_status/1},
      {"capacity_pack_required_capacity_fraction_by_ground_station",
       &Report.required_fraction_by_station/1},
      {"capacity_pack_required_capacity_fraction_by_direction",
       &Report.required_fraction_by_direction/1},
      {"capacity_pack_selected_required_capacity_fraction_by_ground_station",
       &Report.selected_required_fraction_by_station/1},
      {"capacity_pack_selected_required_capacity_fraction_by_direction",
       &Report.selected_required_fraction_by_direction/1},
      {"capacity_pack_deferred_required_capacity_fraction_by_ground_station",
       &Report.deferred_required_fraction_by_station/1},
      {"capacity_pack_deferred_required_capacity_fraction_by_direction",
       &Report.deferred_required_fraction_by_direction/1}
    ]
  end
end
