defmodule OrbitalDynamics.MissionAnalysis.Resource.Generation.Declared do
  @moduledoc "Explicit constant or piecewise-constant bus generation; no inferred solar exposure."
  @behaviour OrbitalDynamics.MissionAnalysis.Resource.Generation
  alias OrbitalDynamics.MissionAnalysis.{Input, Models.SurfaceSupport}

  def prepare(_, _, c) do
    validate!(c)

    {:ok, c,
     %{
       "model" => "declared_bus_power",
       "configuration" => c,
       "limits" => ["no inferred solar exposure or physical source validation"]
     }}
  end

  def boundaries(%{"kind" => "constant"}), do: []
  def boundaries(c), do: Enum.flat_map(c["intervals"], &[&1["starts_at_s"], &1["ends_at_s"]])

  def evaluate(input, c) do
    power =
      case c do
        %{"kind" => "constant"} ->
          c["power_w"]

        _ ->
          case Enum.find(
                 c["intervals"],
                 &(input.epoch_s >= &1["starts_at_s"] and input.epoch_s < &1["ends_at_s"])
               ) do
            nil -> :null
            i -> i["power_w"]
          end
      end

    if power == :null,
      do: {:unknown, :declared_generation_unknown},
      else: {:ok, power, %{"model" => "declared_bus_power"}}
  end

  defp validate!(%{"kind" => "constant", "power_w" => w} = g) when map_size(g) == 2, do: power!(w)

  defp validate!(%{"kind" => "piecewise_constant", "intervals" => intervals} = g)
       when map_size(g) == 2 do
    unless is_list(intervals) and length(intervals) in 1..1000,
      do: raise(ArgumentError, "1..1000 declared charging intervals required")

    Enum.reduce(intervals, nil, fn i, previous ->
      SurfaceSupport.fields!(i, ~w(starts_at_s ends_at_s power_w), "charging interval")
      a = Input.number!(i["starts_at_s"], "charging start", -1.0e12, 1.0e12)
      b = Input.number!(i["ends_at_s"], "charging end", -1.0e12, 1.0e12)

      unless b > a and (previous == nil or a >= previous),
        do: raise(ArgumentError, "charging intervals must be ordered and nonoverlapping")

      power!(i["power_w"])
      b
    end)
  end

  defp validate!(_), do: raise(ArgumentError, "invalid declared charging configuration")
  defp power!(:null), do: :null
  defp power!(w), do: Input.number!(w, "battery bus power", 0, 1.0e12)
end
