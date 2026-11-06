defmodule OrbitalDynamics.MissionAnalysis.ReportData.Pending do
  @moduledoc false
  @enforce_keys [:value, :label]
  defstruct [:value, :label]
end

defmodule OrbitalDynamics.MissionAnalysis.ReportData.Completed do
  @moduledoc false
  @enforce_keys [:value]
  defstruct [:value]
end

defmodule OrbitalDynamics.MissionAnalysis.ReportData do
  @moduledoc "Explicit native-data to JSON-value projection for completed reports. Unchanged branches retain sharing."
  alias OrbitalDynamics.MissionAnalysis.Path.CheckResult

  @doc "Project a closed evidence partition once. Computational callbacks cannot return this internal wrapper."
  def complete(value), do: %__MODULE__.Completed{value: encode(value)}

  @doc "Retain raw callback diagnostics until their report boundary; no traversal here."
  def pending(value, label), do: %__MODULE__.Pending{value: value, label: label}

  def encode(%__MODULE__.Pending{value: value, label: label}) do
    OrbitalDynamics.MissionAnalysis.NativeData.validate!(value, label)
    encode(value)
  end

  def encode(%OrbitalDynamics.MissionAnalysis.Path.Result{} = result),
    do:
      encode(%{"checks" => result.checks, "metrics" => pending(result.metrics, "result metrics")})

  def encode(%__MODULE__.Completed{value: value}), do: value
  def encode(%CheckResult{} = c), do: CheckResult.report(c)
  def encode(%_{} = value), do: value |> Map.from_struct() |> encode()

  def encode(value) when is_map(value) do
    Enum.reduce(value, value, fn {key, old}, result ->
      name = key!(key)

      if name != key and Map.has_key?(value, name),
        do: raise(ArgumentError, "report contains duplicate atom/string field #{name}")

      encoded = encode(old)

      cond do
        name != key -> result |> Map.delete(key) |> Map.put(name, encoded)
        encoded === old -> result
        true -> Map.put(result, name, encoded)
      end
    end)
  end

  def encode([_ | _] = value), do: encode_list(value)
  def encode([]), do: []
  def encode(v) when is_tuple(v), do: v |> Tuple.to_list() |> encode()
  def encode(v) when v in [nil, :null], do: :null
  def encode(v) when is_boolean(v) or is_integer(v), do: v
  def encode(v) when is_atom(v), do: Atom.to_string(v)

  def encode(v) when is_binary(v) do
    unless String.valid?(v), do: raise(ArgumentError, "report contains invalid UTF-8 text")
    v
  end

  def encode(v) when is_float(v) do
    unless v == v and abs(v) <= 1.7976931348623157e308,
      do: raise(ArgumentError, "report contains non-finite number")

    v
  end

  def encode(_), do: raise(ArgumentError, "unsupported report value")

  defp encode_list([head | tail] = original) do
    first = encode(head)
    rest = encode_list(tail)
    if first === head and rest === tail, do: original, else: [first | rest]
  end

  defp encode_list([]), do: []
  defp encode_list(_), do: raise(ArgumentError, "report contains an improper list")
  defp key!(v) when is_binary(v), do: encode(v)
  defp key!(v) when is_atom(v), do: Atom.to_string(v)
  defp key!(_), do: raise(ArgumentError, "report field names must be atoms or strings")
end
