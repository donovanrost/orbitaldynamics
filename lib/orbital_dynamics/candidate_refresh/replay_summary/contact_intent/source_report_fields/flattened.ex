defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.CapacityPack
  alias __MODULE__.DirectionRouting
  alias __MODULE__.StationFeedback
  import __MODULE__.Aggregation

  def source_report_fields(source_reports) do
    %{
      "source_report_contact_intent_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_contact_intent_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_contact_intent_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_contact_intent_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
    |> Map.merge(CapacityPack.fields(source_reports))
    |> Map.merge(DirectionRouting.fields(source_reports))
    |> Map.merge(StationFeedback.fields(source_reports))
  end
end
