defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.Normalization do
  @moduledoc false

  alias __MODULE__.StableIds
  alias __MODULE__.ValueEncoding

  def stable_id_or_nil(value), do: StableIds.stable_id_or_nil(value)

  def stringify_keys(value), do: ValueEncoding.stringify_keys(value)

  def encode_value(value), do: ValueEncoding.encode_value(value)
end
