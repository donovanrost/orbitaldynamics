defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.IntentDirections do
  @moduledoc false

  alias __MODULE__.PairMaps

  def direction_counts(intents) do
    PairMaps.direction_counts(intents)
  end

  def contact_ids_by_direction(intents) do
    PairMaps.contact_ids_by_direction(intents)
  end

  def direction_keys(%{} = contact_ids_by_direction) do
    PairMaps.direction_keys(contact_ids_by_direction)
  end

  def direction_keys(_contact_ids_by_direction), do: nil
end
