defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting do
  @moduledoc false

  alias __MODULE__.ContactIdMaps
  alias __MODULE__.IntentDirections
  alias __MODULE__.RouteMap
  alias __MODULE__.SummaryDirections
  alias __MODULE__.ValueMaps

  defdelegate contact_ids(direction_routing, contact_ids_field), to: ContactIdMaps
  defdelegate string_list_map_counts(list_map), to: ContactIdMaps
  defdelegate summary_directions(summaries, contact_ids_by_direction), to: SummaryDirections
  defdelegate direction_keys(contact_ids_by_direction), to: IntentDirections
  defdelegate direction_counts(intents), to: IntentDirections
  defdelegate contact_ids_by_direction(intents), to: IntentDirections

  defdelegate build(
                direction_counts,
                contact_ids_by_direction,
                required_capacity_by_direction,
                capacity_contact_ids_by_direction,
                contact_ids_by_direction_and_station,
                required_capacity_by_direction_and_station,
                capacity_contact_ids_by_direction_and_station
              ),
              to: RouteMap

  defdelegate nested_map_value_lists(value_map), to: ValueMaps
  defdelegate map_value_lists(value), to: ValueMaps
end
