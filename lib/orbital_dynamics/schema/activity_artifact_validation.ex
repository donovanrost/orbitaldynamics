defmodule OrbitalDynamics.Schema.ActivityArtifactValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ActivityTemplateContracts,
    ActivityTemplateRegistryContracts,
    PlannedActivityContracts,
    PlannedActivityRegistryContracts,
    Registry,
    TimelineCapabilityContext
  }

  @activity_template "activity_template.v1"
  @planned_activity "planned_activity.v1"

  def validate_template(issues, path, template) do
    ActivityTemplateContracts.validate(
      issues,
      path,
      template,
      contract(ActivityTemplateRegistryContracts, @activity_template),
      TimelineCapabilityContext.timeline_capabilities()
    )
  end

  def validate_planned(issues, path, activity) do
    PlannedActivityContracts.validate(
      issues,
      path,
      activity,
      contract(PlannedActivityRegistryContracts, @planned_activity)
    )
  end

  defp contract(registry_module, contract_name) do
    registry_module.contracts()
    |> Registry.fetch!(contract_name)
  end
end
