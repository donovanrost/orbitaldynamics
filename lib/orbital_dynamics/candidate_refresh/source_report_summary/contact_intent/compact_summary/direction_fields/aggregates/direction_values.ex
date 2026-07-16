defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.Aggregates.DirectionValues do
  @moduledoc false

  alias __MODULE__.ContactIds
  alias __MODULE__.Counts

  def from_compact_summaries(summaries) do
    contact_ids_by_direction = ContactIds.values(summaries)

    %{
      direction_counts: Counts.from_contact_ids(contact_ids_by_direction),
      contact_ids_by_direction: contact_ids_by_direction
    }
  end

  def from_input_summaries(summaries) do
    %{
      direction_counts: Counts.from_input_summaries(summaries),
      contact_ids_by_direction: ContactIds.values(summaries)
    }
  end
end
