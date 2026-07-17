defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation do
  @moduledoc false

  alias __MODULE__.Freshness
  alias __MODULE__.RefreshBudget
  alias __MODULE__.SchemaValidation

  def freshness(refresh_or_artifact) do
    Freshness.from_refresh(refresh_or_artifact)
  end

  def freshness(freshness_summary, summary_source, replay_scope) do
    Freshness.summary(freshness_summary, summary_source, replay_scope)
  end

  def refresh_budget(refresh_or_artifact) do
    RefreshBudget.from_refresh(refresh_or_artifact)
  end

  def refresh_budget(budget_summary, summary_source, replay_scope) do
    RefreshBudget.summary(budget_summary, summary_source, replay_scope)
  end

  def schema_validation(refresh_or_artifact) do
    SchemaValidation.from_refresh(refresh_or_artifact)
  end

  def schema_validation(validation_summary, summary_source, replay_scope) do
    SchemaValidation.summary(validation_summary, summary_source, replay_scope)
  end
end
