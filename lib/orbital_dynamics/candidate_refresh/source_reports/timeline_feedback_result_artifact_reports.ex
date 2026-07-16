defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackReportValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackResultArtifactTrustBoundary

  @nested_report_keys [
    "source_timeline_feedback_report",
    "timeline_feedback_report"
  ]

  def entries(path, %{} = artifact) do
    artifact = TimelineFeedbackReportValues.stringify_keys(artifact)

    exact_entries(path, artifact) ++ nested_entries(path, artifact)
  end

  defp exact_entries(path, artifact) do
    if TimelineFeedback.report?(artifact) do
      [{path, artifact}]
    else
      []
    end
  end

  defp nested_entries(path, artifact) do
    Enum.flat_map(@nested_report_keys, fn report_key ->
      case Map.get(artifact, report_key) do
        %{} = report ->
          [
            {entry_path(path, report_key),
             TimelineFeedbackResultArtifactTrustBoundary.inherit(report, artifact)}
          ]

        _report ->
          []
      end
    end)
  end

  defp entry_path(path, report_key), do: "#{path}.#{report_key}"
end
