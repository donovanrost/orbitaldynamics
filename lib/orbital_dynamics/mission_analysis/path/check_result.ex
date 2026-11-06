defmodule OrbitalDynamics.MissionAnalysis.Path.CheckResult do
  @moduledoc "Native three-valued check. A nil margin is absent; :unknown is an explicitly unknown margin."
  alias OrbitalDynamics.MissionAnalysis.Input
  @enforce_keys [:id, :status]
  defstruct [:id, :status, :margin, :margin_unit, details: %{}]
  @type t :: %__MODULE__{}

  def build(%__MODULE__{} = check), do: check

  def build(fields) when is_map(fields) and not is_struct(fields) do
    fields =
      Enum.reduce([:id, :status, :margin, :margin_unit], fields, fn key, acc ->
        text = Atom.to_string(key)

        if Map.has_key?(acc, key) and Map.has_key?(acc, text),
          do: raise(ArgumentError, "duplicate check field #{text}")

        case Map.fetch(acc, text) do
          :error -> acc
          {:ok, value} -> acc |> Map.delete(text) |> Map.put(key, value)
        end
      end)

    status =
      case fields[:status] do
        "supported" -> :supported
        "violated" -> :violated
        "unknown" -> :unknown
        value -> value
      end

    margin =
      if Map.has_key?(fields, :margin) and fields[:margin] in [nil, :null],
        do: :unknown,
        else: fields[:margin]

    %__MODULE__{
      id: fields[:id],
      status: status,
      margin: margin,
      margin_unit: fields[:margin_unit],
      details: Map.drop(fields, [:id, :status, :margin, :margin_unit])
    }
  end

  def build(_), do: raise(ArgumentError, "path check must be native check data")

  def validate!(%__MODULE__{} = check) do
    unless is_binary(check.id) and byte_size(check.id) in 1..256 and String.valid?(check.id) and
             check.status in [:supported, :violated, :unknown] and is_map(check.details),
           do:
             raise(
               ArgumentError,
               "path checks require unique names and supported/violated/unknown status"
             )

    OrbitalDynamics.MissionAnalysis.NativeData.container!(check.details, "check details")

    case {check.margin, check.margin_unit} do
      {nil, nil} ->
        :ok

      {value, unit} when is_binary(unit) and byte_size(unit) in 1..64 ->
        unless String.valid?(unit),
          do: raise(ArgumentError, "path margin units must be valid text")

        unless value == :unknown, do: Input.number!(value, "path margin", -1.0e30, 1.0e30)

      _ ->
        raise ArgumentError, "path margins require a value and units"
    end

    if Enum.any?(
         [:id, :status, :margin, :margin_unit, "id", "status", "margin", "margin_unit"],
         &Map.has_key?(check.details, &1)
       ),
       do: raise(ArgumentError, "check details cannot replace domain fields")

    check
  end

  def validate!(_), do: raise(ArgumentError, "native CheckResult required")

  @doc "Explicit projection at the reporting boundary; computational consumers use struct fields."
  def report(check) do
    OrbitalDynamics.MissionAnalysis.NativeData.validate!(check.details, "check report details")
    base = Map.merge(check.details, %{"id" => check.id, "status" => Atom.to_string(check.status)})

    projection =
      if check.margin_unit == nil,
        do: base,
        else:
          Map.merge(base, %{
            "margin" => if(check.margin == :unknown, do: :null, else: check.margin),
            "margin_unit" => check.margin_unit
          })

    OrbitalDynamics.MissionAnalysis.ReportData.encode(projection)
  end
end
