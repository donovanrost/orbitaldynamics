defmodule OrbitalDynamics.Schema.TimelineArtifactValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  alias OrbitalDynamics.Schema.{
    OperationalTimelineValidation,
    OperatorReviewValidation,
    TimelineCapabilityContext,
    TimelineTransitionValidation
  }

  @operational_timeline_report "operational_timeline_report.v1"

  def validate_optional_timeline_feedback_report(issues, _path, nil), do: issues

  def validate_optional_timeline_feedback_report(issues, path, %{} = report),
    do: validate(issues, path, report, "timeline_feedback_report.v1")

  def validate_optional_timeline_feedback_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_diff_report(issues, _path, nil), do: issues

  def validate_optional_timeline_diff_report(issues, path, %{} = report),
    do: validate(issues, path, report, "timeline_diff_report.v1")

  def validate_optional_timeline_diff_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_diff_summary(issues, _path, nil), do: issues

  def validate_optional_timeline_diff_summary(issues, path, %{} = summary),
    do: validate(issues, path, summary, "timeline_diff_summary.v1")

  def validate_optional_timeline_diff_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_dependency_impact_summary(issues, _path, nil), do: issues

  def validate_optional_timeline_dependency_impact_summary(issues, path, %{} = summary),
    do: validate(issues, path, summary, "timeline_dependency_impact_summary.v1")

  def validate_optional_timeline_dependency_impact_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_timeline_lifecycle_state_summary(issues, _path, nil), do: issues

  def validate_optional_timeline_lifecycle_state_summary(issues, path, %{} = summary),
    do: validate(issues, path, summary, "timeline_lifecycle_state_summary.v1")

  def validate_optional_timeline_lifecycle_state_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate(issues, path, artifact, @operational_timeline_report),
    do: OperationalTimelineValidation.validate_report(issues, path, artifact)

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "timeline_feedback_report.v1") do
    OrbitalDynamics.Schema.TimelineFeedbackReportContracts.validate(
      issues,
      path,
      artifact,
      TimelineCapabilityContext.timeline_feedback_report_model_limits(),
      fn acc, package ->
        OperatorReviewValidation.validate_optional_package_at(
          acc,
          path <> ".operator_review_package",
          package
        )
      end
    )
  end

  defp validate_artifact(issues, path, artifact, "timeline_diff_report.v1"),
    do:
      OrbitalDynamics.Schema.TimelineDiffReportContracts.validate(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_diff_summary.v1"),
    do:
      OrbitalDynamics.Schema.TimelineDiffSummaryContracts.validate(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_integrity_report.v1"),
    do:
      OrbitalDynamics.Schema.TimelineIntegrityReportContracts.validate(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_dependency_impact_summary.v1"),
    do:
      OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts.validate(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_publication_summary.v1"),
    do:
      OrbitalDynamics.Schema.TimelinePublicationSummaryContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "timeline_activity_state.v1"),
    do:
      OrbitalDynamics.Schema.TimelineActivityStateContracts.validate(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_feedback_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_activity_precondition_summary.v1"),
    do:
      OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts.validate(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_activity_status_state.v1"),
    do:
      OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_status_state(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_activity_approval_state.v1"),
    do:
      OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_approval_state(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_activity_lifecycle_state.v1"),
    do:
      OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_lifecycle_state(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_preservation_report.v1"),
    do:
      OrbitalDynamics.Schema.TimelinePreservationContracts.validate_report(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_preservation_status.v1"),
    do:
      OrbitalDynamics.Schema.TimelinePreservationContracts.validate_status(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_lifecycle_state_summary.v1"),
    do:
      OrbitalDynamics.Schema.TimelineLifecycleStateSummaryContracts.validate(
        issues,
        path,
        artifact,
        TimelineCapabilityContext.timeline_report_model_limits()
      )

  defp validate_artifact(issues, path, artifact, "timeline_transition_application_report.v1"),
    do:
      TimelineTransitionValidation.validate_timeline_transition_application_report(
        issues,
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "timeline_transition_application_summary.v1"),
    do:
      TimelineTransitionValidation.validate_timeline_transition_application_summary(
        issues,
        path,
        artifact
      )

  defp required_fields(contract_name) do
    registry_contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end

  defp registry_contracts do
    [
      OrbitalDynamics.Schema.TimelineActivityStateRegistryContracts,
      OrbitalDynamics.Schema.TimelineDiffRegistryContracts,
      OrbitalDynamics.Schema.TimelineFeedbackStateRegistryContracts,
      OrbitalDynamics.Schema.TimelineIntegrityRegistryContracts,
      OrbitalDynamics.Schema.TimelinePreservationRegistryContracts,
      OrbitalDynamics.Schema.TimelinePublicationRegistryContracts,
      OrbitalDynamics.Schema.TimelineTransitionRegistryContracts,
      OrbitalDynamics.Schema.OperationalTimelineRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
  end
end
