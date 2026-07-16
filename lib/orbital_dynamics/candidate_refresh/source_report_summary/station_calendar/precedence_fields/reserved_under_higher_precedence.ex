defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.PrecedenceFields.ReservedUnderHigherPrecedence do
  @moduledoc false

  alias __MODULE__.GroupedFields
  alias __MODULE__.Values

  def fields(reports) do
    %{
      "reserved_under_higher_precedence_contact_count" =>
        Values.count(reports, "reserved_under_higher_precedence_contact_count"),
      "reserved_under_higher_precedence_contact_ids" =>
        Values.string_values(reports, "reserved_under_higher_precedence_contact_ids"),
      "reserved_under_higher_precedence_reservation_ids" =>
        Values.string_values(reports, "reserved_under_higher_precedence_reservation_ids")
    }
    |> Map.merge(GroupedFields.fields(reports))
  end
end
