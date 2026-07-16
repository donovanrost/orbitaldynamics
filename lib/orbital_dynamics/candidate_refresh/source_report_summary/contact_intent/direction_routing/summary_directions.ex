defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.SummaryDirections do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.IntentDirections

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_lists: 1]

  def summary_directions(summaries, contact_ids_by_direction) do
    summaries
    |> Enum.map(&Map.get(&1, "directions"))
    |> merge_string_lists()
    |> case do
      nil -> IntentDirections.direction_keys(contact_ids_by_direction)
      directions -> directions
    end
  end
end
