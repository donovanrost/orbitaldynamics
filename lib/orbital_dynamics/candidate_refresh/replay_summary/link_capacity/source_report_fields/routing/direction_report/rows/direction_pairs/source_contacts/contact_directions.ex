defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.SourceContacts.ContactDirections do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.Normalization

  def source_contact_direction(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["direction"],
      get_in(contact, ["activity_context", "direction"]),
      contact["type"],
      contact["activity_type"],
      get_in(contact, ["activity_context", "type"]),
      get_in(contact, ["activity_context", "activity_type"])
    ]
    |> Enum.map(&normalize_direction/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  def source_contact_direction(_contact), do: nil

  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
