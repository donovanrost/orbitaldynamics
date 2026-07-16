defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SourceFields do
  @moduledoc false

  alias __MODULE__.TrustBoundaries

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => contract(reports),
      "count" => length(sources),
      "trust_boundary_status" => TrustBoundaries.status(reports),
      "trust_boundaries" => trust_boundaries(reports)
    }
  end

  def trust_boundaries(reports) do
    TrustBoundaries.values(reports)
  end

  defp contract(reports) do
    reports
    |> Enum.map(fn report ->
      Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      _contracts -> "provider_counteroffer_report.v1"
    end
  end
end
