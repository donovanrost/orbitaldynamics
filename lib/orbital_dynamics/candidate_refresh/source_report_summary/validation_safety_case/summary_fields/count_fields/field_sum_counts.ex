defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields.FieldSumCounts do
  @moduledoc false

  alias __MODULE__.CountValues
  alias __MODULE__.FieldSpecs

  def fields(reports) do
    Map.new(FieldSpecs.count_fields(), fn field ->
      {field, CountValues.sum(reports, field)}
    end)
  end
end
