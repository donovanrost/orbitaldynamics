defmodule OrbitalDynamics.CampaignPlanner.DerivedOperationalReviewPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalTimelinePressureEvents,
    OperationalTimelineSourceRows,
    OperatorReviewPressureBranches,
    OperatorReviewSourceReports,
    ReviewSourceReports
  }

  def build(prior_plan, mission_state, policy) do
    []
    |> Kernel.++(prior_operational_timeline(prior_plan))
    |> Kernel.++(mission_operational_timeline(mission_state))
    |> Kernel.++(prior_operator_review(prior_plan, policy))
    |> Kernel.++(mission_operator_review(mission_state, policy))
  end

  defp prior_operational_timeline(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_operational_timeline_reports()
    |> OperationalTimelineSourceRows.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(row, source_path, index)
    end)
  end

  defp mission_operational_timeline(mission_state) do
    mission_state
    |> ReviewSourceReports.operational_timeline_reports()
    |> OperationalTimelineSourceRows.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(row, source_path, index)
    end)
  end

  defp prior_operator_review(prior_plan, policy) do
    prior_plan
    |> OperatorReviewSourceReports.prior_plan_operator_review_packages()
    |> OperatorReviewSourceReports.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_prefix, index} ->
      OperatorReviewPressureBranches.from_row(row, index, policy, source_prefix)
    end)
  end

  defp mission_operator_review(mission_state, policy) do
    mission_state
    |> OperatorReviewSourceReports.operator_review_packages()
    |> OperatorReviewSourceReports.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_prefix, index} ->
      OperatorReviewPressureBranches.from_row(row, index, policy, source_prefix)
    end)
  end
end
