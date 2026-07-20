defmodule OrbitalDynamics.Schema do
  @moduledoc """
  Executable schema contracts for public OrbitalDynamics artifacts.

  This module is intentionally lighter than full JSON Schema. It gives the
  current campaign-planning artifacts a stable, testable contract boundary while
  the artifact shapes are still maturing.
  """

  alias OrbitalDynamics.Schema.{SourceEvidenceValidation, TimelineContextJsonSchema}

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2]

  import OrbitalDynamics.Schema.CommandWindowCapabilityContext,
    only: [command_window_report_model_limits: 0]

  import OrbitalDynamics.Schema.CadenceImportCapabilityContext,
    only: [
      cadence_import_capability: 0,
      cadence_import_manifest_model_limits: 0,
      cadence_import_manifest_scalar_count_fields: 0
    ]

  import OrbitalDynamics.Schema.ContactFilterCapabilityContext,
    only: [
      contact_filter_report_assumptions_json_schema: 0,
      contact_filter_report_model_limits: 0,
      contact_filter_suppression_reasons: 0
    ]

  import OrbitalDynamics.Schema.ContactIntentCapabilityContext,
    only: [
      contact_intent_model_limits: 0,
      contact_intent_summary_assumptions_json_schema: 0
    ]

  import OrbitalDynamics.Schema.ContactAllocationCapabilityContext,
    only: [
      contact_allocation_capabilities: 0,
      contact_allocation_capacity_pack_summary_assumptions_json_schema: 0,
      contact_allocation_model_limits: 0,
      contact_allocation_provider_reservation_request_summary_assumptions_json_schema: 0,
      contact_allocation_reservation_conflict_summary_assumptions_json_schema: 0,
      contact_allocation_station_pressure_summary_assumptions_json_schema: 0,
      contact_allocation_summary_assumptions_json_schema: 0
    ]

  import OrbitalDynamics.Schema.ContactContentionCapabilityContext,
    only: [
      contact_contention_report_assumptions_json_schema: 0,
      contact_contention_report_model_limits: 0
    ]

  import OrbitalDynamics.Schema.LinkCapacityCapabilityContext,
    only: [link_capacity_assumptions_json_schema: 1]

  import OrbitalDynamics.Schema.ManeuverReviewCapabilityContext,
    only: [
      maneuver_recommendation_model_limits: 0,
      maneuver_review_report_model_limits: 0
    ]

  import OrbitalDynamics.Schema.OperatorReviewCapabilityContext,
    only: [
      operator_review_capabilities: 0,
      operator_review_package_model_limits: 0
    ]

  import OrbitalDynamics.Schema.OperationalReadinessCapabilityContext,
    only: [operational_readiness_capabilities: 0]

  import OrbitalDynamics.Schema.PolicyCapabilityContext,
    only: [policy_model_limits: 0]

  import OrbitalDynamics.Schema.ResourceFilterCapabilityContext,
    only: [
      resource_filter_report_assumptions_json_schema: 0,
      resource_filter_report_model_limits: 0,
      resource_filter_suppression_reasons: 0
    ]

  import OrbitalDynamics.Schema.StationCalendarCapabilityContext,
    only: [
      station_calendar_capabilities: 0,
      station_calendar_provider_counteroffer_actions: 0,
      station_calendar_provider_counteroffer_negotiation_states: 0,
      station_calendar_report_model: 0,
      station_calendar_report_model_limits: 0
    ]

  import OrbitalDynamics.Schema.TimelineCapabilityContext,
    only: [
      timeline_activity_precondition_statuses: 0,
      timeline_candidate_rejection_actions: 0,
      timeline_candidate_rejection_reasons: 0,
      timeline_capabilities: 0,
      timeline_feedback_capabilities: 0,
      timeline_feedback_report_model_limits: 0,
      timeline_integrity_issue_types: 0,
      timeline_report_model_limits: 0,
      timeline_required_operator_actions: 0,
      timeline_transition_decisions: 0
    ]

  import OrbitalDynamics.Schema.ValidationCapabilityContext,
    only: [
      model_acceptance_report_model_limits: 0,
      schema_migration_row_statuses: 0,
      schema_migration_statuses: 0
    ]

  @accepted_planning_state "accepted_planning_state.v1"
  @candidate_activity "candidate_activity.v1"
  @spacecraft_state_estimate "spacecraft_state_estimate.v1"
  @maneuver_execution_delta "maneuver_execution_delta.v1"
  @validation_record "validation_record.v1"
  @planned_activity "planned_activity.v1"
  @station_calendar_provider "station_calendar_provider.v1"
  @realized_activity "realized_activity.v1"
  @timeline_feedback_report "timeline_feedback_report.v1"
  @policy_decision "policy_decision.v1"
  @strategy_recommendation "strategy_recommendation.v1"
  @timeline_diff_summary "timeline_diff_summary.v1"
  @timeline_dependency_impact_summary "timeline_dependency_impact_summary.v1"
  @timeline_publication_summary "timeline_publication_summary.v1"
  @timeline_activity_precondition_summary "timeline_activity_precondition_summary.v1"
  @timeline_preservation_report "timeline_preservation_report.v1"
  @timeline_preservation_status "timeline_preservation_status.v1"
  @timeline_transition_application_summary "timeline_transition_application_summary.v1"
  @constraint_report "constraint_report.v1"
  @environment_model_capability "environment_model_capability.v1"
  @environment_provider_capability "environment_provider_capability.v1"
  @subsystem_model_capability "subsystem_model_capability.v1"
  @schema_validation_report "schema_validation_report.v1"
  @schema_validation_batch_report "schema_validation_batch_report.v1"
  @schema_migration_report "schema_migration_report.v1"

  @json_schema_draft "https://json-schema.org/draft/2020-12/schema"
  @stable_id_pattern OrbitalDynamics.Schema.StableIdValidation.pattern()
  @sha256_pattern "^[0-9a-f]{64}$"
  @field_type_hints OrbitalDynamics.Schema.FieldTypeHints.all()

  @contracts OrbitalDynamics.Schema.RegistryCatalog.contracts()

  @doc """
  Returns the known executable artifact contracts.
  """
  def contracts, do: OrbitalDynamics.Schema.Registry.all(@contracts)

  @doc """
  Returns public capability metadata for the executable artifact registry.
  """
  def capabilities do
    OrbitalDynamics.Schema.RegistryCapability.build(
      OrbitalDynamics.Schema.Registry.all(@contracts),
      json_schema_draft: @json_schema_draft,
      compatibility_policy: compatibility_policy(),
      identity_policy: identity_policy(),
      validation_report_contracts: [
        @schema_validation_report,
        @schema_validation_batch_report,
        @schema_migration_report
      ]
    )
  end

  @doc """
  Returns the schema export compatibility policy.

  The current JSON Schema documents are top-level compatibility exports. Nested
  and semantic checks remain in the executable Elixir validators, so published
  contract compatibility is evaluated against required fields, their coarse
  exported types, and schema contract/version identifiers.
  """
  def compatibility_policy, do: OrbitalDynamics.Schema.ExportPolicy.compatibility_policy()

  @doc """
  Returns the stable identity policy for public artifact IDs.
  """
  def identity_policy, do: OrbitalDynamics.Schema.ExportPolicy.identity_policy(@stable_id_pattern)

  @doc """
  Returns one known contract by name.
  """
  def contract(name) when is_binary(name),
    do: OrbitalDynamics.Schema.Registry.fetch(@contracts, name)

  @doc """
  Exports one executable contract as a machine-readable JSON Schema document.

  The generated schema is intentionally a top-level compatibility contract. The
  Elixir validators remain the source of truth for nested rows and semantic
  checks while artifact shapes are still maturing.
  """
  def json_schema(@candidate_activity) do
    {:ok,
     OrbitalDynamics.Schema.JsonDocument.candidate_activity(
       candidate_activity_json_schema(),
       @candidate_activity,
       json_schema_draft: @json_schema_draft,
       compatibility_policy: compatibility_policy(),
       identity_policy: identity_policy()
     )}
  end

  def json_schema(name) when is_binary(name) do
    with {:ok, contract} <- contract(name) do
      {:ok, json_schema_document(name, contract)}
    end
  end

  @doc """
  Exports all executable contracts as a deterministic registry bundle.
  """
  def json_schema_bundle do
    OrbitalDynamics.Schema.JsonExport.bundle(
      OrbitalDynamics.Schema.Registry.all(@contracts),
      [
        json_schema_draft: @json_schema_draft,
        compatibility_policy: compatibility_policy(),
        identity_policy: identity_policy()
      ],
      &json_schema/1
    )
  end

  @doc """
  Writes one exported JSON Schema document to disk.
  """
  def write_json_schema!(name, path) when is_binary(name) and is_binary(path) do
    OrbitalDynamics.Schema.JsonExport.write_schema!(name, path, &json_schema/1)
  end

  @doc """
  Writes the exported JSON Schema registry bundle to disk.
  """
  def write_json_schema_bundle!(path) when is_binary(path) do
    OrbitalDynamics.Schema.JsonExport.write_bundle!(json_schema_bundle(), path)
  end

  @doc """
  Writes every exported contract schema to a directory.
  """
  def write_json_schema_files!(directory) when is_binary(directory) do
    OrbitalDynamics.Schema.JsonExport.write_files!(
      OrbitalDynamics.Schema.Registry.all(@contracts),
      directory,
      &json_schema/1
    )
  end

  @doc """
  Declares the model limits for schema validation reports.
  """
  def schema_validation_model_limits, do: OrbitalDynamics.Schema.RegistryCapability.model_limits()

  @doc """
  Validates an artifact map against the inferred or requested contract.

  Returns `{:ok, report}` when the artifact satisfies the contract and
  `{:error, report}` otherwise. Reports are JSON-serializable maps.
  """
  def validate_artifact(%{} = artifact, opts \\ []) do
    OrbitalDynamics.Schema.ArtifactValidation.validate(artifact, opts, contracts(),
      contract: &contract/1,
      error: &error/2,
      validate_contract: &OrbitalDynamics.Schema.ArtifactValidationRouter.validate/3
    )
  end

  @doc """
  Wraps artifact validation in a `schema_validation_report.v1` artifact.
  """
  def validation_report(%{} = artifact, opts \\ []) do
    OrbitalDynamics.Schema.Report.validation_report_for_artifact(
      artifact,
      opts,
      &validate_artifact/2,
      schema_contract: @schema_validation_report,
      model_limits: schema_validation_model_limits()
    )
  end

  @doc """
  Validates a JSON artifact file.

  If the file is a study result artifact with an embedded `campaign_plan`, the
  nested campaign artifact is validated by default.
  """
  def lint_file(path, opts \\ []) when is_binary(path) do
    OrbitalDynamics.Schema.FileLint.lint_file(path, opts, &validate_artifact/2)
  end

  @doc """
  Validates a JSON artifact file and returns `schema_validation_report.v1`.
  """
  def lint_file_report(path, opts \\ []) when is_binary(path) do
    OrbitalDynamics.Schema.FileLint.lint_file_report(path, opts, &validation_report/2)
  end

  defp json_schema_document(name, contract) do
    property_context = json_schema_property_context()

    attrs = [
      json_schema_draft: @json_schema_draft,
      compatibility_policy: compatibility_policy(),
      identity_policy: identity_policy(),
      contract_fun: &contract/1,
      property_fun: fn field, contract_name, contract ->
        OrbitalDynamics.Schema.JsonSchemaPropertyRouter.property(
          field,
          contract_name,
          contract,
          property_context
        )
      end,
      stable_id_pattern: @stable_id_pattern,
      constraint_report_model_limits_by_model_fun:
        &OrbitalDynamics.Schema.ConstraintReportContracts.model_limits_by_model/0,
      validation_record_registry_conditions_fun: &validation_record_registry_conditions/0,
      accepted_planning_state: @accepted_planning_state,
      constraint_report: @constraint_report,
      environment_model_capability: @environment_model_capability,
      environment_provider_capability: @environment_provider_capability,
      maneuver_execution_delta: @maneuver_execution_delta,
      planned_activity: @planned_activity,
      realized_activity: @realized_activity,
      spacecraft_state_estimate: @spacecraft_state_estimate,
      station_calendar_provider: @station_calendar_provider,
      subsystem_model_capability: @subsystem_model_capability,
      validation_record: @validation_record
    ]

    OrbitalDynamics.Schema.JsonDocument.build_from_attrs(name, contract, attrs)
  end

  defp registry_contract!(name), do: OrbitalDynamics.Schema.Registry.fetch!(@contracts, name)

  defp timeline_preservation_assumptions_json_schema(@timeline_preservation_report) do
    OrbitalDynamics.Schema.CommonJsonSchema.string_const_assumptions(%{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "lifecycle_lock_approval_and_executed_preservation_review"
    })
  end

  defp timeline_preservation_assumptions_json_schema(@timeline_preservation_status) do
    OrbitalDynamics.Schema.CommonJsonSchema.string_const_assumptions(%{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "single_activity_lifecycle_preservation_preflight"
    })
  end

  defp json_schema_property_context do
    [
      field_type_hints: @field_type_hints,
      stable_id_pattern: @stable_id_pattern,
      schema_providers: %{
        {:activity_context_json_schema, 0} => &activity_context_json_schema/0,
        {:approval_requirement_json_schema, 0} => &approval_requirement_json_schema/0,
        {:cadence_import_capability, 0} => &cadence_import_capability/0,
        {:cadence_import_json_schema, 1} => &cadence_import_json_schema/1,
        {:cadence_import_manifest_model_limits, 0} => &cadence_import_manifest_model_limits/0,
        {:cadence_import_manifest_row_json_schema, 0} =>
          &cadence_import_manifest_row_json_schema/0,
        {:cadence_import_manifest_scalar_count_fields, 0} =>
          &cadence_import_manifest_scalar_count_fields/0,
        {:campaign_activity_json_schema, 0} => &campaign_activity_json_schema/0,
        {:candidate_activity_json_schema, 0} => &candidate_activity_json_schema/0,
        {:candidate_activity_source_window_json_schema, 0} =>
          &candidate_activity_source_window_json_schema/0,
        {:command_window_report_model_limits, 0} => &command_window_report_model_limits/0,
        {:contact_allocation_capabilities, 0} => &contact_allocation_capabilities/0,
        {:contact_allocation_capacity_pack_summary_assumptions_json_schema, 0} =>
          &contact_allocation_capacity_pack_summary_assumptions_json_schema/0,
        {:contact_allocation_model_limits, 0} => &contact_allocation_model_limits/0,
        {:contact_allocation_provider_reservation_request_summary_assumptions_json_schema, 0} =>
          &contact_allocation_provider_reservation_request_summary_assumptions_json_schema/0,
        {:contact_allocation_reservation_conflict_summary_assumptions_json_schema, 0} =>
          &contact_allocation_reservation_conflict_summary_assumptions_json_schema/0,
        {:contact_allocation_station_pressure_summary_assumptions_json_schema, 0} =>
          &contact_allocation_station_pressure_summary_assumptions_json_schema/0,
        {:contact_allocation_summary_assumptions_json_schema, 0} =>
          &contact_allocation_summary_assumptions_json_schema/0,
        {:contact_contention_report_assumptions_json_schema, 0} =>
          &contact_contention_report_assumptions_json_schema/0,
        {:contact_contention_report_model_limits, 0} => &contact_contention_report_model_limits/0,
        {:contact_filter_report_assumptions_json_schema, 0} =>
          &contact_filter_report_assumptions_json_schema/0,
        {:contact_filter_report_model_limits, 0} => &contact_filter_report_model_limits/0,
        {:contact_intent_model_limits, 0} => &contact_intent_model_limits/0,
        {:contact_intent_summary_assumptions_json_schema, 0} =>
          &contact_intent_summary_assumptions_json_schema/0,
        {:execution_uncertainty_json_schema, 0} => &execution_uncertainty_json_schema/0,
        {:ground_station_identity_json_schema, 0} => &ground_station_identity_json_schema/0,
        {:link_capacity_assumptions_json_schema, 1} => &link_capacity_assumptions_json_schema/1,
        {:maneuver_recommendation_model_limits, 0} => &maneuver_recommendation_model_limits/0,
        {:maneuver_review_report_model_limits, 0} => &maneuver_review_report_model_limits/0,
        {:model_acceptance_report_model_limits, 0} => &model_acceptance_report_model_limits/0,
        {:nested_stable_id_array_map_json_schema, 0} => &nested_stable_id_array_map_json_schema/0,
        {:operational_readiness_capabilities, 0} => &operational_readiness_capabilities/0,
        {:operational_readiness_evidence_json_schema, 0} =>
          &operational_readiness_evidence_json_schema/0,
        {:operational_readiness_gate_json_schema, 0} => &operational_readiness_gate_json_schema/0,
        {:operational_timeline_row_json_schema, 0} => &operational_timeline_row_json_schema/0,
        {:operator_review_capabilities, 0} => &operator_review_capabilities/0,
        {:operator_review_package_model_limits, 0} => &operator_review_package_model_limits/0,
        {:planned_activity_json_schema, 0} => &planned_activity_json_schema/0,
        {:policy_action_rule_json_schema, 0} => &policy_action_rule_json_schema/0,
        {:policy_decision_json_schema, 0} => &policy_decision_json_schema/0,
        {:policy_decision_rule_match_json_schema, 0} => &policy_decision_rule_match_json_schema/0,
        {:policy_escalation_json_schema, 0} => &policy_escalation_json_schema/0,
        {:policy_model_limits, 0} => &policy_model_limits/0,
        {:protection_decision_json_schema, 0} => &protection_decision_json_schema/0,
        {:quality_gate_report_row_json_schema, 0} => &quality_gate_report_row_json_schema/0,
        {:realized_activity_json_schema, 0} => &realized_activity_json_schema/0,
        {:registry_contract!, 1} => &registry_contract!/1,
        {:resource_filter_report_assumptions_json_schema, 0} =>
          &resource_filter_report_assumptions_json_schema/0,
        {:resource_filter_report_model_limits, 0} => &resource_filter_report_model_limits/0,
        {:schema_migration_row_statuses, 0} => &schema_migration_row_statuses/0,
        {:schema_migration_statuses, 0} => &schema_migration_statuses/0,
        {:schema_validation_model_limits, 0} => &schema_validation_model_limits/0,
        {:scoped_downlink_context_json_schema_properties, 0} =>
          &scoped_downlink_context_json_schema_properties/0,
        {:sha256_json_schema, 0} => &sha256_json_schema/0,
        {:spacecraft_identity_json_schema, 0} => &spacecraft_identity_json_schema/0,
        {:stable_id_array_map_schema, 0} => &stable_id_array_map_schema/0,
        {:stable_id_array_schema, 0} => &stable_id_array_schema/0,
        {:station_calendar_provider_counteroffer_actions, 0} =>
          &station_calendar_provider_counteroffer_actions/0,
        {:station_calendar_report_model, 0} => &station_calendar_report_model/0,
        {:station_calendar_report_model_limits, 0} => &station_calendar_report_model_limits/0,
        {:target_identity_json_schema, 0} => &target_identity_json_schema/0,
        {:timeline_activity_precondition_statuses, 0} =>
          &timeline_activity_precondition_statuses/0,
        {:timeline_candidate_rejection_actions, 0} => &timeline_candidate_rejection_actions/0,
        {:timeline_candidate_rejection_reasons, 0} => &timeline_candidate_rejection_reasons/0,
        {:timeline_capabilities, 0} => &timeline_capabilities/0,
        {:timeline_dependency_impact_row_json_schema, 0} =>
          &timeline_dependency_impact_row_json_schema/0,
        {:timeline_dependency_impact_summary_source_json_schema, 0} =>
          &timeline_dependency_impact_summary_source_json_schema/0,
        {:timeline_diff_row_json_schema, 0} => &timeline_diff_row_json_schema/0,
        {:timeline_diff_summary_source_json_schema, 0} =>
          &timeline_diff_summary_source_json_schema/0,
        {:timeline_feedback_capabilities, 0} => &timeline_feedback_capabilities/0,
        {:timeline_feedback_report_model_limits, 0} => &timeline_feedback_report_model_limits/0,
        {:timeline_identity_json_schema, 0} => &timeline_identity_json_schema/0,
        {:timeline_integrity_issue_types, 0} => &timeline_integrity_issue_types/0,
        {:timeline_precondition_json_schema, 0} => &timeline_precondition_json_schema/0,
        {:timeline_preservation_assumptions_json_schema, 1} =>
          &timeline_preservation_assumptions_json_schema/1,
        {:timeline_report_model_limits, 0} => &timeline_report_model_limits/0,
        {:timeline_transition_application_row_json_schema, 0} =>
          &timeline_transition_application_row_json_schema/0,
        {:timeline_transition_decisions, 0} => &timeline_transition_decisions/0
      }
    ]
    |> Keyword.update!(:schema_providers, fn providers ->
      providers
      |> Map.merge(
        OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders.build(@stable_id_pattern)
      )
      |> Map.merge(
        OrbitalDynamics.Schema.ValidationSchemaProviders.build(
          @stable_id_pattern,
          validation_report_schema: fn ->
            json_schema_document(
              @schema_validation_report,
              registry_contract!(@schema_validation_report)
            )
          end
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.StationCalendarSchemaProviders.build(
          @stable_id_pattern,
          provider_counteroffer_negotiation_states:
            &station_calendar_provider_counteroffer_negotiation_states/0,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
          policy_decision_schema: &policy_decision_json_schema/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.ExecutionStateSchemaProviders.build(
          @stable_id_pattern,
          planned_activity_schema: &planned_activity_json_schema/0,
          realized_activity_schema: &realized_activity_json_schema/0,
          timeline_link_schema: &timeline_link_json_schema/0,
          activity_context_schema: &activity_context_json_schema/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.ResourcePlanningSchemaProviders.build(
          @stable_id_pattern,
          source_window_schema: &candidate_activity_source_window_json_schema/0,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
          policy_decision_schema: &policy_decision_json_schema/0,
          contact_filter_suppression_reasons: &contact_filter_suppression_reasons/0,
          resource_filter_suppression_reasons: &resource_filter_suppression_reasons/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.build(
          @stable_id_pattern,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
          policy_decision_schema: &policy_decision_json_schema/0,
          station_calendar_capability: &station_calendar_capabilities/0
        )
      )
      |> Map.merge(OrbitalDynamics.Schema.CandidateDiffSchemaProviders.build(@stable_id_pattern))
      |> Map.merge(
        OrbitalDynamics.Schema.ContactPlanningSchemaProviders.build(
          @stable_id_pattern,
          timeline_identity_schema: &timeline_identity_json_schema/0,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
          contact_intent_model_limits: &contact_intent_model_limits/0,
          policy_decision_schema: &policy_decision_json_schema/0,
          source_window_schema: &candidate_activity_source_window_json_schema/0,
          cadence_import_schema: &cadence_import_json_schema/1
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.StrategySchemaProviders.build(
          @stable_id_pattern,
          scoped_downlink_context_properties: &scoped_downlink_context_json_schema_properties/0,
          strategy_recommendation_schema: fn ->
            @strategy_recommendation
            |> json_schema_document(registry_contract!(@strategy_recommendation))
            |> Map.take(["type", "additionalProperties", "required", "properties"])
          end,
          provider_counteroffer_negotiation_states:
            &station_calendar_provider_counteroffer_negotiation_states/0,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
          policy_decision_schema: &policy_decision_json_schema/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.TimelineFeedbackSchemaProviders.build(
          @stable_id_pattern,
          @timeline_feedback_report,
          realized_activity_schema: &realized_activity_json_schema/0,
          timeline_feedback_capability: &timeline_feedback_capabilities/0,
          protection_decision_schema: &protection_decision_json_schema/0,
          timeline_identity_schema: &timeline_identity_json_schema/0,
          activity_context_schema: &activity_context_json_schema/0,
          planned_activity_schema: &planned_activity_json_schema/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.ExecutionReviewSchemaProviders.build(
          @stable_id_pattern,
          activity_context_schema: &activity_context_json_schema/0,
          policy_decision_schema: &policy_decision_json_schema/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.TimelineEdgeSchemaProviders.build(
          @stable_id_pattern,
          campaign_activity_schema: &campaign_activity_json_schema/0,
          timeline_capability: &timeline_capabilities/0,
          activity_context_schema: &activity_context_json_schema/0,
          timeline_report_model_limits: &timeline_report_model_limits/0,
          timeline_transition_decisions: &timeline_transition_decisions/0,
          protection_decision_schema: &protection_decision_json_schema/0,
          timeline_identity_schema: &timeline_identity_json_schema/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.OperatorReviewSchemaProviders.build(
          @stable_id_pattern,
          operator_review_capability: &operator_review_capabilities/0,
          readiness_capability: &operational_readiness_capabilities/0,
          timeline_capability: &timeline_capabilities/0,
          activity_context_schema: &activity_context_json_schema/0,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          candidate_activity_source_window_schema:
            &candidate_activity_source_window_json_schema/0,
          operational_readiness_evidence_schema: &operational_readiness_evidence_json_schema/0,
          operational_readiness_gate_schema: &operational_readiness_gate_json_schema/0,
          operational_readiness_source_report_evidence_schema:
            &operational_readiness_source_report_evidence_json_schema/0,
          operational_timeline_row_schema: &operational_timeline_row_json_schema/0,
          policy_decision_evidence_schema: &policy_decision_evidence_json_schema/0,
          policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
          policy_escalation_schema: &policy_escalation_json_schema/0,
          protection_decision_schema: &protection_decision_json_schema/0,
          quality_gate_report_row_schema: &quality_gate_report_row_json_schema/0,
          quality_gate_source_report_evidence_schema:
            &quality_gate_source_report_evidence_json_schema/0,
          source_evidence_schema: &source_evidence_json_schema/0,
          timeline_activity_precondition_summary_source_schema:
            &timeline_activity_precondition_summary_source_json_schema/0,
          timeline_activity_state_source_schema: &timeline_activity_state_source_json_schema/0,
          timeline_diff_summary_source_schema: &timeline_diff_summary_source_json_schema/0,
          timeline_identity_schema: &timeline_identity_json_schema/0,
          timeline_lifecycle_state_source_schema: &timeline_lifecycle_state_source_json_schema/0,
          timeline_link_schema: &timeline_link_json_schema/0,
          timeline_preservation_source_schema: &timeline_preservation_source_json_schema/0,
          timeline_protection_summary_schema: &timeline_protection_summary_json_schema/0,
          timeline_transition_application_row_schema:
            &timeline_transition_application_row_json_schema/0,
          timeline_transition_application_summary_source_schema:
            &timeline_transition_application_summary_source_json_schema/0,
          feedback_maneuver_handoff_properties:
            &feedback_maneuver_handoff_json_schema_properties/0,
          link_handoff_properties: &link_handoff_json_schema_properties/0,
          resource_projection_battery_handoff_properties:
            &resource_projection_battery_handoff_json_schema_properties/0,
          scoped_downlink_context_properties: &scoped_downlink_context_json_schema_properties/0,
          thermal_handoff_properties: &thermal_handoff_json_schema_properties/0,
          timeline_activity_precondition_handoff_properties:
            &timeline_activity_precondition_handoff_json_schema_properties/0,
          timeline_dependency_impact_handoff_properties:
            &timeline_dependency_impact_handoff_json_schema_properties/0,
          timeline_publication_handoff_properties:
            &timeline_publication_handoff_json_schema_properties/0
        )
      )
    end)
  end

  defp default_json_schema_property(field, contract_name, contract) do
    OrbitalDynamics.Schema.JsonSchemaPropertySupport.default_property(
      field,
      contract_name,
      contract,
      @field_type_hints,
      @stable_id_pattern
    )
  end

  defp policy_decision_json_schema do
    @policy_decision
    |> json_schema_document(registry_contract!(@policy_decision))
    |> Map.take(["type", "additionalProperties", "required", "properties"])
  end

  defp policy_decision_evidence_json_schema do
    OrbitalDynamics.Schema.PolicyDecisionJsonSchema.evidence(
      stable_id_pattern: @stable_id_pattern,
      policy_escalation_schema: policy_escalation_json_schema()
    )
  end

  defp source_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.source_evidence(source_evidence_schema_deps())
  end

  defp operational_readiness_source_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.operational_readiness_source_report(
      source_evidence_schema_deps()
    )
  end

  defp quality_gate_source_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.quality_gate_source_report(
      quality_gate_source_report_schema_deps()
    )
  end

  defp source_freshness_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.freshness_report(
      source_evidence_schema_deps(),
      SourceEvidenceValidation.freshness_statuses()
    )
  end

  defp source_schema_validation_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.schema_validation_report(
      source_evidence_schema_deps(),
      SourceEvidenceValidation.schema_validation_statuses()
    )
  end

  defp source_execution_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.execution_report(
      source_evidence_schema_deps(),
      OrbitalDynamics.Schema.ExecutionReportContracts.statuses()
    )
  end

  defp source_evidence_schema_deps do
    %{
      stable_id_pattern: @stable_id_pattern,
      battery_handoff_properties: resource_projection_battery_handoff_json_schema_properties()
    }
  end

  defp quality_gate_source_report_schema_deps do
    source_evidence_schema_deps()
    |> Map.merge(%{
      count_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      stable_id_array_map_schema: stable_id_array_map_schema()
    })
  end

  defp policy_action_rule_json_schema do
    action_rule_fields = OrbitalDynamics.Schema.PolicyFieldGroups.action_rule()

    OrbitalDynamics.Schema.PolicyActionRuleJsonSchema.action_rule(
      stable_id_pattern: @stable_id_pattern,
      policy_context_fields: OrbitalDynamics.Schema.PolicyFieldGroups.json_schema(),
      number_fields: Keyword.fetch!(action_rule_fields, :number_fields),
      integer_fields: Keyword.fetch!(action_rule_fields, :integer_fields)
    )
  end

  defp policy_decision_rule_match_json_schema do
    OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema.rule_match_from_context(
      stable_id_pattern: @stable_id_pattern,
      policy_context_fields: OrbitalDynamics.Schema.PolicyFieldGroups.json_schema()
    )
  end

  defp policy_escalation_json_schema do
    OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema.escalation_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp scoped_downlink_context_json_schema_properties do
    OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema.scoped_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp sha256_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.sha256(@sha256_pattern)
  end

  defp stable_id_array_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(@stable_id_pattern)
  end

  defp stable_id_array_map_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array_map(@stable_id_pattern)
  end

  defp nested_stable_id_array_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.nested_stable_id_array_map(@stable_id_pattern)
  end

  defp candidate_activity_json_schema do
    OrbitalDynamics.Schema.CandidateActivityJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      source_window_schema: &candidate_activity_source_window_json_schema/0,
      probability_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp campaign_activity_json_schema do
    candidate_activity_json_schema()
  end

  defp planned_activity_json_schema do
    OrbitalDynamics.Schema.PlannedActivityJsonSchema.schema(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability(),
      source_window_schema: candidate_activity_source_window_json_schema(),
      timeline_identity_schema: timeline_identity_json_schema(),
      cadence_import_schema: cadence_import_json_schema("planned_activity.v1"),
      execution_uncertainty_schema: execution_uncertainty_json_schema()
    )
  end

  defp approval_requirement_json_schema do
    OrbitalDynamics.Schema.ApprovalRequirementJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      rule_match_schema: &policy_decision_rule_match_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      policy_escalation_schema: &policy_escalation_json_schema/0
    )
  end

  defp realized_activity_json_schema do
    OrbitalDynamics.Schema.RealizedActivityJsonSchema.schema(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability(),
      number_or_string_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_or_string(),
      execution_uncertainty_schema: execution_uncertainty_json_schema(),
      ground_station_schema: ground_station_identity_json_schema(),
      spacecraft_schema: spacecraft_identity_json_schema(),
      target_schema: target_identity_json_schema()
    )
  end

  defp target_identity_json_schema do
    OrbitalDynamics.Schema.IdentityJsonSchema.target_from_context(@stable_id_pattern)
  end

  defp ground_station_identity_json_schema do
    OrbitalDynamics.Schema.IdentityJsonSchema.ground_station_from_context(@stable_id_pattern)
  end

  defp spacecraft_identity_json_schema do
    OrbitalDynamics.Schema.IdentityJsonSchema.spacecraft_from_context(@stable_id_pattern)
  end

  defp validation_record_registry_conditions do
    OrbitalDynamics.Schema.ValidationJsonSchema.registry_conditions(@stable_id_pattern)
  end

  defp timeline_identity_json_schema,
    do: TimelineContextJsonSchema.timeline_identity(@stable_id_pattern)

  defp execution_uncertainty_json_schema,
    do:
      TimelineContextJsonSchema.execution_uncertainty(
        OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet()
      )

  defp protection_decision_json_schema,
    do: TimelineContextJsonSchema.protection_decision(@stable_id_pattern)

  defp timeline_preservation_source_json_schema do
    OrbitalDynamics.Schema.TimelinePreservationJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp timeline_link_json_schema,
    do: TimelineContextJsonSchema.timeline_link(@stable_id_pattern)

  defp timeline_protection_summary_json_schema,
    do: TimelineContextJsonSchema.timeline_protection_summary(stable_id_array_schema())

  defp activity_context_json_schema,
    do:
      TimelineContextJsonSchema.activity_context(
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: stable_id_array_schema(),
        string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
        number_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_array(),
        numeric_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_map(),
        candidate_activity_source_window_schema: candidate_activity_source_window_json_schema(),
        numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
        probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
      )

  defp candidate_activity_source_window_json_schema do
    OrbitalDynamics.Schema.CandidateActivityJsonSchema.source_window_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp cadence_import_json_schema(schema_contract) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["external_id", "activity_type"],
      "properties" => %{
        "external_id" => %{"type" => "string", "pattern" => @stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "schema_contract" => %{"type" => "string", "const" => schema_contract}
      }
    }
  end

  defp operational_timeline_row_json_schema do
    OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.row_from_context(
      capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      timeline_precondition_schema: &timeline_precondition_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      timeline_integrity_issue_schema: &timeline_integrity_issue_json_schema/0
    )
  end

  defp candidate_rejection_source_json_schema do
    OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_capability: &timeline_capabilities/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp timeline_precondition_json_schema do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.precondition_from_context(
      capability: &timeline_capabilities/0
    )
  end

  defp timeline_integrity_issue_json_schema do
    OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.integrity_issue_from_context(
      capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp timeline_diff_row_json_schema do
    OrbitalDynamics.Schema.TimelineDiffReportJsonSchema.row_from_context(
      capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      protection_decision_schema: &protection_decision_json_schema/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp timeline_lifecycle_state_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      transition_decisions: &timeline_transition_decisions/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      activity_context_schema: &activity_context_json_schema/0,
      protection_decision_schema: &lifecycle_state_source_protection_decision_json_schema/0
    )
  end

  defp timeline_activity_state_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityStateJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      protection_decision_schema: &protection_decision_json_schema/0
    )
  end

  defp timeline_activity_precondition_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryJsonSchema.summary_source_from_context(
      @timeline_activity_precondition_summary,
      registry_contract!(@timeline_activity_precondition_summary),
      [
        model_limits: &timeline_report_model_limits/0,
        precondition_statuses: &timeline_activity_precondition_statuses/0,
        string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        precondition_schema: &timeline_precondition_json_schema/0,
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0
      ],
      &default_json_schema_property/3
    )
  end

  defp lifecycle_state_source_protection_decision_json_schema do
    %{
      "oneOf" => [
        protection_decision_json_schema(),
        %{"type" => "string"}
      ]
    }
  end

  defp timeline_diff_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema.summary_source_from_context(
      @timeline_diff_summary,
      registry_contract!(@timeline_diff_summary),
      [
        model_limits: &timeline_report_model_limits/0,
        row_schema: &timeline_diff_row_json_schema/0,
        capability: &timeline_capabilities/0,
        stable_id_pattern: @stable_id_pattern
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_dependency_impact_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.summary_source_from_context(
      @timeline_dependency_impact_summary,
      registry_contract!(@timeline_dependency_impact_summary),
      [
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        required_operator_actions: &timeline_required_operator_actions/0,
        model_limits: &timeline_report_model_limits/0
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_publication_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelinePublicationSummaryJsonSchema.summary_source_from_context(
      @timeline_publication_summary,
      registry_contract!(@timeline_publication_summary),
      [
        stable_id_pattern: @stable_id_pattern,
        timeline_diff_summary_source_schema: &timeline_diff_summary_source_json_schema/0,
        timeline_dependency_impact_summary_source_schema:
          &timeline_dependency_impact_summary_source_json_schema/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0,
        model_limits: &timeline_report_model_limits/0
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_transition_application_row_json_schema do
    OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.application_row_from_context(
      timeline_capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      protection_decision_schema: &protection_decision_json_schema/0,
      timeline_diff_row_schema: &timeline_diff_row_json_schema/0
    )
  end

  defp timeline_transition_application_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.summary_source_from_context(
      @timeline_transition_application_summary,
      registry_contract!(@timeline_transition_application_summary),
      [
        timeline_capability: &timeline_capabilities/0,
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0,
        string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
        protection_decision_schema: &protection_decision_json_schema/0,
        timeline_diff_row_schema: &timeline_diff_row_json_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0,
        activity_context_schema: &activity_context_json_schema/0,
        model_limits: &timeline_report_model_limits/0,
        enum_count_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_dependency_impact_row_json_schema do
    OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      required_operator_actions: &timeline_required_operator_actions/0
    )
  end

  defp operational_readiness_gate_json_schema do
    OrbitalDynamics.Schema.OperationalReadinessGateJsonSchema.gate(
      capability: operational_readiness_capabilities(),
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp quality_gate_report_row_json_schema do
    OrbitalDynamics.Schema.QualityGateReportJsonSchema.row(
      capability: operational_readiness_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      gate_schema: operational_readiness_gate_json_schema()
    )
  end

  defp cadence_import_operational_readiness_evidence_json_schema_properties do
    OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema.evidence_properties(%{
      gate_schema: operational_readiness_gate_json_schema(),
      evidence_schema: operational_readiness_evidence_json_schema()
    })
  end

  defp resource_projection_battery_handoff_json_schema_properties do
    OrbitalDynamics.Schema.ResourceProjectionHandoffJsonSchema.battery_properties(
      OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.battery_handoff_number_fields()
    )
  end

  defp cadence_import_resource_projection_evidence_json_schema_properties do
    OrbitalDynamics.Schema.ResourceProjectionHandoffJsonSchema.evidence_properties(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      approval_requirement_schema: approval_requirement_json_schema(),
      policy_decision_rule_match_schema: policy_decision_rule_match_json_schema()
    )
  end

  defp operational_readiness_evidence_json_schema do
    OrbitalDynamics.Schema.OperationalReadinessEvidenceJsonSchema.schema(
      count_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      stable_id_array_schema: stable_id_array_schema(),
      branch_event_trust_boundary_status_counts_schema:
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map(),
      timeline_publication_context_properties:
        OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.timeline_publication_context_properties(
          stable_id_pattern: @stable_id_pattern
        )
    )
  end

  defp cadence_import_manifest_row_json_schema do
    OrbitalDynamics.Schema.CadenceImportManifestJsonSchema.row(
      capability: cadence_import_capability(),
      readiness_capability: operational_readiness_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema_providers: cadence_import_manifest_row_json_schema_providers(),
      property_providers: cadence_review_row_json_schema_property_providers()
    )
  end

  defp cadence_import_manifest_row_json_schema_providers do
    [
      activity_context_json_schema: &activity_context_json_schema/0,
      branch_comparison_source_row_json_schema: fn ->
        OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders.branch_comparison_source_row(
          @stable_id_pattern
        )
      end,
      branch_event_trust_boundary_status_counts_json_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      cadence_import_status_json_schema:
        &OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema.status/0,
      cadence_source_review_row_json_schema: &cadence_source_review_row_json_schema/0,
      candidate_activity_source_window_json_schema:
        &candidate_activity_source_window_json_schema/0,
      candidate_rejection_source_json_schema: &candidate_rejection_source_json_schema/0,
      contact_allocation_capacity_requirement_row_json_schema: fn ->
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.contact_allocation_capacity_requirement_row(
          @stable_id_pattern
        )
      end,
      contact_contention_deferred_priority_json_schema: fn ->
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.contact_contention_deferred_priority(
          @stable_id_pattern
        )
      end,
      non_negative_number_map_json_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      number_or_number_array_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.number_or_number_array/0,
      number_or_string_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      operational_readiness_evidence_json_schema: &operational_readiness_evidence_json_schema/0,
      operational_readiness_gate_json_schema: &operational_readiness_gate_json_schema/0,
      operational_readiness_source_report_evidence_json_schema:
        &operational_readiness_source_report_evidence_json_schema/0,
      operational_timeline_row_json_schema: &operational_timeline_row_json_schema/0,
      policy_decision_evidence_json_schema: &policy_decision_evidence_json_schema/0,
      policy_escalation_json_schema: &policy_escalation_json_schema/0,
      priority_field_evidence_counts_json_schema:
        &OrbitalDynamics.Schema.GroundNetworkSchemaProviders.priority_field_evidence_counts/0,
      probability_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      quality_gate_report_row_json_schema: &quality_gate_report_row_json_schema/0,
      quality_gate_source_report_evidence_json_schema:
        &quality_gate_source_report_evidence_json_schema/0,
      semantic_change_details_json_schema:
        &OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details/0,
      source_evidence_json_schema: &source_evidence_json_schema/0,
      source_execution_report_evidence_json_schema:
        &source_execution_report_evidence_json_schema/0,
      source_freshness_report_evidence_json_schema:
        &source_freshness_report_evidence_json_schema/0,
      source_schema_validation_report_evidence_json_schema:
        &source_schema_validation_report_evidence_json_schema/0,
      source_window_lineage_json_schema: fn ->
        OrbitalDynamics.Schema.CandidateDiffSchemaProviders.source_window_lineage(
          @stable_id_pattern
        )
      end,
      stable_id_array_map_schema: &stable_id_array_map_schema/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      timeline_activity_precondition_summary_source_json_schema:
        &timeline_activity_precondition_summary_source_json_schema/0,
      timeline_activity_state_source_json_schema: &timeline_activity_state_source_json_schema/0,
      timeline_diff_summary_source_json_schema: &timeline_diff_summary_source_json_schema/0,
      timeline_identity_json_schema: &timeline_identity_json_schema/0,
      timeline_lifecycle_state_source_json_schema: &timeline_lifecycle_state_source_json_schema/0,
      timeline_link_json_schema: &timeline_link_json_schema/0,
      timeline_preservation_source_json_schema: &timeline_preservation_source_json_schema/0,
      timeline_protection_summary_json_schema: &timeline_protection_summary_json_schema/0,
      timeline_transition_application_row_json_schema:
        &timeline_transition_application_row_json_schema/0,
      timeline_transition_application_summary_source_json_schema:
        &timeline_transition_application_summary_source_json_schema/0
    ]
  end

  defp cadence_review_row_json_schema_property_providers do
    OrbitalDynamics.Schema.CadenceReviewSchemaProviders.property_providers(
      @stable_id_pattern,
      cadence_import_operational_readiness_evidence_properties:
        &cadence_import_operational_readiness_evidence_json_schema_properties/0,
      cadence_import_resource_projection_evidence_properties:
        &cadence_import_resource_projection_evidence_json_schema_properties/0,
      feedback_maneuver_handoff_properties: &feedback_maneuver_handoff_json_schema_properties/0,
      link_handoff_properties: &link_handoff_json_schema_properties/0,
      resource_projection_battery_handoff_properties:
        &resource_projection_battery_handoff_json_schema_properties/0,
      scoped_downlink_context_properties: &scoped_downlink_context_json_schema_properties/0,
      thermal_handoff_properties: &thermal_handoff_json_schema_properties/0,
      timeline_activity_precondition_handoff_properties:
        &timeline_activity_precondition_handoff_json_schema_properties/0,
      timeline_dependency_impact_handoff_properties:
        &timeline_dependency_impact_handoff_json_schema_properties/0,
      timeline_publication_handoff_properties:
        &timeline_publication_handoff_json_schema_properties/0
    )
  end

  defp timeline_dependency_impact_handoff_json_schema_properties do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.dependency_impact_properties(
      stable_id_array_schema: stable_id_array_schema(),
      timeline_dependency_impact_row_schema: timeline_dependency_impact_row_json_schema()
    )
  end

  defp timeline_publication_handoff_json_schema_properties do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.publication_properties(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      stable_id_array_map_schema: stable_id_array_map_schema(),
      count_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      timeline_publication_summary_source_schema:
        timeline_publication_summary_source_json_schema()
    )
  end

  defp timeline_activity_precondition_handoff_json_schema_properties do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.activity_precondition_properties(
      timeline_capability: timeline_capabilities(),
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      timeline_precondition_schema: timeline_precondition_json_schema(),
      timeline_activity_precondition_summary_source_schema:
        timeline_activity_precondition_summary_source_json_schema()
    )
  end

  defp link_handoff_json_schema_properties do
    OrbitalDynamics.Schema.LinkHandoffJsonSchema.properties(
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
    )
  end

  defp feedback_maneuver_handoff_json_schema_properties do
    OrbitalDynamics.Schema.FeedbackManeuverHandoffJsonSchema.properties(
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
    )
  end

  defp thermal_handoff_json_schema_properties do
    OrbitalDynamics.Schema.ThermalHandoffJsonSchema.properties(
      stable_id_pattern: @stable_id_pattern,
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
    )
  end

  defp cadence_source_review_row_json_schema do
    OrbitalDynamics.Schema.CadenceSourceReviewRowJsonSchema.row(
      cadence_capability: cadence_import_capability(),
      readiness_capability: operational_readiness_capabilities(),
      timeline_capability: timeline_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema_providers: cadence_source_review_row_json_schema_providers(),
      property_providers: cadence_review_row_json_schema_property_providers()
    )
  end

  defp cadence_source_review_row_json_schema_providers do
    [
      activity_context_json_schema: &activity_context_json_schema/0,
      branch_comparison_source_row_json_schema: fn ->
        OrbitalDynamics.Schema.PlanningAnalysisSchemaProviders.branch_comparison_source_row(
          @stable_id_pattern
        )
      end,
      branch_event_trust_boundary_status_counts_json_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      candidate_activity_source_window_json_schema:
        &candidate_activity_source_window_json_schema/0,
      candidate_rejection_source_json_schema: &candidate_rejection_source_json_schema/0,
      contact_allocation_capacity_requirement_row_json_schema: fn ->
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.contact_allocation_capacity_requirement_row(
          @stable_id_pattern
        )
      end,
      contact_contention_deferred_priority_json_schema: fn ->
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.contact_contention_deferred_priority(
          @stable_id_pattern
        )
      end,
      non_negative_number_map_json_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0,
      number_or_string_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      operational_readiness_source_report_evidence_json_schema:
        &operational_readiness_source_report_evidence_json_schema/0,
      operational_timeline_row_json_schema: &operational_timeline_row_json_schema/0,
      policy_decision_evidence_json_schema: &policy_decision_evidence_json_schema/0,
      policy_escalation_json_schema: &policy_escalation_json_schema/0,
      priority_field_evidence_counts_json_schema:
        &OrbitalDynamics.Schema.GroundNetworkSchemaProviders.priority_field_evidence_counts/0,
      probability_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      quality_gate_source_report_evidence_json_schema:
        &quality_gate_source_report_evidence_json_schema/0,
      semantic_change_details_json_schema:
        &OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details/0,
      source_evidence_json_schema: &source_evidence_json_schema/0,
      source_execution_report_evidence_json_schema:
        &source_execution_report_evidence_json_schema/0,
      source_freshness_report_evidence_json_schema:
        &source_freshness_report_evidence_json_schema/0,
      source_schema_validation_report_evidence_json_schema:
        &source_schema_validation_report_evidence_json_schema/0,
      source_window_lineage_json_schema: fn ->
        OrbitalDynamics.Schema.CandidateDiffSchemaProviders.source_window_lineage(
          @stable_id_pattern
        )
      end,
      stable_id_array_map_schema: &stable_id_array_map_schema/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      timeline_activity_precondition_summary_source_json_schema:
        &timeline_activity_precondition_summary_source_json_schema/0,
      timeline_activity_state_source_json_schema: &timeline_activity_state_source_json_schema/0,
      timeline_diff_summary_source_json_schema: &timeline_diff_summary_source_json_schema/0,
      timeline_identity_json_schema: &timeline_identity_json_schema/0,
      timeline_lifecycle_state_source_json_schema: &timeline_lifecycle_state_source_json_schema/0,
      timeline_link_json_schema: &timeline_link_json_schema/0,
      timeline_preservation_source_json_schema: &timeline_preservation_source_json_schema/0,
      timeline_protection_summary_json_schema: &timeline_protection_summary_json_schema/0,
      timeline_transition_application_row_json_schema:
        &timeline_transition_application_row_json_schema/0,
      timeline_transition_application_summary_source_json_schema:
        &timeline_transition_application_summary_source_json_schema/0
    ]
  end
end
