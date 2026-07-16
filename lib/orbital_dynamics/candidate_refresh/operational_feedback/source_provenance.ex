defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceProvenance do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.Normalization
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.SourceTrustBoundaries

  def source_result_artifact_field_trust_boundaries(sources) when is_list(sources) do
    sources
    |> Enum.reduce(%{}, fn {_path, feedback, trust_boundary}, boundaries ->
      trust_boundaries =
        trust_boundary
        |> List.wrap()
        |> Enum.map(&RowValues.encode_value/1)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.uniq()
        |> Enum.sort()

      if trust_boundaries == [] do
        boundaries
      else
        feedback
        |> Normalization.normalize_explicit()
        |> Map.drop(["provenance", "trust_boundary"])
        |> Enum.reduce(boundaries, fn {field, values}, boundaries ->
          put_field_trust_boundaries(boundaries, field, values, trust_boundaries)
        end)
      end
    end)
    |> case do
      boundaries when boundaries == %{} -> nil
      boundaries -> boundaries
    end
  end

  def source_result_artifact_field_trust_boundaries(_sources), do: nil

  def put_source_result_artifact_provenance(provenance, []), do: provenance

  def put_source_result_artifact_provenance(provenance, sources) when is_list(sources) do
    input_keys = source_result_artifact_input_keys(sources)
    trust_boundaries = SourceTrustBoundaries.source_result_artifact_trust_boundaries(sources)
    field_trust_boundaries = source_result_artifact_field_trust_boundaries(sources)

    provenance
    |> Map.put("derived_from_source_result_artifact_operational_feedback", true)
    |> maybe_put(
      "source_result_artifact_operational_feedback_paths",
      Enum.map(sources, fn {path, _feedback, _trust_boundary} -> path end)
    )
    |> Map.put("source_result_artifact_operational_feedback_count", length(sources))
    |> maybe_put("source_result_artifact_operational_feedback_input_keys", input_keys)
    |> maybe_put(
      "source_result_artifact_operational_feedback_trust_boundary_status",
      if(trust_boundaries == [], do: "missing", else: "declared")
    )
    |> maybe_put("source_result_artifact_operational_feedback_trust_boundaries", trust_boundaries)
    |> maybe_put(
      "source_result_artifact_operational_feedback_field_trust_boundaries",
      field_trust_boundaries
    )
    |> merge_source_report_input_keys(input_keys)
  end

  def put_source_report_provenance(provenance, [], _source_data_fun), do: provenance

  def put_source_report_provenance(provenance, sources, source_data_fun) do
    {derived_from_field, fields, input_keys} = source_data_fun.(sources)

    provenance
    |> Map.put(derived_from_field, true)
    |> put_source_report_fields(fields)
    |> merge_source_report_input_keys(input_keys)
  end

  def put_invalid_sections_provenance(provenance, []), do: provenance

  def put_invalid_sections_provenance(provenance, invalid_sections) do
    provenance
    |> Map.put(
      "input_keys",
      Enum.uniq(provenance["input_keys"] ++ ["invalid_operational_feedback_input"])
    )
    |> Map.put("invalid_operational_feedback_input", true)
    |> Map.put(
      "invalid_operational_feedback_input_reason",
      "operational_feedback_sections_invalid"
    )
    |> Map.put("invalid_operational_feedback_sections", invalid_sections)
    |> Map.put("source_operational_feedback", %{"invalid_feedback_sections" => invalid_sections})
  end

  def put_timeline_feedback_source_identity(provenance, timeline_source) do
    provenance
    |> maybe_put(
      "source_timeline_feedback_report_contract",
      Map.get(timeline_source, "source_report_contract")
    )
    |> maybe_put(
      "source_timeline_feedback_report_count",
      Map.get(timeline_source, "source_report_count")
    )
    |> maybe_put(
      "source_timeline_feedback_report_row_count",
      Map.get(timeline_source, "source_report_row_count")
    )
    |> maybe_put(
      "source_timeline_feedback_input_keys",
      Map.get(timeline_source, "input_keys")
    )
    |> maybe_put(
      "source_timeline_feedback_trust_boundary_status",
      Map.get(timeline_source, "trust_boundary_status")
    )
    |> maybe_put(
      "source_timeline_feedback_trust_boundaries",
      Map.get(timeline_source, "trust_boundaries")
    )
  end

  def put_timeline_feedback_source_counts(provenance, timeline_source) do
    [
      "source_report_status_counts",
      "source_feedback_kind_counts",
      "source_match_strategy_counts",
      "source_cadence_import_status_counts",
      "source_planned_protection_decision_counts",
      "source_execution_uncertainty_declared_count",
      "source_execution_uncertainty_missing_count",
      "source_station_reservation_evidence_row_count",
      "source_station_reservation_expiration_evidence_row_count",
      "source_operational_feedback_excluded_count"
    ]
    |> Enum.reduce(provenance, fn key, provenance ->
      maybe_put(provenance, key, Map.get(timeline_source, key))
    end)
  end

  def put_timeline_feedback_source_provenance(provenance, [], _paths), do: provenance

  def put_timeline_feedback_source_provenance(provenance, sources, paths)
      when is_list(sources) do
    source = merged_timeline_feedback_source(sources)
    input_keys = Map.get(source, "input_keys", [])

    provenance
    |> Map.put("derived_from_source_timeline_feedback_report", true)
    |> maybe_put("source_timeline_feedback_report_paths", paths)
    |> put_timeline_feedback_source_identity(source)
    |> put_timeline_feedback_source_counts(source)
    |> merge_source_report_input_keys(input_keys)
  end

  def put_timeline_diff_source_provenance(provenance, [], _paths), do: provenance

  def put_timeline_diff_source_provenance(provenance, sources, paths)
      when is_list(sources) do
    source = merged_timeline_diff_source(sources)
    input_keys = Map.get(source, "input_keys", [])

    provenance
    |> Map.put("derived_from_source_timeline_diff_report", true)
    |> maybe_put("source_timeline_diff_report_paths", paths)
    |> maybe_put(
      "source_timeline_diff_report_contract",
      Map.get(source, "source_report_contract")
    )
    |> maybe_put("source_timeline_diff_report_count", Map.get(source, "source_report_count"))
    |> maybe_put(
      "source_timeline_diff_report_row_count",
      Map.get(source, "source_report_row_count")
    )
    |> maybe_put(
      "source_timeline_diff_removed_downlink_count",
      Map.get(source, "source_removed_downlink_count")
    )
    |> maybe_put(
      "source_timeline_diff_removed_observation_count",
      Map.get(source, "source_removed_observation_count")
    )
    |> maybe_put(
      "source_timeline_diff_changed_downlink_shortfall_count",
      Map.get(source, "source_changed_downlink_shortfall_count")
    )
    |> maybe_put(
      "source_timeline_diff_changed_contact_feedback_count",
      Map.get(source, "source_changed_contact_feedback_count")
    )
    |> maybe_put(
      "source_timeline_diff_changed_observation_count",
      Map.get(source, "source_changed_observation_count")
    )
    |> maybe_put(
      "source_timeline_diff_changed_observation_quality_feedback_count",
      Map.get(source, "source_changed_observation_quality_feedback_count")
    )
    |> maybe_put(
      "source_timeline_diff_changed_command_feedback_count",
      Map.get(source, "source_changed_command_feedback_count")
    )
    |> maybe_put(
      "source_timeline_diff_changed_maneuver_feedback_count",
      Map.get(source, "source_changed_maneuver_feedback_count")
    )
    |> maybe_put(
      "source_timeline_diff_trust_boundary_status",
      Map.get(source, "trust_boundary_status")
    )
    |> maybe_put("source_timeline_diff_trust_boundaries", Map.get(source, "trust_boundaries"))
    |> maybe_put(
      "source_timeline_diff_status_counts",
      Map.get(source, "source_diff_status_counts")
    )
    |> maybe_put(
      "source_timeline_diff_required_operator_action_counts",
      Map.get(source, "source_required_operator_action_counts")
    )
    |> merge_source_report_input_keys(input_keys)
  end

  def put_operational_timeline_source_provenance(provenance, [], _paths), do: provenance

  def put_operational_timeline_source_provenance(provenance, sources, paths)
      when is_list(sources) do
    source = merged_operational_timeline_source(sources)
    input_keys = Map.get(source, "input_keys", [])

    provenance
    |> Map.put("derived_from_source_operational_timeline_report", true)
    |> maybe_put("source_operational_timeline_report_paths", paths)
    |> maybe_put(
      "source_operational_timeline_report_contract",
      Map.get(source, "source_report_contract")
    )
    |> maybe_put(
      "source_operational_timeline_report_count",
      Map.get(source, "source_report_count")
    )
    |> maybe_put(
      "source_operational_timeline_report_row_count",
      Map.get(source, "source_report_row_count")
    )
    |> maybe_put(
      "source_operational_timeline_contact_feedback_count",
      Map.get(source, "source_contact_feedback_count")
    )
    |> maybe_put(
      "source_operational_timeline_command_feedback_count",
      Map.get(source, "source_command_feedback_count")
    )
    |> maybe_put(
      "source_operational_timeline_maneuver_feedback_count",
      Map.get(source, "source_maneuver_feedback_count")
    )
    |> maybe_put(
      "source_operational_timeline_observation_feedback_count",
      Map.get(source, "source_observation_feedback_count")
    )
    |> maybe_put(
      "source_operational_timeline_station_throughput_feedback_count",
      Map.get(source, "source_station_throughput_feedback_count")
    )
    |> maybe_put(
      "source_operational_timeline_station_reservation_evidence_row_count",
      Map.get(source, "source_station_reservation_evidence_row_count")
    )
    |> maybe_put(
      "source_operational_timeline_station_reservation_expiration_evidence_row_count",
      Map.get(source, "source_station_reservation_expiration_evidence_row_count")
    )
    |> maybe_put(
      "source_operational_timeline_integrity_issue_count",
      Map.get(source, "source_timeline_integrity_issue_count")
    )
    |> maybe_put(
      "source_operational_timeline_dependency_integrity_issue_count",
      Map.get(source, "source_dependency_integrity_issue_count")
    )
    |> maybe_put(
      "source_operational_timeline_exclusivity_integrity_issue_count",
      Map.get(source, "source_exclusivity_integrity_issue_count")
    )
    |> maybe_put(
      "source_operational_timeline_trust_boundary_status",
      Map.get(source, "trust_boundary_status")
    )
    |> maybe_put(
      "source_operational_timeline_trust_boundaries",
      Map.get(source, "trust_boundaries")
    )
    |> maybe_put(
      "source_operational_timeline_required_operator_action_counts",
      Map.get(source, "source_required_operator_action_counts")
    )
    |> merge_source_report_input_keys(input_keys)
  end

  def put_command_window_source_provenance(provenance, [], _paths), do: provenance

  def put_command_window_source_provenance(provenance, sources, paths)
      when is_list(sources) do
    source = merged_command_window_source(sources)
    input_keys = Map.get(source, "input_keys", [])

    provenance
    |> Map.put("derived_from_source_command_window_report", true)
    |> maybe_put("source_command_window_report_paths", paths)
    |> maybe_put(
      "source_command_window_report_contract",
      Map.get(source, "source_report_contract")
    )
    |> maybe_put("source_command_window_report_count", Map.get(source, "source_report_count"))
    |> maybe_put(
      "source_command_window_report_row_count",
      Map.get(source, "source_report_row_count")
    )
    |> maybe_put(
      "source_command_window_command_feedback_count",
      Map.get(source, "source_command_feedback_count")
    )
    |> maybe_put(
      "source_command_window_trust_boundary_status",
      Map.get(source, "trust_boundary_status")
    )
    |> maybe_put(
      "source_command_window_trust_boundaries",
      Map.get(source, "trust_boundaries")
    )
    |> maybe_put(
      "source_command_window_required_operator_action_counts",
      Map.get(source, "source_required_operator_action_counts")
    )
    |> merge_source_report_input_keys(input_keys)
  end

  def put_maneuver_review_source_provenance(provenance, [], _paths), do: provenance

  def put_maneuver_review_source_provenance(provenance, sources, paths)
      when is_list(sources) do
    source = merged_maneuver_review_source(sources)
    input_keys = Map.get(source, "input_keys", [])

    provenance
    |> Map.put("derived_from_source_maneuver_review_report", true)
    |> maybe_put("source_maneuver_review_report_paths", paths)
    |> maybe_put(
      "source_maneuver_review_report_contract",
      Map.get(source, "source_report_contract")
    )
    |> maybe_put("source_maneuver_review_report_count", Map.get(source, "source_report_count"))
    |> maybe_put(
      "source_maneuver_review_report_row_count",
      Map.get(source, "source_report_row_count")
    )
    |> maybe_put(
      "source_maneuver_review_success_feedback_count",
      Map.get(source, "source_maneuver_success_feedback_count")
    )
    |> maybe_put(
      "source_maneuver_review_execution_uncertainty_declared_count",
      Map.get(source, "source_execution_uncertainty_declared_count")
    )
    |> maybe_put(
      "source_maneuver_review_execution_uncertainty_missing_count",
      Map.get(source, "source_execution_uncertainty_missing_count")
    )
    |> maybe_put(
      "source_maneuver_review_trust_boundary_status",
      Map.get(source, "trust_boundary_status")
    )
    |> maybe_put(
      "source_maneuver_review_trust_boundaries",
      Map.get(source, "trust_boundaries")
    )
    |> maybe_put(
      "source_maneuver_review_required_operator_action_counts",
      Map.get(source, "source_required_operator_action_counts")
    )
    |> merge_source_report_input_keys(input_keys)
  end

  defp merged_timeline_feedback_source(sources) do
    trust_boundaries =
      sources
      |> Enum.flat_map(&List.wrap(Map.get(&1, "trust_boundaries")))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "source_report_contract" => "timeline_feedback_report.v1",
      "source_report_count" => length(sources),
      "source_report_row_count" => sum_source_count(sources, "source_report_row_count"),
      "input_keys" =>
        sources
        |> Enum.flat_map(&List.wrap(Map.get(&1, "input_keys")))
        |> Enum.uniq()
        |> Enum.sort(),
      "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
      "trust_boundaries" => trust_boundaries,
      "source_report_status_counts" =>
        merge_source_count_maps(sources, "source_report_status_counts"),
      "source_feedback_kind_counts" =>
        merge_source_count_maps(sources, "source_feedback_kind_counts"),
      "source_match_strategy_counts" =>
        merge_source_count_maps(sources, "source_match_strategy_counts"),
      "source_cadence_import_status_counts" =>
        merge_source_count_maps(sources, "source_cadence_import_status_counts"),
      "source_station_reservation_evidence_row_count" =>
        sum_source_count(sources, "source_station_reservation_evidence_row_count"),
      "source_station_reservation_expiration_evidence_row_count" =>
        sum_source_count(sources, "source_station_reservation_expiration_evidence_row_count"),
      "source_operational_feedback_excluded_count" =>
        sum_source_count(sources, "source_operational_feedback_excluded_count")
    }
    |> RowValues.compact_nil_values()
  end

  defp merged_timeline_diff_source(sources) do
    trust_boundaries =
      sources
      |> Enum.flat_map(&List.wrap(Map.get(&1, "trust_boundaries")))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "source_report_contract" => "timeline_diff_report.v1",
      "source_report_count" => length(sources),
      "source_report_row_count" => sum_source_count(sources, "source_report_row_count"),
      "source_removed_downlink_count" =>
        sum_source_count(sources, "source_removed_downlink_count"),
      "source_removed_observation_count" =>
        sum_source_count(sources, "source_removed_observation_count"),
      "source_changed_downlink_shortfall_count" =>
        sum_source_count(sources, "source_changed_downlink_shortfall_count"),
      "source_changed_contact_feedback_count" =>
        sum_source_count(sources, "source_changed_contact_feedback_count"),
      "source_changed_observation_count" =>
        sum_source_count(sources, "source_changed_observation_count"),
      "source_changed_observation_quality_feedback_count" =>
        sum_source_count(sources, "source_changed_observation_quality_feedback_count"),
      "source_changed_command_feedback_count" =>
        sum_source_count(sources, "source_changed_command_feedback_count"),
      "source_changed_maneuver_feedback_count" =>
        sum_source_count(sources, "source_changed_maneuver_feedback_count"),
      "input_keys" =>
        sources
        |> Enum.flat_map(&List.wrap(Map.get(&1, "input_keys")))
        |> Enum.uniq()
        |> Enum.sort(),
      "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
      "trust_boundaries" => trust_boundaries,
      "source_diff_status_counts" =>
        merge_source_count_maps(sources, "source_diff_status_counts"),
      "source_required_operator_action_counts" =>
        merge_source_count_maps(sources, "source_required_operator_action_counts")
    }
    |> RowValues.compact_nil_values()
  end

  defp merged_operational_timeline_source(sources) do
    trust_boundaries =
      sources
      |> Enum.flat_map(&List.wrap(Map.get(&1, "trust_boundaries")))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "source_report_contract" => "operational_timeline_report.v1",
      "source_report_count" => length(sources),
      "source_report_row_count" => sum_source_count(sources, "source_report_row_count"),
      "source_contact_feedback_count" =>
        sum_source_count(sources, "source_contact_feedback_count"),
      "source_command_feedback_count" =>
        sum_source_count(sources, "source_command_feedback_count"),
      "source_maneuver_feedback_count" =>
        sum_source_count(sources, "source_maneuver_feedback_count"),
      "source_observation_feedback_count" =>
        sum_source_count(sources, "source_observation_feedback_count"),
      "source_station_throughput_feedback_count" =>
        sum_source_count(sources, "source_station_throughput_feedback_count"),
      "source_timeline_integrity_issue_count" =>
        sum_source_count(sources, "source_timeline_integrity_issue_count"),
      "source_dependency_integrity_issue_count" =>
        sum_source_count(sources, "source_dependency_integrity_issue_count"),
      "source_exclusivity_integrity_issue_count" =>
        sum_source_count(sources, "source_exclusivity_integrity_issue_count"),
      "source_station_reservation_evidence_row_count" =>
        sum_source_count(sources, "source_station_reservation_evidence_row_count"),
      "source_station_reservation_expiration_evidence_row_count" =>
        sum_source_count(sources, "source_station_reservation_expiration_evidence_row_count"),
      "input_keys" =>
        sources
        |> Enum.flat_map(&List.wrap(Map.get(&1, "input_keys")))
        |> Enum.uniq()
        |> Enum.sort(),
      "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
      "trust_boundaries" => trust_boundaries,
      "source_required_operator_action_counts" =>
        merge_source_count_maps(sources, "source_required_operator_action_counts")
    }
    |> RowValues.compact_nil_values()
  end

  defp merged_command_window_source(sources) do
    trust_boundaries =
      sources
      |> Enum.flat_map(&List.wrap(Map.get(&1, "trust_boundaries")))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "source_report_contract" => "command_window_report.v1",
      "source_report_count" => length(sources),
      "source_report_row_count" => sum_source_count(sources, "source_report_row_count"),
      "source_command_feedback_count" =>
        sum_source_count(sources, "source_command_feedback_count"),
      "input_keys" =>
        sources
        |> Enum.flat_map(&List.wrap(Map.get(&1, "input_keys")))
        |> Enum.uniq()
        |> Enum.sort(),
      "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
      "trust_boundaries" => trust_boundaries,
      "source_required_operator_action_counts" =>
        merge_source_count_maps(sources, "source_required_operator_action_counts")
    }
    |> RowValues.compact_nil_values()
  end

  defp merged_maneuver_review_source(sources) do
    trust_boundaries =
      sources
      |> Enum.flat_map(&List.wrap(Map.get(&1, "trust_boundaries")))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "source_report_contract" => "maneuver_review_report.v1",
      "source_report_count" => length(sources),
      "source_report_row_count" => sum_source_count(sources, "source_report_row_count"),
      "source_maneuver_success_feedback_count" =>
        sum_source_count(sources, "source_maneuver_success_feedback_count"),
      "source_execution_uncertainty_declared_count" =>
        sum_source_count(sources, "source_execution_uncertainty_declared_count"),
      "source_execution_uncertainty_missing_count" =>
        sum_source_count(sources, "source_execution_uncertainty_missing_count"),
      "input_keys" =>
        sources
        |> Enum.flat_map(&List.wrap(Map.get(&1, "input_keys")))
        |> Enum.uniq()
        |> Enum.sort(),
      "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
      "trust_boundaries" => trust_boundaries,
      "source_required_operator_action_counts" =>
        merge_source_count_maps(sources, "source_required_operator_action_counts")
    }
    |> RowValues.compact_nil_values()
  end

  defp source_result_artifact_input_keys(sources) do
    sources
    |> source_result_artifact_feedback()
    |> data_keys()
  end

  defp source_result_artifact_feedback(sources) when is_list(sources) do
    sources
    |> Enum.reduce(%{}, fn {_path, feedback, _trust_boundary}, merged ->
      feedback =
        feedback
        |> Normalization.normalize_explicit()
        |> Map.drop(["provenance", "trust_boundary"])

      merge_feedback(merged, feedback)
    end)
    |> compact_feedback()
  end

  defp data_keys(feedback) when is_map(feedback) do
    feedback
    |> Map.drop(["provenance", "trust_boundary", "source", "metadata"])
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  defp merge_feedback(derived, explicit) do
    Map.merge(derived, explicit, fn _key, derived_value, explicit_value ->
      if is_map(derived_value) and is_map(explicit_value) do
        Map.merge(derived_value, explicit_value)
      else
        explicit_value
      end
    end)
  end

  defp compact_feedback(feedback) do
    feedback
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Map.new()
  end

  defp put_field_trust_boundaries(boundaries, field, %{} = values, trust_boundaries) do
    values
    |> Enum.reduce(boundaries, fn {key, value}, boundaries ->
      if value in [nil, %{}, []] do
        boundaries
      else
        put_feedback_trust_boundary(boundaries, field, key, trust_boundaries)
      end
    end)
  end

  defp put_field_trust_boundaries(boundaries, _field, _values, _trust_boundaries),
    do: boundaries

  defp put_feedback_trust_boundary(boundaries, field, key, trust_boundaries) do
    field = RowValues.encode_value(field)
    key = RowValues.encode_value(key) || "default"

    Map.update(boundaries, field, %{key => trust_boundaries}, fn field_boundaries ->
      Map.update(field_boundaries, key, trust_boundaries, fn existing ->
        (List.wrap(existing) ++ trust_boundaries)
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end)
  end

  defp put_source_report_fields(provenance, fields) do
    Enum.reduce(fields, provenance, fn
      {_field, nil}, acc -> acc
      {field, value}, acc -> Map.put(acc, field, value)
    end)
  end

  defp merge_source_report_input_keys(provenance, input_keys) do
    Map.update(provenance, "input_keys", input_keys, fn keys ->
      keys
      |> Kernel.++(input_keys)
      |> Enum.uniq()
      |> Enum.sort()
    end)
  end

  defp sum_source_count(sources, key) do
    sources
    |> Enum.map(&(RowValues.numeric_value(Map.get(&1, key)) || 0))
    |> Enum.sum()
    |> case do
      0 -> nil
      value -> value
    end
  end

  defp merge_source_count_maps(sources, key) do
    sources
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn counts, merged ->
      Enum.reduce(counts, merged, fn {count_key, count_value}, merged ->
        Map.update(merged, count_key, RowValues.numeric_value(count_value) || 0, fn existing ->
          existing + (RowValues.numeric_value(count_value) || 0)
        end)
      end)
    end)
    |> case do
      counts when map_size(counts) == 0 -> nil
      counts -> counts
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
