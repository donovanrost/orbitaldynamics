defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewRowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewRowEncoding

  def embedded_report(%{} = row) do
    cond do
      is_map(get_in(row, ["source_review_row", "source_operational_readiness_report"])) ->
        get_in(row, ["source_review_row", "source_operational_readiness_report"])

      is_map(row["source_operational_readiness_report"]) ->
        row["source_operational_readiness_report"]

      true ->
        nil
    end
  end

  def embedded_report(_row), do: nil

  def trust_boundary(artifact) do
    artifact = OperationalReadinessReviewRowEncoding.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
