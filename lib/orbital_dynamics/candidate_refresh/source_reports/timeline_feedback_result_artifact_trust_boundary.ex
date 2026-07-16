defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackResultArtifactTrustBoundary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackReportValues

  def inherit(%{} = report, %{} = artifact) do
    report = TimelineFeedbackReportValues.stringify_keys(report)
    trust_boundary = result_artifact_trust_boundary(artifact)

    if trust_boundary in [nil, ""] or
         OperationalFeedback.source_timeline_feedback_trust_boundaries(report) != [] do
      report
    else
      put_inherited_trust_boundary(report, trust_boundary)
    end
  end

  def inherit(report, _artifact), do: report

  defp put_inherited_trust_boundary(report, trust_boundary) do
    encoded_trust_boundary = TimelineFeedbackReportValues.encode_value(trust_boundary)

    Map.update(
      report,
      "provenance",
      %{"trust_boundary" => encoded_trust_boundary},
      fn
        %{} = provenance ->
          Map.put_new(provenance, "trust_boundary", encoded_trust_boundary)

        _provenance ->
          %{"trust_boundary" => encoded_trust_boundary}
      end
    )
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = TimelineFeedbackReportValues.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
