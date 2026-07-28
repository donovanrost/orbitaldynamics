defmodule OrbitalDynamics.Schema.CampaignRepairSourceResourceProjectionFlowSummaryHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CampaignRepairResourceProjectionHandoffContracts,
    as: ResourceProjectionHandoffContracts

  @source_field "source_resource_projection_flow_summary"
  @source "campaign_repair.source_resource_projection_flow_summary.projected_resources"

  def validate(issues, artifact) do
    ResourceProjectionHandoffContracts.validate_flow_summary(
      issues,
      artifact,
      @source_field,
      @source
    )
  end
end
