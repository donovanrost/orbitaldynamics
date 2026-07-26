defmodule OrbitalDynamics.Schema.CandidateRefreshWindowContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_number: 4,
      expect_optional_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_interval: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate_refreshed_windows(issues, refreshed_windows) when is_map(refreshed_windows) do
    validate_refreshed_windows(issues, "$.refreshed_windows", refreshed_windows)
  end

  def validate_refreshed_windows(issues, _refreshed_windows), do: issues

  def validate_optional_refreshed_windows(issues, _path, nil), do: issues

  def validate_optional_refreshed_windows(issues, path, %{} = refreshed_windows) do
    validate_refreshed_windows(issues, path, refreshed_windows)
  end

  def validate_optional_refreshed_windows(issues, path, _refreshed_windows),
    do: [error(path, "must be an object") | issues]

  def validate_refreshed_windows(issues, path, refreshed_windows)
      when is_map(refreshed_windows) do
    issues
    |> expect_type(path, refreshed_windows, "access_windows", :list)
    |> expect_type(
      path,
      refreshed_windows,
      "target_visibility_windows",
      :list
    )
    |> expect_type(
      path,
      refreshed_windows,
      "eclipse_intervals",
      :list
    )
    |> validate_rows(
      "#{path}.access_windows",
      Map.get(refreshed_windows, "access_windows", []),
      &validate_refreshed_window/3
    )
    |> validate_rows(
      "#{path}.target_visibility_windows",
      Map.get(refreshed_windows, "target_visibility_windows", []),
      &validate_refreshed_window/3
    )
    |> validate_rows(
      "#{path}.eclipse_intervals",
      Map.get(refreshed_windows, "eclipse_intervals", []),
      &validate_refreshed_window/3
    )
  end

  def validate_refreshed_window(issues, path, window) do
    issues
    |> require_fields(path, window, [
      "id",
      "type",
      "scenario_id",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(path, window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_number(path, window, "starts_at_s")
    |> expect_number(path, window, "ends_at_s")
    |> expect_optional_non_negative_integer(path, window, "sample_count")
    |> expect_optional_type(path, window, "assumptions", :map)
    |> validate_refreshed_window_assumptions(path, window)
    |> validate_interval(path, window)
    |> validate_refreshed_window_sample_coverage(path, window)
  end

  def validate_remaining_horizon(issues, path, horizon) do
    issues
    |> expect_equal(path, horizon, "schema_contract", "remaining_horizon.v1")
    |> validate_embedded_remaining_horizon_fields(path, horizon)
  end

  def validate_optional_embedded_remaining_horizon(issues, _path, nil), do: issues

  def validate_optional_embedded_remaining_horizon(issues, path, %{} = horizon) do
    validate_embedded_remaining_horizon(issues, path, horizon)
  end

  def validate_optional_embedded_remaining_horizon(issues, _path, _horizon), do: issues

  def validate_embedded_remaining_horizon(issues, path, horizon) do
    issues
    |> expect_optional_field_equals(
      path,
      horizon,
      "schema_contract",
      "remaining_horizon.v1",
      "must match remaining_horizon.v1 when declared"
    )
    |> validate_embedded_remaining_horizon_fields(path, horizon)
  end

  defp validate_embedded_remaining_horizon_fields(issues, path, horizon) do
    issues
    |> require_fields(path, horizon, ["starts_at_s", "ends_at_s", "output_step_s"])
    |> expect_number(path, horizon, "starts_at_s")
    |> expect_number(path, horizon, "ends_at_s")
    |> expect_number(path, horizon, "output_step_s")
    |> validate_interval(path, horizon)
    |> validate_remaining_horizon_timing(path, horizon)
  end

  defp validate_refreshed_window_assumptions(
         issues,
         path,
         %{"assumptions" => %{} = assumptions}
       ) do
    issues
    |> expect_optional_number(
      path <> ".assumptions",
      assumptions,
      "event_time_tolerance_s"
    )
    |> expect_optional_number(path <> ".assumptions", assumptions, "max_sample_step_s")
    |> expect_optional_type(
      path <> ".assumptions",
      assumptions,
      "event_detector",
      :binary
    )
    |> expect_optional_type(
      path <> ".assumptions",
      assumptions,
      "event_timing_policy",
      :binary
    )
  end

  defp validate_refreshed_window_assumptions(issues, _path, _window), do: issues

  defp validate_refreshed_window_sample_coverage(
         issues,
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
          path <> ".sample_count",
          "must cover window duration using assumptions.max_sample_step_s"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_refreshed_window_sample_coverage(issues, _path, _window), do: issues

  defp validate_remaining_horizon_timing(
         issues,
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
    |> validate_remaining_horizon_output_step(path, output_step_s, duration_s)
    |> expect_field_equals(
      path,
      horizon,
      "duration_s",
      duration_s,
      "must equal ends_at_s - starts_at_s"
    )
  end

  defp validate_remaining_horizon_timing(issues, _path, _horizon), do: issues

  defp validate_remaining_horizon_output_step(issues, path, output_step_s, duration_s) do
    cond do
      output_step_s <= 0 ->
        [error(path <> ".output_step_s", "must be greater than 0") | issues]

      duration_s >= 0 and output_step_s > duration_s ->
        [error(path <> ".output_step_s", "must not exceed horizon duration") | issues]

      true ->
        issues
    end
  end
end
