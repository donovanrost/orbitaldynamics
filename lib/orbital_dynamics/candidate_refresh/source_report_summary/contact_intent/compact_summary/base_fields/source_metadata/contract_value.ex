defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.SourceMetadata.ContractValue do
  @moduledoc false

  def contract(summaries) do
    summaries
    |> Enum.map(&Map.get(&1, "contract", Map.get(&1, "schema_contract")))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      contracts -> Enum.join(Enum.sort(contracts), "+")
    end
  end
end
