defmodule OrbitalDynamics.EventDetectors.Extrema do
  @moduledoc "Quantity extrema from explicit fixed-step central differences on a declared state source."
  alias OrbitalDynamics.EventSearch.{Source, Function}
  alias OrbitalDynamics.EventDetectors.Geometry
  alias OrbitalDynamics.MissionAnalysis.Input

  def function(id, %Source{} = source, %Function{} = quantity, derivative_step_s, opts) do
    h = Input.positive!(derivative_step_s, "extremum derivative step")

    Function.new!(
      id,
      fn state ->
        t = state.epoch.seconds_since_j2000
        left = t - h
        right = t + h

        if left >= t or right <= t do
          {:unknown, :extremum_derivative_epoch_resolution}
        else
          with {:ok, center} <- Geometry.secondary(source, state),
               true <-
                 center.position_km == state.position_km and
                   center.velocity_km_s == state.velocity_km_s,
               {:ok, a} <- Source.at(source, left),
               {:ok, b} <- Source.at(source, right),
               {:ok, va, _, _} <- Function.call(quantity, a),
               {:ok, v, _, m} <- Function.call(quantity, state),
               {:ok, vb, _, _} <- Function.call(quantity, b) do
            {:ok, (vb - va) / (right - left), nil,
             Map.merge(m, %{
               "quantity_value" => v,
               "quantity_units" => quantity.units,
               "derivative_before_s" => left,
               "derivative_after_s" => right
             })}
          else
            false -> {:error, :extremum_source_does_not_match_observer_state}
            other -> other
          end
        end
      end,
      [
        units: quantity.units <> "/s",
        labels: %{increasing: "local_minimum", decreasing: "local_maximum"},
        assumptions: %{
          "quantity" => Function.describe(quantity),
          "differentiation_source" => Source.describe(source),
          "derivative_step_s" => h,
          "limits" =>
            "central finite difference extrema, not analytic derivatives; requires source padding and continuous unwrapped quantity"
        }
      ] ++ opts
    )
  end
end
