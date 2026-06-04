defmodule OrbitalDynamics.Study.Benchmark.Report do
  @moduledoc """
  Summary helpers for study benchmark artifacts.
  """

  alias OrbitalDynamics.{OperationalScale, Validation}

  @doc """
  Declares the study benchmark report model and known limits.
  """
  def capabilities do
    %{
      report: :study_benchmark_summary,
      model: :persisted_study_benchmark_median_summary,
      validation_level: :artifact_contract,
      grouping: [
        :mode,
        :propagator,
        :monte_carlo_count,
        :task_chunk_size,
        :max_concurrency
      ],
      statistics: [
        :median_duration_ms,
        :median_propagation_ms,
        :median_event_detection_ms,
        :median_artifact_build_ms,
        :median_overhead_ms,
        :median_artifact_body_bytes,
        :median_artifact_size_mb,
        :median_artifact_bytes_per_scenario,
        :median_scenarios_per_second,
        :median_task_batch_count,
        :median_wave_count,
        :node_balance_ratio,
        :speedup_vs_local,
        :backend_acceptance_status,
        :trend_delta_percent
      ],
      known_limits: [
        :artifact_level_only,
        :median_summary_only,
        :no_statistical_significance_test,
        :speedup_uses_matching_local_case,
        :distributed_counts_depend_on_reported_node_telemetry,
        :backend_acceptance_uses_declared_policy,
        :trend_uses_artifact_generated_at_order
      ]
    }
  end

  @doc """
  Returns the declared model limits for persisted study benchmark summaries.
  """
  def model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  @doc """
  Reads a study benchmark artifact from disk.
  """
  def read_artifact!(path) when is_binary(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  @doc """
  Builds median timing summaries grouped by execution mode.
  """
  def summarize(artifact, opts \\ [])

  def summarize(%{"results" => results} = artifact, opts) when is_list(results) do
    groups =
      results
      |> Enum.group_by(&group_key/1)
      |> Enum.map(fn {{mode, propagator, monte_carlo_count, task_chunk_size, max_concurrency},
                      rows} ->
        %{
          mode: mode,
          propagator: propagator,
          monte_carlo_count: monte_carlo_count,
          task_chunk_size: task_chunk_size,
          max_concurrency: max_concurrency,
          effective_task_concurrency: group_value(rows, "effective_task_concurrency"),
          repetitions: length(rows),
          median_duration_ms: median(Enum.map(rows, & &1["duration_ms"])),
          median_propagation_ms:
            rows
            |> Enum.map(& &1["propagation_ms"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_event_detection_ms:
            rows
            |> Enum.map(& &1["event_detection_ms"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_artifact_build_ms:
            rows
            |> Enum.map(& &1["artifact_build_ms"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_overhead_ms:
            rows
            |> Enum.map(& &1["overhead_ms"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_overhead_percent:
            rows
            |> Enum.map(& &1["overhead_percent"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_artifact_body_bytes:
            rows
            |> Enum.map(& &1["artifact_body_bytes"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_artifact_size_mb:
            rows
            |> Enum.map(& &1["artifact_size_mb"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_artifact_bytes_per_scenario:
            rows
            |> Enum.map(& &1["artifact_bytes_per_scenario"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_scenarios_per_second:
            rows
            |> Enum.map(& &1["scenarios_per_second"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_task_batch_count:
            rows
            |> Enum.map(& &1["task_batch_count"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          median_wave_count:
            rows
            |> Enum.map(& &1["wave_count"])
            |> Enum.filter(&is_number/1)
            |> median_or_nil(),
          execution_plan: group_execution_plan(rows),
          median_scheduler_utilization:
            rows
            |> runtime_telemetry_values("scheduler_utilization")
            |> median_or_nil(),
          scenario_count: median(Enum.map(rows, & &1["scenario_count"])),
          failure_count: Enum.reduce(rows, 0, &(&1["failure_count"] + &2)),
          output_matches_baseline: Enum.all?(rows, &(&1["matches_baseline"] == true)),
          per_node_trajectory_counts: per_node_trajectory_counts(rows),
          per_node_runtime_telemetry: per_node_runtime_telemetry(rows),
          node_balance_ratio: node_balance_ratio(rows),
          node_count: node_count(rows),
          task_supervisor_nodes:
            rows
            |> Enum.map(& &1["task_supervisor_node"])
            |> Enum.reject(&is_nil/1)
            |> Enum.uniq()
            |> Enum.sort()
        }
      end)
      |> Enum.sort_by(
        &{count_sort_value(&1.monte_carlo_count), propagator_sort_value(&1.propagator),
         concurrency_sort_value(&1.max_concurrency), chunk_sort_value(&1.task_chunk_size),
         &1.mode}
      )

    local_duration_by_case =
      groups
      |> Enum.filter(&(&1.mode == "local"))
      |> Enum.group_by(&{&1.monte_carlo_count, &1.max_concurrency})
      |> Map.new(fn {benchmark_case, local_groups} ->
        baseline = Enum.find(local_groups, &(&1.propagator == "two_body")) || hd(local_groups)
        {benchmark_case, baseline.median_duration_ms}
      end)

    %{
      schema_version: artifact["schema_version"],
      generated_at: artifact["generated_at"],
      manifest: artifact["manifest"] || %{},
      model_limits: model_limits(),
      benchmark_options: artifact["benchmark_options"] || %{},
      operational_scale_target: Keyword.get(opts, :scale_target),
      backend_acceptance_policy: "backend_acceptance_policy.v1",
      groups:
        Enum.map(groups, fn group ->
          attach_local_speedup(
            group,
            Map.get(local_duration_by_case, {group.monte_carlo_count, group.max_concurrency})
          )
          |> attach_scale_comparison(Keyword.get(opts, :scale_target))
          |> attach_backend_acceptance()
        end)
    }
  end

  @doc """
  Builds a trend summary across multiple study benchmark artifacts.

  Trends compare matching benchmark groups by artifact `generated_at` order.
  They are descriptive only: no statistical significance test is implied, and
  each point is already a per-artifact median summary.
  """
  def trend_summary(artifacts, opts \\ [])

  def trend_summary(artifacts, opts) when is_list(artifacts) do
    summaries =
      artifacts
      |> Enum.map(&artifact_summary(&1, opts))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(&generated_sort_value(&1.generated_at))

    groups =
      summaries
      |> Enum.flat_map(&trend_points/1)
      |> Enum.group_by(&summary_group_key/1)
      |> Enum.map(fn {_key, points} ->
        trend_group(points, Keyword.get(opts, :tolerance_percent, 0.0))
      end)
      |> Enum.sort_by(
        &{count_sort_value(&1.monte_carlo_count), propagator_sort_value(&1.propagator),
         concurrency_sort_value(&1.max_concurrency), chunk_sort_value(&1.task_chunk_size),
         &1.mode}
      )

    %{
      schema_version: 1,
      artifact_count: length(summaries),
      model_limits: model_limits(),
      operational_scale_target: Keyword.get(opts, :scale_target),
      groups: groups
    }
    |> attach_trend_scale_comparison(Keyword.get(opts, :scale_target))
  end

  def trend_summary(_artifacts, _opts), do: {:error, {:invalid_field, "artifacts"}}

  defp group_key(row),
    do:
      {row["mode"], Map.get(row, "propagator"), Map.get(row, "monte_carlo_count"),
       Map.get(row, "task_chunk_size"), Map.get(row, "max_concurrency")}

  defp artifact_summary(path, opts) when is_binary(path) do
    path
    |> read_artifact!()
    |> artifact_summary(opts)
  end

  defp artifact_summary(%{} = artifact, opts), do: summarize(artifact, opts)
  defp artifact_summary(_artifact, _opts), do: nil

  defp trend_points(summary) do
    Enum.map(summary.groups, fn group ->
      %{
        generated_at: summary.generated_at,
        manifest_path: get_in(summary, [:manifest, "path"]),
        group: group
      }
    end)
  end

  defp summary_group_key(%{group: group}), do: summary_group_key(group)

  defp summary_group_key(group) do
    {group.mode, group.propagator, group.monte_carlo_count, group.task_chunk_size,
     group.max_concurrency}
  end

  defp trend_group(points, tolerance_percent) do
    points = Enum.sort_by(points, &generated_sort_value(&1.generated_at))
    first = List.first(points)
    latest = List.last(points)
    first_group = first.group
    latest_group = latest.group
    delta_ms = numeric_delta(latest_group.median_duration_ms, first_group.median_duration_ms)

    delta_percent =
      numeric_delta_percent(latest_group.median_duration_ms, first_group.median_duration_ms)

    %{
      mode: latest_group.mode,
      propagator: latest_group.propagator,
      monte_carlo_count: latest_group.monte_carlo_count,
      task_chunk_size: latest_group.task_chunk_size,
      max_concurrency: latest_group.max_concurrency,
      sample_count: length(points),
      first_generated_at: first.generated_at,
      latest_generated_at: latest.generated_at,
      first_median_duration_ms: first_group.median_duration_ms,
      latest_median_duration_ms: latest_group.median_duration_ms,
      duration_delta_ms: delta_ms,
      duration_delta_percent: delta_percent,
      trend_status: trend_status(length(points), delta_percent, tolerance_percent),
      latest_backend_acceptance_status: get_in(latest_group, [:backend_acceptance, :status]),
      latest_output_matches_baseline: latest_group.output_matches_baseline,
      latest_operational_scale_status:
        get_in(latest_group, [:operational_scale_comparison, "status"]),
      points:
        Enum.map(points, fn point ->
          %{
            generated_at: point.generated_at,
            manifest_path: point.manifest_path,
            median_duration_ms: point.group.median_duration_ms,
            median_artifact_size_mb: Map.get(point.group, :median_artifact_size_mb),
            output_matches_baseline: point.group.output_matches_baseline
          }
        end)
    }
  end

  defp numeric_delta(latest, first) when is_number(latest) and is_number(first),
    do: (latest - first) * 1.0

  defp numeric_delta(_latest, _first), do: nil

  defp numeric_delta_percent(latest, first)
       when is_number(latest) and is_number(first) and first != 0.0,
       do: (latest - first) / first * 100.0

  defp numeric_delta_percent(_latest, _first), do: nil

  defp trend_status(sample_count, _delta_percent, _tolerance_percent) when sample_count < 2,
    do: "insufficient_history"

  defp trend_status(_sample_count, nil, _tolerance_percent), do: "not_evaluated"

  defp trend_status(_sample_count, delta_percent, tolerance_percent) do
    cond do
      delta_percent < -abs(tolerance_percent) -> "improved"
      delta_percent > abs(tolerance_percent) -> "regressed"
      true -> "unchanged"
    end
  end

  defp generated_sort_value(nil), do: ""
  defp generated_sort_value(value), do: to_string(value)

  defp count_sort_value(nil), do: 0
  defp count_sort_value(count) when is_integer(count), do: count

  defp propagator_sort_value(nil), do: ""
  defp propagator_sort_value(propagator) when is_binary(propagator), do: propagator

  defp concurrency_sort_value(nil), do: 0

  defp concurrency_sort_value(max_concurrency) when is_integer(max_concurrency),
    do: max_concurrency

  defp chunk_sort_value(nil), do: 0
  defp chunk_sort_value(chunk_size) when is_integer(chunk_size), do: chunk_size

  defp group_value(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [value] -> value
      _values -> nil
    end
  end

  defp group_execution_plan(rows) do
    rows
    |> Enum.map(&Map.get(&1, "execution_plan"))
    |> Enum.reject(&(is_nil(&1) or &1 == %{}))
    |> Enum.uniq()
    |> case do
      [plan] -> plan
      _plans -> nil
    end
  end

  defp per_node_trajectory_counts(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("per_node_trajectory_counts", %{})
      |> Map.to_list()
    end)
    |> Enum.reduce(%{}, fn {node, count}, counts ->
      Map.update(counts, node, count, &(&1 + count))
    end)
  end

  defp node_count(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("per_node_trajectory_counts", %{})
      |> Map.keys()
    end)
    |> Enum.uniq()
    |> length()
  end

  defp node_balance_ratio(rows) do
    counts =
      rows
      |> per_node_trajectory_counts()
      |> Map.values()
      |> Enum.filter(&is_number/1)

    case counts do
      [] ->
        nil

      [_single_node] ->
        nil

      counts ->
        min = Enum.min(counts)
        max = Enum.max(counts)

        if max == 0 do
          nil
        else
          min / max
        end
    end
  end

  defp runtime_telemetry_values(rows, key) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("runtime_telemetry", %{})
      |> Map.values()
      |> Enum.map(&Map.get(&1, key))
    end)
    |> Enum.filter(&is_number/1)
  end

  defp per_node_runtime_telemetry(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("runtime_telemetry", %{})
      |> Map.to_list()
    end)
    |> Enum.group_by(fn {node, _telemetry} -> node end, fn {_node, telemetry} -> telemetry end)
    |> Map.new(fn {node, telemetry_rows} ->
      {node,
       %{
         median_scheduler_utilization:
           telemetry_rows
           |> Enum.map(&Map.get(&1, "scheduler_utilization"))
           |> Enum.filter(&is_number/1)
           |> median_or_nil(),
         median_run_queue_after:
           telemetry_rows
           |> Enum.map(&Map.get(&1, "run_queue_after"))
           |> Enum.filter(&is_number/1)
           |> median_or_nil(),
         median_reductions_delta:
           telemetry_rows
           |> Enum.map(&Map.get(&1, "reductions_delta"))
           |> Enum.filter(&is_number/1)
           |> median_or_nil(),
         median_memory_total_bytes_after:
           telemetry_rows
           |> Enum.map(&Map.get(&1, "memory_total_bytes_after"))
           |> Enum.filter(&is_number/1)
           |> median_or_nil()
       }}
    end)
  end

  defp attach_local_speedup(group, nil), do: Map.put(group, :speedup_vs_local, nil)

  defp attach_local_speedup(group, local_ms) when local_ms == 0.0,
    do: Map.put(group, :speedup_vs_local, nil)

  defp attach_local_speedup(%{median_duration_ms: median_duration_ms} = group, _local_ms)
       when median_duration_ms == 0.0,
       do: Map.put(group, :speedup_vs_local, nil)

  defp attach_local_speedup(group, local_ms),
    do: Map.put(group, :speedup_vs_local, local_ms / group.median_duration_ms)

  defp attach_scale_comparison(group, nil), do: group

  defp attach_scale_comparison(group, scale_target) do
    case OperationalScale.compare_benchmark_group(scale_target, group) do
      {:ok, comparison} -> Map.put(group, :operational_scale_comparison, comparison)
      {:error, _reason} -> group
    end
  end

  defp attach_trend_scale_comparison(summary, nil), do: summary

  defp attach_trend_scale_comparison(summary, scale_target) do
    case OperationalScale.compare_benchmark_trend(scale_target, summary) do
      {:ok, comparison} -> Map.put(summary, :operational_scale_trend_comparison, comparison)
      {:error, _reason} -> summary
    end
  end

  defp attach_backend_acceptance(group) do
    policy = Validation.backend_acceptance_policy()
    implementation = backend_implementation(group)
    tier = get_in(policy, ["implementation_tiers", implementation]) || "unknown"
    tier_policy = get_in(policy, ["acceptance_tiers", tier]) || %{}
    benchmark_artifact_present? = true
    reference_match? = group.output_matches_baseline == true
    speedup = Map.get(group, :speedup_vs_local)

    Map.put(group, :backend_acceptance, %{
      implementation: implementation,
      tier: tier,
      status:
        backend_acceptance_status(tier, reference_match?, benchmark_artifact_present?, speedup),
      reference_match: reference_match?,
      benchmark_artifact_present: benchmark_artifact_present?,
      speedup_vs_local: speedup,
      speedup_claim: speedup_claim(tier, reference_match?, benchmark_artifact_present?, speedup),
      requires_reference_match: Map.get(tier_policy, "requires_reference_match", true),
      requires_benchmark_artifact: Map.get(tier_policy, "requires_benchmark_artifact", true),
      policy_contract: policy["schema_contract"]
    })
  end

  defp backend_implementation(%{propagator: "two_body"}),
    do: "OrbitalDynamics.Propagators.TwoBody"

  defp backend_implementation(%{propagator: "j2"}),
    do: "OrbitalDynamics.Propagators.J2"

  defp backend_implementation(%{propagator: "two_body_nx"}),
    do: "OrbitalDynamics.Propagators.TwoBodyNx"

  defp backend_implementation(%{propagator: "two_body_nx_compiled"}),
    do: "OrbitalDynamics.Propagators.TwoBodyNxCompiled"

  defp backend_implementation(%{propagator: "two_body_exla_cpu"}),
    do: "OrbitalDynamics.Propagators.TwoBodyExlaCpu"

  defp backend_implementation(%{propagator: "j2_exla_cpu"}),
    do: "OrbitalDynamics.Propagators.J2ExlaCpu"

  defp backend_implementation(%{propagator: propagator}) when is_binary(propagator),
    do: propagator

  defp backend_implementation(_group), do: nil

  defp backend_acceptance_status(_tier, false, _benchmark_artifact_present?, _speedup),
    do: "requires_reference_match"

  defp backend_acceptance_status(
         "reference_default",
         true,
         _benchmark_artifact_present?,
         _speedup
       ),
       do: "accepted_reference_default"

  defp backend_acceptance_status("experimental_accelerator", true, true, speedup)
       when is_number(speedup) and speedup > 1.0,
       do: "accepted_accelerator_speedup_evidence"

  defp backend_acceptance_status("experimental_accelerator", true, true, _speedup),
    do: "correctness_only_no_speedup_claim"

  defp backend_acceptance_status("external_service_adapter", true, true, _speedup),
    do: "requires_provider_policy_review"

  defp backend_acceptance_status(_tier, true, true, _speedup), do: "unknown_backend_tier"

  defp speedup_claim(_tier, false, _benchmark_artifact_present?, _speedup),
    do: "not_claimed_reference_mismatch"

  defp speedup_claim("reference_default", true, _benchmark_artifact_present?, _speedup),
    do: "not_required_for_reference_default"

  defp speedup_claim("experimental_accelerator", true, true, speedup)
       when is_number(speedup) and speedup > 1.0,
       do: "supported_for_this_benchmark_group"

  defp speedup_claim("experimental_accelerator", true, true, _speedup),
    do: "not_supported_by_this_benchmark_group"

  defp speedup_claim(_tier, true, true, _speedup), do: "not_claimed_unknown_backend_tier"

  defp median(values) do
    sorted = Enum.sort(values)
    count = length(sorted)
    middle = div(count, 2)

    if rem(count, 2) == 1 do
      Enum.at(sorted, middle) * 1.0
    else
      (Enum.at(sorted, middle - 1) + Enum.at(sorted, middle)) / 2.0
    end
  end

  defp median_or_nil([]), do: nil
  defp median_or_nil(values), do: median(values)
end
