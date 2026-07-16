defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactIdValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  def source_contact_ids(row, normalization) do
    row
    |> SourceContactValues.source_contact_values()
    |> Enum.map(&source_contact_id(&1, normalization))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def source_contact_id(%{} = contact, normalization) do
    contact = normalization.stringify_keys(contact)

    [
      contact["id"],
      contact["activity_id"],
      contact["contact_id"],
      get_in(contact, ["activity_context", "id"]),
      get_in(contact, ["activity_context", "activity_id"])
    ]
    |> Enum.find_value(&normalization.stable_id_or_nil/1)
  end

  def source_contact_id(value, normalization), do: normalization.stable_id_or_nil(value)
end
