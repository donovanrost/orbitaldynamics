defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps do
  @moduledoc false

  alias __MODULE__.MapValues
  alias __MODULE__.NonEmptyMaps
  alias __MODULE__.PairMaps

  def map_value_lists(%{} = value_map) do
    value_map
    |> MapValues.from_value_map()
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def from_pairs(pairs) do
    pairs
    |> PairMaps.from_pairs()
    |> non_empty_map()
  end

  def non_empty_map(map), do: NonEmptyMaps.value(map)
end
