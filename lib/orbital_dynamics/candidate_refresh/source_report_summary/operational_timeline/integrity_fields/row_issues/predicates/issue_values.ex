defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields.RowIssues.Predicates.IssueValues do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  def present?(row, field) do
    row
    |> value(field)
    |> value_present?()
  end

  defp value(row, field) do
    row[field] ||
      context_value(row, field)
  end

  defp context_value(row, field) do
    Enum.find_value(FieldSpecs.context_fields(), &get_in(row, [&1, field]))
  end

  defp value_present?(values) when is_list(values) do
    Enum.any?(values, &value_present?/1)
  end

  defp value_present?(%{} = value), do: map_size(value) > 0
  defp value_present?(value), do: value not in [nil, "", false]
end
