defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.PreconditionRows do
  @moduledoc false

  alias __MODULE__.StatusValues
  alias __MODULE__.Values

  def values(%{"preconditions" => rows}) when is_list(rows) do
    Values.normalize(rows)
  end

  def values(%{"rows" => rows}) when is_list(rows) do
    Values.from_rows(rows)
  end

  def values(_summary), do: []

  def count(rows, status) do
    StatusValues.count(rows, status)
  end

  def status(rows) do
    StatusValues.status(rows)
  end

  def types(rows, status) do
    StatusValues.types(rows, status)
  end
end
