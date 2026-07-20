defmodule OrbitalDynamics.Schema.ContactIntentCapabilityContext do
  @moduledoc false

  def contact_intent_model_limits do
    OrbitalDynamics.Communications.ContactIntent.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.sort()
  end

  def contact_intent_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactIntentSummaryJsonSchema.assumptions(
      station_capacity_value_paths:
        OrbitalDynamics.Schema.ContactIntentSummaryContracts.station_capacity_value_path_assumptions(),
      required_capacity_value_paths:
        OrbitalDynamics.Schema.ContactIntentSummaryContracts.required_capacity_value_path_assumptions(),
      required_capacity_fraction_source_values:
        OrbitalDynamics.Schema.ContactIntentSummaryContracts.required_capacity_fraction_source_values()
    )
  end
end
