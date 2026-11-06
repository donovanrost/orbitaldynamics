defmodule OrbitalDynamics.MissionAnalysis.NativeData do
  @moduledoc "Bounded raw diagnostic payload validation at report projection. Computational admission uses container!/2 only."
  @max_float 1.7976931348623157e308

  def validate!(value, label) do
    walk(value, label, 0, {20_000, 4_194_304})
    value
  end

  @doc "Check a computational container without recursively inspecting its diagnostic fields."
  def container!(%OrbitalDynamics.MissionAnalysis.ReportData.Completed{}, label),
    do: raise(ArgumentError, "#{label} cannot be an internal report object")

  def container!(%OrbitalDynamics.MissionAnalysis.ReportData.Pending{}, label),
    do: raise(ArgumentError, "#{label} cannot be an internal report object")

  def container!(value, _) when is_map(value), do: value
  def container!(_, label), do: raise(ArgumentError, "#{label} must be a native map or struct")

  def fields(%_{} = value), do: Map.from_struct(value)
  def fields(value) when is_map(value), do: value

  defp walk(_, label, depth, {nodes, bytes}) when depth > 64 or nodes <= 0 or bytes < 0,
    do: raise(ArgumentError, "#{label} exceeds native data limits")

  defp walk(v, label, _, {nodes, bytes}) when is_binary(v) do
    unless String.valid?(v), do: raise(ArgumentError, "#{label} contains invalid UTF-8 text")
    remaining = bytes - byte_size(v)
    if remaining < 0, do: raise(ArgumentError, "#{label} exceeds native data limits")
    {nodes - 1, remaining}
  end

  defp walk(v, _, _, {nodes, bytes}) when is_atom(v) or is_integer(v), do: {nodes - 1, bytes}

  defp walk(v, label, _, {nodes, bytes}) when is_float(v) do
    unless v == v and abs(v) <= @max_float,
      do: raise(ArgumentError, "#{label} contains a non-finite number")

    {nodes - 1, bytes}
  end

  defp walk(v, label, depth, budget) when is_tuple(v) do
    if tuple_size(v) > 2048, do: raise(ArgumentError, "#{label} exceeds native collection limits")
    walk(Tuple.to_list(v), label, depth + 1, budget)
  end

  defp walk(%OrbitalDynamics.MissionAnalysis.ReportData.Completed{}, label, _, _),
    do: raise(ArgumentError, "#{label} cannot contain internal completed-report partitions")

  defp walk(%OrbitalDynamics.MissionAnalysis.ReportData.Pending{}, label, _, _),
    do: raise(ArgumentError, "#{label} cannot contain internal pending-report payloads")

  defp walk(v, label, depth, {nodes, bytes}) when is_map(v) do
    v = fields(v)
    if map_size(v) > 2048, do: raise(ArgumentError, "#{label} exceeds native collection limits")

    Enum.reduce(v, {nodes - 1, bytes}, fn {k, v}, state ->
      unless is_atom(k) or is_binary(k),
        do: raise(ArgumentError, "#{label} field names must be atoms or strings")

      state = walk(k, label, depth + 1, state)
      walk(v, label, depth + 1, state)
    end)
  end

  defp walk(v, label, depth, {nodes, bytes}) when is_list(v),
    do: list(v, label, depth + 1, {nodes - 1, bytes}, 0)

  defp walk(_, label, _, _), do: raise(ArgumentError, "#{label} contains unsupported native data")
  defp list([], _, _, state, _), do: state

  defp list([h | t], label, depth, state, n) when n < 2048,
    do: list(t, label, depth, walk(h, label, depth, state), n + 1)

  defp list(_, label, _, _, _),
    do: raise(ArgumentError, "#{label} contains an improper or oversized collection")
end
