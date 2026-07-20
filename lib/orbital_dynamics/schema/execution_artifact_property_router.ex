defmodule OrbitalDynamics.Schema.ExecutionArtifactPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "realized_state_snapshot.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.realized_state_snapshot(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :realized_activity_json_schema, []) end,
       fn -> provider(context, :realized_spacecraft_state_json_schema, []) end,
       fn -> provider(context, :realized_state_snapshot_metadata_json_schema, []) end,
       &OrbitalDynamics.CampaignPlanner.realized_state_snapshot_model_limits/0}
    )
  end

  def property(field, "realized_activity.v1", contract, context) do
    OrbitalDynamics.Schema.RealizedActivityJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.RealizedActivityJsonSchema.property_fun_from_context(
          stable_id_pattern: context_value(context, :stable_id_pattern),
          numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0,
          ground_station_schema: fn ->
            provider(context, :ground_station_identity_json_schema, [])
          end,
          spacecraft_schema: fn -> provider(context, :spacecraft_identity_json_schema, []) end,
          target_schema: fn -> provider(context, :target_identity_json_schema, []) end
        ),
      execution_uncertainty_schema: fn ->
        provider(context, :execution_uncertainty_json_schema, [])
      end,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      default_property: fn field, contract ->
        fallback(field, "realized_activity.v1", contract, context)
      end
    )
  end

  def property(field, "maneuver_recommendation.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.recommendation(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"maneuver_recommendation.v1", context_value(context, :stable_id_pattern),
       &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0,
       fn -> provider(context, :maneuver_recommendation_model_limits, []) end}
    )
  end
end
