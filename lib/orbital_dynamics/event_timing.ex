defmodule OrbitalDynamics.EventTiming do
  @moduledoc """
  Detector-wide event timing tolerance metadata.

  Current event detectors are sampled detectors with linear boundary
  interpolation as the compatibility default. Access-window callers may opt
  into detector-local root refinement on an interpolated state path. This
  module retains the conservative default policy; the access detector adds its
  tighter local root bracket and explicit interpolation limits without claiming
  dense propagation or external validation.
  """

  alias OrbitalDynamics.{Epoch, StateVector, Trajectory}

  @max_states 10_000
  @max_opts_length 64
  @max_container_depth 8
  @max_container_entries 2_048
  @max_list_length 1_024
  @max_map_size 128
  @safe_number_limit 1.0e15
  @epoch_scales [:tdb, :tai, :utc]
  @metadata_vector_keys [
    "sun_direction",
    "before_sun_direction",
    "after_sun_direction",
    "sun_direction_at_start_sample",
    "sun_direction_at_end_sample"
  ]

  @doc """
  Builds timing policy metadata for a detected event.
  """
  def policy(trajectory, detector, opts \\ [])

  def policy(%Trajectory{} = trajectory, detector, opts) do
    with :ok <- validate_opts(opts),
         {:ok, max_sample_step_s} <- max_sample_step_s(trajectory) do
      interpolation = Keyword.get(opts, :interpolation, :linear_sample_crossing)

      %{
        event_timing_policy: :sampled_state_linear_boundary,
        event_detector: detector,
        interpolation: interpolation,
        event_time_tolerance_s: max_sample_step_s,
        max_sample_step_s: max_sample_step_s,
        confidence: confidence(max_sample_step_s, interpolation)
      }
    end
  end

  def policy(_trajectory, _detector, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :trajectory}}
  end

  @doc """
  Builds local timing metadata for a refined boundary bracket.

  `policy/3` describes the whole trajectory cadence. Refined event boundaries
  also need the local before/after sample width, because a dense region in an
  otherwise sparse trajectory has a tighter timing bound than the trajectory
  maximum.
  """
  def boundary_policy(before_epoch, after_epoch, opts \\ [])

  def boundary_policy(before_epoch, after_epoch, opts) do
    with :ok <- validate_opts(opts),
         {:ok, before_s} <- epoch_seconds(before_epoch, :before_epoch),
         {:ok, after_s} <- epoch_seconds(after_epoch, :after_epoch) do
      interpolation = Keyword.get(opts, :interpolation, :linear_sample_crossing)
      bracket_s = abs(after_s - before_s) * 1.0

      %{
        event_timing_policy: :sampled_state_linear_boundary,
        interpolation: interpolation,
        event_time_tolerance_s: bracket_s,
        event_time_bracket_s: bracket_s,
        before_epoch_s: before_s,
        after_epoch_s: after_s,
        root_solved: false,
        confidence: confidence(bracket_s, interpolation)
      }
    end
  end

  @doc """
  Adds event timing policy metadata to an event.
  """
  def annotate_event(event, trajectory, detector, opts \\ [])

  def annotate_event(%{} = event, %Trajectory{} = trajectory, detector, opts) do
    with :ok <- validate_opts(opts),
         {:ok, metadata} <- event_metadata(event),
         %{} = timing_policy <- policy(trajectory, detector, opts) do
      Map.put(event, :metadata, Map.merge(timing_policy, metadata))
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def annotate_event(_event, _trajectory, _detector, opts) do
    with :ok <- validate_opts(opts), do: {:error, {:invalid_option, :event}}
  end

  defp event_metadata(%{metadata: metadata}) when is_map(metadata) do
    with :ok <- preflight_metadata(metadata) do
      {:ok, metadata}
    end
  end

  defp event_metadata(%{metadata: nil}), do: {:ok, %{}}
  defp event_metadata(%{metadata: _metadata}), do: {:error, {:invalid_event, :metadata}}
  defp event_metadata(_event), do: {:ok, %{}}

  defp max_sample_step_s(%Trajectory{states: states}) do
    with {:ok, states} <- bounded_list_items(states, :states, @max_states),
         :ok <- validate_state_epochs(states) do
      max_state_step_s(states)
    end
  end

  defp max_state_step_s([]), do: {:ok, 0.0}
  defp max_state_step_s([_state]), do: {:ok, 0.0}

  defp max_state_step_s(states) do
    max_step_s =
      states
      |> Enum.map(& &1.epoch.seconds_since_j2000)
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [before_s, after_s] -> abs(after_s - before_s) end)
      |> Enum.max(fn -> 0.0 end)
      |> Kernel.*(1.0)

    {:ok, max_step_s}
  end

  defp confidence(max_sample_step_s, _interpolation) when max_sample_step_s == 0.0,
    do: :exact_sample_only

  defp confidence(_max_sample_step_s, :linear_sample_crossing), do: :bounded_by_sample_cadence
  defp confidence(_max_sample_step_s, _interpolation), do: :sampled

  defp validate_state_epochs(states) do
    states
    |> Enum.reduce_while({:ok, nil}, fn
      %StateVector{epoch: epoch}, {:ok, previous_s} ->
        case epoch_seconds(epoch, :state_epoch) do
          {:ok, seconds} ->
            if is_number(previous_s) and seconds < previous_s do
              {:halt, {:error, {:invalid_trajectory, :nonmonotonic_epochs}}}
            else
              {:cont, {:ok, seconds}}
            end

          {:error, _reason} ->
            {:halt, {:error, {:invalid_trajectory, :epoch_seconds_since_j2000}}}
        end

      _state, {:ok, _previous_s} ->
        {:halt, {:error, {:invalid_trajectory, :state}}}
    end)
    |> case do
      {:ok, _last_s} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp epoch_seconds(%Epoch{} = epoch, field) do
    if exact_epoch_shape?(epoch) do
      scale = Map.fetch!(epoch, :scale)
      seconds = Map.fetch!(epoch, :seconds_since_j2000)

      if scale in @epoch_scales and finite_number?(seconds) do
        {:ok, seconds * 1.0}
      else
        {:error, {:invalid_epoch, field}}
      end
    else
      {:error, {:invalid_epoch, field}}
    end
  end

  defp epoch_seconds(%{__struct__: _struct}, field), do: {:error, {:invalid_epoch, field}}
  defp epoch_seconds(%{}, field), do: {:error, {:invalid_epoch, field}}

  defp epoch_seconds(_epoch, field), do: {:error, {:invalid_epoch, field}}

  defp exact_epoch_shape?(epoch) do
    map_size(epoch) == 3 and Map.has_key?(epoch, :scale) and
      Map.has_key?(epoch, :seconds_since_j2000)
  end

  defp validate_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_option_values(items) do
      :ok
    else
      false -> {:error, {:invalid_option, :opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp keyword_entry?({key, _value}) when is_atom(key), do: true
  defp keyword_entry?(_entry), do: false

  defp unique_keyword_keys?(items) do
    keys = Enum.map(items, fn {key, _value} -> key end)
    length(keys) == length(Enum.uniq(keys))
  end

  defp preflight_option_values(items) do
    values = Enum.map(items, fn {_key, value} -> value end)
    preflight_container(values, :opts)
  end

  defp preflight_metadata(metadata) do
    preflight_metadata([{metadata, 0, nil}], 0)
  end

  defp preflight_metadata([], _visited), do: :ok

  defp preflight_metadata(_stack, visited) when visited > @max_container_entries,
    do: {:error, {:container_limit_exceeded, :metadata}}

  defp preflight_metadata([{_term, depth, _key_name} | _rest], _visited)
       when depth > @max_container_depth,
       do: {:error, {:container_depth_exceeded, :metadata}}

  defp preflight_metadata([{%{__struct__: _struct}, _depth, _key_name} | _rest], _visited),
    do: {:error, {:invalid_container, :metadata}}

  defp preflight_metadata([{tuple, _depth, key_name} | rest], visited) when is_tuple(tuple) do
    if key_name in @metadata_vector_keys and finite_vector_tuple?(tuple) do
      preflight_metadata(rest, visited + tuple_size(tuple))
    else
      {:error, {:invalid_container, :metadata}}
    end
  end

  defp preflight_metadata([{%{} = map, depth, _key_name} | rest], visited) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, :metadata}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, :metadata}}

      true ->
        with :ok <- reject_generic_alias_collisions(map) do
          children =
            Enum.map(map, fn {key, value} -> {value, depth + 1, metadata_key_name(key)} end)

          preflight_metadata(children ++ rest, visited + map_size(map))
        end
    end
  end

  defp preflight_metadata([{list, depth, _key_name} | rest], visited) when is_list(list) do
    case bounded_list_items(list, :metadata, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1, nil})
        preflight_metadata(children ++ rest, visited + length(items))

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_metadata([{term, _depth, _key_name} | rest], visited)
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term) do
    preflight_metadata(rest, visited + 1)
  end

  defp preflight_metadata([{term, _depth, _key_name} | rest], visited)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_metadata(rest, visited + 1)
    else
      {:error, {:invalid_container, :metadata}}
    end
  end

  defp preflight_metadata([_term | _rest], _visited),
    do: {:error, {:invalid_container, :metadata}}

  defp metadata_key_name(key) when is_atom(key), do: Atom.to_string(key)
  defp metadata_key_name(key) when is_binary(key), do: key
  defp metadata_key_name(_key), do: nil

  defp preflight_container(term, field) do
    preflight_container([{term, 0}], 0, field)
  end

  defp preflight_container([], _visited, _field), do: :ok

  defp preflight_container(_stack, visited, field) when visited > @max_container_entries,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_container([{_term, depth} | _rest], _visited, field)
       when depth > @max_container_depth do
    {:error, {:container_depth_exceeded, field}}
  end

  defp preflight_container([{%{__struct__: _struct}, _depth} | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{tuple, _depth} | _rest], _visited, field) when is_tuple(tuple),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{%{} = map, depth} | rest], visited, field) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, field}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, field}}

      true ->
        with :ok <- reject_generic_alias_collisions(map) do
          children = Enum.map(Map.values(map), &{&1, depth + 1})
          preflight_container(children ++ rest, visited + map_size(map), field)
        end
    end
  end

  defp preflight_container([{list, depth} | rest], visited, field) when is_list(list) do
    case bounded_list_items(list, field, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1})
        preflight_container(children ++ rest, visited + length(items), field)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term) do
    preflight_container(rest, visited + 1, field)
  end

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_container(rest, visited + 1, field)
    else
      {:error, {:invalid_container, field}}
    end
  end

  defp preflight_container([_term | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp invalid_map_key?(map) do
    Enum.any?(Map.keys(map), fn key -> not (is_atom(key) or is_binary(key)) end)
  end

  defp reject_generic_alias_collisions(%{} = map) do
    keys = Map.keys(map)

    atom_key_strings =
      keys
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    case Enum.find(keys, fn key -> is_binary(key) and MapSet.member?(atom_key_strings, key) end) do
      nil -> :ok
      key -> {:error, {:atom_string_alias_collision, key}}
    end
  end

  defp finite_vector_tuple?({x, y, z}),
    do: finite_number?(x) and finite_number?(y) and finite_number?(z)

  defp finite_vector_tuple?(_tuple), do: false

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_not_list, field, _limit), do: {:error, {:invalid_container, field}}

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp finite_number?(_value), do: false
end
