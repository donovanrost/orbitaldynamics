defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.InvalidInputs.Rows do
  @moduledoc false

  alias __MODULE__.IdValues
  alias __MODULE__.RequiredOperatorActions

  def count(report) do
    report
    |> values()
    |> length()
  end

  def ids(report) do
    IdValues.ids(report)
  end

  def required_operator_action_counts(report) do
    report
    |> values()
    |> RequiredOperatorActions.counts()
  end

  defp values(report), do: Map.get(report, "invalid_contact_inputs", [])
end
