defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary do
  @moduledoc false

  alias __MODULE__.InputContractCounts
  alias __MODULE__.IntegerValue
  alias __MODULE__.MapCounts
  alias __MODULE__.StatusCount

  def count(summary, fallback_field) do
    case MapCounts.count(summary) do
      {:ok, count} -> count
      :error -> integer(summary, fallback_field)
    end
  end

  def status_count(summary, status, fallback_field) do
    StatusCount.count(summary, status, fallback_field)
  end

  def input_contract_counts(report) do
    InputContractCounts.counts(report)
  end

  def integer(%{} = summary, field) do
    IntegerValue.from_field(summary, field)
  end
end
