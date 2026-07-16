defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.DirectionFields
  alias __MODULE__.HoldImportFields
  alias __MODULE__.IdentityStatusFields

  def row_count(report), do: CountFields.row_count(report)

  def affected_contact_count(report), do: CountFields.affected_contact_count(report)

  def provider_calendar_contention_group_count(report),
    do: CountFields.provider_calendar_contention_group_count(report)

  def review_count(report), do: CountFields.review_count(report)

  def optional_count_sum(reports, field), do: CountFields.optional_count_sum(reports, field)

  def import_readiness_status_counts(report),
    do: CountFields.import_readiness_status_counts(report)

  def import_classification_counts(report), do: CountFields.import_classification_counts(report)

  def hold_import_status_counts(report) do
    HoldImportFields.hold_import_status_counts(report)
  end

  def hold_required_import_action_counts(report) do
    HoldImportFields.hold_required_import_action_counts(report)
  end

  def evidence_count(report), do: CountFields.evidence_count(report)

  def expiration_evidence_count(report), do: CountFields.expiration_evidence_count(report)

  def match_status_counts(report) do
    IdentityStatusFields.match_status_counts(report)
  end

  def status_counts(report) do
    IdentityStatusFields.status_counts(report)
  end

  def ids(reports) do
    IdentityStatusFields.ids(reports)
  end

  def ids_by_match_status(report) do
    IdentityStatusFields.ids_by_match_status(report)
  end

  def affected_contact_ids(reports) do
    IdentityStatusFields.affected_contact_ids(reports)
  end

  def contact_ids_by_match_status(report) do
    IdentityStatusFields.contact_ids_by_match_status(report)
  end

  def contact_ids_by_status(report) do
    IdentityStatusFields.contact_ids_by_status(report)
  end

  def direction_counts(report) do
    DirectionFields.direction_counts(report)
  end

  def contact_ids_by_direction(report) do
    DirectionFields.contact_ids_by_direction(report)
  end

  def hold_ids_by_direction(report) do
    HoldImportFields.hold_ids_by_direction(report)
  end

  def hold_ids_by_import_status(report) do
    HoldImportFields.hold_ids_by_import_status(report)
  end

  def hold_ids_by_required_import_action(report) do
    HoldImportFields.hold_ids_by_required_import_action(report)
  end

  def hold_contact_ids_by_direction(report) do
    HoldImportFields.hold_contact_ids_by_direction(report)
  end

  def hold_contact_ids_by_import_status(report) do
    HoldImportFields.hold_contact_ids_by_import_status(report)
  end

  def ids_by_status(report) do
    IdentityStatusFields.ids_by_status(report)
  end

  def reserved_by_counts(report) do
    IdentityStatusFields.reserved_by_counts(report)
  end

  def contact_ids_by_reserved_by(report) do
    IdentityStatusFields.contact_ids_by_reserved_by(report)
  end

  def ids_by_reserved_by(report) do
    IdentityStatusFields.ids_by_reserved_by(report)
  end

  def expires_at_s(reports) do
    IdentityStatusFields.expires_at_s(reports)
  end
end
