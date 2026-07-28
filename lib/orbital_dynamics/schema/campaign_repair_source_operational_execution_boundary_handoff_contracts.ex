defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalExecutionBoundaryHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CampaignRepairSourceOperationalImportEligibilityHandoffContracts,
    as: ReadinessSummaryHandoffContracts

  @source_field "source_operational_execution_boundary_summary"
  @source "campaign_repair.source_operational_execution_boundary_summary"

  def validate(issues, artifact) do
    ReadinessSummaryHandoffContracts.validate_source(issues, artifact, @source_field, @source)
  end
end
