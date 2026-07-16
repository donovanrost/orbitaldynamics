defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs.GroupPairs do
  @moduledoc false

  alias __MODULE__.PairSources
  alias __MODULE__.PairValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def group_pairs(group) do
    group = EncodedValue.stringify_keys(group)

    group
    |> pair_sources()
    |> Enum.map(&PairValues.contact_pair(&1, group))
    |> Enum.reject(fn {direction, contact_id} ->
      direction in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp pair_sources(group) do
    case PairSources.source_contacts(group) do
      [] -> PairSources.fallback_contacts(group)
      contacts -> contacts
    end
  end
end
