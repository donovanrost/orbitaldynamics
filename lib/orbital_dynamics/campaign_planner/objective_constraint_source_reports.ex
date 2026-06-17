defmodule OrbitalDynamics.CampaignPlanner.ObjectiveConstraintSourceReports do
  @moduledoc false

  @constraint_fields [
    {"source_constraint_report", "mission_state.source_constraint_report"},
    {"constraint_report", "mission_state.constraint_report"}
  ]
  @prior_constraint_fields [
    {"source_constraint_report", "prior_plan.source_constraint_report"},
    {"constraint_report", "prior_plan.constraint_report"}
  ]
  @objective_satisfaction_fields [
    {"source_objective_satisfaction_report",
     "mission_state.source_objective_satisfaction_report"},
    {"objective_satisfaction_report", "mission_state.objective_satisfaction_report"}
  ]
  @prior_objective_satisfaction_fields [
    {"source_objective_satisfaction_report", "prior_plan.source_objective_satisfaction_report"},
    {"objective_satisfaction_report", "prior_plan.objective_satisfaction_report"}
  ]
  @objective_tradeoff_fields [
    {"source_objective_tradeoff_report", "mission_state.source_objective_tradeoff_report"},
    {"objective_tradeoff_report", "mission_state.objective_tradeoff_report"}
  ]
  @prior_objective_tradeoff_fields [
    {"source_objective_tradeoff_report", "prior_plan.source_objective_tradeoff_report"},
    {"objective_tradeoff_report", "prior_plan.objective_tradeoff_report"}
  ]
  @score_term_fields [
    {"source_score_term_report", "mission_state.source_score_term_report"},
    {"score_term_report", "mission_state.score_term_report"}
  ]
  @prior_score_term_fields [
    {"source_score_term_report", "prior_plan.source_score_term_report"},
    {"score_term_report", "prior_plan.score_term_report"}
  ]

  def constraint_reports(mission_state, opts),
    do: reports(mission_state, @constraint_fields, opts)

  def prior_constraint_reports(prior_plan, opts) do
    prior_plan_reports(prior_plan, @prior_constraint_fields, @constraint_fields, opts)
  end

  def source_constraint_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [{"source_constraint_report", "mission_state.source_constraint_report"}],
      opts
    )
  end

  def source_constraint_reports_with_result_artifact_fallback(mission_state, opts) do
    source_reports_with_result_artifact_fallback(
      mission_state,
      &source_constraint_reports(&1, opts),
      ["source_constraint_report", "constraint_report"],
      opts
    )
  end

  def canonical_constraint_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [{"constraint_report", "mission_state.constraint_report"}],
      opts
    )
  end

  def objective_satisfaction_reports(mission_state, opts) do
    reports(mission_state, @objective_satisfaction_fields, opts)
  end

  def prior_objective_satisfaction_reports(prior_plan, opts) do
    prior_plan_reports(
      prior_plan,
      @prior_objective_satisfaction_fields,
      @objective_satisfaction_fields,
      opts
    )
  end

  def source_objective_satisfaction_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [
        {"source_objective_satisfaction_report",
         "mission_state.source_objective_satisfaction_report"}
      ],
      opts
    )
  end

  def source_objective_satisfaction_reports_with_result_artifact_fallback(mission_state, opts) do
    source_reports_with_result_artifact_fallback(
      mission_state,
      &source_objective_satisfaction_reports(&1, opts),
      ["source_objective_satisfaction_report", "objective_satisfaction_report"],
      opts
    )
  end

  def canonical_objective_satisfaction_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [{"objective_satisfaction_report", "mission_state.objective_satisfaction_report"}],
      opts
    )
  end

  def objective_tradeoff_reports(mission_state, opts) do
    reports(mission_state, @objective_tradeoff_fields, opts)
  end

  def prior_objective_tradeoff_reports(prior_plan, opts) do
    prior_plan_reports(
      prior_plan,
      @prior_objective_tradeoff_fields,
      @objective_tradeoff_fields,
      opts
    )
  end

  def source_objective_tradeoff_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [{"source_objective_tradeoff_report", "mission_state.source_objective_tradeoff_report"}],
      opts
    )
  end

  def source_objective_tradeoff_reports_with_result_artifact_fallback(mission_state, opts) do
    source_reports_with_result_artifact_fallback(
      mission_state,
      &source_objective_tradeoff_reports(&1, opts),
      ["source_objective_tradeoff_report", "objective_tradeoff_report"],
      opts
    )
  end

  def canonical_objective_tradeoff_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [{"objective_tradeoff_report", "mission_state.objective_tradeoff_report"}],
      opts
    )
  end

  def score_term_reports(mission_state, opts),
    do: reports(mission_state, @score_term_fields, opts)

  def prior_score_term_reports(prior_plan, opts) do
    prior_plan_reports(prior_plan, @prior_score_term_fields, @score_term_fields, opts)
  end

  def source_score_term_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [{"source_score_term_report", "mission_state.source_score_term_report"}],
      opts
    )
  end

  def source_score_term_reports_with_result_artifact_fallback(mission_state, opts) do
    source_reports_with_result_artifact_fallback(
      mission_state,
      &source_score_term_reports(&1, opts),
      ["source_score_term_report", "score_term_report"],
      opts
    )
  end

  def canonical_score_term_reports(mission_state, opts) do
    source_reports(
      mission_state,
      [{"score_term_report", "mission_state.score_term_report"}],
      opts
    )
  end

  def pressure_rows(reports) do
    report_pressure_rows(reports, &Map.get(&1, "rows", []))
  end

  def objective_tradeoff_pressure_rows(reports) do
    report_pressure_rows(reports, &objective_tradeoff_report_rows/1)
  end

  defp reports(mission_state, fields, opts) do
    source_reports(mission_state, fields, opts) ++
      result_artifact_embedded_reports(mission_state, Enum.map(fields, &elem(&1, 0)), opts)
  end

  defp report_pressure_rows(reports, rows_fun) do
    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> rows_fun.()
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        {Map.put(row, "_source_report_trust_boundary", trust_boundary), source_path, index}
      end)
    end)
  end

  defp objective_tradeoff_report_rows(report) do
    cond do
      is_list(report["tradeoffs"]) -> report["tradeoffs"]
      is_list(report["rows"]) -> report["rows"]
      true -> []
    end
  end

  defp source_reports(mission_state, fields, opts) do
    callbacks = callbacks!(opts)
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      callbacks.source_report_entries.(Map.get(mission_state, field), source_path)
    end)
  end

  defp prior_plan_reports(prior_plan, fields, result_artifact_fields, opts) do
    prior_plan = stringify_keys(prior_plan || %{})

    direct_reports =
      fields
      |> Enum.flat_map(fn {field, source_path} ->
        case Map.get(prior_plan, field) do
          %{} = report -> [{stringify_keys(report), source_path}]
          _report -> []
        end
      end)

    direct_reports ++ prior_plan_result_artifact_reports(prior_plan, result_artifact_fields, opts)
  end

  defp prior_plan_result_artifact_reports(prior_plan, fields, opts) do
    callbacks = prior_plan_callbacks!(opts)
    report_keys = Enum.map(fields, &elem(&1, 0))
    callbacks.result_artifact_embedded_reports.(prior_plan, report_keys)
  end

  defp source_reports_with_result_artifact_fallback(
         mission_state,
         direct_source_fun,
         result_artifact_keys,
         opts
       ) do
    case direct_source_fun.(mission_state) do
      [] ->
        mission_state
        |> stringify_keys()
        |> result_artifact_embedded_reports(result_artifact_keys, opts)

      reports ->
        reports
    end
  end

  defp result_artifact_embedded_reports(mission_state, report_keys, opts)
       when is_list(report_keys) do
    Enum.flat_map(report_keys, &result_artifact_embedded_reports(mission_state, &1, opts))
  end

  defp result_artifact_embedded_reports(mission_state, report_key, opts) do
    callbacks = callbacks!(opts)
    callbacks.result_artifact_embedded_reports.(mission_state, report_key)
  end

  defp callbacks!(opts) do
    %{
      source_report_entries: Keyword.fetch!(opts, :source_report_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp prior_plan_callbacks!(opts) do
    %{
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
