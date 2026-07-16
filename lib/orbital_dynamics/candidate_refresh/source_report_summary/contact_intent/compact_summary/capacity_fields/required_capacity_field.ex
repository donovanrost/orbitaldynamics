defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.RequiredCapacityField do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.CapacityMaps

  def field(summaries) do
    %{
      "capacity_pack_required_capacity_fraction" =>
        CapacityMaps.required_capacity_fraction(
          summaries,
          "capacity_pack_required_capacity_fraction"
        )
    }
  end
end
