defmodule OrbitalDynamics.CampaignPlanner.ObjectiveConstraintSourceReports do
  @moduledoc false

  alias __MODULE__.PressureRows
  alias __MODULE__.Reports
  alias OrbitalDynamics.CampaignPlanner.BranchRefreshSourceInputs

  def constraint_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.constraint_reports(mission_state, opts)

  def prior_constraint_reports(prior_plan, opts),
    do: Reports.prior_constraint_reports(prior_plan, opts)

  def prior_constraint_reports(prior_plan),
    do: Reports.prior_constraint_reports(prior_plan)

  def source_constraint_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.source_constraint_reports(mission_state, opts)

  def source_constraint_reports_with_result_artifact_fallback(
        mission_state,
        opts \\ Reports.default_callbacks()
      ),
      do: Reports.source_constraint_reports_with_result_artifact_fallback(mission_state, opts)

  def canonical_constraint_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.canonical_constraint_reports(mission_state, opts)

  def objective_satisfaction_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.objective_satisfaction_reports(mission_state, opts)

  def prior_objective_satisfaction_reports(prior_plan, opts),
    do: Reports.prior_objective_satisfaction_reports(prior_plan, opts)

  def prior_objective_satisfaction_reports(prior_plan),
    do: Reports.prior_objective_satisfaction_reports(prior_plan)

  def source_objective_satisfaction_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.source_objective_satisfaction_reports(mission_state, opts)

  def source_objective_satisfaction_reports_with_result_artifact_fallback(
        mission_state,
        opts \\ Reports.default_callbacks()
      ) do
    Reports.source_objective_satisfaction_reports_with_result_artifact_fallback(
      mission_state,
      opts
    )
  end

  def canonical_objective_satisfaction_reports(
        mission_state,
        opts \\ Reports.default_callbacks()
      ),
      do: Reports.canonical_objective_satisfaction_reports(mission_state, opts)

  def objective_tradeoff_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.objective_tradeoff_reports(mission_state, opts)

  def prior_objective_tradeoff_reports(prior_plan, opts),
    do: Reports.prior_objective_tradeoff_reports(prior_plan, opts)

  def prior_objective_tradeoff_reports(prior_plan),
    do: Reports.prior_objective_tradeoff_reports(prior_plan)

  def source_objective_tradeoff_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.source_objective_tradeoff_reports(mission_state, opts)

  def source_objective_tradeoff_reports_with_result_artifact_fallback(
        mission_state,
        opts \\ Reports.default_callbacks()
      ),
      do:
        Reports.source_objective_tradeoff_reports_with_result_artifact_fallback(
          mission_state,
          opts
        )

  def canonical_objective_tradeoff_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.canonical_objective_tradeoff_reports(mission_state, opts)

  def score_term_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.score_term_reports(mission_state, opts)

  def prior_score_term_reports(prior_plan, opts),
    do: Reports.prior_score_term_reports(prior_plan, opts)

  def prior_score_term_reports(prior_plan),
    do: Reports.prior_score_term_reports(prior_plan)

  def source_score_term_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.source_score_term_reports(mission_state, opts)

  def source_score_term_reports_with_result_artifact_fallback(
        mission_state,
        opts \\ Reports.default_callbacks()
      ),
      do: Reports.source_score_term_reports_with_result_artifact_fallback(mission_state, opts)

  def canonical_score_term_reports(mission_state, opts \\ Reports.default_callbacks()),
    do: Reports.canonical_score_term_reports(mission_state, opts)

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def pressure_rows(reports) do
    PressureRows.pressure_rows(reports)
  end

  def objective_tradeoff_pressure_rows(reports) do
    PressureRows.objective_tradeoff_pressure_rows(reports)
  end

  defp candidate_refresh_source_input_collectors,
    do: [
      {"source_constraint_report", &source_constraint_reports_with_result_artifact_fallback/1},
      {"constraint_report", &canonical_constraint_reports/1},
      {"source_objective_satisfaction_report",
       &source_objective_satisfaction_reports_with_result_artifact_fallback/1},
      {"objective_satisfaction_report", &canonical_objective_satisfaction_reports/1},
      {"source_objective_tradeoff_report",
       &source_objective_tradeoff_reports_with_result_artifact_fallback/1},
      {"objective_tradeoff_report", &canonical_objective_tradeoff_reports/1},
      {"source_score_term_report", &source_score_term_reports_with_result_artifact_fallback/1},
      {"score_term_report", &canonical_score_term_reports/1}
    ]
end
