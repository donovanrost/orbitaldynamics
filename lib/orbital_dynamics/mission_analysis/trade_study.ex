defmodule OrbitalDynamics.MissionAnalysis.TradeStudy do
  @moduledoc """
  Bounded, deterministic Cartesian parameter sweeps over mission configurations.

  Axes contain named cases with explicit updates to existing map/list paths.
  One case can update correlated inputs (such as mirror area and dimension).
  An evaluator receives each complete configuration and returns a MissionAnalysis
  report or a tagged error. The sweep has no mission-specific parameter names.
  """
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport
  alias OrbitalDynamics.Schema.JsonSafety

  def run!(base, axes, evaluator, opts) when is_function(evaluator, 1) do
    unless Keyword.keyword?(opts) and Enum.sort(Keyword.keys(opts)) == [:max_cases, :study_id],
      do: raise(ArgumentError, "required sweep options: study_id, max_cases")

    id = Input.id!(Keyword.fetch!(opts, :study_id))
    limit = Keyword.fetch!(opts, :max_cases)

    unless is_integer(limit) and limit in 1..256,
      do: raise(ArgumentError, "max_cases must be an integer in 1..256 (excluding baseline)")

    base = JsonSafety.normalize_input!(base, "baseline configuration")
    axes = JsonSafety.normalize_input!(axes, "sweep axes")
    validate!(base, axes, limit)

    baseline = evaluate(base, "baseline", %{}, [], evaluator)

    combinations =
      Enum.reduce(axes, [{%{}, []}], fn axis, combinations ->
        for {parameters, updates} <- combinations, c <- axis["cases"] do
          {Map.put(parameters, axis["id"], c["id"]), updates ++ c["updates"]}
        end
      end)

    cases =
      combinations
      |> Enum.with_index(1)
      |> Enum.map(fn {{parameters, updates}, index} ->
        config = Enum.reduce(updates, base, fn u, acc -> update!(acc, u["path"], u["value"]) end)
        evaluate(config, "case-#{index}", parameters, updates, evaluator)
      end)

    %{
      "format" => "mission_trade_study.v1",
      "study_id" => id,
      "execution_boundary" => "analysis_only_no_command_execution",
      "baseline_configuration" => base,
      "axes" => axes,
      "baseline" => baseline,
      "case_count" => length(cases),
      "error_case_count" => Enum.count(cases, &(&1["status"] == "error")),
      "cases" => cases,
      "limits" => [
        "finite Cartesian grid, not optimization or a constellation performance forecast",
        "window spans are sampled evidence; no interpolation or continuous certification",
        "failure counts are nonexclusive diagnostics, not causal attribution",
        "sole-failure counts identify samples with exactly one failed check, not recoverable service",
        "metric ranges cover eligible samples or sampled selected intervals, not integrated delivery",
        "parameter comparisons inherit each model's assumptions and baseline horizon"
      ]
    }
  end

  defp validate!(base, axes, limit) do
    unless is_map(base) and is_list(axes) and length(axes) in 1..12,
      do: raise(ArgumentError, "baseline object and 1..12 axes required")

    ids =
      Enum.map(axes, fn axis ->
        SurfaceSupport.fields!(axis, ~w(id cases), "axis")
        Input.id!(axis["id"])
      end)

    unique!(ids, "axis IDs")

    Enum.reduce(axes, 1, fn axis, count ->
      cases = axis["cases"]

      unless is_list(cases) and length(cases) in 1..256,
        do: raise(ArgumentError, "each axis needs 1..256 cases")

      count = count * length(cases)
      if count > limit, do: raise(ArgumentError, "Cartesian sweep exceeds max_cases #{limit}")

      case_ids =
        Enum.map(cases, fn c ->
          SurfaceSupport.fields!(c, ~w(id updates), "axis case")
          Input.id!(c["id"])
        end)

      unique!(case_ids, "case IDs within an axis")

      Enum.each(cases, fn c ->
        updates = c["updates"]

        unless is_list(updates) and length(updates) in 1..32,
          do: raise(ArgumentError, "each case needs 1..32 updates")

        Enum.each(updates, fn u ->
          SurfaceSupport.fields!(u, ~w(path value), "update")
          path = u["path"]

          unless is_list(path) and length(path) in 1..16 and
                   Enum.all?(path, &(is_binary(&1) or (is_integer(&1) and &1 >= 0))),
                 do:
                   raise(
                     ArgumentError,
                     "paths require 1..16 string keys or nonnegative list indices"
                   )

          update!(base, path, u["value"])
        end)

        disjoint_paths!(Enum.map(updates, & &1["path"]))
      end)

      paths = Enum.map(cases, fn c -> Enum.sort(Enum.map(c["updates"], & &1["path"])) end)

      unless length(Enum.uniq(paths)) == 1,
        do: raise(ArgumentError, "all cases of an axis must update the same paths")

      count
    end)

    axes
    |> Enum.flat_map(fn a -> hd(a["cases"])["updates"] end)
    |> Enum.map(& &1["path"])
    |> disjoint_paths!()
  end

  defp unique!(ids, label) do
    if length(ids) != length(Enum.uniq(ids)), do: raise(ArgumentError, "duplicate #{label}")
  end

  defp disjoint_paths!(paths) do
    for {a, i} <- Enum.with_index(paths), {b, j} <- Enum.with_index(paths), i < j do
      if List.starts_with?(a, b) or List.starts_with?(b, a),
        do: raise(ArgumentError, "sweep updates must not overlap: #{inspect(a)} / #{inspect(b)}")
    end
  end

  defp update!(_value, [], replacement), do: replacement

  defp update!(map, [key | rest], replacement) when is_map(map) and is_binary(key) do
    unless Map.has_key?(map, key),
      do: raise(ArgumentError, "sweep path has missing key #{inspect(key)}")

    Map.put(map, key, update!(Map.fetch!(map, key), rest, replacement))
  end

  defp update!(list, [index | rest], replacement)
       when is_list(list) and is_integer(index) and index >= 0 do
    if index >= length(list), do: raise(ArgumentError, "sweep path index out of range")
    List.replace_at(list, index, update!(Enum.at(list, index), rest, replacement))
  end

  defp update!(_, path, _),
    do: raise(ArgumentError, "sweep path does not match configuration: #{inspect(path)}")

  defp evaluate(config, id, parameters, updates, evaluator) do
    row = %{"id" => id, "parameters" => parameters, "updates" => updates}

    case evaluator.(config) do
      {:ok, %{"format" => "mission_analysis.v1"} = report} ->
        if Enum.any?(
             report["analyses"],
             &(Map.has_key?(&1, "evaluated_sample_count") and not Map.has_key?(&1, "samples"))
           ) do
          Map.merge(row, %{
            "status" => "error",
            "error" => "trade summaries require include_samples: true"
          })
        else
          Map.merge(row, %{
            "status" => "ok",
            "summary" => summarize(report),
            "analysis_provenance" => %{
              "time_system" => report["time_system"],
              "sampling_assumptions" => report["assumptions"],
              "model_limits" => report["model_limits"],
              "pairs" =>
                Enum.map(
                  report["analyses"],
                  &Map.take(&1, ~w(asset_id request_id model assumptions trajectory_assumptions))
                ),
              "orbit_estimates" => get_in(report, ["reference_mission", "orbit_estimates"]) || []
            }
          })
        end

      {:error, reason} ->
        Map.merge(row, %{"status" => "error", "error" => inspect(reason, limit: 30)})

      _ ->
        Map.merge(row, %{"status" => "error", "error" => "invalid_evaluator_result"})
    end
  end

  @doc "Summarizes physical eligibility separately from scheduling and resources."
  def summarize(report) do
    if Enum.any?(
         report["analyses"],
         &(Map.has_key?(&1, "evaluated_sample_count") and not Map.has_key?(&1, "samples"))
       ),
       do: raise(ArgumentError, "trade summaries require include_samples: true")

    activities = report["activities"]

    %{
      "request_count" => length(report["requests"]),
      "supported_request_count" => Enum.count(report["requests"], &(&1["opportunity_count"] > 0)),
      "scheduled_request_count" => length(activities),
      "opportunity_count" => length(report["opportunities"]),
      "scheduled_duration_s" =>
        Enum.sum(Enum.map(activities, &(&1["ends_at_s"] - &1["starts_at_s"]))),
      "scheduled_value" => Enum.sum(Enum.map(activities, & &1["value"])),
      "requests" =>
        Enum.map(report["requests"], fn request ->
          pairs = Enum.filter(report["analyses"], &(&1["request_id"] == request["request_id"]))
          samples = Enum.flat_map(pairs, &Map.get(&1, "samples", []))
          selected = Enum.filter(activities, &(&1["request_id"] == request["request_id"]))
          # Pair identity is retained when matching selected intervals.
          selected_samples =
            Enum.flat_map(pairs, fn pair ->
              Enum.filter(Map.get(pair, "samples", []), fn s ->
                Enum.any?(
                  selected,
                  &(&1["asset_id"] == pair["asset_id"] and
                      s["epoch_s"] >= &1["starts_at_s"] and s["epoch_s"] <= &1["ends_at_s"])
                )
              end)
            end)

          eligible = Enum.filter(samples, & &1["feasible"])

          checks =
            samples
            |> Enum.flat_map(fn s ->
              failed = Enum.reject(s["checks"], & &1["passed"])
              Enum.map(s["checks"], &{&1["id"], &1["passed"], length(failed) == 1})
            end)
            |> Enum.group_by(&elem(&1, 0))
            |> Map.new(fn {id, values} ->
              {id,
               %{
                 "evaluated_sample_count" => length(values),
                 "failed_sample_count" => Enum.count(values, &(not elem(&1, 1))),
                 "sole_failed_check_sample_count" =>
                   Enum.count(values, &(not elem(&1, 1) and elem(&1, 2)))
               }}
            end)

          %{
            "request_id" => request["request_id"],
            "physical_status" =>
              if(request["opportunity_count"] > 0,
                do: "duration_supported",
                else: "no_duration_supported_window"
              ),
            "scheduling_status" => request["status"],
            "scheduling_reasons" => request["reasons"],
            "pair_statuses" => Enum.map(pairs, &Map.take(&1, ~w(asset_id status))),
            "opportunity_count" => request["opportunity_count"],
            "eligible_sample_count" => length(eligible),
            "longest_eligible_run_span_s" =>
              pairs
              |> Enum.map(
                &longest_run(
                  Map.get(&1, "samples", []),
                  report["assumptions"]["max_sample_gap_s"]
                )
              )
              |> Enum.max(fn -> 0 end),
            "check_diagnostics" => checks,
            "eligible_metric_ranges" => metric_ranges(eligible),
            "selected_interval_sample_metric_ranges" => metric_ranges(selected_samples)
          }
        end)
    }
  end

  defp longest_run(samples, gap) do
    {_, _, longest} =
      Enum.reduce(samples, {nil, nil, 0.0}, fn s, {start, previous, longest} ->
        cond do
          not s["feasible"] -> {nil, nil, longest}
          start == nil or s["epoch_s"] - previous > gap -> {s["epoch_s"], s["epoch_s"], longest}
          true -> {start, s["epoch_s"], max(longest, s["epoch_s"] - start)}
        end
      end)

    longest
  end

  defp metric_ranges(samples) do
    samples
    |> Enum.flat_map(fn s -> Enum.filter(s["metrics"], fn {_, value} -> is_number(value) end) end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {name, values} ->
      {name,
       %{"min" => Enum.min(values), "max" => Enum.max(values), "sample_count" => length(values)}}
    end)
  end

  @doc "Compact comparison table; detailed per-request physics and diagnostics remain in JSON."
  def csv(report) do
    headers =
      ["case", "status"] ++
        Enum.map(report["axes"], & &1["id"]) ++
        [
          "supported_requests",
          "scheduled_requests",
          "scheduled_duration_s",
          "opportunities",
          "error"
        ]

    rows =
      Enum.map([report["baseline"] | report["cases"]], fn row ->
        s = Map.get(row, "summary", %{})

        [row["id"], row["status"]] ++
          Enum.map(report["axes"], &Map.get(row["parameters"], &1["id"], "baseline")) ++
          Enum.map(
            ~w(supported_request_count scheduled_request_count scheduled_duration_s opportunity_count),
            &Map.get(s, &1, "")
          ) ++ [Map.get(row, "error", "")]
      end)

    [headers | rows]
    |> Enum.map_join("\n", fn row -> Enum.map_join(row, ",", &csv_cell/1) end)
    |> Kernel.<>("\n")
  end

  def metric_csv(report) do
    rows =
      for row <- [report["baseline"] | report["cases"]],
          row["status"] == "ok",
          r <- row["summary"]["requests"],
          scope <- ~w(eligible_metric_ranges selected_interval_sample_metric_ranges),
          {metric, range} <- Enum.sort(r[scope]) do
        [
          row["id"],
          r["request_id"],
          scope,
          metric,
          range["min"],
          range["max"],
          range["sample_count"]
        ]
      end

    encode_rows([["case", "request", "scope", "metric", "min", "max", "sample_count"] | rows])
  end

  def check_csv(report) do
    rows =
      for row <- [report["baseline"] | report["cases"]],
          row["status"] == "ok",
          r <- row["summary"]["requests"],
          {id, c} <- Enum.sort(r["check_diagnostics"]) do
        [
          row["id"],
          r["request_id"],
          id,
          c["evaluated_sample_count"],
          c["failed_sample_count"],
          c["sole_failed_check_sample_count"]
        ]
      end

    encode_rows([
      ["case", "request", "check", "evaluated_samples", "failed_samples", "sole_failure_samples"]
      | rows
    ])
  end

  def markdown(report) do
    axes = Enum.map(report["axes"], & &1["id"])

    headers =
      ["Case", "Status"] ++
        axes ++ ["Supported requests", "Scheduled requests", "Scheduled seconds"]

    rows =
      Enum.map([report["baseline"] | report["cases"]], fn row ->
        summary = Map.get(row, "summary", %{})

        [row["id"], row["status"]] ++
          Enum.map(axes, &Map.get(row["parameters"], &1, "baseline")) ++
          Enum.map(
            ~w(supported_request_count scheduled_request_count scheduled_duration_s),
            &Map.get(summary, &1, "—")
          )
      end)

    table =
      [headers, Enum.map(headers, fn _ -> "---" end) | rows]
      |> Enum.map_join("\n", fn row -> "| " <> Enum.map_join(row, " | ", &to_string/1) <> " |" end)

    "# " <>
      report["study_id"] <>
      "\n\n" <>
      table <>
      "\n\nSupported requests have at least one sampled window long enough for their duration. " <>
      "Scheduling additionally enforces asset conflicts and declared budgets.\n\n" <>
      "See [metrics.csv](metrics.csv) for eligible and selected-interval sample metric ranges, " <>
      "[checks.csv](checks.csv) for nonexclusive and sole-failure diagnostics, and " <>
      "[report.json](report.json) for exact configuration, updates, errors, per-request status, and limits.\n\n" <>
      Enum.map_join(report["limits"], "\n", &("- " <> &1)) <> "\n"
  end

  defp encode_rows(rows),
    do: Enum.map_join(rows, "\n", fn row -> Enum.map_join(row, ",", &csv_cell/1) end) <> "\n"

  defp csv_cell(value), do: "\"" <> String.replace(to_string(value), "\"", "\"\"") <> "\""
end
