defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.AggregateFields.FieldSpecs do
  @moduledoc false

  alias __MODULE__.{Dependency, Exclusivity, Review}

  def review, do: Review.all()

  def dependency, do: Dependency.all()

  def exclusivity, do: Exclusivity.all()
end
