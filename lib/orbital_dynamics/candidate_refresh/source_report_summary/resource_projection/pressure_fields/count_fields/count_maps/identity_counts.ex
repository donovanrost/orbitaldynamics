defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts do
  @moduledoc false

  alias __MODULE__.CountValues

  defdelegate ground_station_counts(report), to: CountValues

  defdelegate spacecraft_counts(report), to: CountValues

  defdelegate activity_id_counts(report), to: CountValues
end
