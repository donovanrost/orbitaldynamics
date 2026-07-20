defmodule OrbitalDynamics.Schema.ContactContentionCapabilityContext do
  @moduledoc false

  def contact_contention_report_model_limits do
    OrbitalDynamics.Communications.ContactContention.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def contact_contention_report_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.report_assumptions_from_capabilities(
      OrbitalDynamics.Communications.ContactContention.capabilities()
    )
  end
end
