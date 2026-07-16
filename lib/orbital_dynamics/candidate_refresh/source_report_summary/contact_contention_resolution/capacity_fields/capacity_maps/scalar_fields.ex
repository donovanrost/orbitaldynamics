defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.CapacityFields.CapacityMaps.ScalarFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_numeric_values: 2
    ]

  def fields(reports) do
    %{
      "capacity_pack_required_capacity_fraction" =>
        sum_report_numeric_values(reports, &CapacityPack.required_fraction/1),
      "capacity_pack_selected_required_capacity_fraction" =>
        sum_report_numeric_values(reports, &CapacityPack.selected_required_fraction/1),
      "capacity_pack_deferred_required_capacity_fraction" =>
        sum_report_numeric_values(reports, &CapacityPack.deferred_required_fraction/1)
    }
  end
end
