defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.DirectionValues.Counts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def from_contact_ids(contact_ids_by_direction) do
    DirectionRouting.string_list_map_counts(contact_ids_by_direction)
  end

  def from_input_summaries(summaries) do
    summaries
    |> Enum.map(&Map.get(&1, "direction_counts"))
    |> merge_count_maps()
  end
end
