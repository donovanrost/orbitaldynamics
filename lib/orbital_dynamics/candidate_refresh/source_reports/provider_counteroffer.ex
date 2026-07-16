defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounteroffer do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRows

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> ProviderCounterofferDirectReports.reports()
    |> Kernel.++(
      ProviderCounterofferArtifactReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ProviderCounterofferEncoding.stringify_keys(report)}
    end)
  end

  def entries(path, value) do
    ProviderCounterofferEntries.entries(path, value)
  end

  def build_entries(path, value, builder) do
    ProviderCounterofferEntries.build_entries(path, value, builder)
  end

  def operator_review_package_report(path, %{} = package) do
    ProviderCounterofferReviewRows.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    ProviderCounterofferReviewRows.cadence_import_manifest_report(path, manifest)
  end

  def report?(%{} = report) do
    ProviderCounterofferEntries.report?(report)
  end

  def report?(report), do: ProviderCounterofferEntries.report?(report)
end
