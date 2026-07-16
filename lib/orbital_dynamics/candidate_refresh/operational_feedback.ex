defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback do
  @moduledoc false

  alias __MODULE__.Aggregation
  alias __MODULE__.CommandWindowRows
  alias __MODULE__.ManeuverReviewRows
  alias __MODULE__.Normalization
  alias __MODULE__.OperationalTimelineRows
  alias __MODULE__.RealizedActivityRows
  alias __MODULE__.ResourceRows
  alias __MODULE__.SourceProvenance
  alias __MODULE__.SourceTrustBoundaries
  alias __MODULE__.TimelineDiffRows

  def data_keys(feedback) when is_map(feedback), do: Aggregation.data_keys(feedback)

  def normalize_explicit(feedback) when is_map(feedback) do
    Normalization.normalize_explicit(feedback)
  end

  def merge(derived, explicit), do: Aggregation.merge(derived, explicit)

  def compact(feedback), do: Aggregation.compact(feedback)

  def key?(key), do: Normalization.key?(key)

  def valid_source_string?(value), do: Normalization.valid_source_string?(value)

  def sanitize_realized_activity_rows(rows),
    do: RealizedActivityRows.sanitize_realized_activity_rows(rows)

  def sanitize_realized_activity_row(%{} = row),
    do: RealizedActivityRows.sanitize_realized_activity_row(row)

  def sanitize_realized_activity_row(row),
    do: RealizedActivityRows.sanitize_realized_activity_row(row)

  def realized_activity_feedback(feedback, prior_candidates) when is_map(feedback),
    do: RealizedActivityRows.realized_activity_feedback(feedback, prior_candidates)

  def realized_activity_feedback(feedback, prior_candidates),
    do: RealizedActivityRows.realized_activity_feedback(feedback, prior_candidates)

  def realized_activity_report(feedback, prior_candidates) when is_map(feedback),
    do: RealizedActivityRows.realized_activity_report(feedback, prior_candidates)

  def realized_activity_report(feedback, prior_candidates),
    do: RealizedActivityRows.realized_activity_report(feedback, prior_candidates)

  def realized_activity_report_for_rows([], prior_candidates),
    do: RealizedActivityRows.realized_activity_report_for_rows([], prior_candidates)

  def realized_activity_report_for_rows(rows, prior_candidates) when is_list(rows),
    do: RealizedActivityRows.realized_activity_report_for_rows(rows, prior_candidates)

  def realized_activity_source(report), do: RealizedActivityRows.realized_activity_source(report)

  def source_result_artifact_feedback(sources) when is_list(sources),
    do: Aggregation.source_result_artifact_feedback(sources)

  def source_result_artifact_feedback(sources),
    do: Aggregation.source_result_artifact_feedback(sources)

  def source_report_feedback(reports, feedback_fun)
      when is_list(reports) and is_function(feedback_fun, 1),
      do: Aggregation.source_report_feedback(reports, feedback_fun)

  def source_report_feedback(reports, feedback_fun),
    do: Aggregation.source_report_feedback(reports, feedback_fun)

  def source_result_artifact_input_keys(sources),
    do: Aggregation.source_result_artifact_input_keys(sources)

  def source_result_artifact_trust_boundaries(sources),
    do: SourceTrustBoundaries.source_result_artifact_trust_boundaries(sources)

  def source_result_artifact_field_trust_boundaries(sources) when is_list(sources) do
    SourceProvenance.source_result_artifact_field_trust_boundaries(sources)
  end

  def source_result_artifact_field_trust_boundaries(sources),
    do: SourceProvenance.source_result_artifact_field_trust_boundaries(sources)

  def put_source_result_artifact_provenance(provenance, []),
    do: SourceProvenance.put_source_result_artifact_provenance(provenance, [])

  def put_source_result_artifact_provenance(provenance, sources) when is_list(sources) do
    SourceProvenance.put_source_result_artifact_provenance(provenance, sources)
  end

  def put_source_report_provenance(provenance, [], source_data_fun),
    do: SourceProvenance.put_source_report_provenance(provenance, [], source_data_fun)

  def put_source_report_provenance(provenance, sources, source_data_fun) do
    SourceProvenance.put_source_report_provenance(provenance, sources, source_data_fun)
  end

  def put_invalid_sections_provenance(provenance, []),
    do: SourceProvenance.put_invalid_sections_provenance(provenance, [])

  def put_invalid_sections_provenance(provenance, invalid_sections) do
    SourceProvenance.put_invalid_sections_provenance(provenance, invalid_sections)
  end

  def put_timeline_feedback_source_identity(provenance, timeline_source),
    do: SourceProvenance.put_timeline_feedback_source_identity(provenance, timeline_source)

  def put_timeline_feedback_source_counts(provenance, timeline_source),
    do: SourceProvenance.put_timeline_feedback_source_counts(provenance, timeline_source)

  def put_timeline_feedback_source_provenance(provenance, sources, paths),
    do: SourceProvenance.put_timeline_feedback_source_provenance(provenance, sources, paths)

  def put_timeline_diff_source_provenance(provenance, sources, paths),
    do: SourceProvenance.put_timeline_diff_source_provenance(provenance, sources, paths)

  def put_operational_timeline_source_provenance(provenance, sources, paths),
    do: SourceProvenance.put_operational_timeline_source_provenance(provenance, sources, paths)

  def put_command_window_source_provenance(provenance, sources, paths),
    do: SourceProvenance.put_command_window_source_provenance(provenance, sources, paths)

  def put_maneuver_review_source_provenance(provenance, sources, paths),
    do: SourceProvenance.put_maneuver_review_source_provenance(provenance, sources, paths)

  def source_timeline_feedback_trust_boundaries(reports),
    do: SourceTrustBoundaries.source_timeline_feedback_trust_boundaries(reports)

  def source_operational_timeline_trust_boundaries(reports),
    do: SourceTrustBoundaries.source_operational_timeline_trust_boundaries(reports)

  def put_source_operational_timeline_trust_boundary(feedback, reports),
    do: SourceTrustBoundaries.put_source_operational_timeline_trust_boundary(feedback, reports)

  def put_source_timeline_feedback_trust_boundary(feedback, reports),
    do: SourceTrustBoundaries.put_source_timeline_feedback_trust_boundary(feedback, reports)

  def source_timeline_diff_trust_boundaries(reports),
    do: SourceTrustBoundaries.source_timeline_diff_trust_boundaries(reports)

  def put_source_timeline_diff_trust_boundary(feedback, reports),
    do: SourceTrustBoundaries.put_source_timeline_diff_trust_boundary(feedback, reports)

  def source_command_window_trust_boundaries(reports),
    do: SourceTrustBoundaries.source_command_window_trust_boundaries(reports)

  def put_source_command_window_trust_boundary(feedback, reports),
    do: SourceTrustBoundaries.put_source_command_window_trust_boundary(feedback, reports)

  def source_maneuver_review_trust_boundaries(reports),
    do: SourceTrustBoundaries.source_maneuver_review_trust_boundaries(reports)

  def put_source_maneuver_review_trust_boundary(feedback, reports),
    do: SourceTrustBoundaries.put_source_maneuver_review_trust_boundary(feedback, reports)

  def command_window_report_feedback(report),
    do: CommandWindowRows.command_window_report_feedback(report)

  def operational_timeline_report_feedback(report),
    do: OperationalTimelineRows.operational_timeline_report_feedback(report)

  def timeline_diff_report_feedback(report),
    do: TimelineDiffRows.report_feedback(report)

  def operational_timeline_contact_feedback_row?(row),
    do: OperationalTimelineRows.operational_timeline_contact_feedback_row?(row)

  def operational_timeline_command_feedback_row?(row),
    do: OperationalTimelineRows.operational_timeline_command_feedback_row?(row)

  def operational_timeline_maneuver_feedback_row?(row),
    do: OperationalTimelineRows.operational_timeline_maneuver_feedback_row?(row)

  def operational_timeline_observation_feedback_row?(row),
    do: OperationalTimelineRows.operational_timeline_observation_feedback_row?(row)

  def operational_timeline_station_throughput_feedback_row?(row),
    do: OperationalTimelineRows.operational_timeline_station_throughput_feedback_row?(row)

  def operational_timeline_feedback_key(row),
    do: OperationalTimelineRows.operational_timeline_feedback_key(row)

  def timeline_diff_removed_downlink_feedback_row?(%{} = row),
    do: TimelineDiffRows.removed_downlink_feedback_row?(row)

  def timeline_diff_changed_downlink_shortfall_feedback_row?(%{} = row),
    do: TimelineDiffRows.changed_downlink_shortfall_feedback_row?(row)

  def timeline_diff_changed_contact_feedback_row?(%{} = row),
    do: TimelineDiffRows.changed_contact_feedback_row?(row)

  def timeline_diff_changed_observation_quality_feedback_row?(%{} = row),
    do: TimelineDiffRows.changed_observation_quality_feedback_row?(row)

  def timeline_diff_changed_command_feedback_row?(%{} = row),
    do: TimelineDiffRows.changed_command_feedback_row?(row)

  def timeline_diff_changed_maneuver_feedback_row?(%{} = row),
    do: TimelineDiffRows.changed_maneuver_feedback_row?(row)

  def timeline_diff_status(row), do: TimelineDiffRows.status(row)

  def timeline_diff_changed_fields(row), do: TimelineDiffRows.changed_fields(row)

  def timeline_diff_observation_activity?(row),
    do: TimelineDiffRows.observation_activity?(row)

  def timeline_diff_observation_activity?(row, side),
    do: TimelineDiffRows.observation_activity?(row, side)

  def timeline_diff_changed_observation_target_id(row),
    do: TimelineDiffRows.changed_observation_target_id(row)

  def timeline_diff_changed_observation_success_factor(row),
    do: TimelineDiffRows.changed_observation_success_factor(row)

  def maneuver_review_report_feedback(report),
    do: ManeuverReviewRows.maneuver_review_report_feedback(report)

  def command_window_feedback_row?(row), do: CommandWindowRows.command_window_feedback_row?(row)

  def command_window_feedback_key(row), do: CommandWindowRows.command_window_feedback_key(row)

  def command_window_success_factor(row), do: CommandWindowRows.command_window_success_factor(row)

  def merge_command_window_feedback(row, feedback),
    do: CommandWindowRows.merge_command_window_feedback(row, feedback)

  def maneuver_review_feedback_row?(row),
    do: ManeuverReviewRows.maneuver_review_feedback_row?(row)

  def maneuver_review_success_feedback_row?(row),
    do: ManeuverReviewRows.maneuver_review_success_feedback_row?(row)

  def maneuver_review_execution_uncertainty_feedback_row?(row),
    do: ManeuverReviewRows.maneuver_review_execution_uncertainty_feedback_row?(row)

  def maneuver_review_feedback_key(row), do: ManeuverReviewRows.maneuver_review_feedback_key(row)

  def maneuver_review_success_factor(row),
    do: ManeuverReviewRows.maneuver_review_success_factor(row)

  def merge_maneuver_review_feedback(row, feedback),
    do: ManeuverReviewRows.merge_maneuver_review_feedback(row, feedback)

  def maneuver_review_execution_uncertainty_status(row),
    do: ManeuverReviewRows.maneuver_review_execution_uncertainty_status(row)

  def put_source_realized_activity_summary(provenance, rows),
    do: RealizedActivityRows.put_source_realized_activity_summary(provenance, rows)

  def link_capacity_station_throughput_factor(row),
    do: ResourceRows.link_capacity_station_throughput_factor(row)

  def link_capacity_feedback_rows(report), do: ResourceRows.link_capacity_feedback_rows(report)

  def link_capacity_station_id(row), do: ResourceRows.link_capacity_station_id(row)

  def link_capacity_row_feedback(row, station_id),
    do: ResourceRows.link_capacity_row_feedback(row, station_id)

  def resource_projection_row_feedback(row, spacecraft_id),
    do: ResourceRows.resource_projection_row_feedback(row, spacecraft_id)

  def resource_filter_row_feedback(row), do: ResourceRows.resource_filter_row_feedback(row)

  def realized_activity_unit_interval_values(row),
    do: RealizedActivityRows.realized_activity_unit_interval_values(row)

  def realized_activity_nonnegative_number_values(row),
    do: RealizedActivityRows.realized_activity_nonnegative_number_values(row)

  def value_missing?(value), do: RealizedActivityRows.value_missing?(value)

  def unit_interval_number_status(value),
    do: RealizedActivityRows.unit_interval_number_status(value)

  def nonnegative_number_status(value),
    do: RealizedActivityRows.nonnegative_number_status(value)

  def row_id(row), do: RealizedActivityRows.row_id(row)

  def nested_identifier(row, object_key, identity_keys),
    do: RealizedActivityRows.nested_identifier(row, object_key, identity_keys)

  def raw_identifier(value), do: RealizedActivityRows.raw_identifier(value)

  def unit_interval_field?(field)
      when field in [
             "contact_success_rate",
             "observation_success_rate",
             "maneuver_success_rate",
             "command_success_rate",
             "station_throughput_factor",
             "image_quality_score",
             "cloud_cover_fraction",
             "blur_score"
           ],
      do: true

  def unit_interval_field?(_field), do: false

  def resource_availability_boolean_value(value),
    do: Normalization.resource_availability_boolean_value(value)

  def invalid_sections(feedback), do: Normalization.invalid_sections(feedback)

  def normalize_resource_margin_aliases(%{} = value) do
    Normalization.normalize_resource_margin_aliases(value)
  end
end
