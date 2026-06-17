defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Freshness
  alias __MODULE__.RefreshBudget
  alias __MODULE__.SchemaValidation

  def freshness_fields(source_reports) do
    Freshness.fields(source_reports)
  end

  def refresh_budget_fields(source_reports) do
    RefreshBudget.fields(source_reports)
  end

  def schema_validation_fields(source_reports) do
    SchemaValidation.fields(source_reports)
  end
end
