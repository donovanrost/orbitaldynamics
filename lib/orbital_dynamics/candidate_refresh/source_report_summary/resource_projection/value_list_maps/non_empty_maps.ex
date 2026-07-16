defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps.NonEmptyMaps do
  @moduledoc false

  def value(map) when map_size(map) == 0, do: nil
  def value(map), do: map
end
