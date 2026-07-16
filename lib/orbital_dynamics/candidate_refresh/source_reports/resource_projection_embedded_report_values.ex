defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionEmbeddedReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRows

  def invalid_input_ids(inputs, primary_key) do
    Enum.map(inputs, &(&1[primary_key] || &1["subject_id"]))
  end

  def result_artifact_trust_boundary(artifact) do
    artifact = ResourceProjectionReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
