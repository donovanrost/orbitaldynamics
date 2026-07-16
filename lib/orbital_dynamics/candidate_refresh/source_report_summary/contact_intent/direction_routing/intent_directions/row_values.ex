defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.DirectionRouting.IntentDirections.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds
  alias __MODULE__.DirectionAliases

  def direction(intent) do
    [
      intent["direction"],
      intent["activity_type"],
      intent["type"],
      get_in(intent, ["activity_context", "direction"]),
      get_in(intent, ["source_activity", "direction"]),
      get_in(intent, ["source_activity", "activity_context", "direction"])
    ]
    |> Enum.map(&DirectionAliases.normalize/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  def contact_intent_stable_id(intent) do
    [
      intent["id"],
      intent["contact_id"],
      intent["activity_id"],
      intent["source_contact_id"],
      get_in(intent, ["activity_context", "contact_id"]),
      get_in(intent, ["activity_context", "id"]),
      get_in(intent, ["source_activity", "id"]),
      get_in(intent, ["source_activity", "contact_id"])
    ]
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end
end
