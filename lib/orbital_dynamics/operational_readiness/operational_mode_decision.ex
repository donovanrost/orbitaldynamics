defmodule OrbitalDynamics.OperationalReadiness.OperationalModeDecision do
  @moduledoc false

  @analysis_modes ~w(analysis_only simulation rehearsal trade_study training not_for_execution)
  @analysis_mode_aliases %{
    "analysis" => "analysis_only",
    "analysis_mode" => "analysis_only",
    "analytical" => "analysis_only",
    "dry_run" => "simulation",
    "exercise" => "rehearsal",
    "no_execute" => "not_for_execution",
    "no_execution" => "not_for_execution",
    "not_for_ops" => "not_for_execution",
    "ops_rehearsal" => "rehearsal",
    "sim" => "simulation",
    "trade" => "trade_study",
    "tradeoff" => "trade_study"
  }

  def analysis_modes, do: @analysis_modes
  def analysis_mode_aliases, do: @analysis_mode_aliases

  def decide(artifact, opts) do
    cond do
      Keyword.get(opts, :not_for_execution) == true ->
        {"not_for_execution", "opts.not_for_execution",
         "opts mark the artifact not-for-execution"}

      mode = opts |> Keyword.get(:mode) |> normalized_mode() ->
        analysis_mode_decision(mode, "opts.mode")

      mode = opts |> Keyword.get(:operational_mode) |> normalized_mode() ->
        analysis_mode_decision(mode, "opts.operational_mode")

      truthy?(Map.get(artifact, "not_for_execution")) ->
        {"not_for_execution", "artifact.not_for_execution",
         "artifact is marked not-for-execution"}

      truthy?(get_in(artifact, ["metadata", "not_for_execution"])) ->
        {"not_for_execution", "artifact.metadata.not_for_execution",
         "artifact metadata marks the artifact not-for-execution"}

      truthy?(get_in(artifact, ["assumptions", "not_for_execution"])) ->
        {"not_for_execution", "artifact.assumptions.not_for_execution",
         "artifact assumptions mark the artifact not-for-execution"}

      mode =
          artifact
          |> first_value([
            ["operational_mode"],
            ["mode"],
            ["artifact_mode"],
            ["metadata", "operational_mode"],
            ["metadata", "mode"],
            ["assumptions", "operational_mode"],
            ["assumptions", "mode"]
          ])
          |> normalized_mode() ->
        analysis_mode_decision(mode, "artifact mode")

      true ->
        nil
    end
  end

  defp analysis_mode_decision(mode, source) when mode in @analysis_modes do
    {mode, source, "#{source} marks the artifact #{mode}"}
  end

  defp analysis_mode_decision(_mode, _source), do: nil

  defp normalized_mode(nil), do: nil

  defp normalized_mode(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
    |> case do
      "" -> nil
      value -> Map.get(@analysis_mode_aliases, value, value)
    end
  end

  defp truthy?(value) when value in [true, "true", "yes", "1", 1], do: true
  defp truthy?(value) when is_binary(value), do: normalized_mode(value) in ["true", "yes", "1"]
  defp truthy?(value) when is_atom(value), do: value |> Atom.to_string() |> truthy?()
  defp truthy?(_value), do: false

  defp first_value(map, paths) do
    paths
    |> Enum.map(&get_in(map, &1))
    |> Enum.find(fn value -> value not in [nil, ""] end)
  end

  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
