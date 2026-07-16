defmodule OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetResultArtifactTraversal
  alias OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetTraversalEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module,
        report_key
      ) do
    refresh
    |> FreshnessBudgetDirectReports.reports(source_module, report_key)
    |> Kernel.++(
      FreshnessBudgetResultArtifactTraversal.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        source_module,
        report_key
      )
    )
    |> Enum.filter(fn {_path, report} -> source_module.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, FreshnessBudgetTraversalEncoding.stringify_keys(report)}
    end)
  end
end
