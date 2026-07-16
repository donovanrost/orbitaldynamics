defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPackageSummaries,
    as: PackageSummaries

  def operator_review_entries(path, value, summary?) when is_function(summary?, 1) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      PackageSummaries.operator_review_package_summary(entry_path, entry_value, summary?)
    end)
  end

  def cadence_import_entries(path, value, summary?) when is_function(summary?, 1) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      PackageSummaries.cadence_import_manifest_summary(entry_path, entry_value, summary?)
    end)
  end
end
