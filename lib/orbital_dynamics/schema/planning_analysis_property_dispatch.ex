defmodule OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ConstraintReportJsonSchema,
    MonteCarloReproducibilityReportJsonSchema,
    OptimizerContractJsonSchema,
    ResourceFilterSummaryJsonSchema,
    ScoreTermReportJsonSchema
  }

  def score_term(
        field,
        contract_name,
        contract,
        default_property,
        {models, model_limits, row_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ScoreTermReportJsonSchema.property_field?/1,
      ScoreTermReportJsonSchema.property_fun_from_context(
        models: models,
        model_limits: model_limits,
        row_schema: row_schema
      ),
      default_property
    )
  end

  def resource_filter_summary(
        field,
        contract_name,
        contract,
        default_property,
        {
          schema_contract,
          source_artifact_type,
          stable_id_pattern,
          model_limits,
          assumptions_schema,
          suppressed_candidate_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ResourceFilterSummaryJsonSchema.property_field?/1,
      ResourceFilterSummaryJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        source_artifact_type: source_artifact_type,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits,
        assumptions_schema: assumptions_schema,
        suppressed_candidate_schema: suppressed_candidate_schema
      ),
      default_property
    )
  end

  def constraint(
        field,
        contract_name,
        contract,
        default_property,
        {models, model_limits, row_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ConstraintReportJsonSchema.property_field?/1,
      ConstraintReportJsonSchema.property_fun_from_context(
        models: models,
        model_limits: model_limits,
        row_schema: row_schema
      ),
      default_property
    )
  end

  def optimizer_contract(
        field,
        contract_name,
        contract,
        default_property,
        {schema_contract, stable_id_pattern}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &OptimizerContractJsonSchema.property_field?/1,
      OptimizerContractJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern
      ),
      default_property
    )
  end

  def monte_carlo(
        field,
        contract_name,
        contract,
        default_property,
        {schema_contract, stable_id_pattern, model_limits, numeric_triplet_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &MonteCarloReproducibilityReportJsonSchema.property_field?/1,
      MonteCarloReproducibilityReportJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits,
        numeric_triplet_schema: numeric_triplet_schema
      ),
      default_property
    )
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
