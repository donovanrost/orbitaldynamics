defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.SourceContactIds.ContactIdMaps do
  @moduledoc false

  alias __MODULE__.DirectionRoutingCount
  alias __MODULE__.SummaryMaps

  def count(summary, fields, routing_contact_ids_field) do
    case SummaryMaps.count(summary, fields) do
      nil -> DirectionRoutingCount.value(summary, routing_contact_ids_field)
      count -> count
    end
  end
end
