defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalQualityGateSchemaValidationHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CampaignRepairQualityGateHandoffContracts,
    as: QualityGateHandoffContracts

  @source_field "source_operational_quality_gate_schema_validation_summary"
  @source "campaign_repair.source_operational_quality_gate_schema_validation_summary"

  def validate(issues, artifact) do
    QualityGateHandoffContracts.validate_source(issues, artifact, @source_field, @source)
  end
end
