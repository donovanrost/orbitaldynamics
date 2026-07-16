defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.StatusCounts.StatusCategory.Groups.StatusSets.Categories.CategoryMap.CategoryAliases do
  @moduledoc false

  @groups [
    {"met", ~w(satisfied complete completed selected met)},
    {"unmet",
     ~w(unsatisfied not_satisfied not_met missing missed failed late overdue violated breached)},
    {
      "partial",
      ~w(partial shortfall insufficient below_target below_threshold under_target under_threshold gap has_gap at_risk needs_replan needs_refresh requires_attention degraded behind_plan)
    },
    {"candidate_available", ~w(candidate_found candidate_window_available viable_candidate)},
    {"no_candidate_window", ~w(no_candidate no_window no_viable_candidate)}
  ]

  @categories for {category, statuses} <- @groups,
                  status <- statuses,
                  into: %{},
                  do: {status, category}

  def category_for(status), do: Map.get(@categories, status)
end
