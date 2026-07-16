defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.PrecedenceFields.ReservedUnderHigherPrecedence.GroupedFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.PrecedenceFields.ReservedUnderHigherPrecedence.Values

  def fields(reports) do
    %{
      "reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
        Values.string_list_map(
          reports,
          "reserved_under_higher_precedence_contact_ids_by_applied_availability"
        ),
      "reserved_under_higher_precedence_contact_ids_by_reservation_status" =>
        Values.string_list_map(
          reports,
          "reserved_under_higher_precedence_contact_ids_by_reservation_status"
        ),
      "reserved_under_higher_precedence_contact_ids_by_reserved_by" =>
        Values.string_list_map(
          reports,
          "reserved_under_higher_precedence_contact_ids_by_reserved_by"
        ),
      "reserved_under_higher_precedence_reservation_ids_by_status" =>
        Values.string_list_map(
          reports,
          "reserved_under_higher_precedence_reservation_ids_by_status"
        ),
      "reserved_under_higher_precedence_reservation_ids_by_reserved_by" =>
        Values.string_list_map(
          reports,
          "reserved_under_higher_precedence_reservation_ids_by_reserved_by"
        )
    }
  end
end
