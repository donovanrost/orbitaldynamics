defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ObjectiveResourceReports.ReportSources.CollectionFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollection,
    as: LinkConstraintCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollection,
    as: ObjectiveCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollection,
    as: ResourceCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollection,
    as: ScoreTermCollectionSourceReports

  def function_for(:source_constraint_reports),
    do: &LinkConstraintCollectionSourceReports.constraint_reports/3

  def function_for(:source_objective_satisfaction_reports),
    do: &ObjectiveCollectionSourceReports.objective_satisfaction_reports/3

  def function_for(:source_objective_tradeoff_reports),
    do: &ObjectiveCollectionSourceReports.objective_tradeoff_reports/3

  def function_for(:source_score_term_reports),
    do: &ScoreTermCollectionSourceReports.score_term_reports/3

  def function_for(:source_resource_projection_reports),
    do: &ResourceCollectionSourceReports.resource_projection_reports/3

  def function_for(:source_resource_filter_reports),
    do: &ResourceCollectionSourceReports.resource_filter_reports/3
end
