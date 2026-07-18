defmodule OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ManeuverRecommendationJsonSchema,
    ManeuverReviewReportJsonSchema,
    RealizedStateSnapshotJsonSchema
  }

  def realized_state_snapshot(
        field,
        contract_name,
        contract,
        default_property,
        {
          realized_activity_schema,
          realized_spacecraft_state_schema,
          metadata_schema,
          model_limits
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &RealizedStateSnapshotJsonSchema.property_field?/1,
      RealizedStateSnapshotJsonSchema.property_fun_from_context(
        realized_activity_schema: realized_activity_schema,
        realized_spacecraft_state_schema: realized_spacecraft_state_schema,
        metadata_schema: metadata_schema,
        model_limits: model_limits
      ),
      default_property
    )
  end

  def recommendation(
        field,
        contract_name,
        contract,
        default_property,
        {schema_contract, stable_id_pattern, numeric_triplet_schema, model_limits}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ManeuverRecommendationJsonSchema.property_field?/1,
      ManeuverRecommendationJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern,
        numeric_triplet_schema: numeric_triplet_schema,
        model_limits: model_limits
      ),
      default_property
    )
  end

  def review(
        field,
        contract_name,
        contract,
        default_property,
        {row_schema, stable_id_pattern, model_limits}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ManeuverReviewReportJsonSchema.property_field?/1,
      ManeuverReviewReportJsonSchema.property_fun_from_context(
        row_schema: row_schema,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits
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
