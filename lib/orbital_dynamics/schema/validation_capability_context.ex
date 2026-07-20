defmodule OrbitalDynamics.Schema.ValidationCapabilityContext do
  @moduledoc false

  def validation_capabilities do
    OrbitalDynamics.Validation.capabilities()
  end

  def model_acceptance_report_model_limits do
    validation_capabilities()
    |> Map.fetch!(:known_limits)
  end

  def schema_migration_statuses do
    validation_capabilities().schema_migration_statuses
  end

  def schema_migration_row_statuses do
    validation_capabilities().schema_migration_row_statuses
  end
end
