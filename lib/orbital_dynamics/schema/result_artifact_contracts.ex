defmodule OrbitalDynamics.Schema.ResultArtifactContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_number_vector: 3,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, artifact, execution_report_validator)
      when is_function(execution_report_validator, 1) do
    issues
    |> expect_equal(path, artifact, "schema_version", 1)
    |> validate_stable_ids(path, artifact, ["study_id"])
    |> expect_type(path, artifact, "run", :map)
    |> expect_type(path, artifact, "assumptions", :map)
    |> expect_type(path, artifact, "metadata", :map)
    |> expect_type(path, artifact, "trajectories", :list)
    |> expect_type(path, artifact, "access_windows", :list)
    |> expect_type(path, artifact, "eclipse_intervals", :list)
    |> expect_type(path, artifact, "target_visibility_windows", :list)
    |> expect_type(path, artifact, "ground_track_crossings", :list)
    |> expect_type(path, artifact, "errors", :list)
    |> expect_type(path, artifact, "execution_report", :map)
    |> expect_type(path, artifact, "payload_metrics", :map)
    |> validate_nested(path, artifact, execution_report_validator)
  end

  defp validate_nested(issues, path, artifact, execution_report_validator) do
    issues =
      case Map.get(artifact, "execution_report") do
        %{} = execution_report ->
          execution_report_validator.(execution_report) ++ issues

        _value ->
          issues
      end

    issues
    |> validate_payload_metrics(path, artifact)
    |> validate_rows(
      "#{path}.trajectories",
      Map.get(artifact, "trajectories", []),
      &validate_trajectory/3
    )
    |> validate_rows(
      "#{path}.ground_track_crossings",
      Map.get(artifact, "ground_track_crossings", []),
      &validate_ground_track_crossing/3
    )
  end

  defp validate_payload_metrics(
         issues,
         path,
         %{"payload_metrics" => %{} = metrics} = artifact
       ) do
    metrics_path = "#{path}.payload_metrics"

    issues
    |> require_fields(metrics_path, metrics, [
      "schema_contract",
      "artifact_body_bytes",
      "top_level_key_count",
      "sections"
    ])
    |> expect_equal(
      metrics_path,
      metrics,
      "schema_contract",
      "result_payload_metrics.v1"
    )
    |> expect_non_negative_integer(metrics_path, metrics, "artifact_body_bytes")
    |> expect_non_negative_integer(metrics_path, metrics, "top_level_key_count")
    |> expect_type(metrics_path, metrics, "sections", :map)
    |> validate_payload_metrics_counts(path, artifact, metrics)
  end

  defp validate_payload_metrics(issues, _path, _artifact), do: issues

  defp validate_payload_metrics_counts(issues, path, artifact, metrics) do
    expected_section_keys =
      artifact
      |> Map.delete("payload_metrics")
      |> Map.keys()
      |> Enum.sort()

    sections = Map.get(metrics, "sections")
    metrics_path = "#{path}.payload_metrics"

    issues
    |> expect_field_equals(
      metrics_path,
      metrics,
      "top_level_key_count",
      length(expected_section_keys),
      "must equal top-level artifact key count excluding payload_metrics"
    )
    |> validate_payload_metric_section_keys(
      metrics_path,
      sections,
      expected_section_keys
    )
    |> validate_payload_metric_sections(metrics_path, sections)
  end

  defp validate_payload_metric_section_keys(
         issues,
         metrics_path,
         sections,
         expected_section_keys
       )
       when is_map(sections) do
    section_keys =
      sections
      |> Map.keys()
      |> Enum.sort()

    if section_keys == expected_section_keys do
      issues
    else
      [
        error(
          "#{metrics_path}.sections",
          "must contain one section per top-level artifact key excluding payload_metrics"
        )
        | issues
      ]
    end
  end

  defp validate_payload_metric_section_keys(
         issues,
         _metrics_path,
         _sections,
         _expected_section_keys
       ),
       do: issues

  defp validate_payload_metric_sections(issues, metrics_path, sections)
       when is_map(sections) do
    Enum.reduce(sections, issues, fn
      {section, %{} = metrics}, acc ->
        section_path = "#{metrics_path}.sections.#{section}"

        acc
        |> expect_non_negative_integer(section_path, metrics, "bytes")
        |> expect_optional_non_negative_integer(section_path, metrics, "row_count")

      {section, _metrics}, acc ->
        [error("#{metrics_path}.sections.#{section}", "must be an object") | acc]
    end)
  end

  defp validate_payload_metric_sections(issues, _metrics_path, _sections), do: issues

  defp validate_trajectory(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "scenario_id",
      "sample_count",
      "starts_at_s",
      "ends_at_s",
      "final_position_km",
      "final_velocity_km_s",
      "assumptions"
    ])
    |> validate_stable_ids(path, row, ["scenario_id"])
    |> expect_type(path, row, "sample_count", :integer)
    |> expect_number(path, row, "starts_at_s")
    |> expect_number(path, row, "ends_at_s")
    |> expect_number_vector("#{path}.final_position_km", Map.get(row, "final_position_km"))
    |> expect_number_vector(
      "#{path}.final_velocity_km_s",
      Map.get(row, "final_velocity_km_s")
    )
    |> expect_type(path, row, "assumptions", :map)
    |> validate_optional_trajectory_node(path, row)
  end

  defp validate_optional_trajectory_node(issues, path, row) do
    if Map.has_key?(row, "node") and not is_binary(Map.get(row, "node")) do
      [error("#{path}.node", "must be a string") | issues]
    else
      issues
    end
  end

  defp validate_ground_track_crossing(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "scenario_id",
      "event_type",
      "crossing",
      "target_deg",
      "frame",
      "starts_at_s",
      "assumptions"
    ])
    |> validate_stable_ids(path, row, ["scenario_id", "request_id"])
    |> expect_one_of(path, row, "crossing", ["latitude", "longitude"])
    |> expect_one_of(path, row, "event_type", [
      "latitude_crossing",
      "longitude_crossing"
    ])
    |> expect_one_of(path, row, "frame", ["inertial", "body_fixed"])
    |> expect_number(path, row, "target_deg")
    |> expect_number(path, row, "starts_at_s")
    |> expect_type(path, row, "assumptions", :map)
  end

  defp error(path, message),
    do: %{"severity" => "error", "path" => path, "message" => message}
end
