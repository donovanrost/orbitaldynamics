defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ContactNetworkFields do
  @moduledoc false

  alias __MODULE__.ContactFields
  alias __MODULE__.FieldGroups

  def source_report_fields(refresh_or_artifact, source_reports) do
    ContactFields.source_report_fields(source_reports)
    |> Map.merge(FieldGroups.contention_fields(refresh_or_artifact, source_reports))
    |> Map.merge(FieldGroups.station_fields(refresh_or_artifact, source_reports))
  end
end
