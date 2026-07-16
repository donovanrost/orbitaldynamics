defmodule OrbitalDynamics.CampaignPlanner.MissionStateCandidateRefreshSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    CadenceImportSourceReports,
    CandidateReviewSourceReports,
    ContactAllocationSourceReports,
    ContactContentionSourceReports,
    ContactFilterSourceReports,
    ContactIntentSourceReports,
    LinkCapacitySourceReports,
    ModelAcceptanceSourceReports,
    ObjectiveConstraintSourceReports,
    OperationalReadinessSourceReports,
    OperatorReviewSourceReports,
    ProviderCounterofferSourceReports,
    QualityGateSourceReports,
    RefreshSourceReports,
    ResourceFilterSourceReports,
    ResourceProjectionSourceReports,
    ReviewSourceReports,
    SchemaValidationSourceReports,
    StationSourceReports,
    TimelineSourceReports,
    ValidationSafetyCaseSourceReports,
    ValueEncoding
  }

  def build(mission_state) do
    mission_state = ValueEncoding.stringify_keys(mission_state || %{})

    mission_state
    |> delegated_candidate_refresh_source_inputs()
    |> BranchRefreshSourceInputs.put_missing_candidate_refresh_result_artifact_source_aliases(
      mission_state
    )
    |> ValueEncoding.compact_map()
    |> BranchRefreshSourceInputs.non_empty_report()
  end

  def candidate_refresh_source_input_keys do
    candidate_refresh_source_input_modules()
    |> Enum.flat_map(fn source_report_module ->
      %{}
      |> source_report_module.candidate_refresh_source_inputs()
      |> Map.keys()
    end)
    |> Enum.sort()
  end

  defp delegated_candidate_refresh_source_inputs(mission_state) do
    Enum.reduce(candidate_refresh_source_input_modules(), %{}, fn source_report_module, inputs ->
      Map.merge(inputs, source_report_module.candidate_refresh_source_inputs(mission_state))
    end)
  end

  defp candidate_refresh_source_input_modules do
    [
      ResourceProjectionSourceReports,
      ContactAllocationSourceReports,
      ContactContentionSourceReports,
      LinkCapacitySourceReports,
      TimelineSourceReports,
      OperatorReviewSourceReports,
      CadenceImportSourceReports,
      ValidationSafetyCaseSourceReports,
      SchemaValidationSourceReports,
      ObjectiveConstraintSourceReports,
      ModelAcceptanceSourceReports,
      ProviderCounterofferSourceReports,
      RefreshSourceReports,
      CandidateReviewSourceReports,
      ResourceFilterSourceReports,
      ContactFilterSourceReports,
      ContactIntentSourceReports,
      QualityGateSourceReports,
      OperationalReadinessSourceReports,
      StationSourceReports,
      ReviewSourceReports
    ]
  end
end
