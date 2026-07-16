defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.DirectionValues.ContactIds do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1
    ]

  def values(summaries) do
    summaries
    |> Enum.map(&Map.get(&1, "contact_ids_by_direction"))
    |> merge_string_list_maps()
  end
end
