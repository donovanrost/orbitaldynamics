defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.InputSummaries.AggregateValues.TrustBoundaryStatus do
  @moduledoc false

  def merged(summaries) do
    summaries
    |> statuses()
    |> merged_status()
  end

  defp statuses(summaries) do
    summaries
    |> Enum.map(&Map.get(&1, "trust_boundary_status"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp merged_status([]), do: nil

  defp merged_status(statuses) do
    if "declared" in statuses do
      "declared"
    else
      Enum.sort(statuses) |> List.first()
    end
  end
end
