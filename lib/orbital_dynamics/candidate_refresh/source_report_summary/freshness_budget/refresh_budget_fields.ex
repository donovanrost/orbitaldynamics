defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget.RefreshBudgetFields do
  @moduledoc false

  alias __MODULE__.CandidateFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_values: 1]

  def fields(reports) do
    %{
      "invalid_candidate_limit_policy_count" =>
        Enum.count(reports, &(Map.get(&1, "invalid_candidate_limit_policy") == true)),
      "invalid_candidate_limit_policy_reason_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "invalid_candidate_limit_policy_reason"))
        |> count_values()
    }
    |> Map.merge(CandidateFields.fields(reports))
  end
end
