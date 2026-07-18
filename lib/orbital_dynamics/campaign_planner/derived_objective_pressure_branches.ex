defmodule OrbitalDynamics.CampaignPlanner.DerivedObjectivePressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ConstraintPressureBranches,
    ObjectiveConstraintSourceReports,
    ObjectiveSatisfactionPressureBranches,
    ObjectiveTradeoffPressureBranches,
    ScoreTermPressureBranches
  }

  def build(prior_plan, mission_state) do
    []
    |> Kernel.++(prior_score_term(prior_plan))
    |> Kernel.++(mission_score_term(mission_state))
    |> Kernel.++(prior_objective_satisfaction(prior_plan))
    |> Kernel.++(mission_objective_satisfaction(mission_state))
    |> Kernel.++(prior_objective_tradeoff(prior_plan))
    |> Kernel.++(mission_objective_tradeoff(mission_state))
    |> Kernel.++(prior_constraint(prior_plan))
    |> Kernel.++(mission_constraint(mission_state))
  end

  defp prior_score_term(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_score_term_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ScoreTermPressureBranches.branch(row, source_path, index)
    end)
  end

  defp mission_score_term(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.score_term_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ScoreTermPressureBranches.branch(row, source_path, index)
    end)
  end

  defp prior_objective_satisfaction(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_objective_satisfaction_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveSatisfactionPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp mission_objective_satisfaction(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.objective_satisfaction_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveSatisfactionPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp prior_objective_tradeoff(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_objective_tradeoff_reports()
    |> ObjectiveConstraintSourceReports.objective_tradeoff_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveTradeoffPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp mission_objective_tradeoff(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.objective_tradeoff_reports()
    |> ObjectiveConstraintSourceReports.objective_tradeoff_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveTradeoffPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp prior_constraint(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_constraint_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ConstraintPressureBranches.branch(row, source_path, index)
    end)
  end

  defp mission_constraint(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.constraint_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ConstraintPressureBranches.branch(row, source_path, index)
    end)
  end
end
