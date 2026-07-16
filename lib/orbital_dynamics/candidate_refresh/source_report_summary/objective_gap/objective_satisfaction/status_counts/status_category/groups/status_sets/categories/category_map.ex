defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.StatusCounts.StatusCategory.Groups.StatusSets.Categories.CategoryMap do
  @moduledoc false

  alias __MODULE__.CategoryAliases

  def value(status), do: CategoryAliases.category_for(status) || status
end
