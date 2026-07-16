defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.InvalidInputs.Rows.RequiredOperatorActions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  def counts(rows) do
    rows
    |> Enum.map(&NormalizedToken.value(Map.get(&1, "required_operator_action")))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> frequencies()
  end

  defp frequencies(values) do
    values
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end
end
