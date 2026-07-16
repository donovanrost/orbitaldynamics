defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.DuplicateIdentities.RowValues.CountSpecs do
  @moduledoc false

  def total_field, do: "duplicate_timeline_identity_count"

  def source, do: {"duplicate_source_timeline_identity_count", "source"}

  def replacement, do: {"duplicate_replacement_timeline_identity_count", "replacement"}
end
