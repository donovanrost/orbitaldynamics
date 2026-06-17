defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation do
  @moduledoc false

  alias __MODULE__.Freshness
  alias __MODULE__.RefreshBudget
  alias __MODULE__.SchemaValidation

  def freshness(refresh_or_artifact, callbacks) do
    Freshness.from_refresh(refresh_or_artifact, callbacks)
  end

  def freshness_source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    Freshness.source_report_fields(refresh_or_artifact, source_reports, callbacks)
  end

  def freshness(freshness_summary, summary_source, replay_scope) do
    Freshness.summary(freshness_summary, summary_source, replay_scope)
  end

  def refresh_budget(refresh_or_artifact, callbacks) do
    RefreshBudget.from_refresh(refresh_or_artifact, callbacks)
  end

  def refresh_budget_source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    RefreshBudget.source_report_fields(refresh_or_artifact, source_reports, callbacks)
  end

  def refresh_budget(budget_summary, summary_source, replay_scope) do
    RefreshBudget.summary(budget_summary, summary_source, replay_scope)
  end

  def schema_validation(refresh_or_artifact, callbacks) do
    SchemaValidation.from_refresh(refresh_or_artifact, callbacks)
  end

  def schema_validation_source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    SchemaValidation.source_report_fields(refresh_or_artifact, source_reports, callbacks)
  end

  def schema_validation(validation_summary, summary_source, replay_scope) do
    SchemaValidation.summary(validation_summary, summary_source, replay_scope)
  end
end
