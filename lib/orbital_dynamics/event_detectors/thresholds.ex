defmodule OrbitalDynamics.EventDetectors.Thresholds do
  @moduledoc "Reusable scalar, plane, reference-center distance and spherical-altitude event functions."
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.EventSearch.Function

  def scalar(id, quantity, threshold, opts) when is_function(quantity, 1) do
    Input.number!(threshold, "event threshold", -1.0e30, 1.0e30)

    callback = fn state ->
      case quantity.(state) do
        {:ok, value, rate, metadata} ->
          {:ok, value - threshold, rate, Map.put(metadata, "threshold", threshold)}

        other ->
          other
      end
    end

    Function.new!(id, callback, opts)
  end

  def plane(id, normal, offset_km, opts) do
    normal = Input.unit!(normal, "event plane normal")
    Input.number!(offset_km, "plane offset", -1.0e15, 1.0e15)

    Function.new!(
      id,
      fn state ->
        {:ok, V.dot(state.position_km, normal) - offset_km, V.dot(state.velocity_km_s, normal),
         %{}}
      end,
      [
        units: "km",
        assumptions: %{
          "geometry" => "declared_coordinate_plane",
          "normal" => Tuple.to_list(normal),
          "offset_km" => offset_km,
          "velocity_semantics" => "time derivative of position in declared source axes"
        }
      ] ++ opts
    )
  end

  def radius(id, radius_km, opts) do
    Input.positive!(radius_km, "distance threshold")

    Function.new!(
      id,
      fn state ->
        r = V.norm(state.position_km)

        if r == 0,
          do: {:unknown, :radius_derivative_undefined_at_center},
          else:
            {:ok, r - radius_km, V.dot(state.position_km, state.velocity_km_s) / r,
             %{"radius_km" => r}}
      end,
      [
        units: "km",
        assumptions: %{
          "geometry" => "distance_from_declared_frame_center",
          "threshold_km" => radius_km
        }
      ] ++ opts
    )
  end

  def altitude(id, body_radius_km, altitude_km, opts) do
    Input.positive!(body_radius_km, "spherical body radius")
    Input.number!(altitude_km, "altitude threshold", -body_radius_km, 1.0e15)
    f = radius(id, body_radius_km + altitude_km, opts)

    %{
      f
      | assumptions:
          Map.merge(f.assumptions, %{
            "geometry" => "spherical_altitude",
            "body_radius_km" => body_radius_km,
            "altitude_km" => altitude_km
          })
    }
  end

  def true_anomaly(id, mu_km3_s2, eccentricity_tolerance, angle_deg, opts) do
    Input.positive!(mu_km3_s2, "osculating-element gravitational parameter")
    Input.number!(eccentricity_tolerance, "eccentricity tolerance", 1.0e-15, 0.1)
    Input.number!(angle_deg, "true anomaly", -180, 360)
    angle = angle_deg * :math.pi() / 180

    Function.new!(
      id,
      fn state ->
        if state.frame.orientation == :body_fixed,
          do: raise(ArgumentError, "osculating true anomaly requires inertial axes")

        r = state.position_km
        v = state.velocity_km_s
        radius = V.norm(r)
        h = V.cross(r, v)
        momentum = V.norm(h)

        if radius == 0 or momentum == 0 do
          {:unknown, :osculating_anomaly_undefined}
        else
          e = V.subtract(V.scale(V.cross(v, h), 1 / mu_km3_s2), V.scale(r, 1 / radius))
          eccentricity = V.norm(e)

          if eccentricity <= eccentricity_tolerance do
            {:unknown, :true_anomaly_undefined_for_circular_state}
          else
            cosine = V.dot(e, r) / (eccentricity * radius)
            sine = V.dot(V.scale(h, 1 / momentum), V.cross(e, r)) / (eccentricity * radius)

            {:ok, sine * :math.cos(angle) - cosine * :math.sin(angle), nil,
             %{
               "forward_half_plane" => cosine * :math.cos(angle) + sine * :math.sin(angle) > 0,
               "eccentricity" => eccentricity
             }}
          end
        end
      end,
      [
        units: "1",
        root_filter: fn m -> m["forward_half_plane"] end,
        assumptions: %{
          "geometry" => "osculating_true_anomaly",
          "mu_km3_s2" => mu_km3_s2,
          "eccentricity_tolerance" => eccentricity_tolerance,
          "angle_deg" => angle_deg
        }
      ] ++ opts
    )
  end
end
