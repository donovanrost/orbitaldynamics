defmodule OrbitalDynamics.MissionAnalysis.Request do
  @moduledoc """
  A request for one continuous activity within an allowed interval.

  The subject is opaque to the runner. The model interprets it and `parameters`.
  Value is caller-defined scheduling utility, not a physical outcome or price.
  Costs are declared totals for the requested duration, not rates. Multiple
  spacecraft aggregation and partial fulfillment are outside this first slice.
  """
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Schema.JsonSafety

  @enforce_keys [
    :id,
    :model,
    :activity_type,
    :subject,
    :starts_at_s,
    :ends_at_s,
    :duration_s,
    :time_scale,
    :value,
    :parameters,
    :resource_costs
  ]
  defstruct @enforce_keys
  @type t :: %__MODULE__{}

  def new!(id, model, subject, opts) when is_atom(model) and is_list(opts) do
    keys =
      ~w(activity_type starts_at_s ends_at_s duration_s time_scale value parameters resource_costs)a

    unless Keyword.keyword?(opts) and Enum.sort(Keyword.keys(opts)) == Enum.sort(keys),
      do: raise(ArgumentError, "request requires explicit, unique options: #{inspect(keys)}")

    start = Input.number!(Keyword.fetch!(opts, :starts_at_s), "starts_at_s", -1.0e12, 1.0e12)
    stop = Input.number!(Keyword.fetch!(opts, :ends_at_s), "ends_at_s", -1.0e12, 1.0e12)
    duration = Input.positive!(Keyword.fetch!(opts, :duration_s), "duration_s")
    scale = Keyword.fetch!(opts, :time_scale)

    if scale not in [:tdb, :tai, :utc],
      do: raise(ArgumentError, "explicit epoch time scale required")

    if stop <= start or duration > stop - start,
      do: raise(ArgumentError, "invalid request interval/duration")

    parameters = Keyword.fetch!(opts, :parameters)
    unless is_map(parameters), do: raise(ArgumentError, "request parameters must be a map")

    %__MODULE__{
      id: Input.id!(id),
      model: model,
      subject: subject,
      activity_type: Input.id!(Keyword.fetch!(opts, :activity_type)),
      starts_at_s: start,
      ends_at_s: stop,
      duration_s: duration,
      time_scale: scale,
      value: Input.number!(Keyword.fetch!(opts, :value), "value", 0, 1.0e15),
      parameters: JsonSafety.normalize_input!(parameters, "request parameters"),
      resource_costs: Input.budgets!(Keyword.fetch!(opts, :resource_costs))
    }
  end
end
