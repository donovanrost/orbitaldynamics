defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounteroffer
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEncoding

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.source_provider_counteroffer_report",
         Map.get(artifact, "source_provider_counteroffer_report")},
        {"#{path}.provider_counteroffer_report",
         Map.get(artifact, "provider_counteroffer_report")},
        {"#{path}.source_provider_counteroffer_review_summary",
         Map.get(artifact, "source_provider_counteroffer_review_summary")},
        {"#{path}.provider_counteroffer_review_summary",
         Map.get(artifact, "provider_counteroffer_review_summary")},
        {"#{path}.source_provider_counteroffer_import_readiness_summary",
         Map.get(artifact, "source_provider_counteroffer_import_readiness_summary")},
        {"#{path}.provider_counteroffer_import_readiness_summary",
         Map.get(artifact, "provider_counteroffer_import_readiness_summary")},
        {"#{path}.source_provider_counteroffer_plan_impact_summary",
         Map.get(artifact, "source_provider_counteroffer_plan_impact_summary")},
        {"#{path}.provider_counteroffer_plan_impact_summary",
         Map.get(artifact, "provider_counteroffer_plan_impact_summary")}
      ]
      |> Enum.flat_map(fn {entry_path, report} ->
        ProviderCounteroffer.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defp stringify_keys(value), do: ProviderCounterofferEncoding.stringify_keys(value)
end
