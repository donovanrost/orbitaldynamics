defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics do
  @moduledoc false

  alias __MODULE__.{SourceMetadata, StationFeedback}

  def fields(intents) do
    %{
      "station_feedback_count" => StationFeedback.count(intents),
      "station_calendar_status_counts" => StationFeedback.status_counts(intents)
    }
    |> Map.merge(SourceMetadata.fields(intents))
  end
end
