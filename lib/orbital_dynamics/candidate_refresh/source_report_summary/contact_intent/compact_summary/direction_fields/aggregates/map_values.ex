defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.MapValues do
  @moduledoc false

  alias __MODULE__.DirectionMaps
  alias __MODULE__.StationMaps

  def from_compact_summaries(summaries),
    do: direction_map_values(summaries, StationMaps.from_compact_summaries(summaries))

  def from_input_summaries(summaries),
    do: direction_map_values(summaries, StationMaps.from_input_summaries(summaries))

  defp direction_map_values(summaries, station_map_fields) do
    summaries
    |> DirectionMaps.values()
    |> Map.merge(station_map_fields)
  end
end
