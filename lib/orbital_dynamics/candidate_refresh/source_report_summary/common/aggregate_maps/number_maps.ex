defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.NumberMaps do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.NestedMaps
  alias __MODULE__.NumericMaps

  def merge_count_maps(count_maps) do
    CountMaps.merge(count_maps)
  end

  def merge_numeric_maps(numeric_maps) do
    NumericMaps.merge(numeric_maps)
  end

  def merge_nested_numeric_maps(numeric_maps),
    do: NestedMaps.merge(numeric_maps, &merge_numeric_maps/1)
end
