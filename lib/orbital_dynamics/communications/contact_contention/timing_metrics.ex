defmodule OrbitalDynamics.Communications.ContactContention.TimingMetrics do
  @moduledoc false

  def build(contacts) do
    intervals =
      contacts
      |> Enum.map(fn contact -> {contact["starts_at_s"], contact["ends_at_s"]} end)
      |> Enum.filter(fn {starts_at_s, ends_at_s} ->
        is_number(starts_at_s) and is_number(ends_at_s) and starts_at_s < ends_at_s
      end)

    %{
      "contention_window_s" => contention_window_s(intervals),
      "total_contact_duration_s" => total_contact_duration_s(intervals),
      "overlap_duration_s" => overlap_duration_s(intervals),
      "max_concurrent_contacts" => max_concurrent_contacts(intervals),
      "overlap_contact_pair_count" => overlap_contact_pair_count(intervals)
    }
    |> compact_map()
  end

  defp contention_window_s([]), do: nil

  defp contention_window_s(intervals) do
    starts_at_s =
      intervals |> Enum.map(fn {starts_at_s, _ends_at_s} -> starts_at_s end) |> Enum.min()

    ends_at_s = intervals |> Enum.map(fn {_starts_at_s, ends_at_s} -> ends_at_s end) |> Enum.max()

    ends_at_s - starts_at_s
  end

  defp total_contact_duration_s(intervals) do
    Enum.reduce(intervals, 0.0, fn {starts_at_s, ends_at_s}, total ->
      total + ends_at_s - starts_at_s
    end)
  end

  defp overlap_duration_s(intervals) do
    intervals
    |> interval_events()
    |> Enum.reduce({nil, 0, 0.0}, fn {time_s, delta}, {previous_time_s, active_count, total} ->
      total =
        if is_number(previous_time_s) and active_count > 1 do
          total + time_s - previous_time_s
        else
          total
        end

      {time_s, active_count + delta, total}
    end)
    |> elem(2)
  end

  defp max_concurrent_contacts(intervals) do
    intervals
    |> interval_events()
    |> Enum.reduce({0, 0}, fn {_time_s, delta}, {active_count, maximum} ->
      active_count = active_count + delta
      {active_count, max(maximum, active_count)}
    end)
    |> elem(1)
  end

  defp interval_events(intervals) do
    intervals
    |> Enum.flat_map(fn {starts_at_s, ends_at_s} -> [{starts_at_s, 1}, {ends_at_s, -1}] end)
    |> Enum.group_by(fn {time_s, _delta} -> time_s end, fn {_time_s, delta} -> delta end)
    |> Enum.map(fn {time_s, deltas} -> {time_s, Enum.sum(deltas)} end)
    |> Enum.sort_by(fn {time_s, _delta} -> time_s end)
  end

  defp overlap_contact_pair_count(intervals) do
    intervals
    |> Enum.with_index()
    |> Enum.flat_map(fn {{starts_at_s, ends_at_s}, index} ->
      intervals
      |> Enum.with_index()
      |> Enum.filter(fn {{other_starts_at_s, other_ends_at_s}, other_index} ->
        index < other_index and starts_at_s < other_ends_at_s and other_starts_at_s < ends_at_s
      end)
    end)
    |> length()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
