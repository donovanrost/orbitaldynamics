defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportReportCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRows

  def report_from_embedded_rows(path, source, applications, artifact) do
    EmbeddedRowFallbacks.report_from_embedded_rows(
      path,
      source,
      applications,
      artifact,
      &report_from_applications/4
    )
  end

  defp report_from_applications(path, source, applications, artifact) do
    report =
      %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "model" => "preserved_timeline_transition_application_rows",
        "source" => source,
        "applications" => applications,
        "application_count" => length(applications)
      }
      |> Map.merge(TimelineTransitionApplicationReviewImportReportCounts.fields(applications))
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp stringify_keys(value),
    do: TimelineTransitionApplicationReviewImportRows.stringify_keys(value)
end
