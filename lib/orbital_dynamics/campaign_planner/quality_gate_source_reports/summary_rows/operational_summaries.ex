defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries do
  @moduledoc false

  alias __MODULE__.{ImportReadiness, OperatorTraining, SchemaValidation, UnavailableResource}

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"} = summary
      ) do
    ImportReadiness.pressure_rows_for_report(summary)
  end

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_schema_validation_summary.v1"} = summary
      ) do
    SchemaValidation.pressure_rows_for_report(summary)
  end

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"} = summary
      ) do
    OperatorTraining.pressure_rows_for_report(summary)
  end

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"} =
          summary
      ) do
    UnavailableResource.pressure_rows_for_report(summary)
  end
end
