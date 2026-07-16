defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.ResultArtifactSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  def sources_for_refresh(refresh, result_artifact_trust_boundary_fun)
      when is_function(result_artifact_trust_boundary_fun, 1) do
    refresh
    |> ResultArtifactCollectionSourceReports.reports()
    |> sources(result_artifact_trust_boundary_fun)
  end

  def sources(result_artifacts, result_artifact_trust_boundary_fun)
      when is_list(result_artifacts) and is_function(result_artifact_trust_boundary_fun, 1) do
    Enum.flat_map(result_artifacts, fn {path, artifact} ->
      case Map.get(artifact, "operational_feedback") do
        %{} = feedback ->
          [
            {
              "#{path}.operational_feedback",
              RowValues.stringify_keys_with_keyword_maps(feedback),
              operational_feedback_trust_boundary(
                feedback,
                artifact,
                result_artifact_trust_boundary_fun
              )
            }
          ]

        _feedback ->
          []
      end
    end)
  end

  def sources(_result_artifacts, _result_artifact_trust_boundary_fun), do: []

  defp operational_feedback_trust_boundary(
         %{} = feedback,
         artifact,
         result_artifact_trust_boundary_fun
       ) do
    feedback = RowValues.stringify_keys_with_keyword_maps(feedback)

    Map.get(feedback, "trust_boundary") ||
      get_in(feedback, ["provenance", "trust_boundary"]) ||
      result_artifact_trust_boundary_fun.(artifact)
  end
end
