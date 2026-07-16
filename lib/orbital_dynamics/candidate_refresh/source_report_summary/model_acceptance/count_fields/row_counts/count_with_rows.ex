defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.RowCounts.CountWithRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.RowCounts.RowValues

  def count(report, compact_count_fun, row_count_fun) do
    case RowValues.rows(report) do
      [] -> compact_count_fun.(report)
      rows -> row_count_fun.(rows)
    end
  end
end
