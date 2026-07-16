defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common do
  @moduledoc false

  alias __MODULE__.AggregateDelegates
  alias __MODULE__.FieldValues
  alias __MODULE__.ReportCounts
  alias __MODULE__.StationReservationEvidence
  alias __MODULE__.TrustBoundaries
  alias __MODULE__.ValueCounts

  defdelegate sum_report_count(reports, counter), to: ReportCounts
  defdelegate sum_report_numeric_values(reports, counter), to: ReportCounts
  defdelegate report_count(value), to: ReportCounts
  defdelegate numeric_report_count(report, field), to: ReportCounts

  defdelegate merge_count_maps(count_maps), to: AggregateDelegates
  defdelegate merge_numeric_maps(numeric_maps), to: AggregateDelegates
  defdelegate merge_nested_numeric_maps(numeric_maps), to: AggregateDelegates
  defdelegate merge_string_lists(lists), to: AggregateDelegates
  defdelegate merge_string_list_maps(list_maps), to: AggregateDelegates
  defdelegate merge_nested_string_list_maps(list_maps), to: AggregateDelegates
  defdelegate merge_numeric_list_maps(list_maps), to: AggregateDelegates

  defdelegate count_values(values), to: ValueCounts
  defdelegate count_source_report_values(values), to: ValueCounts
  defdelegate count_report_field_values(reports, field), to: ValueCounts

  defdelegate sorted_string_values(values), to: FieldValues
  defdelegate source_field_values(source, field), to: FieldValues
  defdelegate source_rows(report), to: FieldValues
  defdelegate source_rows(report, field), to: FieldValues
  defdelegate compact_map(map), to: FieldValues

  defdelegate report_station_reservation_evidence_count(report),
    to: StationReservationEvidence,
    as: :evidence_count

  defdelegate report_station_reservation_expiration_evidence_count(report),
    to: StationReservationEvidence,
    as: :expiration_evidence_count

  defdelegate source_report_trust_boundary_status(reports),
    to: TrustBoundaries,
    as: :source_report_status

  defdelegate source_report_trust_boundaries(reports),
    to: TrustBoundaries,
    as: :source_report_values

  defdelegate normalize_trust_boundaries(values), to: TrustBoundaries, as: :normalize
end
