defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence do
  @moduledoc false

  alias __MODULE__.Values

  defdelegate fields(reports), to: Values
  defdelegate count_sum(reports, field), to: Values
  defdelegate count_map_merge(reports, field), to: Values
  defdelegate string_values(reports, field), to: Values
  defdelegate string_list_map_merge(reports, field), to: Values
  defdelegate count_map(report, field), to: Values
end
