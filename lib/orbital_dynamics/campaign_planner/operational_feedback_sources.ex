defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackSources do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivitySourceMetadata,
    ActivitySourceRows,
    BranchRefreshSourceInputs,
    CadenceImportSourceReports,
    CommandWindowOperationalFeedback,
    CommandWindowSourceMetadata,
    ManeuverReviewFeedbackRows,
    ManeuverReviewOperationalFeedback,
    ManeuverReviewResultArtifactRows,
    ManeuverReviewSourceMetadata,
    OperationalFeedbackNormalization,
    OperationalTimelineSourceMetadata,
    OperationalTimelineSourceRows,
    OperatorReviewOperationalFeedback,
    OperatorReviewSourceReports,
    RealizedActivitiesOperationalFeedback,
    ReviewSourceReports,
    TimelineFeedbackSourceMetadata
  }

  def source_rows(rows) do
    Enum.reduce(rows, OperationalFeedbackNormalization.normalize(%{}), fn row, merged ->
      feedback = Map.get(row, "source_operational_feedback", %{})
      OperationalFeedbackNormalization.merge(merged, feedback)
    end)
  end

  def prior_plan_timeline_feedback_operational_feedback(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_timeline_feedback_reports()
    |> Enum.reduce(OperationalFeedbackNormalization.normalize(%{}), fn {report, _source_path},
                                                                       feedback ->
      report
      |> Map.get("operational_feedback", %{})
      |> OperationalFeedbackNormalization.merge(feedback)
    end)
  end

  def mission_state_timeline_feedback_operational_feedback(mission_state) do
    mission_state
    |> ReviewSourceReports.timeline_feedback_reports()
    |> Enum.reduce(OperationalFeedbackNormalization.normalize(%{}), fn {report, _source_path},
                                                                       feedback ->
      report
      |> Map.get("operational_feedback", %{})
      |> OperationalFeedbackNormalization.merge(feedback)
    end)
  end

  def prior_plan_planned_activity_operational_feedback(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_planned_activity_rows()
    |> operational_timeline_rows_operational_feedback()
  end

  def mission_state_planned_activity_operational_feedback(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_planned_activity_rows()
    |> operational_timeline_rows_operational_feedback()
  end

  def prior_plan_proposed_contact_operational_feedback(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_proposed_contact_rows()
    |> operational_timeline_rows_operational_feedback()
  end

  def mission_state_proposed_contact_operational_feedback(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_proposed_contact_rows()
    |> operational_timeline_rows_operational_feedback()
  end

  def prior_plan_realized_activity_operational_feedback(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_realized_activity_rows()
    |> then(fn rows ->
      RealizedActivitiesOperationalFeedback.feedback(%{"realized_activities" => rows}, prior_plan)
    end)
  end

  def mission_state_realized_activity_operational_feedback(mission_state, prior_plan) do
    mission_state
    |> ActivitySourceRows.mission_state_realized_activity_rows(prior_plan)
    |> then(fn rows ->
      RealizedActivitiesOperationalFeedback.feedback(%{"realized_activities" => rows}, prior_plan)
    end)
  end

  def prior_plan_operational_timeline_operational_feedback(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_operational_timeline_reports()
    |> OperationalTimelineSourceRows.rows()
    |> operational_timeline_rows_operational_feedback()
  end

  def mission_state_operational_timeline_operational_feedback(mission_state) do
    mission_state
    |> ReviewSourceReports.operational_timeline_reports()
    |> OperationalTimelineSourceRows.rows()
    |> operational_timeline_rows_operational_feedback()
  end

  def prior_plan_command_window_operational_feedback(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_command_window_reports()
    |> CommandWindowOperationalFeedback.from_reports()
  end

  def mission_state_command_window_operational_feedback(mission_state) do
    mission_state
    |> ReviewSourceReports.command_window_reports()
    |> CommandWindowOperationalFeedback.from_reports()
  end

  def prior_plan_maneuver_review_operational_feedback(prior_plan) do
    ManeuverReviewOperationalFeedback.prior_plan_source_rows(
      prior_plan_maneuver_review_report_rows(prior_plan),
      prior_plan_result_artifact_maneuver_review_rows(prior_plan)
    )
    |> ManeuverReviewOperationalFeedback.from_rows()
  end

  def mission_state_maneuver_review_operational_feedback(mission_state) do
    mission_state
    |> ReviewSourceReports.maneuver_review_reports()
    |> ManeuverReviewOperationalFeedback.mission_state_source_rows()
    |> ManeuverReviewOperationalFeedback.from_rows()
  end

  def prior_plan_operator_review_source_operational_feedback(prior_plan) do
    prior_plan
    |> OperatorReviewSourceReports.prior_plan_operator_review_packages()
    |> OperatorReviewSourceReports.operational_feedback_rows()
    |> source_rows()
  end

  def mission_state_operator_review_source_operational_feedback(mission_state) do
    mission_state
    |> OperatorReviewSourceReports.operator_review_packages()
    |> OperatorReviewSourceReports.operational_feedback_rows()
    |> source_rows()
  end

  def prior_plan_operator_review_operational_feedback(prior_plan) do
    prior_plan
    |> OperatorReviewSourceReports.prior_plan_operator_review_packages()
    |> OperatorReviewSourceReports.rows()
    |> operator_review_rows_operational_feedback()
  end

  def mission_state_operator_review_operational_feedback(mission_state) do
    mission_state
    |> OperatorReviewSourceReports.operator_review_packages()
    |> OperatorReviewSourceReports.rows()
    |> operator_review_rows_operational_feedback()
  end

  def prior_plan_cadence_import_source_operational_feedback(prior_plan) do
    prior_plan
    |> CadenceImportSourceReports.prior_plan_cadence_import_manifests()
    |> CadenceImportSourceReports.operational_feedback_rows()
    |> source_rows()
  end

  def mission_state_cadence_import_source_operational_feedback(mission_state) do
    mission_state
    |> CadenceImportSourceReports.cadence_import_manifests()
    |> CadenceImportSourceReports.operational_feedback_rows()
    |> source_rows()
  end

  def prior_plan_cadence_import_operational_feedback(prior_plan) do
    prior_plan
    |> CadenceImportSourceReports.prior_plan_cadence_import_manifests()
    |> CadenceImportSourceReports.source_review_rows()
    |> operator_review_rows_operational_feedback()
  end

  def mission_state_cadence_import_operational_feedback(mission_state) do
    mission_state
    |> CadenceImportSourceReports.cadence_import_manifests()
    |> CadenceImportSourceReports.source_review_rows()
    |> operator_review_rows_operational_feedback()
  end

  def mission_state_timeline_feedback_report(mission_state) do
    mission_state
    |> ReviewSourceReports.timeline_feedback_reports()
    |> case do
      [{report, _source_path}] ->
        report

      reports when is_list(reports) and reports != [] ->
        BranchRefreshSourceInputs.merge_reports(reports)

      _reports ->
        %{}
    end
  end

  def prior_plan_operational_timeline_source_metadata(prior_plan) do
    OperationalTimelineSourceMetadata.prior_plan(
      prior_plan,
      operational_timeline_source_metadata_context()
    )
  end

  def mission_state_operational_timeline_source_metadata(mission_state) do
    OperationalTimelineSourceMetadata.mission_state(
      mission_state,
      operational_timeline_source_metadata_context()
    )
  end

  def prior_plan_planned_activity_source_metadata(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_planned_activity_rows_with_source()
    |> ActivitySourceMetadata.metadata("planned_activity.v1")
  end

  def mission_state_planned_activity_source_metadata(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_planned_activity_rows_with_source()
    |> ActivitySourceMetadata.metadata("planned_activity.v1")
  end

  def prior_plan_proposed_contact_source_metadata(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_proposed_contact_rows_with_source()
    |> ActivitySourceMetadata.metadata("proposed_contact.v1")
  end

  def mission_state_proposed_contact_source_metadata(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_proposed_contact_rows_with_source()
    |> ActivitySourceMetadata.metadata("proposed_contact.v1")
  end

  def prior_plan_realized_activity_source_metadata(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_realized_activity_rows_with_source()
    |> ActivitySourceMetadata.realized_metadata()
  end

  def mission_state_realized_activity_source_metadata(mission_state, prior_plan) do
    mission_state
    |> ActivitySourceRows.mission_state_realized_activity_rows_with_source(prior_plan)
    |> ActivitySourceMetadata.realized_metadata()
  end

  def prior_plan_command_window_source_metadata(prior_plan) do
    CommandWindowSourceMetadata.prior_plan(prior_plan, command_window_source_metadata_context())
  end

  def mission_state_command_window_source_metadata(mission_state) do
    CommandWindowSourceMetadata.mission_state(
      mission_state,
      command_window_source_metadata_context()
    )
  end

  def prior_plan_timeline_feedback_source_metadata(prior_plan) do
    TimelineFeedbackSourceMetadata.prior_plan(
      prior_plan,
      timeline_feedback_source_metadata_context()
    )
  end

  def mission_state_timeline_feedback_source_metadata(mission_state) do
    TimelineFeedbackSourceMetadata.mission_state(
      mission_state,
      timeline_feedback_source_metadata_context()
    )
  end

  def prior_plan_maneuver_review_source_metadata(prior_plan) do
    ManeuverReviewSourceMetadata.prior_plan(prior_plan, maneuver_review_source_metadata_context())
  end

  def mission_state_maneuver_review_source_metadata(mission_state) do
    ManeuverReviewSourceMetadata.mission_state(
      mission_state,
      maneuver_review_source_metadata_context()
    )
  end

  def prior_plan_operator_review_source_metadata(prior_plan) do
    prior_plan
    |> OperatorReviewSourceReports.prior_plan_operator_review_packages()
    |> OperatorReviewSourceReports.source_metadata_from_packages("operator_review_package.v1")
  end

  def mission_state_operator_review_source_metadata(mission_state) do
    mission_state
    |> OperatorReviewSourceReports.operator_review_packages()
    |> OperatorReviewSourceReports.source_metadata_from_packages("operator_review_package.v1")
  end

  def prior_plan_operator_review_source_operational_feedback_metadata(prior_plan) do
    prior_plan
    |> OperatorReviewSourceReports.prior_plan_operator_review_packages()
    |> OperatorReviewSourceReports.source_operational_feedback_metadata()
  end

  def mission_state_operator_review_source_operational_feedback_metadata(mission_state) do
    mission_state
    |> OperatorReviewSourceReports.operator_review_packages()
    |> OperatorReviewSourceReports.source_operational_feedback_metadata()
  end

  def prior_plan_cadence_import_source_review_metadata(prior_plan) do
    prior_plan
    |> CadenceImportSourceReports.prior_plan_cadence_import_manifests()
    |> CadenceImportSourceReports.source_review_metadata()
  end

  def mission_state_cadence_import_source_review_metadata(mission_state) do
    mission_state
    |> CadenceImportSourceReports.cadence_import_manifests()
    |> CadenceImportSourceReports.source_review_metadata()
  end

  def prior_plan_cadence_import_source_operational_feedback_metadata(prior_plan) do
    prior_plan
    |> CadenceImportSourceReports.prior_plan_cadence_import_manifests()
    |> CadenceImportSourceReports.source_operational_feedback_metadata()
  end

  def mission_state_cadence_import_source_operational_feedback_metadata(mission_state) do
    mission_state
    |> CadenceImportSourceReports.cadence_import_manifests()
    |> CadenceImportSourceReports.source_operational_feedback_metadata()
  end

  def prior_plan_cadence_import_all_operational_feedback_rows(prior_plan) do
    prior_plan
    |> CadenceImportSourceReports.prior_plan_cadence_import_manifests()
    |> CadenceImportSourceReports.all_operational_feedback_rows()
  end

  def mission_state_cadence_import_all_operational_feedback_rows(mission_state) do
    mission_state
    |> CadenceImportSourceReports.cadence_import_manifests()
    |> CadenceImportSourceReports.all_operational_feedback_rows()
  end

  def prior_plan_operator_review_all_operational_feedback_rows(prior_plan) do
    prior_plan
    |> OperatorReviewSourceReports.prior_plan_operator_review_packages()
    |> OperatorReviewSourceReports.all_operational_feedback_rows()
  end

  def mission_state_operator_review_all_operational_feedback_rows(mission_state) do
    mission_state
    |> OperatorReviewSourceReports.operator_review_packages()
    |> OperatorReviewSourceReports.all_operational_feedback_rows()
  end

  defp prior_plan_maneuver_review_report_rows(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_maneuver_review_direct_reports()
    |> Enum.flat_map(fn {report, _source_path} -> Map.get(report, "rows", []) end)
  end

  defp prior_plan_maneuver_review_source_rows(prior_plan) do
    ManeuverReviewOperationalFeedback.prior_plan_source_rows(
      prior_plan_maneuver_review_report_rows(prior_plan),
      prior_plan_result_artifact_maneuver_review_rows(prior_plan)
    )
  end

  defp mission_state_maneuver_review_source_rows(mission_state) do
    mission_state
    |> ReviewSourceReports.maneuver_review_reports()
    |> ManeuverReviewOperationalFeedback.mission_state_source_rows()
  end

  defp prior_plan_result_artifacts(prior_plan) do
    prior_plan
    |> BranchRefreshSourceInputs.result_artifacts_with_source("prior_plan")
    |> Enum.map(fn {artifact, _source_path} -> artifact end)
  end

  defp prior_plan_result_artifact_maneuver_review_rows(prior_plan) do
    prior_plan
    |> BranchRefreshSourceInputs.result_artifacts_with_source("prior_plan")
    |> Enum.flat_map(fn {artifact, source_path} ->
      ManeuverReviewResultArtifactRows.rows(artifact, source_path)
    end)
  end

  defp operational_timeline_source_metadata_context do
    [
      prior_plan_reports: &ReviewSourceReports.prior_plan_operational_timeline_reports/1,
      prior_plan_rows: &prior_plan_operational_timeline_rows/1,
      mission_state_reports: &ReviewSourceReports.operational_timeline_reports/1,
      mission_state_rows: &mission_state_operational_timeline_rows/1
    ]
  end

  defp command_window_source_metadata_context do
    [
      prior_plan_reports: &ReviewSourceReports.prior_plan_command_window_reports/1,
      prior_plan_rows: &prior_plan_command_window_rows/1,
      mission_state_reports: &ReviewSourceReports.command_window_reports/1,
      mission_state_rows: &mission_state_command_window_rows/1
    ]
  end

  defp timeline_feedback_source_metadata_context do
    [
      prior_plan_reports: &ReviewSourceReports.prior_plan_timeline_feedback_reports/1,
      mission_state_reports: &ReviewSourceReports.timeline_feedback_reports/1
    ]
  end

  defp maneuver_review_source_metadata_context do
    [
      prior_plan_reports: &ReviewSourceReports.prior_plan_maneuver_review_reports/1,
      prior_plan_source_rows: &prior_plan_maneuver_review_source_rows/1,
      prior_plan_result_artifacts: &prior_plan_result_artifacts/1,
      prior_plan_result_artifact_rows: &prior_plan_result_artifact_maneuver_review_rows/1,
      mission_state_reports: &ReviewSourceReports.maneuver_review_reports/1,
      mission_state_source_rows: &mission_state_maneuver_review_source_rows/1,
      feedback_row?: &ManeuverReviewFeedbackRows.feedback_row?/1
    ]
  end

  defp prior_plan_operational_timeline_rows(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_operational_timeline_reports()
    |> OperationalTimelineSourceRows.rows()
  end

  defp mission_state_operational_timeline_rows(mission_state) do
    mission_state
    |> ReviewSourceReports.operational_timeline_reports()
    |> OperationalTimelineSourceRows.rows()
  end

  defp prior_plan_command_window_rows(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_command_window_reports()
    |> CommandWindowOperationalFeedback.rows()
  end

  defp mission_state_command_window_rows(mission_state) do
    mission_state
    |> ReviewSourceReports.command_window_reports()
    |> CommandWindowOperationalFeedback.rows()
  end

  defp operator_review_rows_operational_feedback(rows) do
    OperatorReviewOperationalFeedback.from_rows(rows)
  end

  defp operational_timeline_rows_operational_feedback(rows) do
    rows
    |> Enum.map(&Map.put_new(&1, "review_type", "operational_timeline_review"))
    |> operator_review_rows_operational_feedback()
  end
end
