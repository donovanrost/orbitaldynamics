defmodule OrbitalDynamics.EventSearch.Function do
  @moduledoc """
  Continuous scalar event function in explicit units. Callback receives one state
  and returns {:ok, value, time_derivative_or_nil, JSON_metadata}, or an explicit
  unknown/error. Optional derivatives enable stationary-contact searches; they
  must describe this same function in these same axes. No derivative is inferred.
  """
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Schema.JsonSafety
  @enforce_keys [:id, :evaluate, :units, :value_tolerance]
  defstruct @enforce_keys ++
              [labels: %{}, condition: :none, direction: :any, root_filter: nil, assumptions: %{}]

  def new!(id, evaluate, opts) when is_function(evaluate, 1) do
    Input.id!(id)

    unless Keyword.keyword?(opts) and
             Enum.sort(
               Keyword.keys(opts) -- [:labels, :condition, :direction, :root_filter, :assumptions]
             ) == [:units, :value_tolerance] and
             length(opts) == length(Enum.uniq(Keyword.keys(opts))),
           do:
             raise(
               ArgumentError,
               "explicit event units/value_tolerance and valid controls required"
             )

    units = opts[:units]

    unless is_binary(units) and byte_size(units) in 1..64,
      do: raise(ArgumentError, "event function units required")

    condition = Keyword.get(opts, :condition, :none)
    direction = Keyword.get(opts, :direction, :any)

    unless condition in [:none, :nonnegative, :nonpositive] and
             direction in [:any, :increasing, :decreasing, :touching],
           do: raise(ArgumentError, "invalid event condition/direction")

    filter = Keyword.get(opts, :root_filter)

    unless filter == nil or (is_function(filter, 1) and condition == :none),
      do: raise(ArgumentError, "root filters apply only to point searches")

    labels = Keyword.get(opts, :labels, %{})

    unless is_map(labels) and
             Enum.all?(
               Map.keys(labels),
               &(&1 in [:increasing, :decreasing, :touching, :boundary])
             ),
           do: raise(ArgumentError, "invalid event labels")

    Enum.each(labels, fn {_, label} -> Input.id!(label) end)
    assumptions = Keyword.get(opts, :assumptions, %{})
    unless is_map(assumptions), do: raise(ArgumentError, "event assumptions must be a map")

    %__MODULE__{
      id: id,
      evaluate: evaluate,
      units: units,
      value_tolerance: Input.number!(opts[:value_tolerance], "event value tolerance", 0, 1.0e15),
      labels: labels,
      direction: direction,
      condition: condition,
      root_filter: filter,
      assumptions: JsonSafety.normalize_input!(assumptions, "event assumptions")
    }
  end

  @doc "Evaluate through the active search's shared accounting context, or directly outside a search."
  def call(%__MODULE__{} = f, state) do
    OrbitalDynamics.EventSearch.Context.function(f, state, fn ->
      case f.evaluate.(state) do
        {:ok, value, rate, metadata} when is_map(metadata) ->
          Input.number!(value, "event function value", -1.0e30, 1.0e30)
          if rate != nil, do: Input.number!(rate, "event function rate", -1.0e30, 1.0e30)
          {:ok, value, rate, JsonSafety.normalize_input!(metadata, "event metadata")}

        {:unknown, _} = unknown ->
          unknown

        {:error, _} = error ->
          error

        _ ->
          raise ArgumentError, "invalid event function result"
      end
    end)
  end

  @doc "Compose normalized scalar conditions; each child scale carries its own units. Unknown children remain unknown."
  def combine(id, children, operation, opts) do
    unless is_list(children) and length(children) in 1..16 and operation in [:all, :any, :not] and
             (operation != :not or length(children) == 1),
           do: raise(ArgumentError, "invalid bounded event composition")

    Enum.each(children, fn
      {%__MODULE__{} = f, scale} ->
        unless f.condition in [:nonnegative, :nonpositive],
          do: raise(ArgumentError, "composed children require an explicit signed condition")

        Input.positive!(scale, "condition normalization scale")

      _ ->
        raise ArgumentError, "event children require function/scale pairs"
    end)

    callback = fn state ->
      Enum.reduce_while(children, {:ok, []}, fn {f, scale}, {:ok, values} ->
        case call(f, state) do
          {:ok, value, _rate, _metadata} ->
            signed = if f.condition == :nonpositive, do: -value, else: value
            {:cont, {:ok, [signed / scale | values]}}

          other ->
            {:halt, other}
        end
      end)
      |> case do
        {:ok, values} ->
          value =
            case operation do
              :all -> Enum.min(values)
              :any -> Enum.max(values)
              :not -> -hd(values)
            end

          {:ok, value, nil, %{}}

        other ->
          other
      end
    end

    new!(
      id,
      callback,
      [
        units: "1",
        assumptions: %{
          "operation" => Atom.to_string(operation),
          "children" =>
            Enum.map(children, fn {f, scale} ->
              %{"function" => describe(f), "normalization_scale" => scale}
            end),
          "limits" =>
            "closed signed margins; :not reverses sense and retains equality, not a strict set complement; nonsmooth derivative/grazing behavior is not inferred"
        }
      ] ++ Keyword.put_new(opts, :condition, :nonnegative)
    )
  end

  def describe(f),
    do: %{
      "id" => f.id,
      "units" => f.units,
      "value_tolerance" => f.value_tolerance,
      "condition" => Atom.to_string(f.condition),
      "direction" => Atom.to_string(f.direction),
      "assumptions" => f.assumptions
    }
end
