defmodule OrbitalDynamics.MissionAnalysis.ResolutionStudy do
  @moduledoc """
  Mission-independent comparison of explicit sampling and integration levels.

  Evaluators return refined MissionAnalysis reports. Stability means agreement
  against the declared finest tested level within caller-specified tolerances.
  It is neither a proof of convergence nor a physical uncertainty bound.
  """
  alias OrbitalDynamics.MissionAnalysis.{Input, TradeStudy}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport

  def run!(levels, evaluator, opts) when is_function(evaluator, 1) do
    keys =
      ~w(study_id reference_level_id window_time_tolerance_s schedule_time_tolerance_s margin_thresholds)a

    unless Keyword.keyword?(opts) and Enum.sort(Keyword.keys(opts)) == Enum.sort(keys),
      do: raise(ArgumentError, "explicit resolution options required")

    id = Input.id!(opts[:study_id])
    reference_id = Input.id!(opts[:reference_level_id])

    window_tolerance =
      Input.number!(opts[:window_time_tolerance_s], "window_time_tolerance_s", 0, 1.0e6)

    schedule_tolerance =
      Input.number!(opts[:schedule_time_tolerance_s], "schedule_time_tolerance_s", 0, 1.0e6)

    thresholds = thresholds!(opts[:margin_thresholds])
    validate_levels!(levels, reference_id)

    results =
      Enum.map(levels, fn level ->
        case evaluator.(level) do
          {:ok, %{"format" => "mission_analysis.v1"} = report} ->
            if get_in(report, ["assumptions", "window_refinement"]) == nil do
              %{
                "level" => level,
                "status" => "error",
                "error" => "resolution studies require refined reports"
              }
            else
              %{
                "level" => level,
                "status" => "ok",
                "summary" => TradeStudy.summarize(report),
                "request_evidence" => evidence(report, thresholds),
                "provenance" => %{
                  "time_system" => report["time_system"],
                  "assumptions" => report["assumptions"],
                  "model_limits" => report["model_limits"],
                  "pairs" =>
                    Enum.map(
                      report["analyses"],
                      &Map.take(
                        &1,
                        ~w(asset_id request_id model assumptions trajectory_assumptions evaluated_sample_count transition_refinement_evaluation_count)
                      )
                    )
                }
              }
            end

          {:error, reason} ->
            %{"level" => level, "status" => "error", "error" => inspect(reason, limit: 30)}

          _ ->
            %{
              "level" => level,
              "status" => "error",
              "error" => "invalid_resolution_evaluator_result"
            }
        end
      end)

    reference = Enum.find(results, &(&1["level"]["id"] == reference_id))

    request_ids =
      results
      |> Enum.flat_map(&Map.get(&1, "request_evidence", []))
      |> Enum.map(& &1["request_id"])
      |> Enum.uniq()
      |> Enum.sort()

    comparisons =
      Enum.map(results, fn row ->
        %{
          "level_id" => row["level"]["id"],
          "requests" =>
            Enum.map(request_ids, fn request_id ->
              compare(row, reference, request_id, window_tolerance, schedule_tolerance)
            end)
        }
      end)

    stability =
      Enum.map(request_ids, fn request_id ->
        others =
          Enum.reject(comparisons, &(&1["level_id"] == reference_id))
          |> Enum.map(fn c -> Enum.find(c["requests"], &(&1["request_id"] == request_id)) end)

        status =
          cond do
            Enum.any?(others, &(&1["status"] == "unknown")) -> "unknown"
            Enum.any?(others, &(&1["status"] == "changed")) -> "changed_across_tested_levels"
            true -> "stable_across_tested_levels"
          end

        %{"request_id" => request_id, "status" => status}
      end)

    %{
      "format" => "mission_resolution_study.v1",
      "study_id" => id,
      "execution_boundary" => "analysis_only_no_command_execution",
      "reference_level_id" => reference_id,
      "comparison_policy" => %{
        "window_time_tolerance_s" => window_tolerance,
        "schedule_time_tolerance_s" => schedule_tolerance,
        "margin_thresholds" => thresholds
      },
      "levels" => results,
      "comparisons" => comparisons,
      "request_stability" => stability,
      "error_level_count" => Enum.count(results, &(&1["status"] == "error")),
      "limits" => [
        "agreement at tested resolutions is not a convergence proof or operational validation",
        "the finest tested level is a comparison baseline, not independent physical truth",
        "brief windows and constraint violations can remain between tested samples",
        "transition bracket widths exclude orbit, environment, optics and attitude uncertainty",
        "signed margins and near-limit flags describe tested activity samples only",
        "numeric margins with different units are never ranked against each other",
        "categorical checks and unknown margins have no quantitative robustness claim",
        "tracking is a fixed-lookback secant; acquisition and slew feasibility remain unmodeled"
      ]
    }
  end

  defp thresholds!(thresholds) when is_map(thresholds) do
    Map.new(thresholds, fn {id, threshold} ->
      Input.id!(id)
      SurfaceSupport.fields!(threshold, ~w(unit minimum_headroom), "margin threshold")

      unless is_binary(threshold["unit"]) and byte_size(threshold["unit"]) in 1..64,
        do: raise(ArgumentError, "margin threshold unit required")

      {id,
       %{
         "unit" => threshold["unit"],
         "minimum_headroom" =>
           Input.number!(threshold["minimum_headroom"], "minimum_headroom", 0, 1.0e15)
       }}
    end)
  end

  defp validate_levels!(levels, reference_id) do
    unless is_list(levels) and length(levels) in 2..16,
      do: raise(ArgumentError, "2..16 resolution levels required")

    Enum.each(levels, fn l ->
      SurfaceSupport.fields!(l, ~w(id dimension sample_step_s max_step_s), "resolution level")
      Input.id!(l["id"])

      unless l["dimension"] in ~w(reference sampling integration),
        do: raise(ArgumentError, "invalid resolution dimension")

      Input.positive!(l["sample_step_s"], "sample_step_s")
      Input.positive!(l["max_step_s"], "max_step_s")
    end)

    unless length(Enum.uniq_by(levels, & &1["id"])) == length(levels),
      do: raise(ArgumentError, "duplicate level IDs")

    unless length(Enum.uniq_by(levels, &{&1["sample_step_s"] * 1.0, &1["max_step_s"] * 1.0})) ==
             length(levels),
           do: raise(ArgumentError, "resolution levels must use distinct step combinations")

    reference = Enum.find(levels, &(&1["id"] == reference_id))

    unless reference != nil and reference["dimension"] == "reference" and
             Enum.count(levels, &(&1["dimension"] == "reference")) == 1,
           do: raise(ArgumentError, "exactly one named reference level required")

    unless Enum.all?(
             levels,
             &(reference["sample_step_s"] <= &1["sample_step_s"] and
                 reference["max_step_s"] <= &1["max_step_s"])
           ),
           do:
             raise(
               ArgumentError,
               "reference must use the finest tested sampling and integration steps"
             )

    Enum.each(levels, fn l ->
      if (l["dimension"] == "sampling" and l["max_step_s"] != reference["max_step_s"]) or
           (l["dimension"] == "integration" and l["sample_step_s"] != reference["sample_step_s"]),
         do: raise(ArgumentError, "vary one resolution dimension at a time relative to reference")
    end)
  end

  defp evidence(report, thresholds) do
    Enum.map(report["requests"], fn request ->
      pairs = Enum.filter(report["analyses"], &(&1["request_id"] == request["request_id"]))

      windows =
        pairs
        |> Enum.flat_map(fn pair ->
          Enum.map(
            Map.get(pair, "window_evidence", []),
            &Map.put(&1, "asset_id", pair["asset_id"])
          )
        end)
        |> Enum.sort_by(&{&1["asset_id"], &1["starts_at_s"], &1["ends_at_s"]})

      activities =
        report["activities"]
        |> Enum.filter(&(&1["request_id"] == request["request_id"]))
        |> Enum.map(fn a ->
          samples =
            pairs
            |> Enum.filter(&(&1["asset_id"] == a["asset_id"]))
            |> Enum.flat_map(& &1["samples"])
            |> Kernel.++(Map.get(a, "endpoint_samples", []))
            |> Enum.filter(
              &(&1["epoch_s"] >= a["starts_at_s"] and &1["epoch_s"] <= a["ends_at_s"])
            )
            |> Enum.uniq_by(&(&1["epoch_s"] * 1.0))
            |> Enum.sort_by(& &1["epoch_s"])

          supporting =
            Enum.find(
              windows,
              &(&1["asset_id"] == a["asset_id"] and &1["starts_at_s"] <= a["starts_at_s"] and
                  &1["ends_at_s"] >= a["ends_at_s"])
            )

          a
          |> Map.take(~w(asset_id starts_at_s ends_at_s type))
          |> Map.merge(%{
            "supporting_window" => supporting || :null,
            "duration_headroom_s" =>
              if(supporting,
                do:
                  supporting["ends_at_s"] - supporting["starts_at_s"] -
                    request["required_duration_s"],
                else: :null
              ),
            "endpoint_evaluation_count" => Map.get(a, "endpoint_evaluation_count", 0),
            "endpoint_evidence_present" => length(Map.get(a, "endpoint_samples", [])) == 2,
            "tested_sample_count" => length(samples),
            "largest_tested_interval_s" =>
              samples
              |> Enum.chunk_every(2, 1, :discard)
              |> Enum.map(fn [x, y] -> y["epoch_s"] - x["epoch_s"] end)
              |> Enum.max(fn -> 0.0 end),
            "sampled_check_margins" => margins(samples, thresholds)
          })
        end)

      %{
        "request_id" => request["request_id"],
        "opportunity_count" => request["opportunity_count"],
        "scheduling_status" => request["status"],
        "scheduling_reasons" => request["reasons"],
        "required_duration_s" => request["required_duration_s"],
        "windows" => windows,
        "activities" => activities
      }
    end)
  end

  defp margins(samples, thresholds) do
    samples
    |> Enum.flat_map(& &1["checks"])
    |> Enum.group_by(& &1["id"])
    |> Enum.sort()
    |> Enum.map(fn {id, checks} ->
      numeric = Enum.filter(checks, &is_number(&1["margin"]))
      units = numeric |> Enum.map(& &1["margin_unit"]) |> Enum.uniq()

      minimum =
        if length(units) == 1, do: numeric |> Enum.map(& &1["margin"]) |> Enum.min(), else: :null

      threshold = thresholds[id]

      assessment =
        cond do
          units == [] -> "no_numeric_margin"
          length(units) != 1 -> "inconsistent_units"
          threshold == nil -> "no_headroom_threshold_declared"
          threshold["unit"] != hd(units) -> "threshold_unit_mismatch"
          minimum < threshold["minimum_headroom"] -> "near_declared_limit"
          true -> "meets_declared_sampled_headroom"
        end

      %{
        "check_id" => id,
        "minimum_sampled_margin" => minimum,
        "margin_unit" => if(length(units) == 1, do: hd(units), else: :null),
        "numeric_sample_count" => length(numeric),
        "unknown_or_categorical_sample_count" => length(checks) - length(numeric),
        "failed_sample_count" => Enum.count(checks, &(not &1["passed"])),
        "assessment" => assessment
      }
    end)
  end

  defp compare(row, reference, id, wt, st) do
    actual = Enum.find(Map.get(row, "request_evidence", []), &(&1["request_id"] == id))
    expected = Enum.find(Map.get(reference, "request_evidence", []), &(&1["request_id"] == id))

    if row["status"] != "ok" or reference["status"] != "ok" or actual == nil or expected == nil do
      %{
        "request_id" => id,
        "status" => "unknown",
        "reasons" => ["level_error_or_missing_request"]
      }
    else
      window_delta = timing_delta(actual["windows"], expected["windows"])
      activity_delta = timing_delta(actual["activities"], expected["activities"])

      reasons =
        []
        |> reason(
          actual["opportunity_count"] != expected["opportunity_count"],
          "duration_support_changed"
        )
        |> reason(
          actual["scheduling_status"] != expected["scheduling_status"],
          "scheduling_status_changed"
        )
        |> reason(
          actual["scheduling_reasons"] != expected["scheduling_reasons"],
          "scheduling_reason_changed"
        )
        |> reason(window_delta == :null, "window_count_or_asset_changed")
        |> reason(is_number(window_delta) and window_delta > wt, "window_timing_changed")
        |> reason(activity_delta == :null, "scheduled_asset_or_count_changed")
        |> reason(is_number(activity_delta) and activity_delta > st, "schedule_timing_changed")

      %{
        "request_id" => id,
        "status" => if(reasons == [], do: "agrees_with_reference", else: "changed"),
        "reasons" => Enum.reverse(reasons),
        "max_window_endpoint_delta_s" => window_delta,
        "max_activity_endpoint_delta_s" => activity_delta
      }
    end
  end

  defp reason(reasons, true, reason), do: [reason | reasons]
  defp reason(reasons, false, _), do: reasons

  defp timing_delta(a, b) do
    if length(a) != length(b) or Enum.map(a, & &1["asset_id"]) != Enum.map(b, & &1["asset_id"]) do
      :null
    else
      Enum.zip(a, b)
      |> Enum.flat_map(fn {x, y} ->
        [abs(x["starts_at_s"] - y["starts_at_s"]), abs(x["ends_at_s"] - y["ends_at_s"])]
      end)
      |> Enum.max(fn -> 0.0 end)
    end
  end

  def csv(report) do
    rows =
      for r <- report["levels"] do
        s = Map.get(r, "summary", %{})

        [
          r["level"]["id"],
          r["status"],
          r["level"]["sample_step_s"],
          r["level"]["max_step_s"],
          Map.get(s, "supported_request_count", ""),
          Map.get(s, "scheduled_request_count", ""),
          Map.get(s, "scheduled_duration_s", ""),
          Map.get(r, "error", "")
        ]
      end

    [
      [
        "level",
        "status",
        "sampling_s",
        "integration_s",
        "supported_requests",
        "scheduled_requests",
        "scheduled_seconds",
        "error"
      ]
      | rows
    ]
    |> Enum.map_join("\n", fn row ->
      Enum.map_join(row, ",", &("\"" <> String.replace(to_string(&1), "\"", "\"\"") <> "\""))
    end)
    |> Kernel.<>("\n")
  end

  def markdown(report) do
    table =
      [
        "| Level | Sample s | Integration s | Supported | Scheduled | Seconds |",
        "| --- | --- | --- | --- | --- | --- |"
      ] ++
        Enum.map(report["levels"], fn r ->
          s = Map.get(r, "summary", %{})

          "| #{r["level"]["id"]} | #{r["level"]["sample_step_s"]} | #{r["level"]["max_step_s"]} | #{Map.get(s, "supported_request_count", "error")} | #{Map.get(s, "scheduled_request_count", "error")} | #{Map.get(s, "scheduled_duration_s", "error")} |"
        end)

    "# #{report["study_id"]}\n\n" <>
      Enum.join(table, "\n") <>
      "\n\n" <>
      Enum.map_join(
        report["request_stability"],
        "\n",
        &("- " <> &1["request_id"] <> ": " <> &1["status"])
      ) <>
      "\n\n" <>
      reference_markdown(report) <>
      "\n\n[report.json](report.json) contains transition brackets, sampled margins, supporting windows, " <>
      "per-level comparisons, assumptions and errors. Agreement is relative to the finest tested level.\n\n" <>
      Enum.map_join(report["limits"], "\n", &("- " <> &1)) <> "\n"
  end

  defp reference_markdown(report) do
    reference = Enum.find(report["levels"], &(&1["level"]["id"] == report["reference_level_id"]))

    Enum.map_join(Map.get(reference, "request_evidence", []), "\n\n", fn request ->
      "## Reference evidence: #{request["request_id"]}\n\n" <>
        Enum.map_join(request["activities"], "\n\n", fn a ->
          "Activity: #{a["starts_at_s"]}–#{a["ends_at_s"]} seconds since J2000 in the declared scale. " <>
            "Window duration headroom: #{a["duration_headroom_s"]} s. " <>
            "Largest tested activity interval: #{a["largest_tested_interval_s"]} s.\n\n" <>
            "| Check | Minimum sampled margin | Unit | Assessment |\n| --- | --- | --- | --- |\n" <>
            Enum.map_join(a["sampled_check_margins"], "\n", fn m ->
              value =
                if m["minimum_sampled_margin"] == :null,
                  do: "unknown",
                  else: to_string(m["minimum_sampled_margin"])

              unit = if m["margin_unit"] == :null, do: "—", else: m["margin_unit"]
              "| #{m["check_id"]} | #{value} | #{unit} | #{m["assessment"]} |"
            end)
        end)
    end)
  end
end
