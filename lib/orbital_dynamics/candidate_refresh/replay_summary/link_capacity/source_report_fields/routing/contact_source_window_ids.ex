defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactSourceWindowIds do
  @moduledoc false

  def contact_source_window_ids(contact, normalization) do
    contact = normalization.stringify_keys(contact)

    [
      contact["source_window_id"],
      get_in(contact, ["source_window", "id"]),
      get_in(contact, ["activity_context", "source_window_id"])
    ]
    |> List.flatten()
    |> Enum.map(&normalization.stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
