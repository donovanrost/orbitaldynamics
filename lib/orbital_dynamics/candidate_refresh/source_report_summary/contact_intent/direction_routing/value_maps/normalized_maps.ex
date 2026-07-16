defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.ValueMaps.NormalizedMaps do
  @moduledoc false

  alias __MODULE__.{ListMaps, NumericMaps}

  def nested_map_value_lists(value_map) do
    ListMaps.nested(value_map)
  end

  def map_value_lists(value_map) do
    ListMaps.values(value_map)
  end

  def normalize_numeric_map(value_map) do
    NumericMaps.normalize(value_map)
  end

  def nested_normalize_numeric_map(value_map) do
    NumericMaps.nested_normalize(value_map)
  end
end
