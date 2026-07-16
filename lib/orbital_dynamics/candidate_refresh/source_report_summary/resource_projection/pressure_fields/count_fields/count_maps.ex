defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps do
  @moduledoc false

  alias __MODULE__.CountDelegates
  alias __MODULE__.MergedValues

  def status_counts(report), do: CountDelegates.status_counts(report)

  def ground_station_counts(report), do: CountDelegates.ground_station_counts(report)

  def spacecraft_counts(report), do: CountDelegates.spacecraft_counts(report)

  def activity_id_counts(report), do: CountDelegates.activity_id_counts(report)

  def type_counts(report), do: CountDelegates.type_counts(report)

  def merged_count_values(reports, values_fun) when is_function(values_fun, 1) do
    MergedValues.from_reports(reports, values_fun)
  end
end
