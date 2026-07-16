defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.SourceContactIds.ContactIdMaps.SummaryMaps do
  @moduledoc false

  alias __MODULE__.ContactIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent,
    as: SourceReportContactIntent

  def count(summary, fields) do
    flat_contact_id_maps = contact_id_maps(summary, Map.fetch!(fields, :flat))
    nested_contact_id_maps = contact_id_maps(summary, Map.fetch!(fields, :nested))

    case flat_contact_id_maps != [] or nested_contact_id_maps != [] do
      true ->
        flat_contact_id_maps
        |> ContactIds.from_maps()
        |> Kernel.++(ContactIds.from_nested_maps(nested_contact_id_maps))
        |> SourceReportContactIntent.count_unique_contact_ids()

      false ->
        nil
    end
  end

  defp contact_id_maps(summary, fields) do
    fields
    |> Enum.map(&Map.get(summary, &1))
    |> Enum.filter(&is_map/1)
  end
end
