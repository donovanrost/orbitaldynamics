defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowReportCounts

  def count_rows(rows, field) do
    ProviderCounterofferReviewRowReportCounts.count_rows(rows, field)
  end

  def result_artifact_trust_boundary(artifact) do
    artifact = ProviderCounterofferEncoding.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)

  def numeric_value(value), do: ValueEncoding.numeric_value(value)
end
