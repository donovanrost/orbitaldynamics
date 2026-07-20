defmodule OrbitalDynamics.OperationalReadiness.Capability do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperationalReadiness.ImportEligibilitySummary
  alias OrbitalDynamics.OperationalReadiness.OperationalModeDecision
  alias OrbitalDynamics.OperationalReadiness.QualityGateSchemaValidationSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateSummary

  @schema_contract "operational_readiness_report.v1"
  @gate_summary_schema_contract "operational_readiness_gate_summary.v1"
  @execution_boundary_summary_schema_contract "operational_execution_boundary_summary.v1"
  @quality_gate_schema_contract "quality_gate_report.v1"
  @quality_gate_unavailable_resource_summary_schema_contract "operational_quality_gate_unavailable_resource_summary.v1"
  @quality_gate_operator_training_summary_schema_contract "operational_quality_gate_operator_training_summary.v1"
  @quality_gate_import_readiness_summary_schema_contract "operational_quality_gate_import_readiness_summary.v1"
  @import_classifications ~w(importable review_only analysis_only blocked)
  @readiness_levels ~w(import_eligible operator_review analysis_only blocked)
  @gate_statuses ~w(passed review_required analysis_only blocked)
  @freshness_statuses ~w(current stale unknown)

  def build do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_operational_readiness_classifier,
      validation_level: :artifact_contract,
      import_eligibility_summary_artifact_contract: ImportEligibilitySummary.schema_contract(),
      gate_summary_artifact_contract: @gate_summary_schema_contract,
      execution_boundary_summary_artifact_contract: @execution_boundary_summary_schema_contract,
      quality_gate_summary_artifact_contract: QualityGateSummary.schema_contract(),
      quality_gate_unavailable_resource_summary_artifact_contract:
        @quality_gate_unavailable_resource_summary_schema_contract,
      quality_gate_operator_training_summary_artifact_contract:
        @quality_gate_operator_training_summary_schema_contract,
      quality_gate_schema_validation_summary_artifact_contract:
        QualityGateSchemaValidationSummary.schema_contract(),
      quality_gate_import_readiness_summary_artifact_contract:
        @quality_gate_import_readiness_summary_schema_contract,
      import_classifications: @import_classifications,
      readiness_levels: @readiness_levels,
      gate_statuses: @gate_statuses,
      freshness_statuses: @freshness_statuses,
      import_statuses: CadenceImport.capability().import_statuses,
      cadence_import_statuses: CadenceImport.capability().cadence_import_statuses,
      analysis_modes: OperationalModeDecision.analysis_modes(),
      analysis_mode_aliases: OperationalModeDecision.analysis_mode_aliases(),
      gates: [
        "source_contract",
        "operational_mode",
        "adapter_boundary",
        "mission_policy",
        "operator_training",
        "resource_availability",
        "operator_review",
        "cadence_import"
      ],
      readiness_helpers: [
        :report,
        :import_eligibility,
        :gate_summary,
        :execution_boundary_summary,
        :quality_gate_report,
        :quality_gate_summary,
        :quality_gate_unavailable_resource_summary,
        :quality_gate_operator_training_summary,
        :quality_gate_schema_validation_summary,
        :quality_gate_import_readiness_summary
      ],
      summary_semantics: [
        :import_eligibility_summary,
        :readiness_summary_row_derived_gate_counts,
        :gate_status_routing_id_sets,
        :gate_classification_routing_id_sets,
        :quality_gate_report_routing_id_sets,
        :quality_gate_report_row_derived_classification,
        :quality_gate_report_execution_boundary,
        :quality_gate_summary,
        :quality_gate_summary_row_derived_counts,
        :quality_gate_resource_availability_row_context,
        :quality_gate_unavailable_resource_summary,
        :quality_gate_unavailable_resource_routing_id_sets,
        :quality_gate_operator_training_summary,
        :quality_gate_operator_training_routing_id_sets,
        :quality_gate_schema_validation_summary,
        :quality_gate_schema_validation_routing_id_sets,
        :quality_gate_import_readiness_summary,
        :quality_gate_import_readiness_routing_id_sets,
        :quality_gate_import_readiness_freshness_status_values,
        :quality_gate_import_readiness_import_status_values,
        :quality_gate_import_readiness_cadence_import_status_values,
        :quality_gate_cadence_import_row_context,
        :resource_availability_quality_gate,
        :execution_boundary_summary
      ],
      readiness_evidence_semantics: [
        :readiness_review_and_import_row_counts,
        :readiness_review_status_count_maps,
        :readiness_import_status_count_maps,
        :readiness_timeline_publication_context,
        :readiness_freshness_status_count_maps,
        :readiness_schema_validation_status_and_issue_counts,
        :readiness_source_model_and_limit_count_maps,
        :readiness_mission_policy_classification_count_maps,
        :readiness_operator_training_requirement_count_maps,
        :readiness_adapter_boundary_status_count_maps,
        :readiness_adapter_boundary_untrusted_count_maps,
        :readiness_resource_availability_reason_count_maps,
        :readiness_resource_availability_reason_ids,
        :readiness_unavailable_resource_reason_ids,
        :readiness_station_availability_reason_count_maps
      ],
      quality_gate_row_semantics: [
        :quality_gate_status_and_classification_counts,
        :quality_gate_status_and_classification_id_sets,
        :quality_gate_adapter_boundary_status_counts,
        :quality_gate_operator_training_requirement_context,
        :quality_gate_resource_availability_reason_ids,
        :quality_gate_station_availability_reason_ids,
        :quality_gate_unavailable_resource_reason_ids,
        :quality_gate_resource_blocking_dimension_counts,
        :quality_gate_resource_blocked_contact_id_maps,
        :quality_gate_cadence_import_status_count_maps,
        :quality_gate_freshness_status_count_maps,
        :quality_gate_schema_validation_status_and_issue_counts,
        :quality_gate_timeline_publication_context
      ],
      public_facades: [
        :operational_readiness_report,
        :operational_import_eligibility,
        :operational_readiness_gate_summary,
        :operational_execution_boundary_summary,
        :operational_quality_gate_report,
        :operational_quality_gate_summary,
        :operational_quality_gate_unavailable_resource_summary,
        :operational_quality_gate_operator_training_summary,
        :operational_quality_gate_schema_validation_summary,
        :operational_quality_gate_import_readiness_summary
      ],
      quality_gate_contract: @quality_gate_schema_contract,
      handoff_artifacts: [
        "operator_review_package.v1",
        "cadence_import_manifest.v1"
      ],
      handoff_review_type: "operational_readiness_review",
      handoff_import_action: "review_operational_readiness",
      known_limits: [
        :artifact_only,
        :does_not_write_cadence,
        :does_not_approve_operator_actions,
        :does_not_execute_commands,
        :uses_declared_review_and_import_evidence
      ]
    }
  end
end
