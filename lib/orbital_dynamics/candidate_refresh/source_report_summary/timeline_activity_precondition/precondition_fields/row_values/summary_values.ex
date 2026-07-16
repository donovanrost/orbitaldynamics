defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.SummaryValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.PreconditionRows
  alias __MODULE__.FallbackValues

  def row_count(%{"preconditions" => preconditions}) when is_list(preconditions),
    do: length(preconditions)

  def row_count(_summary), do: 0

  def precondition_count(%{} = summary, status) do
    value_from_rows(summary, &PreconditionRows.count(&1, status), fn ->
      FallbackValues.precondition_count(summary, status)
    end)
  end

  def precondition_count(_summary, _status), do: 0

  def precondition_status(%{} = summary) do
    value_from_rows(summary, &PreconditionRows.status/1, fn ->
      FallbackValues.precondition_status(summary)
    end)
  end

  def precondition_types(%{} = summary, field) do
    value_from_rows(
      summary,
      &PreconditionRows.types(&1, FallbackValues.type_status(field)),
      fn -> FallbackValues.precondition_types(summary, field) end
    )
  end

  defp value_from_rows(summary, row_values, fallback_values) do
    case PreconditionRows.values(summary) do
      [] -> fallback_values.()
      precondition_rows -> row_values.(precondition_rows)
    end
  end
end
