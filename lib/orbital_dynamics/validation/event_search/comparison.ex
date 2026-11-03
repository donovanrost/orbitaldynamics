defmodule OrbitalDynamics.Validation.EventSearch.Comparison do
  @moduledoc false

  # Match complete ordered event identities before computing residuals. No
  # nearest-neighbor pairing, truncating zip or empty maximum can imply success.
  def compare(reference, observed, tolerance_s, root_tolerance_s) do
    identity =
      length(reference) == length(observed) and
        Enum.map(reference, & &1["type"]) == Enum.map(observed, & &1["type"])

    rows =
      Enum.with_index(reference)
      |> Enum.map(fn {r, index} ->
        o = Enum.at(observed, index)
        matched = is_map(o) and o["type"] == r["type"]
        delta = if matched, do: o["epoch_s"] - r["epoch_s"], else: :null
        bounded = matched and bracket?(o, root_tolerance_s)

        %{
          "type" => r["type"],
          "reference_epoch_s" => r["epoch_s"],
          "observed" => o || :null,
          "signed_error_s" => delta,
          "absolute_error_s" => if(is_number(delta), do: abs(delta), else: :null),
          "root_bracket_passed" => bounded,
          "status" =>
            if(matched and bounded and abs(delta) <= tolerance_s, do: "pass", else: "fail")
        }
      end)

    %{
      "status" =>
        if(identity and Enum.all?(rows, &(&1["status"] == "pass")), do: "pass", else: "fail"),
      "identity_passed" => identity,
      "reference_count" => length(reference),
      "observed_count" => length(observed),
      "unexpected_observations" => Enum.drop(observed, length(reference)),
      "absolute_time_tolerance_s" => tolerance_s,
      "root_bracket_width_tolerance_s" => root_tolerance_s,
      "max_absolute_error_s" =>
        if(identity,
          do: rows |> Enum.map(& &1["absolute_error_s"]) |> Enum.max(fn -> :null end),
          else: :null
        ),
      "boundaries" => rows
    }
  end

  defp bracket?(%{"epoch_s" => t, "bracket_start_s" => a, "bracket_end_s" => b}, tolerance)
       when is_number(t) and is_number(a) and is_number(b),
       do: a <= t and t <= b and b >= a and b - a <= tolerance

  defp bracket?(_, _), do: false
end
