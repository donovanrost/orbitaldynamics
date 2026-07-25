defmodule OrbitalDynamics.Schema.OperationalReadinessValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_artifact(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact_contract(path, artifact, contract_name)
  end

  def operational_readiness_model_limits do
    OrbitalDynamics.Schema.OperationalReadinessCapabilityContext.operational_readiness_model_limits()
  end

  def operational_readiness_gate_summary_model_limits do
    [
      "operational_readiness_gate_summary_routes_only",
      "operational_readiness_gate_summary_does_not_approve_or_import"
    ]
  end

  def operational_execution_boundary_summary_model_limits do
    [
      "operational_execution_boundary_summary_routes_only",
      "operational_execution_boundary_summary_does_not_execute_or_import"
    ]
  end

  def operational_import_eligibility_summary_model_limits do
    [
      "operational_import_eligibility_summary_routes_only",
      "operational_import_eligibility_summary_does_not_approve_or_import"
    ]
  end

  def quality_gate_report_model_limits do
    [
      "quality_gate_report_derives_classification_from_gate_rows",
      "quality_gate_report_does_not_approve_or_import"
    ]
  end

  def quality_gate_summary_model_limits do
    [
      "quality_gate_summary_derives_classification_from_gate_rows",
      "quality_gate_summary_does_not_approve_or_import"
    ]
  end

  def quality_gate_unavailable_resource_summary_model_limits do
    [
      "quality_gate_unavailable_resource_summary_routes_only",
      "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
    ]
  end

  def quality_gate_operator_training_summary_model_limits do
    [
      "quality_gate_operator_training_summary_routes_only",
      "quality_gate_operator_training_summary_does_not_approve_or_import"
    ]
  end

  def quality_gate_schema_validation_summary_model_limits do
    [
      "quality_gate_schema_validation_summary_routes_only",
      "quality_gate_schema_validation_summary_does_not_approve_or_import"
    ]
  end

  def quality_gate_import_readiness_summary_model_limits do
    [
      "quality_gate_import_readiness_summary_routes_only",
      "quality_gate_import_readiness_summary_does_not_approve_or_import"
    ]
  end

  def validate_optional_operational_readiness_report(issues, _path, nil), do: issues

  def validate_optional_operational_readiness_report(issues, path, %{} = report),
    do: validate_operational_readiness_report(issues, path, report)

  def validate_optional_operational_readiness_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_operational_import_eligibility_summary(issues, _path, nil),
    do: issues

  def validate_optional_operational_import_eligibility_summary(issues, path, %{} = summary),
    do: validate_operational_import_eligibility_summary(issues, path, summary)

  def validate_optional_operational_import_eligibility_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_operational_readiness_gate_summary(issues, _path, nil), do: issues

  def validate_optional_operational_readiness_gate_summary(issues, path, %{} = summary),
    do: validate_operational_readiness_gate_summary(issues, path, summary)

  def validate_optional_operational_readiness_gate_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_operational_execution_boundary_summary(issues, _path, nil),
    do: issues

  def validate_optional_operational_execution_boundary_summary(issues, path, %{} = summary),
    do: validate_operational_execution_boundary_summary(issues, path, summary)

  def validate_optional_operational_execution_boundary_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_operational_quality_gate_summary(issues, _path, nil), do: issues

  def validate_optional_operational_quality_gate_summary(issues, path, %{} = summary),
    do: validate_operational_quality_gate_summary(issues, path, summary)

  def validate_optional_operational_quality_gate_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  def validate_optional_operational_quality_gate_unavailable_resource_summary(
        issues,
        _path,
        nil
      ),
      do: issues

  def validate_optional_operational_quality_gate_unavailable_resource_summary(
        issues,
        path,
        %{} = summary
      ),
      do: validate_operational_quality_gate_unavailable_resource_summary(issues, path, summary)

  def validate_optional_operational_quality_gate_unavailable_resource_summary(
        issues,
        path,
        _summary
      ),
      do: [error(path, "must be an object") | issues]

  def validate_optional_quality_gate_report(issues, _path, nil), do: issues

  def validate_optional_quality_gate_report(issues, path, %{} = report),
    do: validate_quality_gate_report(issues, path, report)

  def validate_optional_quality_gate_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_operational_readiness_report(issues, path, report) do
    OrbitalDynamics.Schema.OperationalReadinessReportContracts.validate(
      issues,
      path,
      report,
      operational_readiness_model_limits(),
      &validate_operational_readiness_gate/3,
      &validate_operational_readiness_evidence/3
    )
  end

  def validate_operational_import_eligibility_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalImportEligibilitySummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_import_eligibility_summary_model_limits(),
      &validate_operational_readiness_gate/3
    )
  end

  def validate_operational_readiness_gate_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalReadinessGateSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_readiness_gate_summary_model_limits(),
      &validate_operational_readiness_gate/3
    )
  end

  def validate_operational_execution_boundary_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_execution_boundary_summary_model_limits(),
      &validate_operational_readiness_gate/3
    )
  end

  def validate_operational_readiness_gate(issues, path, gate) do
    OrbitalDynamics.Schema.OperationalReadinessGateContracts.validate(
      issues,
      path,
      gate,
      &OrbitalDynamics.Schema.CandidateRefreshReportContracts.validate_timeline_publication_context/3
    )
  end

  def validate_operational_readiness_evidence(issues, path, evidence) do
    OrbitalDynamics.Schema.OperationalReadinessEvidenceContracts.validate(
      issues,
      path,
      evidence,
      &validate_operational_readiness_resource_context/3,
      &OrbitalDynamics.Schema.CandidateRefreshReportContracts.validate_timeline_publication_context/3
    )
  end

  def validate_operational_quality_gate_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      quality_gate_summary_model_limits(),
      &validate_quality_gate_row/3
    )
  end

  def validate_operational_quality_gate_unavailable_resource_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateUnavailableResourceSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      quality_gate_unavailable_resource_summary_model_limits()
    )
  end

  def validate_operational_quality_gate_operator_training_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateOperatorTrainingSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      quality_gate_operator_training_summary_model_limits()
    )
  end

  def validate_operational_quality_gate_schema_validation_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateSchemaValidationSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      quality_gate_schema_validation_summary_model_limits()
    )
  end

  def validate_operational_quality_gate_import_readiness_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      quality_gate_import_readiness_summary_model_limits(),
      &OrbitalDynamics.Schema.CandidateRefreshReportContracts.validate_timeline_publication_context/3
    )
  end

  def validate_quality_gate_report(issues, path, report) do
    OrbitalDynamics.Schema.QualityGateReportContracts.validate_report(
      issues,
      path,
      report,
      quality_gate_report_model_limits(),
      &validate_quality_gate_row/3
    )
  end

  def validate_quality_gate_row(issues, path, row) do
    OrbitalDynamics.Schema.QualityGateRowContracts.validate(
      issues,
      path,
      row,
      &OrbitalDynamics.Schema.OperationalReadinessHandoffContracts.validate_gate_matches_source/3,
      &OrbitalDynamics.Schema.OperationalReadinessHandoffContracts.validate_report_matches_source/3,
      &OrbitalDynamics.Schema.CandidateRefreshReportContracts.validate_timeline_publication_context/3
    )
  end

  def validate_operational_readiness_resource_context(issues, path, row) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.validate_resource_context(
      issues,
      path,
      row
    )
  end

  def validate_operational_readiness_cadence_import_context(issues, path, row) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.validate_cadence_import_context(
      issues,
      path,
      row
    )
  end

  defp validate_artifact_contract(issues, path, artifact, "operational_readiness_report.v1"),
    do: validate_operational_readiness_report(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_import_eligibility_summary.v1"
       ),
       do: validate_operational_import_eligibility_summary(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_readiness_gate_summary.v1"
       ),
       do: validate_operational_readiness_gate_summary(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_execution_boundary_summary.v1"
       ),
       do: validate_operational_execution_boundary_summary(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_quality_gate_summary.v1"
       ),
       do: validate_operational_quality_gate_summary(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_quality_gate_unavailable_resource_summary.v1"
       ),
       do: validate_operational_quality_gate_unavailable_resource_summary(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_quality_gate_operator_training_summary.v1"
       ),
       do: validate_operational_quality_gate_operator_training_summary(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_quality_gate_schema_validation_summary.v1"
       ),
       do: validate_operational_quality_gate_schema_validation_summary(issues, path, artifact)

  defp validate_artifact_contract(
         issues,
         path,
         artifact,
         "operational_quality_gate_import_readiness_summary.v1"
       ),
       do: validate_operational_quality_gate_import_readiness_summary(issues, path, artifact)

  defp validate_artifact_contract(issues, path, artifact, "quality_gate_report.v1"),
    do: validate_quality_gate_report(issues, path, artifact)

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.OperationalReadinessRegistryContracts,
      OrbitalDynamics.Schema.OperationalQualityGateRegistryContracts,
      OrbitalDynamics.Schema.QualityGateRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
