defmodule OrbitalDynamics.Search.Local do
  @moduledoc """
  Deterministic, bounded local-neighborhood generation for numeric parameters.

  The generator emits the seed followed by one decrease and one increase for
  each stepped parameter. Parameter names, move order, bounds, and truncation
  are retained so callers can inspect exactly which alternatives were offered.
  """

  @default_max_alternatives 17
  @max_step_parameters 32
  @max_alternatives_limit 65

  @doc """
  Declares the neighborhood model, deterministic ordering, and known limits.
  """
  def capabilities do
    %{
      generator: :numeric_parameter_local_neighborhood,
      model: :deterministic_bounded_single_axis_step,
      validation_level: :input_validated,
      output: :inspectable_parameter_alternatives,
      ordering: :seed_then_parameter_ascending_then_decrease_increase,
      random?: false,
      default_max_alternatives: @default_max_alternatives,
      max_step_parameters: @max_step_parameters,
      max_alternatives_limit: @max_alternatives_limit,
      known_limits: [
        :numeric_scalar_parameters_only,
        :single_axis_single_step_moves_only,
        :box_bounds_only,
        :one_neighborhood_generation,
        :no_constraint_evaluation,
        :no_solver
      ]
    }
  end

  @doc """
  Generates a bounded axis-step neighborhood around `seed_parameters`.

  Required option `:steps` is a non-empty map whose keys identify seed
  parameters and whose values are positive numeric step sizes. Optional
  `:bounds` entries use `{minimum, maximum}` tuples. The returned alternative
  order is always seed first, then parameter-name ascending, with decrease
  before increase. `:max_alternatives` includes the seed and defaults to
  #{@default_max_alternatives}; the hard maximum is #{@max_alternatives_limit}.
  At most #{@max_step_parameters} parameters may have steps.
  """
  def neighborhood(seed_parameters, opts)
      when is_map(seed_parameters) and is_list(opts) do
    parameters = normalize_numeric_map!(seed_parameters, :seed_parameters, allow_empty?: false)
    steps = opts |> required_steps!() |> normalize_steps!()
    bounds = opts |> Keyword.get(:bounds, %{}) |> normalize_bounds!()
    id_prefix = Keyword.get(opts, :id_prefix, "local")
    max_alternatives = Keyword.get(opts, :max_alternatives, @default_max_alternatives)

    validate_options!(parameters, steps, bounds, id_prefix, max_alternatives)

    step_parameter_names = steps |> Map.keys() |> Enum.sort()

    move_attempts =
      step_parameter_names
      |> Enum.flat_map(fn parameter ->
        step = Map.fetch!(steps, parameter)

        [
          move_attempt(parameters, bounds, id_prefix, parameter, -step, "decrease"),
          move_attempt(parameters, bounds, id_prefix, parameter, step, "increase")
        ]
      end)
      |> Enum.with_index(1)
      |> Enum.map(fn {attempt, generation_index} ->
        put_in(attempt, ["alternative", "generation_index"], generation_index)
      end)

    {feasible_attempts, bound_rejections} =
      Enum.split_with(move_attempts, &is_nil(&1["rejection_reason"]))

    selected_attempts = Enum.take(feasible_attempts, max_alternatives - 1)
    truncated_attempts = Enum.drop(feasible_attempts, max_alternatives - 1)

    seed_id = "#{id_prefix}:seed"

    seed = %{
      "id" => seed_id,
      "generation_index" => 0,
      "parameters" => parameters,
      "move" => %{"type" => "seed"}
    }

    alternatives =
      [seed | Enum.map(selected_attempts, & &1["alternative"])]

    rejected_moves =
      (Enum.map(bound_rejections, &rejected_move/1) ++
         Enum.map(truncated_attempts, &rejected_move(&1, "alternative_limit")))
      |> Enum.sort_by(&{&1["generation_index"], &1["id"]})

    %{
      "model" => "deterministic_bounded_single_axis_step",
      "seed_id" => seed_id,
      "seed_parameters" => parameters,
      "step_parameters" => step_parameter_names,
      "steps" => steps,
      "bounds" => json_bounds(bounds),
      "ordering" => "seed_then_parameter_ascending_then_decrease_increase",
      "max_alternatives" => max_alternatives,
      "generated_move_count" => length(move_attempts),
      "feasible_move_count" => length(feasible_attempts),
      "alternative_count" => length(alternatives),
      "rejected_move_count" => length(rejected_moves),
      "truncated_move_count" => length(truncated_attempts),
      "alternatives" => alternatives,
      "rejected_moves" => rejected_moves
    }
  end

  def neighborhood(_seed_parameters, _opts) do
    raise ArgumentError,
          "seed_parameters must be a non-empty numeric map and opts must be a keyword list"
  end

  defp required_steps!(opts) do
    case Keyword.fetch(opts, :steps) do
      {:ok, steps} -> steps
      :error -> raise ArgumentError, "missing required :steps option"
    end
  end

  defp normalize_steps!(steps) do
    steps = normalize_numeric_map!(steps, :steps, allow_empty?: false)

    if Enum.any?(steps, fn {_key, value} -> value <= 0 end) do
      raise ArgumentError, "steps must contain only positive numeric values"
    end

    steps
  end

  defp normalize_numeric_map!(value, label, opts) when is_map(value) do
    allow_empty? = Keyword.fetch!(opts, :allow_empty?)

    entries =
      Enum.map(value, fn {key, number} ->
        {normalize_name!(key, label), number}
      end)

    cond do
      entries == [] and not allow_empty? ->
        raise ArgumentError, "#{label} must be a non-empty map"

      Enum.any?(entries, fn {_key, number} -> not is_number(number) end) ->
        raise ArgumentError, "#{label} must contain only numeric values"

      duplicate_names?(entries) ->
        raise ArgumentError, "#{label} contains duplicate names after key normalization"

      true ->
        Map.new(entries)
    end
  end

  defp normalize_numeric_map!(_value, label, _opts) do
    raise ArgumentError, "#{label} must be a map"
  end

  defp normalize_bounds!(bounds) when is_map(bounds) do
    entries =
      Enum.map(bounds, fn
        {key, {minimum, maximum}} when is_number(minimum) and is_number(maximum) ->
          {normalize_name!(key, :bounds), {minimum, maximum}}

        _entry ->
          raise ArgumentError, "bounds must contain numeric {minimum, maximum} tuples"
      end)

    cond do
      duplicate_names?(entries) ->
        raise ArgumentError, "bounds contains duplicate names after key normalization"

      Enum.any?(entries, fn {_key, {minimum, maximum}} -> minimum > maximum end) ->
        raise ArgumentError, "bounds minimum must be less than or equal to maximum"

      true ->
        Map.new(entries)
    end
  end

  defp normalize_bounds!(_bounds) do
    raise ArgumentError, "bounds must be a map of parameter names to {minimum, maximum} tuples"
  end

  defp normalize_name!(key, label) when is_atom(key),
    do: normalize_name!(Atom.to_string(key), label)

  defp normalize_name!(key, _label) when is_binary(key) do
    if Regex.match?(~r/\A[A-Za-z][A-Za-z0-9_.-]*\z/, key) do
      key
    else
      raise ArgumentError,
            "parameter and score-term names must start with a letter and contain only letters, digits, ., _, or -"
    end
  end

  defp normalize_name!(_key, label) do
    raise ArgumentError, "#{label} keys must be atoms or strings"
  end

  defp duplicate_names?(entries) do
    names = Enum.map(entries, &elem(&1, 0))
    length(names) != length(Enum.uniq(names))
  end

  defp validate_options!(parameters, steps, bounds, id_prefix, max_alternatives) do
    parameter_names = Map.keys(parameters) |> MapSet.new()
    step_names = Map.keys(steps) |> MapSet.new()
    bound_names = Map.keys(bounds) |> MapSet.new()

    cond do
      map_size(steps) > @max_step_parameters ->
        raise ArgumentError, "steps may contain at most #{@max_step_parameters} parameters"

      not MapSet.subset?(step_names, parameter_names) ->
        raise ArgumentError, "steps keys must identify seed parameters"

      not MapSet.subset?(bound_names, parameter_names) ->
        raise ArgumentError, "bounds keys must identify seed parameters"

      not is_binary(id_prefix) or id_prefix == "" ->
        raise ArgumentError, "id_prefix must be a non-empty string"

      not is_integer(max_alternatives) or max_alternatives <= 0 or
          max_alternatives > @max_alternatives_limit ->
        raise ArgumentError,
              "max_alternatives must be an integer from 1 through #{@max_alternatives_limit}"

      true ->
        validate_seed_bounds!(parameters, bounds)
    end
  end

  defp validate_seed_bounds!(parameters, bounds) do
    case Enum.find(bounds, fn {parameter, {minimum, maximum}} ->
           value = Map.fetch!(parameters, parameter)
           value < minimum or value > maximum
         end) do
      nil ->
        :ok

      {parameter, _bound} ->
        raise ArgumentError, "seed parameter #{parameter} must be within its declared bound"
    end
  end

  defp move_attempt(parameters, bounds, id_prefix, parameter, delta, direction) do
    from = Map.fetch!(parameters, parameter)
    to = from + delta

    alternative = %{
      "id" => "#{id_prefix}:#{parameter}:#{direction}",
      "parameters" => Map.put(parameters, parameter, to),
      "move" => %{
        "type" => "axis_step",
        "parameter" => parameter,
        "direction" => direction,
        "delta" => delta,
        "from" => from,
        "to" => to
      }
    }

    %{
      "alternative" => alternative,
      "rejection_reason" => bound_rejection_reason(parameter, to, bounds)
    }
  end

  defp bound_rejection_reason(parameter, value, bounds) do
    case Map.get(bounds, parameter) do
      {minimum, _maximum} when value < minimum -> "below_minimum_bound"
      {_minimum, maximum} when value > maximum -> "above_maximum_bound"
      _bound -> nil
    end
  end

  defp rejected_move(attempt, reason \\ nil) do
    alternative = attempt["alternative"]

    %{
      "id" => alternative["id"],
      "generation_index" => alternative["generation_index"],
      "move" => alternative["move"],
      "reason" => reason || attempt["rejection_reason"]
    }
  end

  defp json_bounds(bounds) do
    Map.new(bounds, fn {parameter, {minimum, maximum}} ->
      {parameter, %{"minimum" => minimum, "maximum" => maximum}}
    end)
  end
end
