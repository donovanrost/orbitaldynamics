defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffTrustBoundary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffEncoding

  def inherit(reports, %{} = artifact) when is_list(reports) do
    Enum.map(reports, &inherit(&1, artifact))
  end

  def inherit(%{} = report, %{} = artifact) do
    report = TimelinePublicationHandoffEncoding.stringify_keys(report)
    trust_boundary = result_artifact_trust_boundary(artifact)

    if trust_boundary in [nil, ""] or
         OperationalFeedback.source_timeline_feedback_trust_boundaries(report) != [] do
      report
    else
      Map.update(
        report,
        "provenance",
        %{"trust_boundary" => TimelinePublicationHandoffEncoding.encode_value(trust_boundary)},
        fn
          %{} = provenance ->
            Map.put_new(
              provenance,
              "trust_boundary",
              TimelinePublicationHandoffEncoding.encode_value(trust_boundary)
            )

          _provenance ->
            %{"trust_boundary" => TimelinePublicationHandoffEncoding.encode_value(trust_boundary)}
        end
      )
    end
  end

  def inherit(report, _artifact), do: report

  defp result_artifact_trust_boundary(artifact) do
    artifact = TimelinePublicationHandoffEncoding.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
