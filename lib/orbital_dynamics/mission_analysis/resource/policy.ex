defmodule OrbitalDynamics.MissionAnalysis.Resource.Policy do
  @moduledoc "Explicit dynamic resource models and bounded independent integration cadences."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Schema.JsonSafety
  @enforce_keys [:assets, :sample_steps_s, :max_intervals_per_asset, :max_evaluations]
  defstruct @enforce_keys

  def new!(assets, opts) when is_map(assets) do
    unless Keyword.keyword?(opts) and
             Enum.sort(Keyword.keys(opts)) ==
               Enum.sort(~w(sample_steps_s max_intervals_per_asset max_evaluations)a),
           do: raise(ArgumentError, "explicit resource integration controls required")

    steps = opts[:sample_steps_s]

    unless is_list(steps) and length(steps) in 1..6,
      do: raise(ArgumentError, "1..6 resource cadences required")

    steps = Enum.map(steps, &Input.number!(&1, "resource cadence", 0.000001, 1.0e6))

    if length(Enum.uniq(steps)) != length(steps),
      do: raise(ArgumentError, "duplicate resource cadences")

    assets =
      Map.new(assets, fn {id, models} ->
        Input.id!(id)

        unless is_list(models) and length(models) in 1..16,
          do: raise(ArgumentError, "1..16 resource models required per configured asset")

        models =
          Enum.map(models, fn m ->
            unless is_map(m) and
                     Enum.sort(Map.keys(m)) ==
                       Enum.sort(~w(id module configuration exclusive_cost_keys)a),
                   do: raise(ArgumentError, "invalid resource model declaration")

            Input.id!(m.id)

            unless is_atom(m.module) and Code.ensure_loaded?(m.module) and
                     Enum.all?([prepare: 3, initial: 1, boundaries: 1, step: 4], fn {f, a} ->
                       function_exported?(m.module, f, a)
                     end),
                   do: raise(ArgumentError, "resource module must implement Resource.Model")

            unless is_map(m.configuration),
              do: raise(ArgumentError, "resource configuration must be a map")

            unless is_list(m.exclusive_cost_keys),
              do: raise(ArgumentError, "exclusive_cost_keys must be explicit")

            Enum.each(m.exclusive_cost_keys, &Input.id!/1)

            %{
              m
              | configuration:
                  JsonSafety.normalize_input!(m.configuration, "resource configuration")
            }
          end)

        if length(Enum.uniq_by(models, & &1.id)) != length(models),
          do: raise(ArgumentError, "duplicate resource model IDs")

        {id, models}
      end)

    %__MODULE__{
      assets: assets,
      sample_steps_s: Enum.sort(steps, :desc),
      max_intervals_per_asset: integer!(opts[:max_intervals_per_asset], 10000),
      max_evaluations: integer!(opts[:max_evaluations], 100_000)
    }
  end

  def validate!(%__MODULE__{} = p),
    do:
      new!(p.assets,
        sample_steps_s: p.sample_steps_s,
        max_intervals_per_asset: p.max_intervals_per_asset,
        max_evaluations: p.max_evaluations
      )

  defp integer!(n, upper) do
    unless is_integer(n) and n in 1..upper,
      do: raise(ArgumentError, "resource budget must be 1..#{upper}")

    n
  end

  def describe(nil), do: :null

  def describe(p),
    do: %{
      "sample_steps_s" => p.sample_steps_s,
      "max_intervals_per_asset_per_cadence" => p.max_intervals_per_asset,
      "max_model_evaluations" => p.max_evaluations,
      "assets" =>
        Map.new(p.assets, fn {id, models} ->
          {id,
           Enum.map(models, fn m ->
             %{
               "id" => m.id,
               "module" => Atom.to_string(m.module),
               "configuration" => m.configuration,
               "exclusive_cost_keys" => m.exclusive_cost_keys
             }
           end)}
        end)
    }
end
