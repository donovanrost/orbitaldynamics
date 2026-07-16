defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.DuplicateIdentities.RowValues do
  @moduledoc false

  alias __MODULE__.{CountSpecs, Counts}

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.DuplicateIdentities.Scopes

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_rows: 1]

  def duplicate_identity_total_count(report) do
    Counts.value(
      report,
      CountSpecs.total_field(),
      &Scopes.duplicate?/1
    )
  end

  def duplicate_source_timeline_identity_count(report) do
    scoped_count(report, CountSpecs.source())
  end

  def duplicate_replacement_timeline_identity_count(report) do
    scoped_count(report, CountSpecs.replacement())
  end

  def duplicate_identity_scope_counts(report) do
    report
    |> source_rows()
    |> Scopes.counts()
  end

  defp scoped_count(report, {field, scope}) do
    Counts.value(
      report,
      field,
      &Scopes.matches?(&1, scope)
    )
  end
end
