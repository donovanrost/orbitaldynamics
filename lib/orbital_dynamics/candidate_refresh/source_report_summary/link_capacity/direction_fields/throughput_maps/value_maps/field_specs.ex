defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.ThroughputMaps.ValueMaps.FieldSpecs do
  @moduledoc false

  def all do
    [
      {
        :capacity_adjusted,
        "capacity_adjusted_throughput_mb",
        "capacity_adjusted_throughput_mb_by_direction"
      },
      {
        :selected_capacity_adjusted,
        "selected_capacity_adjusted_throughput_mb",
        "selected_capacity_adjusted_throughput_mb_by_direction"
      },
      {
        :unused_capacity_adjusted,
        "unused_capacity_adjusted_throughput_mb",
        "unused_capacity_adjusted_throughput_mb_by_direction"
      }
    ]
  end
end
