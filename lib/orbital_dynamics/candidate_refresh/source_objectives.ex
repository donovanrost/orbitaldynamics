defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives do
  @moduledoc false

  alias __MODULE__.{
    Constraint,
    ContactAllocation,
    ContactContentionResolution,
    LinkCapacity,
    ObjectiveSatisfaction,
    ObjectiveTradeoff,
    ResourceProjection,
    ScoreTerm,
    TimelineDiff
  }

  alias OrbitalDynamics.CandidateRefresh.{
    ResultArtifactTrustBoundary,
    ValueEncoding
  }

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollection,
    as: ContactReviewCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollection,
    as: LinkConstraintCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollection,
    as: ObjectiveCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollection,
    as: ResourceCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollection,
    as: ScoreTermCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollection,
    as: TimelineDiffCollectionSourceReports

  def objectives(refresh) do
    [
      Map.get(refresh, "objectives", []),
      get_in(refresh, ["mission_state", "objectives"]) || [],
      get_in(refresh, ["accepted_planning_state", "objectives"]) || [],
      source_report_objectives(refresh)
    ]
    |> List.flatten()
    |> Enum.map(&ValueEncoding.stringify_keys/1)
  end

  defp source_report_objectives(refresh) do
    Enum.map(source_report_objective_routes(), fn {source_reports_fun, objectives_fun} ->
      refresh
      |> inherited_result_artifact_source_reports(source_reports_fun)
      |> then(objectives_fun)
    end)
  end

  defp source_report_objective_routes do
    [
      {&TimelineDiffCollectionSourceReports.reports/3, &TimelineDiff.objectives/1},
      {&ObjectiveCollectionSourceReports.objective_satisfaction_reports/3,
       &ObjectiveSatisfaction.objectives/1},
      {&ObjectiveCollectionSourceReports.objective_tradeoff_reports/3,
       &ObjectiveTradeoff.objectives/1},
      {&ScoreTermCollectionSourceReports.score_term_reports/3, &ScoreTerm.objectives/1},
      {&LinkConstraintCollectionSourceReports.constraint_reports/3, &Constraint.objectives/1},
      {&ResourceCollectionSourceReports.resource_projection_reports/3,
       &ResourceProjection.objectives/1},
      {&ContactReviewCollectionSourceReports.contact_contention_resolution_reports/3,
       &ContactContentionResolution.objectives/1},
      {&ContactReviewCollectionSourceReports.contact_allocation_reports/3,
       &ContactAllocation.objectives/1},
      {&LinkConstraintCollectionSourceReports.link_capacity_reports/3, &LinkCapacity.objectives/1}
    ]
  end

  defp inherited_result_artifact_source_reports(refresh, source_reports_fun) do
    source_reports_fun.(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
  end
end
