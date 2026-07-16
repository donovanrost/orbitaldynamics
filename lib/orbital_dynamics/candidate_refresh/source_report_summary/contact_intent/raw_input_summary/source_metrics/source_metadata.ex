defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics.SourceMetadata do
  @moduledoc false

  alias __MODULE__.TrustBoundaryFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def fields(intents) do
    %{
      "cadence_import_status_counts" => token_count(intents, "cadence_import_status"),
      "policy_classification_counts" => token_count(intents, "policy_classification")
    }
    |> Map.merge(TrustBoundaryFields.fields(intents))
  end

  defp token_count(intents, field) do
    intents
    |> Enum.map(&(Map.get(&1, field) |> NormalizedToken.value()))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end
end
