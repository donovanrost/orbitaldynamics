defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.HoldFields.HoldIds do
  @moduledoc false

  alias __MODULE__.DirectionMaps
  alias __MODULE__.FieldValues

  def fields(reports) do
    %{
      "reservation_hold_ids" => FieldValues.string_list(reports, "reservation_hold_ids"),
      "reservation_hold_ids_by_expiration_status" =>
        FieldValues.string_list_map(reports, "reservation_hold_ids_by_expiration_status"),
      "reservation_hold_ids_by_status" =>
        FieldValues.string_list_map(reports, "reservation_hold_ids_by_status"),
      "reservation_hold_ids_by_reserved_by" =>
        FieldValues.string_list_map(reports, "reservation_hold_ids_by_reserved_by"),
      "reservation_hold_ids_by_row_type" =>
        FieldValues.string_list_map(reports, "reservation_hold_ids_by_row_type"),
      "reservation_hold_contact_ids_by_expiration_status" =>
        FieldValues.string_list_map(
          reports,
          "reservation_hold_contact_ids_by_expiration_status"
        ),
      "reservation_hold_review_contact_ids" =>
        FieldValues.string_list(reports, "review_contact_ids")
    }
    |> Map.merge(DirectionMaps.fields(reports))
  end
end
