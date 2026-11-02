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
  alias OrbitalDynamics.Schema.JsonSafety
  alias OrbitalDynamics.MissionAnalysis.Input
  @enforce_keys [:checks, :metrics]
  defstruct @enforce_keys
  @type t :: %__MODULE__{}
  def new!(checks, metrics) when is_list(checks) and is_map(metrics) do
    checks = JsonSafety.normalize_input!(checks, "path checks")
    metrics = JsonSafety.normalize_input!(metrics, "path metrics")

    unless checks != [] and
             Enum.all?(checks, fn c ->
               is_map(c) and is_binary(c["id"]) and c["id"] != "" and
                 c["status"] in ~w(supported violated unknown)
             end),
           do:
             raise(
               ArgumentError,
               "path checks require unique names and supported/violated/unknown status"
             )

    ids = Enum.map(checks, & &1["id"])
    if length(Enum.uniq(ids)) != length(ids), do: raise(ArgumentError, "duplicate path check IDs")

    Enum.each(checks, fn c ->
      if Map.has_key?(c, "margin") do
        unless is_binary(c["margin_unit"]) and byte_size(c["margin_unit"]) in 1..64,
          do: raise(ArgumentError, "path margins require units")

        unless c["margin"] == :null,
          do: Input.number!(c["margin"], "path margin", -1.0e30, 1.0e30)
      end
    end)

    %__MODULE__{checks: checks, metrics: metrics}
  end

  def status(%__MODULE__{checks: checks}) do
    cond do
      Enum.any?(checks, &(&1["status"] == "violated")) -> "violated"
      Enum.any?(checks, &(&1["status"] == "unknown")) -> "unknown"
      true -> "supported"
    end
  end
end
