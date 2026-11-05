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
  defstruct @enforce_keys ++ [segment: nil]
  @type t :: %__MODULE__{}

  def new!(id, model, subject, opts) when is_atom(model) and is_list(opts) do
    keys =
      ~w(activity_type starts_at_s ends_at_s duration_s time_scale value parameters resource_costs)a

    unless Keyword.keyword?(opts) and
             Enum.sort(Keyword.keys(opts) -- [:segment]) == Enum.sort(keys) and
             length(Keyword.keys(opts)) == length(Enum.uniq(Keyword.keys(opts))),
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

    request = %__MODULE__{
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

    with_segment!(request, Keyword.get(opts, :segment))
  end

  def with_segment!(request, nil), do: %{request | segment: nil}

  def with_segment!(
        request,
        %{
          request: %__MODULE__{} = original,
          starts_at_s: a,
          ends_at_s: b,
          kind: kind,
          asset_id: asset_id
        } = segment
      )
      when map_size(segment) == 5 do
    unless original.segment == nil and kind in [:remaining, :execution_prefix] and is_number(a) and
             is_number(b) and
             a >= original.starts_at_s and b <= original.ends_at_s and
             b == a + original.duration_s and
             request.id == original.id and request.model == original.model and
             request.subject == original.subject and
             request.parameters == original.parameters and
             request.activity_type == original.activity_type and
             request.time_scale == original.time_scale and
             request.starts_at_s >= a and request.ends_at_s <= b and
             request.duration_s == request.ends_at_s - request.starts_at_s,
           do:
             raise(
               ArgumentError,
               "activity segment must preserve the original request and exact activity bounds"
             )

    Input.id!(asset_id)

    new!(
      original.id,
      original.model,
      original.subject,
      Enum.map(
        ~w(activity_type starts_at_s ends_at_s duration_s time_scale value parameters resource_costs)a,
        &{&1, Map.fetch!(original, &1)}
      )
    )

    valid =
      case kind do
        :remaining ->
          request.starts_at_s > a and request.ends_at_s == b and request.value == original.value and
            request.resource_costs == %{}

        :execution_prefix ->
          request.ends_at_s < b and request.value == 0 and
            request.resource_costs ==
              if(request.starts_at_s == a, do: original.resource_costs, else: %{})
      end

    unless valid,
      do: raise(ArgumentError, "invalid activity-segment value, cost or continuation interval")

    %{request | segment: segment}
  end

  def with_segment!(_, _), do: raise(ArgumentError, "invalid activity segment")

  def segment_description(%{segment: nil}), do: nil

  def segment_description(%{segment: s}),
    do: %{
      "kind" => Atom.to_string(s.kind),
      "asset_id" => s.asset_id,
      "activity_starts_at_s" => s.starts_at_s,
      "activity_ends_at_s" => s.ends_at_s,
      "original_duration_s" => s.request.duration_s,
      "original_value" => s.request.value,
      "original_resource_costs" => s.request.resource_costs
    }
end
