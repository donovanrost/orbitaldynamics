defmodule OrbitalDynamics.Schema.TimelineReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    OperationalTimelineReportJsonSchema,
    TimelineDependencyImpactSummaryJsonSchema,
    TimelineDiffReportJsonSchema,
    TimelineDiffSummaryJsonSchema,
    TimelineFeedbackReportJsonSchema,
    TimelineIntegrityReportJsonSchema,
    TimelinePublicationSummaryJsonSchema
  }

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)

    {property_field?, property} =
      property_dispatch(contract_name, contracts, deps)

    dispatch(
      field,
      contract_name,
      contract,
      property_field?,
      property,
      fn fallback_field, fallback_contract_name, fallback_contract ->
        Keyword.fetch!(deps, :default_property).(
          fallback_field,
          fallback_contract_name,
          fallback_contract
        )
      end
    )
  end

  def feedback(
        field,
        contract_name,
        contract,
        default_property,
        {
          row_schema,
          model_limits,
          capability,
          operational_feedback_schema,
          operational_feedback_provenance_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineFeedbackReportJsonSchema.property_field?/1,
      TimelineFeedbackReportJsonSchema.property_fun_from_context(
        row_schema: row_schema,
        model_limits: model_limits,
        capability: capability,
        operational_feedback_schema: operational_feedback_schema,
        operational_feedback_provenance_schema: operational_feedback_provenance_schema
      ),
      default_property
    )
  end

  def integrity(
        field,
        contract_name,
        contract,
        default_property,
        schema_contract,
        stable_id_pattern,
        {
          row_schema,
          timeline_integrity_issue_types,
          stable_id_array_schema,
          stable_id_array_map_schema,
          model_limits
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineIntegrityReportJsonSchema.property_field?/1,
      TimelineIntegrityReportJsonSchema.property_fun_from_context(
        row_schema: row_schema,
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern,
        timeline_integrity_issue_types: timeline_integrity_issue_types,
        stable_id_array_schema: stable_id_array_schema,
        stable_id_array_map_schema: stable_id_array_map_schema,
        model_limits: model_limits
      ),
      default_property
    )
  end

  def dependency_impact(
        field,
        contract_name,
        contract,
        default_property,
        schema_contract,
        {stable_id_array_schema, row_schema, model_limits}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineDependencyImpactSummaryJsonSchema.property_field?/1,
      TimelineDependencyImpactSummaryJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_array_schema: stable_id_array_schema,
        row_schema: row_schema,
        model_limits: model_limits
      ),
      default_property
    )
  end

  def publication(
        field,
        contract_name,
        contract,
        default_property,
        schema_contract,
        stable_id_pattern,
        {
          timeline_diff_summary_source_schema,
          timeline_dependency_impact_summary_source_schema,
          stable_id_array_schema,
          stable_id_array_map_schema,
          model_limits
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelinePublicationSummaryJsonSchema.property_field?/1,
      TimelinePublicationSummaryJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern,
        timeline_diff_summary_source_schema: timeline_diff_summary_source_schema,
        timeline_dependency_impact_summary_source_schema:
          timeline_dependency_impact_summary_source_schema,
        stable_id_array_schema: stable_id_array_schema,
        stable_id_array_map_schema: stable_id_array_map_schema,
        model_limits: model_limits
      ),
      default_property
    )
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.operational_timeline_report do
    {
      &OperationalTimelineReportJsonSchema.property_field?/1,
      OperationalTimelineReportJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :model_limits),
        row_schema: Keyword.fetch!(deps, :operational_timeline_row_schema),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        capability: Keyword.fetch!(deps, :capability)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.timeline_diff_report do
    {
      &TimelineDiffReportJsonSchema.property_field?/1,
      TimelineDiffReportJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :model_limits),
        row_schema: Keyword.fetch!(deps, :timeline_diff_row_schema),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        capability: Keyword.fetch!(deps, :capability)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.timeline_diff_summary do
    {
      &TimelineDiffSummaryJsonSchema.property_field?/1,
      TimelineDiffSummaryJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :model_limits),
        row_schema: Keyword.fetch!(deps, :timeline_diff_row_schema),
        capability: Keyword.fetch!(deps, :capability),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp dispatch(
         field,
         contract_name,
         contract,
         property_field?,
         property,
         default_property
       ) do
    if property_field?.(field) do
      property.(field)
    else
      default_property.(field, contract_name, contract)
    end
  end
end
