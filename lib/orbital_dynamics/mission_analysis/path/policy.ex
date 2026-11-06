defmodule OrbitalDynamics.MissionAnalysis.Path.Policy do
  @moduledoc "Declared per-asset rules and modes, tested at multiple bounded path cadences."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Schema.JsonSafety
  @enforce_keys [:assets, :sample_steps_s, :max_evaluations, :max_samples_per_segment]
  defstruct @enforce_keys

  def new!(assets, opts) when is_map(assets) do
    keys = ~w(sample_steps_s max_evaluations max_samples_per_segment)a

    unless Keyword.keyword?(opts) and Enum.sort(Keyword.keys(opts)) == Enum.sort(keys),
      do: raise(ArgumentError, "explicit path sampling and budgets required")

    steps = opts[:sample_steps_s]

    unless is_list(steps) and length(steps) in 1..6,
      do: raise(ArgumentError, "1..6 path sample steps required")

    steps = Enum.map(steps, &Input.number!(&1, "path sample step", 0.000001, 1.0e6))

    if length(Enum.uniq(steps)) != length(steps),
      do: raise(ArgumentError, "path sample steps must be distinct")

    assets =
      Map.new(assets, fn {id, a} ->
        Input.id!(id)

        unless Enum.sort(Map.keys(a)) ==
                 Enum.sort(~w(activity_modes transition_mode modes rules)a),
               do:
                 raise(
                   ArgumentError,
                   "explicit activity modes, transition mode and rules required"
                 )

        modes = Map.new(a.activity_modes, fn {r, m} -> {Input.id!(r), Input.id!(m)} end)
        Input.id!(a.transition_mode)
        unless is_map(a.modes), do: raise(ArgumentError, "explicit mode registry required")

        registry =
          Map.new(a.modes, fn {name, parameters} ->
            Input.id!(name)
            unless is_map(parameters), do: raise(ArgumentError, "mode parameters must be maps")
            {name, JsonSafety.normalize_input!(parameters, "mode parameters")}
          end)

        unless is_list(a.rules) and length(a.rules) in 1..32,
          do: raise(ArgumentError, "1..32 path rules required per asset")

        rules =
          Enum.map(a.rules, fn r ->
            unless Enum.sort(Map.keys(r)) == Enum.sort(~w(id module configuration)a),
              do: raise(ArgumentError, "invalid path rule fields")

            Input.id!(r.id)

            unless is_atom(r.module) and Code.ensure_loaded?(r.module) and
                     function_exported?(r.module, :prepare, 3) and
                     function_exported?(r.module, :evaluate, 4),
                   do: raise(ArgumentError, "path rule must implement Path.Check")

            unless is_map(r.configuration),
              do: raise(ArgumentError, "path rule configuration must be a map")

            %{
              r
              | configuration:
                  JsonSafety.normalize_input!(r.configuration, "path rule configuration")
            }
          end)

        unless length(Enum.uniq_by(rules, & &1.id)) == length(rules),
          do: raise(ArgumentError, "duplicate path rule IDs")

        {id,
         %{
           activity_modes: modes,
           transition_mode: a.transition_mode,
           modes: registry,
           rules: rules
         }}
      end)

    %__MODULE__{
      assets: assets,
      sample_steps_s: Enum.sort(steps, :desc),
      max_evaluations: integer!(opts[:max_evaluations], "max_evaluations", 1_000_000),
      max_samples_per_segment:
        integer!(opts[:max_samples_per_segment], "max_samples_per_segment", 10_000)
    }
  end

  def validate!(%__MODULE__{} = p),
    do:
      new!(p.assets,
        sample_steps_s: p.sample_steps_s,
        max_evaluations: p.max_evaluations,
        max_samples_per_segment: p.max_samples_per_segment
      )

  defp integer!(value, label, maximum) do
    unless is_integer(value) and value in 1..maximum,
      do: raise(ArgumentError, "#{label} must be 1..#{maximum}")

    value
  end

  def describe(p),
    do: %{
      "sample_steps_s" => p.sample_steps_s,
      "max_evaluations" => p.max_evaluations,
      "max_samples_per_segment" => p.max_samples_per_segment,
      "assets" =>
        Map.new(p.assets, fn {id, a} ->
          {id,
           %{
             "activity_modes" => a.activity_modes,
             "modes" => a.modes,
             "transition_mode" => a.transition_mode,
             "rules" =>
               Enum.map(a.rules, fn r ->
                 %{
                   "id" => r.id,
                   "module" => Atom.to_string(r.module),
                   "configuration" => r.configuration
                 }
               end)
           }}
        end),
      "limits" => [
        "only declared rules at tested epochs; continuous violations may remain undetected",
        "all tested cadences gate selection; a violation on any tested grid vetoes the candidate",
        "payload mode switches are instantaneous declared assumptions, not validated mechanisms or switch latency",
        "coverage is segment-local; terminal and idle coverage requires an explicit attitude horizon and is reported separately"
      ]
    }
end
