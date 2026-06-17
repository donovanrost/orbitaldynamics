defmodule OrbitalDynamics.Schema.ResultArtifactContracts do
  @moduledoc false

  def validate(issues, path, artifact, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, artifact, "schema_version", 1)
    |> validate_stable_ids(callbacks, path, artifact, ["study_id"])
    |> expect_type(callbacks, path, artifact, "run", :map)
    |> expect_type(callbacks, path, artifact, "assumptions", :map)
    |> expect_type(callbacks, path, artifact, "metadata", :map)
    |> expect_type(callbacks, path, artifact, "trajectories", :list)
    |> expect_type(callbacks, path, artifact, "access_windows", :list)
    |> expect_type(callbacks, path, artifact, "eclipse_intervals", :list)
    |> expect_type(callbacks, path, artifact, "target_visibility_windows", :list)
    |> expect_type(callbacks, path, artifact, "ground_track_crossings", :list)
    |> expect_type(callbacks, path, artifact, "errors", :list)
    |> expect_type(callbacks, path, artifact, "execution_report", :map)
    |> expect_type(callbacks, path, artifact, "payload_metrics", :map)
    |> validate_nested(path, artifact, callbacks)
  end

  defp validate_nested(issues, path, artifact, callbacks) do
    issues =
      case Map.get(artifact, "execution_report") do
        %{} = execution_report ->
          validate_execution_report(callbacks, execution_report) ++ issues

        _value ->
          issues
      end

    issues
    |> validate_payload_metrics(path, artifact, callbacks)
    |> validate_rows(
      callbacks,
      "#{path}.ground_track_crossings",
      Map.get(artifact, "ground_track_crossings", []),
      fn acc, row_path, row -> validate_ground_track_crossing(acc, row_path, row, callbacks) end
    )
  end

  defp validate_payload_metrics(
         issues,
         path,
         %{"payload_metrics" => %{} = metrics} = artifact,
         callbacks
       ) do
    metrics_path = "#{path}.payload_metrics"

    issues
    |> require_fields(callbacks, metrics_path, metrics, [
      "schema_contract",
      "artifact_body_bytes",
      "top_level_key_count",
      "sections"
    ])
    |> expect_equal(
      callbacks,
      metrics_path,
      metrics,
      "schema_contract",
      "result_payload_metrics.v1"
    )
    |> expect_non_negative_integer(callbacks, metrics_path, metrics, "artifact_body_bytes")
    |> expect_non_negative_integer(callbacks, metrics_path, metrics, "top_level_key_count")
    |> expect_type(callbacks, metrics_path, metrics, "sections", :map)
    |> validate_payload_metrics_counts(path, artifact, metrics, callbacks)
  end

  defp validate_payload_metrics(issues, _path, _artifact, _callbacks), do: issues

  defp validate_payload_metrics_counts(issues, path, artifact, metrics, callbacks) do
    expected_section_keys =
      artifact
      |> Map.delete("payload_metrics")
      |> Map.keys()
      |> Enum.sort()

    sections = Map.get(metrics, "sections")
    metrics_path = "#{path}.payload_metrics"

    issues
    |> expect_field_equals(
      callbacks,
      metrics_path,
      metrics,
      "top_level_key_count",
      length(expected_section_keys),
      "must equal top-level artifact key count excluding payload_metrics"
    )
    |> validate_payload_metric_section_keys(
      callbacks,
      metrics_path,
      sections,
      expected_section_keys
    )
    |> validate_payload_metric_sections(callbacks, metrics_path, sections)
  end

  defp validate_payload_metric_section_keys(
         issues,
         callbacks,
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
          callbacks,
          "#{metrics_path}.sections",
          "must contain one section per top-level artifact key excluding payload_metrics"
        )
        | issues
      ]
    end
  end

  defp validate_payload_metric_section_keys(
         issues,
         _callbacks,
         _metrics_path,
         _sections,
         _expected_section_keys
       ),
       do: issues

  defp validate_payload_metric_sections(issues, callbacks, metrics_path, sections)
       when is_map(sections) do
    Enum.reduce(sections, issues, fn
      {section, %{} = metrics}, acc ->
        section_path = "#{metrics_path}.sections.#{section}"

        acc
        |> expect_non_negative_integer(callbacks, section_path, metrics, "bytes")
        |> expect_optional_non_negative_integer(callbacks, section_path, metrics, "row_count")

      {section, _metrics}, acc ->
        [error(callbacks, "#{metrics_path}.sections.#{section}", "must be an object") | acc]
    end)
  end

  defp validate_payload_metric_sections(issues, _callbacks, _metrics_path, _sections), do: issues

  defp validate_ground_track_crossing(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "scenario_id",
      "event_type",
      "crossing",
      "target_deg",
      "frame",
      "starts_at_s",
      "assumptions"
    ])
    |> validate_stable_ids(callbacks, path, row, ["scenario_id", "request_id"])
    |> expect_one_of(callbacks, path, row, "crossing", ["latitude", "longitude"])
    |> expect_one_of(callbacks, path, row, "event_type", [
      "latitude_crossing",
      "longitude_crossing"
    ])
    |> expect_one_of(callbacks, path, row, "frame", ["inertial", "body_fixed"])
    |> expect_number(callbacks, path, row, "target_deg")
    |> expect_number(callbacks, path, row, "starts_at_s")
    |> expect_type(callbacks, path, row, "assumptions", :map)
  end

  defp validate_execution_report(callbacks, execution_report),
    do: apply(Keyword.fetch!(callbacks, :validate_execution_report), [execution_report])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
