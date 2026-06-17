defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows do
  @moduledoc false

  alias __MODULE__.{Context, OperationalSummaries, ReportRows}

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"} = summary
      ) do
    OperationalSummaries.pressure_rows_for_report(summary)
  end

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_schema_validation_summary.v1"} = summary
      ) do
    OperationalSummaries.pressure_rows_for_report(summary)
  end

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_operator_training_summary.v1"} = summary
      ) do
    OperationalSummaries.pressure_rows_for_report(summary)
  end

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"} =
          summary
      ) do
    OperationalSummaries.pressure_rows_for_report(summary)
  end

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_summary.v1"} = summary
      ) do
    ReportRows.operational_quality_gate_summary(summary)
  end

  def pressure_rows_for_report(report) do
    ReportRows.quality_gate_report(report)
  end

  def resource_context(%{} = row) do
    Context.resource_context(row)
  end

  def schema_validation_context(%{} = row) do
    Context.schema_validation_context(row)
  end

  def import_readiness_context(%{} = row) do
    Context.import_readiness_context(row)
  end
end
