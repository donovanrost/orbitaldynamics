defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewReportDerivedValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewRows

  def invalid_resource_summary_input_ids(invalid_resource_summary_inputs) do
    Enum.map(
      invalid_resource_summary_inputs,
      &(&1["resource_summary_id"] || &1["subject_id"])
    )
  end

  def count_rows(rows, field) do
    rows
    |> Enum.map(
      &(Map.get(&1, field)
        |> ResourceFilterReviewRows.normalized_source_report_token())
    )
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  def result_artifact_trust_boundary(artifact) do
    artifact = ResourceFilterReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
