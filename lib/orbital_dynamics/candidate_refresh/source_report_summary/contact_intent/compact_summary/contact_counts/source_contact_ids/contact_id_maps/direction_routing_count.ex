defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.SourceContactIds.ContactIdMaps.DirectionRoutingCount do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent,
    as: SourceReportContactIntent

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting

  def value(summary, routing_contact_ids_field) do
    case Map.get(summary, "direction_routing") do
      %{} = direction_routing ->
        direction_routing
        |> DirectionRouting.contact_ids(routing_contact_ids_field)
        |> SourceReportContactIntent.count_unique_contact_ids()

      _direction_routing ->
        nil
    end
  end
end
