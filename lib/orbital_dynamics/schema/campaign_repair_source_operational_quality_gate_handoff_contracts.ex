defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalQualityGateHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CampaignRepairQualityGateHandoffContracts,
    as: QualityGateHandoffContracts

  @source_field "source_operational_quality_gate_summary"
  @source "campaign_repair.source_operational_quality_gate_summary"

  def validate(issues, artifact) do
    QualityGateHandoffContracts.validate_source(issues, artifact, @source_field, @source)
  end
end
