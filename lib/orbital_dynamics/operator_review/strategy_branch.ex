defmodule OrbitalDynamics.OperatorReview.StrategyBranch do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.CandidateDiff
  alias OrbitalDynamics.OperatorReview.CommandWindow
  alias OrbitalDynamics.OperatorReview.ConstraintObjective
  alias OrbitalDynamics.OperatorReview.ContactAllocation
  alias OrbitalDynamics.OperatorReview.ContactIntent
  alias OrbitalDynamics.OperatorReview.LinkCapacity
  alias OrbitalDynamics.OperatorReview.OperationalTimeline
  alias OrbitalDynamics.OperatorReview.OptimizationReview
  alias OrbitalDynamics.OperatorReview.RefreshState
  alias OrbitalDynamics.OperatorReview.ResourceProjection
  alias OrbitalDynamics.OperatorReview.StationCalendar
  alias OrbitalDynamics.OperatorReview.Suppression
  alias OrbitalDynamics.OperatorReview.TimelineFeedback
  alias OrbitalDynamics.OperatorReview.WarningReview

  def rows(branches) do
    strategy_repair_constraint_rows(branches) ++
      OperationalTimeline.strategy_rows(branches) ++
      strategy_resource_projection_rows(branches) ++
      strategy_candidate_diff_rows(branches) ++
      strategy_contact_suppression_rows(branches) ++
      strategy_station_calendar_rows(branches) ++
      strategy_repair_link_capacity_rows(branches) ++
      strategy_repair_score_term_rows(branches) ++
      strategy_repair_objective_tradeoff_rows(branches) ++
      strategy_contact_allocation_rows(branches) ++
      strategy_repair_contact_allocation_rows(branches) ++
      strategy_contact_intent_rows(branches) ++
      strategy_resource_suppression_rows(branches) ++
      strategy_freshness_rows(branches) ++
      strategy_refresh_budget_rows(branches) ++
      TimelineFeedback.strategy_rows(branches) ++
      strategy_command_window_rows(branches) ++
      WarningReview.strategy_rows(branches)
  end

  defp strategy_resource_suppression_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_resource_filter_report", "suppressed_candidates"])
      |> List.wrap()
      |> Suppression.resource_rows(
        "campaign_strategy.branches.repair_result.source_resource_filter_report.suppressed_candidates"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_constraint_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "constraint_report", "rows"])
      |> List.wrap()
      |> ConstraintObjective.constraint_rows(
        "campaign_strategy.branches.repair_result.constraint_report.rows"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_resource_projection_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["resource_projection_report", "projected_resources"])
      |> List.wrap()
      |> ResourceProjection.rows(
        "campaign_strategy.branches.resource_projection_report.projected_resources"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_refresh_budget_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_refresh_budget_report"])
      |> RefreshState.refresh_budget_rows(
        "campaign_strategy.branches.repair_result.source_refresh_budget_report"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_freshness_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_freshness_report"])
      |> RefreshState.freshness_rows(
        "campaign_strategy.branches.repair_result.source_freshness_report"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_candidate_diff_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_candidate_diff_report"])
      |> CandidateDiff.report_rows(
        "campaign_strategy.branches.repair_result.source_candidate_diff_report"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_contact_suppression_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_contact_filter_report", "suppressed_candidates"])
      |> List.wrap()
      |> Suppression.contact_rows(
        "campaign_strategy.branches.repair_result.source_contact_filter_report.suppressed_candidates"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_station_calendar_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_station_calendar_report", "affected_contacts"])
      |> List.wrap()
      |> StationCalendar.rows(
        "campaign_strategy.branches.repair_result.source_station_calendar_report.affected_contacts"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_link_capacity_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "link_capacity_report"])
      |> LinkCapacity.report_rows("campaign_strategy.branches.repair_result.link_capacity_report")
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_score_term_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "score_term_report", "rows"])
      |> List.wrap()
      |> OptimizationReview.score_term_rows(
        "campaign_strategy.branches.repair_result.score_term_report.rows"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_objective_tradeoff_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "objective_tradeoff_report", "tradeoffs"])
      |> List.wrap()
      |> OptimizationReview.objective_tradeoff_rows(
        "campaign_strategy.branches.repair_result.objective_tradeoff_report.tradeoffs"
      )
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_contact_allocation_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      rows =
        branch
        |> get_in(["repair_result", "source_contact_allocation_report", "rows"])
        |> List.wrap()
        |> ContactAllocation.rows(
          "campaign_strategy.branches.repair_result.source_contact_allocation_report.rows"
        )

      pack_rows =
        branch
        |> get_in([
          "repair_result",
          "source_contact_allocation_report",
          "reduced_capacity_pack_groups"
        ])
        |> List.wrap()
        |> ContactAllocation.capacity_pack_rows(
          "campaign_strategy.branches.repair_result.source_contact_allocation_report.reduced_capacity_pack_groups"
        )

      (rows ++ pack_rows)
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_repair_contact_allocation_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      rows =
        branch
        |> get_in(["repair_result", "contact_allocation_report", "rows"])
        |> List.wrap()
        |> ContactAllocation.rows(
          "campaign_strategy.branches.repair_result.contact_allocation_report.rows"
        )

      pack_rows =
        branch
        |> get_in(["repair_result", "contact_allocation_report", "reduced_capacity_pack_groups"])
        |> List.wrap()
        |> ContactAllocation.capacity_pack_rows(
          "campaign_strategy.branches.repair_result.contact_allocation_report.reduced_capacity_pack_groups"
        )

      (rows ++ pack_rows)
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_contact_intent_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_contact_intents"])
      |> List.wrap()
      |> ContactIntent.rows("campaign_strategy.branches.repair_result.source_contact_intents")
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp strategy_command_window_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "command_window_report", "rows"])
      |> List.wrap()
      |> CommandWindow.rows()
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
