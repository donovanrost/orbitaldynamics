defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiff
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffEncoding

  def entries(path, %{} = artifact) do
    artifact = stringify_keys(artifact)

    exact = TimelineDiff.entries(path, artifact)

    nested =
      [
        {"#{path}.source_timeline_diff_summary",
         Map.get(artifact, "source_timeline_diff_summary")},
        {"#{path}.timeline_diff_summary", Map.get(artifact, "timeline_diff_summary")},
        {"#{path}.source_timeline_diff_report", Map.get(artifact, "source_timeline_diff_report")},
        {"#{path}.timeline_diff_report", Map.get(artifact, "timeline_diff_report")}
      ]
      |> Enum.flat_map(fn {entry_path, report_or_summary} ->
        TimelineDiff.entries(
          entry_path,
          inherit_result_artifact_trust_boundary(report_or_summary, artifact)
        )
      end)

    exact ++ nested
  end

  defp inherit_result_artifact_trust_boundary(report, artifact) when is_map(report) do
    case result_artifact_trust_boundary(artifact) do
      nil ->
        stringify_keys(report)

      trust_boundary ->
        report |> stringify_keys() |> Map.put_new("trust_boundary", trust_boundary)
    end
  end

  defp inherit_result_artifact_trust_boundary(report, _artifact), do: report

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp stringify_keys(value), do: TimelineDiffEncoding.stringify_keys(value)
end
