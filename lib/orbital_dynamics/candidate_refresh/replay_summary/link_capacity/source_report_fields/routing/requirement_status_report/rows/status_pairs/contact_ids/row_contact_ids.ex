defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.ContactIds.RowContactIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.Normalization

  def row_contact_ids(row, fields) do
    row = stringify_keys(row)

    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> List.flatten()
    |> Enum.map(&source_contact_id/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp source_contact_id(%{} = contact) do
    contact = stringify_keys(contact)

    [
      contact["id"],
      contact["activity_id"],
      contact["contact_id"],
      get_in(contact, ["activity_context", "id"]),
      get_in(contact, ["activity_context", "activity_id"])
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp source_contact_id(value), do: stable_id_or_nil(value)

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
