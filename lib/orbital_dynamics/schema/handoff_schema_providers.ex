defmodule OrbitalDynamics.Schema.HandoffSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern) when is_binary(stable_id_pattern) do
    %{
      feedback_maneuver_handoff_properties: fn ->
        OrbitalDynamics.Schema.FeedbackManeuverHandoffJsonSchema.properties(
          probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
        )
      end,
      link_handoff_properties: fn ->
        OrbitalDynamics.Schema.LinkHandoffJsonSchema.properties(
          probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
        )
      end,
      thermal_handoff_properties: fn ->
        OrbitalDynamics.Schema.ThermalHandoffJsonSchema.properties(
          stable_id_pattern: stable_id_pattern,
          probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
        )
      end
    }
  end
end
