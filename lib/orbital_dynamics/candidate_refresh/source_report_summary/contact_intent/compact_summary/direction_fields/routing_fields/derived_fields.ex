defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.DirectionFields.RoutingFields.DerivedFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting

  def fields(summaries, aggregates) do
    %{
      "directions" =>
        DirectionRouting.summary_directions(summaries, aggregates.contact_ids_by_direction),
      "direction_routing" =>
        DirectionRouting.build(
          aggregates.direction_counts,
          aggregates.contact_ids_by_direction,
          aggregates.required_by_direction,
          aggregates.capacity_contact_ids_by_direction,
          aggregates.contact_ids_by_direction_and_station,
          aggregates.required_by_direction_and_station,
          aggregates.capacity_contact_ids_by_direction_and_station
        )
    }
  end
end
