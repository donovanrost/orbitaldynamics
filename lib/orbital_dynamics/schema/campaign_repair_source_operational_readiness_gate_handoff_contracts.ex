defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalReadinessGateHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CampaignRepairSourceOperationalImportEligibilityHandoffContracts,
    as: ReadinessSummaryHandoffContracts

  @source_field "source_operational_readiness_gate_summary"
  @source "campaign_repair.source_operational_readiness_gate_summary"

  def validate(issues, artifact) do
    ReadinessSummaryHandoffContracts.validate_source(issues, artifact, @source_field, @source)
  end
end
