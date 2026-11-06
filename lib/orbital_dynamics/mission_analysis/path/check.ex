defmodule OrbitalDynamics.MissionAnalysis.Path.Check do
  @moduledoc "Mission-owned path checks over sampled states, full orientations and explicit modes."
  @callback prepare(OrbitalDynamics.MissionAnalysis.Asset.t(), term(), map()) ::
              {:ok, term(), map()} | {:error, term()}
  @callback evaluate(
              OrbitalDynamics.StateVector.t(),
              OrbitalDynamics.MissionAnalysis.Attitude.Pointing.t(),
              map(),
              term()
            ) ::
              {:ok, OrbitalDynamics.MissionAnalysis.Path.Result.t()} | {:error, term()}
end

defmodule OrbitalDynamics.MissionAnalysis.Path.Result do
  @moduledoc "Three-valued path evidence. Supported means only the declared check passed at that sample."
  alias OrbitalDynamics.MissionAnalysis.{NativeData, Path.CheckResult}
  @enforce_keys [:checks, :metrics]
  defstruct @enforce_keys
  @type t :: %__MODULE__{checks: [CheckResult.t()], metrics: map()}

  @doc "Construct native callback data; the runner validates each fresh callback return."
  def build(checks, metrics) when is_list(checks) and is_map(metrics),
    do: %__MODULE__{checks: checks, metrics: metrics}

  def new!(checks, metrics),
    do: checks |> Enum.map(&CheckResult.build/1) |> build(metrics) |> validate!()

  @doc "Admit a fresh callback result without JSON conversion or rebuilding its contents."
  def validate!(%__MODULE__{checks: checks, metrics: metrics} = result)
      when is_list(checks) and is_map(metrics) do
    NativeData.container!(metrics, "result metrics")
    admit_checks(checks, MapSet.new(), 0)
    result
  end

  def validate!(_), do: raise(ArgumentError, "invalid native path/resource result")

  defp admit_checks([], _, count) when count > 0, do: :ok

  defp admit_checks([%CheckResult{} = check | rest], ids, count) when count < 2048 do
    CheckResult.validate!(check)
    if MapSet.member?(ids, check.id), do: raise(ArgumentError, "duplicate path check IDs")
    admit_checks(rest, MapSet.put(ids, check.id), count + 1)
  end

  defp admit_checks(_, _, _),
    do:
      raise(
        ArgumentError,
        "path checks must be a nonempty proper list of at most 2048 native checks"
      )

  def outcome(%__MODULE__{checks: checks}) do
    cond do
      Enum.any?(checks, &(&1.status == :violated)) -> :violated
      Enum.any?(checks, &(&1.status == :unknown)) -> :unknown
      true -> :supported
    end
  end

  def status(result), do: result |> outcome() |> Atom.to_string()
end
