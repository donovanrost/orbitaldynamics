defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields.RowIssues.Predicates do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.IssueValues

  def row_predicate(:any), do: &integrity_issue_row?/1
  def row_predicate(:dependency), do: &dependency_issue_row?/1
  def row_predicate(:exclusivity), do: &exclusivity_issue_row?/1

  defp integrity_issue_row?(%{} = row), do: has_issue?(row, FieldSpecs.issue_fields())

  defp dependency_issue_row?(%{} = row), do: has_issue?(row, FieldSpecs.dependency_issue_fields())

  defp exclusivity_issue_row?(%{} = row),
    do: has_issue?(row, FieldSpecs.exclusivity_issue_fields())

  defp has_issue?(row, fields) do
    Enum.any?(fields, fn field ->
      IssueValues.present?(row, field)
    end)
  end
end
