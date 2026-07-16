defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactSpacecraftIds do
  @moduledoc false

  def contact_spacecraft_ids(%{} = contact) do
    [
      contact["spacecraft_id"],
      contact["scenario_id"],
      get_in(contact, ["spacecraft", "id"]),
      get_in(contact, ["satellite", "id"])
    ]
  end

  def contact_spacecraft_ids(_contact), do: []
end
