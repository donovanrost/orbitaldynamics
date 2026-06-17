defmodule OrbitalDynamics.Schema.CandidateRefreshWindowContracts do
  @moduledoc false

  def validate_refreshed_windows(issues, refreshed_windows, callbacks)
      when is_map(refreshed_windows) and is_list(callbacks) do
    issues
    |> expect_type(callbacks, "$.refreshed_windows", refreshed_windows, "access_windows", :list)
    |> expect_type(
      callbacks,
      "$.refreshed_windows",
      refreshed_windows,
      "target_visibility_windows",
      :list
    )
    |> expect_type(
      callbacks,
      "$.refreshed_windows",
      refreshed_windows,
      "eclipse_intervals",
      :list
    )
    |> validate_rows(
      callbacks,
      "$.refreshed_windows.access_windows",
      Map.get(refreshed_windows, "access_windows", []),
      fn acc, path, window -> validate_refreshed_window(acc, path, window, callbacks) end
    )
    |> validate_rows(
      callbacks,
      "$.refreshed_windows.target_visibility_windows",
      Map.get(refreshed_windows, "target_visibility_windows", []),
      fn acc, path, window -> validate_refreshed_window(acc, path, window, callbacks) end
    )
    |> validate_rows(
      callbacks,
      "$.refreshed_windows.eclipse_intervals",
      Map.get(refreshed_windows, "eclipse_intervals", []),
      fn acc, path, window -> validate_refreshed_window(acc, path, window, callbacks) end
    )
  end

  def validate_refreshed_windows(issues, _refreshed_windows, _callbacks), do: issues

  def validate_refreshed_window(issues, path, window, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, window, [
      "id",
      "type",
      "scenario_id",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(callbacks, path, window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_number(callbacks, path, window, "starts_at_s")
    |> expect_number(callbacks, path, window, "ends_at_s")
    |> expect_optional_non_negative_integer(callbacks, path, window, "sample_count")
    |> expect_optional_type(callbacks, path, window, "assumptions", :map)
    |> validate_refreshed_window_assumptions(callbacks, path, window)
    |> validate_interval(callbacks, path, window)
    |> validate_refreshed_window_sample_coverage(callbacks, path, window)
  end

  def validate_remaining_horizon(issues, path, horizon, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, horizon, "schema_contract", "remaining_horizon.v1")
    |> expect_number(callbacks, path, horizon, "starts_at_s")
    |> expect_number(callbacks, path, horizon, "ends_at_s")
    |> expect_number(callbacks, path, horizon, "output_step_s")
    |> validate_interval(callbacks, path, horizon)
    |> validate_remaining_horizon_timing(callbacks, path, horizon)
  end

  defp validate_refreshed_window_assumptions(
         issues,
         callbacks,
         path,
         %{"assumptions" => %{} = assumptions}
       ) do
    issues
    |> expect_optional_number(
      callbacks,
      path <> ".assumptions",
      assumptions,
      "event_time_tolerance_s"
    )
    |> expect_optional_number(callbacks, path <> ".assumptions", assumptions, "max_sample_step_s")
    |> expect_optional_type(
      callbacks,
      path <> ".assumptions",
      assumptions,
      "event_detector",
      :binary
    )
    |> expect_optional_type(
      callbacks,
      path <> ".assumptions",
      assumptions,
      "event_timing_policy",
      :binary
    )
  end

  defp validate_refreshed_window_assumptions(issues, _callbacks, _path, _window), do: issues

  defp validate_refreshed_window_sample_coverage(
         issues,
         callbacks,
         path,
         %{
           "starts_at_s" => starts_at_s,
           "ends_at_s" => ends_at_s,
           "sample_count" => sample_count,
           "assumptions" => %{"max_sample_step_s" => max_sample_step_s}
         }
       )
       when is_number(starts_at_s) and is_number(ends_at_s) and is_integer(sample_count) and
              is_number(max_sample_step_s) do
    duration_s = ends_at_s - starts_at_s

    if duration_s > max(sample_count, 0) * max_sample_step_s + 1.0e-9 do
      [
        error(
          callbacks,
          path <> ".sample_count",
          "must cover window duration using assumptions.max_sample_step_s"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_refreshed_window_sample_coverage(issues, _callbacks, _path, _window), do: issues

  defp validate_remaining_horizon_timing(
         issues,
         callbacks,
         path,
         %{
           "starts_at_s" => starts_at_s,
           "ends_at_s" => ends_at_s,
           "output_step_s" => output_step_s
         } = horizon
       )
       when is_number(starts_at_s) and is_number(ends_at_s) and is_number(output_step_s) do
    duration_s = ends_at_s - starts_at_s

    issues
    |> validate_remaining_horizon_output_step(callbacks, path, output_step_s, duration_s)
    |> expect_field_equals(
      callbacks,
      path,
      horizon,
      "duration_s",
      duration_s,
      "must equal ends_at_s - starts_at_s"
    )
  end

  defp validate_remaining_horizon_timing(issues, _callbacks, _path, _horizon), do: issues

  defp validate_remaining_horizon_output_step(issues, callbacks, path, output_step_s, duration_s) do
    cond do
      output_step_s <= 0 ->
        [error(callbacks, path <> ".output_step_s", "must be greater than 0") | issues]

      duration_s >= 0 and output_step_s > duration_s ->
        [error(callbacks, path <> ".output_step_s", "must not exceed horizon duration") | issues]

      true ->
        issues
    end
  end

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp validate_interval(issues, callbacks, path, map),
    do: apply(require_callback(callbacks, :validate_interval), [issues, path, map])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, key) do
    Keyword.fetch!(callbacks, key)
  end
end
