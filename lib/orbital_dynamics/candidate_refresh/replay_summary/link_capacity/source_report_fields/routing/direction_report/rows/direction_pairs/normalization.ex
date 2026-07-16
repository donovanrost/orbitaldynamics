defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.Normalization do
  @moduledoc false

  alias __MODULE__.DirectionValues
  alias __MODULE__.StableIds
  alias __MODULE__.ValueEncoding

  def normalize_direction(direction), do: DirectionValues.normalize_direction(direction)

  def stable_id_or_nil(value), do: StableIds.stable_id_or_nil(value)

  def stringify_keys(value), do: ValueEncoding.stringify_keys(value)

  def encode_value(value), do: ValueEncoding.encode_value(value)
end
