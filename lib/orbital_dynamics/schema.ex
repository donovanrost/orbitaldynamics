defmodule OrbitalDynamics.Schema do
  @moduledoc """
  Executable schema contracts for public OrbitalDynamics artifacts.

  This module is intentionally lighter than full JSON Schema. It gives the
  current campaign-planning artifacts a stable, testable contract boundary while
  the artifact shapes are still maturing.
  """

  alias OrbitalDynamics.Schema.TimelineCoreSchemaProviders

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
  def validate_artifact(artifact, opts \\ []) do
    OrbitalDynamics.Schema.ArtifactValidation.validate(artifact, opts, contracts(),
      contract: &contract/1,
      error: &error/2,
      validate_contract: &OrbitalDynamics.Schema.ArtifactValidationRouter.validate/3
    )
  end

  @doc """
  Wraps artifact validation in a `schema_validation_report.v1` artifact.
  """
  def validation_report(artifact, opts \\ []) do
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
    common_schema_providers =
      OrbitalDynamics.Schema.CommonSchemaProviders.build(
        @stable_id_pattern,
        @sha256_pattern
      )

    handoff_schema_providers =
      OrbitalDynamics.Schema.HandoffSchemaProviders.build(@stable_id_pattern)

    feedback_maneuver_handoff_properties =
      Map.fetch!(handoff_schema_providers, :feedback_maneuver_handoff_properties)

    link_handoff_properties =
      Map.fetch!(handoff_schema_providers, :link_handoff_properties)

    thermal_handoff_properties =
      Map.fetch!(handoff_schema_providers, :thermal_handoff_properties)

    policy_schema_providers =
      OrbitalDynamics.Schema.PolicySchemaProviders.build(
        @stable_id_pattern,
        policy_decision_schema: fn ->
          @policy_decision
          |> json_schema_document(registry_contract!(@policy_decision))
          |> Map.take(["type", "additionalProperties", "required", "properties"])
        end
      )

    policy_decision_schema =
      Map.fetch!(policy_schema_providers, {:policy_decision_json_schema, 0})

    policy_decision_evidence_schema =
      Map.fetch!(policy_schema_providers, {:policy_decision_evidence_json_schema, 0})

    policy_decision_rule_match_schema =
      Map.fetch!(policy_schema_providers, {:policy_decision_rule_match_json_schema, 0})

    policy_escalation_schema =
      Map.fetch!(policy_schema_providers, {:policy_escalation_json_schema, 0})

    scoped_downlink_context_properties =
      Map.fetch!(
        policy_schema_providers,
        {:scoped_downlink_context_json_schema_properties, 0}
      )

    timeline_core_schema_providers =
      TimelineCoreSchemaProviders.build(@stable_id_pattern)

    activity_context_schema =
      Map.fetch!(timeline_core_schema_providers, {:activity_context_json_schema, 0})

    cadence_import_schema =
      Map.fetch!(timeline_core_schema_providers, {:cadence_import_json_schema, 1})

    candidate_activity_source_window_schema =
      Map.fetch!(
        timeline_core_schema_providers,
        {:candidate_activity_source_window_json_schema, 0}
      )

    execution_uncertainty_schema =
      Map.fetch!(timeline_core_schema_providers, {:execution_uncertainty_json_schema, 0})

    protection_decision_schema =
      Map.fetch!(timeline_core_schema_providers, {:protection_decision_json_schema, 0})

    timeline_identity_schema =
      Map.fetch!(timeline_core_schema_providers, {:timeline_identity_json_schema, 0})

    timeline_link_schema = fn ->
      TimelineCoreSchemaProviders.timeline_link(@stable_id_pattern)
    end

    timeline_preservation_source_schema = fn ->
      TimelineCoreSchemaProviders.timeline_preservation_source(@stable_id_pattern)
    end

    timeline_protection_summary_schema = fn ->
      TimelineCoreSchemaProviders.timeline_protection_summary(@stable_id_pattern)
    end

    timeline_report_schema_providers =
      OrbitalDynamics.Schema.TimelineReportSchemaProviders.build(
        @stable_id_pattern,
        timeline_capability: &timeline_capabilities/0,
        timeline_report_model_limits: &timeline_report_model_limits/0,
        timeline_transition_decisions: &timeline_transition_decisions/0,
        timeline_activity_precondition_statuses: &timeline_activity_precondition_statuses/0,
        timeline_required_operator_actions: &timeline_required_operator_actions/0,
        default_property: &default_json_schema_property/3,
        registry_contract: &registry_contract!/1,
        timeline_activity_precondition_summary_contract: @timeline_activity_precondition_summary,
        timeline_diff_summary_contract: @timeline_diff_summary,
        timeline_dependency_impact_summary_contract: @timeline_dependency_impact_summary,
        timeline_publication_summary_contract: @timeline_publication_summary,
        timeline_transition_application_summary_contract: @timeline_transition_application_summary
      )

    candidate_rejection_source_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:candidate_rejection_source_json_schema, 0}
      )

    operational_timeline_row_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:operational_timeline_row_json_schema, 0}
      )

    timeline_activity_precondition_summary_source_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_activity_precondition_summary_source_json_schema, 0}
      )

    timeline_activity_state_source_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_activity_state_source_json_schema, 0}
      )

    timeline_dependency_impact_handoff_properties =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_dependency_impact_handoff_json_schema_properties, 0}
      )

    timeline_diff_summary_source_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_diff_summary_source_json_schema, 0}
      )

    timeline_lifecycle_state_source_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_lifecycle_state_source_json_schema, 0}
      )

    timeline_publication_handoff_properties =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_publication_handoff_json_schema_properties, 0}
      )

    timeline_activity_precondition_handoff_properties =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_activity_precondition_handoff_json_schema_properties, 0}
      )

    timeline_transition_application_row_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_transition_application_row_json_schema, 0}
      )

    timeline_transition_application_summary_source_schema =
      Map.fetch!(
        timeline_report_schema_providers,
        {:timeline_transition_application_summary_source_json_schema, 0}
      )

    activity_schema_providers =
      OrbitalDynamics.Schema.ActivitySchemaProviders.build(
        @stable_id_pattern,
        source_window_schema: candidate_activity_source_window_schema,
        activity_context_schema: activity_context_schema,
        timeline_identity_schema: timeline_identity_schema,
        cadence_import_schema: cadence_import_schema,
        execution_uncertainty_schema: execution_uncertainty_schema
      )

    campaign_activity_schema =
      Map.fetch!(activity_schema_providers, {:campaign_activity_json_schema, 0})

    planned_activity_schema =
      Map.fetch!(activity_schema_providers, {:planned_activity_json_schema, 0})

    realized_activity_schema =
      Map.fetch!(activity_schema_providers, {:realized_activity_json_schema, 0})

    operational_readiness_schema_providers =
      OrbitalDynamics.Schema.OperationalReadinessSchemaProviders.build(
        @stable_id_pattern,
        readiness_capability: &operational_readiness_capabilities/0,
        approval_requirement_schema: &approval_requirement_json_schema/0,
        policy_decision_rule_match_schema: policy_decision_rule_match_schema
      )

    cadence_import_operational_readiness_evidence_properties =
      Map.fetch!(
        operational_readiness_schema_providers,
        {:cadence_import_operational_readiness_evidence_json_schema_properties, 0}
      )

    cadence_import_resource_projection_evidence_properties =
      Map.fetch!(
        operational_readiness_schema_providers,
        {:cadence_import_resource_projection_evidence_json_schema_properties, 0}
      )

    operational_readiness_evidence_schema =
      Map.fetch!(
        operational_readiness_schema_providers,
        {:operational_readiness_evidence_json_schema, 0}
      )

    operational_readiness_gate_schema =
      Map.fetch!(
        operational_readiness_schema_providers,
        {:operational_readiness_gate_json_schema, 0}
      )

    quality_gate_report_row_schema =
      Map.fetch!(
        operational_readiness_schema_providers,
        {:quality_gate_report_row_json_schema, 0}
      )

    resource_projection_battery_handoff_properties =
      Map.fetch!(
        operational_readiness_schema_providers,
        {:resource_projection_battery_handoff_json_schema_properties, 0}
      )

    source_evidence_providers =
      OrbitalDynamics.Schema.SourceEvidenceSchemaProviders.build(
        @stable_id_pattern,
        battery_handoff_properties: resource_projection_battery_handoff_properties
      )

    [
      field_type_hints: @field_type_hints,
      stable_id_pattern: @stable_id_pattern,
      schema_providers: %{
        {:approval_requirement_json_schema, 0} => &approval_requirement_json_schema/0,
        {:cadence_import_capability, 0} => &cadence_import_capability/0,
        {:cadence_import_manifest_model_limits, 0} => &cadence_import_manifest_model_limits/0,
        {:cadence_import_manifest_scalar_count_fields, 0} =>
          &cadence_import_manifest_scalar_count_fields/0,
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
        {:link_capacity_assumptions_json_schema, 1} => &link_capacity_assumptions_json_schema/1,
        {:maneuver_recommendation_model_limits, 0} => &maneuver_recommendation_model_limits/0,
        {:maneuver_review_report_model_limits, 0} => &maneuver_review_report_model_limits/0,
        {:model_acceptance_report_model_limits, 0} => &model_acceptance_report_model_limits/0,
        {:operational_readiness_capabilities, 0} => &operational_readiness_capabilities/0,
        {:operator_review_capabilities, 0} => &operator_review_capabilities/0,
        {:operator_review_package_model_limits, 0} => &operator_review_package_model_limits/0,
        {:policy_model_limits, 0} => &policy_model_limits/0,
        {:registry_contract!, 1} => &registry_contract!/1,
        {:resource_filter_report_assumptions_json_schema, 0} =>
          &resource_filter_report_assumptions_json_schema/0,
        {:resource_filter_report_model_limits, 0} => &resource_filter_report_model_limits/0,
        {:schema_migration_row_statuses, 0} => &schema_migration_row_statuses/0,
        {:schema_migration_statuses, 0} => &schema_migration_statuses/0,
        {:schema_validation_model_limits, 0} => &schema_validation_model_limits/0,
        {:station_calendar_provider_counteroffer_actions, 0} =>
          &station_calendar_provider_counteroffer_actions/0,
        {:station_calendar_report_model, 0} => &station_calendar_report_model/0,
        {:station_calendar_report_model_limits, 0} => &station_calendar_report_model_limits/0,
        {:timeline_activity_precondition_statuses, 0} =>
          &timeline_activity_precondition_statuses/0,
        {:timeline_candidate_rejection_actions, 0} => &timeline_candidate_rejection_actions/0,
        {:timeline_candidate_rejection_reasons, 0} => &timeline_candidate_rejection_reasons/0,
        {:timeline_capabilities, 0} => &timeline_capabilities/0,
        {:timeline_feedback_capabilities, 0} => &timeline_feedback_capabilities/0,
        {:timeline_feedback_report_model_limits, 0} => &timeline_feedback_report_model_limits/0,
        {:timeline_integrity_issue_types, 0} => &timeline_integrity_issue_types/0,
        {:timeline_preservation_assumptions_json_schema, 1} =>
          &timeline_preservation_assumptions_json_schema/1,
        {:timeline_report_model_limits, 0} => &timeline_report_model_limits/0,
        {:timeline_transition_decisions, 0} => &timeline_transition_decisions/0
      }
    ]
    |> Keyword.update!(:schema_providers, fn providers ->
      providers
      |> Map.merge(common_schema_providers)
      |> Map.merge(operational_readiness_schema_providers)
      |> Map.merge(timeline_report_schema_providers)
      |> Map.merge(timeline_core_schema_providers)
      |> Map.merge(activity_schema_providers)
      |> Map.merge(policy_schema_providers)
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
          policy_decision_rule_match_schema: policy_decision_rule_match_schema,
          policy_decision_schema: policy_decision_schema
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.ExecutionStateSchemaProviders.build(
          @stable_id_pattern,
          planned_activity_schema: planned_activity_schema,
          realized_activity_schema: realized_activity_schema,
          timeline_link_schema: timeline_link_schema,
          activity_context_schema: activity_context_schema
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.ResourcePlanningSchemaProviders.build(
          @stable_id_pattern,
          source_window_schema: candidate_activity_source_window_schema,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: policy_decision_rule_match_schema,
          policy_decision_schema: policy_decision_schema,
          contact_filter_suppression_reasons: &contact_filter_suppression_reasons/0,
          resource_filter_suppression_reasons: &resource_filter_suppression_reasons/0
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.GroundNetworkSchemaProviders.build(
          @stable_id_pattern,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: policy_decision_rule_match_schema,
          policy_decision_schema: policy_decision_schema,
          station_calendar_capability: &station_calendar_capabilities/0
        )
      )
      |> Map.merge(OrbitalDynamics.Schema.CandidateDiffSchemaProviders.build(@stable_id_pattern))
      |> Map.merge(
        OrbitalDynamics.Schema.ContactPlanningSchemaProviders.build(
          @stable_id_pattern,
          timeline_identity_schema: timeline_identity_schema,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: policy_decision_rule_match_schema,
          contact_intent_model_limits: &contact_intent_model_limits/0,
          policy_decision_schema: policy_decision_schema,
          source_window_schema: candidate_activity_source_window_schema,
          cadence_import_schema: cadence_import_schema
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.StrategySchemaProviders.build(
          @stable_id_pattern,
          scoped_downlink_context_properties: scoped_downlink_context_properties,
          strategy_recommendation_schema: fn ->
            @strategy_recommendation
            |> json_schema_document(registry_contract!(@strategy_recommendation))
            |> Map.take(["type", "additionalProperties", "required", "properties"])
          end,
          provider_counteroffer_negotiation_states:
            &station_calendar_provider_counteroffer_negotiation_states/0,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          policy_decision_rule_match_schema: policy_decision_rule_match_schema,
          policy_decision_schema: policy_decision_schema
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.TimelineFeedbackSchemaProviders.build(
          @stable_id_pattern,
          @timeline_feedback_report,
          realized_activity_schema: realized_activity_schema,
          timeline_feedback_capability: &timeline_feedback_capabilities/0,
          protection_decision_schema: protection_decision_schema,
          timeline_identity_schema: timeline_identity_schema,
          activity_context_schema: activity_context_schema,
          planned_activity_schema: planned_activity_schema
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.ExecutionReviewSchemaProviders.build(
          @stable_id_pattern,
          activity_context_schema: activity_context_schema,
          policy_decision_schema: policy_decision_schema
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.TimelineEdgeSchemaProviders.build(
          @stable_id_pattern,
          campaign_activity_schema: campaign_activity_schema,
          timeline_capability: &timeline_capabilities/0,
          activity_context_schema: activity_context_schema,
          timeline_report_model_limits: &timeline_report_model_limits/0,
          timeline_transition_decisions: &timeline_transition_decisions/0,
          protection_decision_schema: protection_decision_schema,
          timeline_identity_schema: timeline_identity_schema
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.OperatorReviewSchemaProviders.build(
          @stable_id_pattern,
          operator_review_capability: &operator_review_capabilities/0,
          readiness_capability: &operational_readiness_capabilities/0,
          timeline_capability: &timeline_capabilities/0,
          activity_context_schema: activity_context_schema,
          approval_requirement_schema: &approval_requirement_json_schema/0,
          candidate_activity_source_window_schema: candidate_activity_source_window_schema,
          operational_readiness_evidence_schema: operational_readiness_evidence_schema,
          operational_readiness_gate_schema: operational_readiness_gate_schema,
          operational_readiness_source_report_evidence_schema:
            Map.fetch!(
              source_evidence_providers,
              :operational_readiness_source_report_evidence
            ),
          operational_timeline_row_schema: operational_timeline_row_schema,
          policy_decision_evidence_schema: policy_decision_evidence_schema,
          policy_decision_rule_match_schema: policy_decision_rule_match_schema,
          policy_escalation_schema: policy_escalation_schema,
          protection_decision_schema: protection_decision_schema,
          quality_gate_report_row_schema: quality_gate_report_row_schema,
          quality_gate_source_report_evidence_schema:
            Map.fetch!(source_evidence_providers, :quality_gate_source_report_evidence),
          source_evidence_schema: Map.fetch!(source_evidence_providers, :source_evidence),
          timeline_activity_precondition_summary_source_schema:
            timeline_activity_precondition_summary_source_schema,
          timeline_activity_state_source_schema: timeline_activity_state_source_schema,
          timeline_diff_summary_source_schema: timeline_diff_summary_source_schema,
          timeline_identity_schema: timeline_identity_schema,
          timeline_lifecycle_state_source_schema: timeline_lifecycle_state_source_schema,
          timeline_link_schema: timeline_link_schema,
          timeline_preservation_source_schema: timeline_preservation_source_schema,
          timeline_protection_summary_schema: timeline_protection_summary_schema,
          timeline_transition_application_row_schema: timeline_transition_application_row_schema,
          timeline_transition_application_summary_source_schema:
            timeline_transition_application_summary_source_schema,
          feedback_maneuver_handoff_properties: feedback_maneuver_handoff_properties,
          link_handoff_properties: link_handoff_properties,
          resource_projection_battery_handoff_properties:
            resource_projection_battery_handoff_properties,
          scoped_downlink_context_properties: scoped_downlink_context_properties,
          thermal_handoff_properties: thermal_handoff_properties,
          timeline_activity_precondition_handoff_properties:
            timeline_activity_precondition_handoff_properties,
          timeline_dependency_impact_handoff_properties:
            timeline_dependency_impact_handoff_properties,
          timeline_publication_handoff_properties: timeline_publication_handoff_properties
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.CadenceReviewSchemaProviders.build(
          @stable_id_pattern,
          cadence_import_capability: &cadence_import_capability/0,
          readiness_capability: &operational_readiness_capabilities/0,
          timeline_capability: &timeline_capabilities/0,
          activity_context_schema: activity_context_schema,
          candidate_activity_source_window_schema: candidate_activity_source_window_schema,
          candidate_rejection_source_schema: candidate_rejection_source_schema,
          operational_readiness_evidence_schema: operational_readiness_evidence_schema,
          operational_readiness_gate_schema: operational_readiness_gate_schema,
          operational_readiness_source_report_evidence_schema:
            Map.fetch!(
              source_evidence_providers,
              :operational_readiness_source_report_evidence
            ),
          operational_timeline_row_schema: operational_timeline_row_schema,
          policy_decision_evidence_schema: policy_decision_evidence_schema,
          policy_escalation_schema: policy_escalation_schema,
          quality_gate_report_row_schema: quality_gate_report_row_schema,
          quality_gate_source_report_evidence_schema:
            Map.fetch!(source_evidence_providers, :quality_gate_source_report_evidence),
          source_evidence_schema: Map.fetch!(source_evidence_providers, :source_evidence),
          source_execution_report_evidence_schema:
            Map.fetch!(source_evidence_providers, :source_execution_report_evidence),
          source_freshness_report_evidence_schema:
            Map.fetch!(source_evidence_providers, :source_freshness_report_evidence),
          source_schema_validation_report_evidence_schema:
            Map.fetch!(source_evidence_providers, :source_schema_validation_report_evidence),
          timeline_activity_precondition_summary_source_schema:
            timeline_activity_precondition_summary_source_schema,
          timeline_activity_state_source_schema: timeline_activity_state_source_schema,
          timeline_diff_summary_source_schema: timeline_diff_summary_source_schema,
          timeline_identity_schema: timeline_identity_schema,
          timeline_lifecycle_state_source_schema: timeline_lifecycle_state_source_schema,
          timeline_link_schema: timeline_link_schema,
          timeline_preservation_source_schema: timeline_preservation_source_schema,
          timeline_protection_summary_schema: timeline_protection_summary_schema,
          timeline_transition_application_row_schema: timeline_transition_application_row_schema,
          timeline_transition_application_summary_source_schema:
            timeline_transition_application_summary_source_schema,
          cadence_import_operational_readiness_evidence_properties:
            cadence_import_operational_readiness_evidence_properties,
          cadence_import_resource_projection_evidence_properties:
            cadence_import_resource_projection_evidence_properties,
          feedback_maneuver_handoff_properties: feedback_maneuver_handoff_properties,
          link_handoff_properties: link_handoff_properties,
          resource_projection_battery_handoff_properties:
            resource_projection_battery_handoff_properties,
          scoped_downlink_context_properties: scoped_downlink_context_properties,
          thermal_handoff_properties: thermal_handoff_properties,
          timeline_activity_precondition_handoff_properties:
            timeline_activity_precondition_handoff_properties,
          timeline_dependency_impact_handoff_properties:
            timeline_dependency_impact_handoff_properties,
          timeline_publication_handoff_properties: timeline_publication_handoff_properties
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

  defp candidate_activity_json_schema do
    OrbitalDynamics.Schema.ActivitySchemaProviders.candidate_activity(
      @stable_id_pattern,
      source_window_schema: fn ->
        TimelineCoreSchemaProviders.candidate_activity_source_window(@stable_id_pattern)
      end,
      activity_context_schema: fn ->
        TimelineCoreSchemaProviders.activity_context(@stable_id_pattern)
      end
    )
  end

  defp approval_requirement_json_schema do
    OrbitalDynamics.Schema.ApprovalRequirementJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      rule_match_schema: fn ->
        OrbitalDynamics.Schema.PolicySchemaProviders.rule_match(@stable_id_pattern)
      end,
      activity_context_schema: fn ->
        TimelineCoreSchemaProviders.activity_context(@stable_id_pattern)
      end,
      policy_escalation_schema: fn ->
        OrbitalDynamics.Schema.PolicySchemaProviders.escalation(@stable_id_pattern)
      end
    )
  end

  defp validation_record_registry_conditions do
    OrbitalDynamics.Schema.ValidationJsonSchema.registry_conditions(@stable_id_pattern)
  end
end
