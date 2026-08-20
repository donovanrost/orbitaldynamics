package org.orbitaldynamics.validation;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.hipparchus.CalculusFieldElement;
import org.hipparchus.geometry.euclidean.threed.Rotation;
import org.hipparchus.geometry.euclidean.threed.RotationConvention;
import org.hipparchus.geometry.euclidean.threed.Vector3D;
import org.hipparchus.ode.nonstiff.ClassicalRungeKuttaIntegrator;
import org.hipparchus.util.FastMath;
import org.orekit.bodies.GeodeticPoint;
import org.orekit.bodies.OneAxisEllipsoid;
import org.orekit.forces.drag.DragForce;
import org.orekit.forces.drag.IsotropicDrag;
import org.orekit.forces.gravity.J2OnlyPerturbation;
import org.orekit.frames.FieldTransform;
import org.orekit.frames.Frame;
import org.orekit.frames.FramesFactory;
import org.orekit.frames.TopocentricFrame;
import org.orekit.frames.Transform;
import org.orekit.frames.TransformProvider;
import org.orekit.orbits.CartesianOrbit;
import org.orekit.orbits.OrbitType;
import org.orekit.models.earth.atmosphere.SimpleExponentialAtmosphere;
import org.orekit.propagation.BoundedPropagator;
import org.orekit.propagation.EphemerisGenerator;
import org.orekit.propagation.SpacecraftState;
import org.orekit.propagation.events.CylindricalShadowEclipseDetector;
import org.orekit.propagation.events.ElevationDetector;
import org.orekit.propagation.events.EventDetectionSettings;
import org.orekit.propagation.events.handlers.RecordAndContinue;
import org.orekit.propagation.events.intervals.AdaptableInterval;
import org.orekit.propagation.numerical.NumericalPropagator;
import org.orekit.time.AbsoluteDate;
import org.orekit.time.FieldAbsoluteDate;
import org.orekit.time.TimeScalesFactory;
import org.orekit.utils.ConstantPVCoordinatesProvider;
import org.orekit.utils.PVCoordinates;

public final class OrekitTruthGenerator {

    private static final Set<String> REQUIRED_KEYS = Set.of(
        "case_id", "generated_at_utc", "orekit_version", "frame", "epoch", "time_scale",
        "horizon_s", "state_output_epochs_s", "integrator", "integrator_step_s",
        "event_max_check_s", "event_threshold_s", "event_max_iterations", "mu_m3_s2",
        "equatorial_radius_m", "j2", "initial_position_m", "initial_velocity_m_s",
        "atmosphere_model", "atmosphere_reference_altitude_m",
        "atmosphere_reference_density_kg_m3", "atmosphere_scale_height_m",
        "spacecraft_mass_kg", "spacecraft_drag_area_m2", "spacecraft_drag_coefficient",
        "earth_rotation_rate_rad_s", "earth_rotation_angle_at_epoch_rad",
        "station_latitude_deg", "station_longitude_deg", "station_altitude_m",
        "station_minimum_elevation_deg", "body_flattening", "sun_direction_eme2000",
        "sun_provider_distance_m", "atmospheric_refraction", "terrain_mask",
        "eclipse_model", "output_float_format", "orekit_data_revision", "eop_source",
        "ephemeris_source"
    );

    private OrekitTruthGenerator() {
    }

    public static void main(final String[] args) throws Exception {
        Locale.setDefault(Locale.ROOT);
        if (args.length != 3) {
            throw new IllegalArgumentException(
                "usage: OrekitTruthGenerator CONFIG OUTPUT SOURCE_ID_SHA256");
        }

        final Map<String, String> config = readStrictProperties(Path.of(args[0]));
        final String sourceIdentity = requireSha256(args[2]);
        validatePinnedConfiguration(config);

        final AbsoluteDate epoch = new AbsoluteDate(
            2000, 1, 1, 12, 0, 0.0, TimeScalesFactory.getTDB());
        final Frame inertial = FramesFactory.getEME2000();
        final double mu = number(config, "mu_m3_s2");
        final double radius = number(config, "equatorial_radius_m");
        final double j2 = number(config, "j2");
        final double step = number(config, "integrator_step_s");
        final double horizon = number(config, "horizon_s");

        final Vector3D position = vector(config, "initial_position_m");
        final Vector3D velocity = vector(config, "initial_velocity_m_s");
        final CartesianOrbit initialOrbit = new CartesianOrbit(
            new PVCoordinates(position, velocity), inertial, epoch, mu);

        final Frame rotating = constantRateBodyFrame(
            inertial,
            epoch,
            number(config, "earth_rotation_rate_rad_s"),
            number(config, "earth_rotation_angle_at_epoch_rad")
        );
        final OneAxisEllipsoid body = new OneAxisEllipsoid(
            radius, number(config, "body_flattening"), rotating);
        final SimpleExponentialAtmosphere atmosphere = new SimpleExponentialAtmosphere(
            body,
            number(config, "atmosphere_reference_density_kg_m3"),
            number(config, "atmosphere_reference_altitude_m"),
            number(config, "atmosphere_scale_height_m"));

        final NumericalPropagator propagator = new NumericalPropagator(
            new ClassicalRungeKuttaIntegrator(step));
        propagator.setOrbitType(OrbitType.CARTESIAN);
        propagator.setInitialState(new SpacecraftState(initialOrbit).withMass(
            number(config, "spacecraft_mass_kg")));
        propagator.addForceModel(new J2OnlyPerturbation(mu, radius, j2, inertial));
        propagator.addForceModel(new DragForce(
            atmosphere,
            new IsotropicDrag(
                number(config, "spacecraft_drag_area_m2"),
                number(config, "spacecraft_drag_coefficient"))));
        final GeodeticPoint stationPoint = new GeodeticPoint(
            FastMath.toRadians(number(config, "station_latitude_deg")),
            FastMath.toRadians(number(config, "station_longitude_deg")),
            number(config, "station_altitude_m"));
        final TopocentricFrame station = new TopocentricFrame(body, stationPoint, "truth-station");

        final RecordAndContinue accessRecorder = new RecordAndContinue();
        final ElevationDetector accessDetector = new ElevationDetector(
            number(config, "event_max_check_s"),
            number(config, "event_threshold_s"),
            station
        ).withConstantElevation(FastMath.toRadians(number(config, "station_minimum_elevation_deg")))
         .withMaxIter(integer(config, "event_max_iterations"))
         .withHandler(accessRecorder);

        final Vector3D sunDirection = vector(config, "sun_direction_eme2000").normalize();
        final ConstantPVCoordinatesProvider sun = new ConstantPVCoordinatesProvider(
            sunDirection.scalarMultiply(number(config, "sun_provider_distance_m")), inertial);
        final RecordAndContinue eclipseRecorder = new RecordAndContinue();
        final EventDetectionSettings eclipseSettings = new EventDetectionSettings(
            AdaptableInterval.of(number(config, "event_max_check_s")),
            number(config, "event_threshold_s"),
            integer(config, "event_max_iterations"));
        final CylindricalShadowEclipseDetector eclipseDetector =
            new CylindricalShadowEclipseDetector(sun, radius, eclipseSettings, eclipseRecorder);

        propagator.addEventDetector(accessDetector);
        propagator.addEventDetector(eclipseDetector);
        final EphemerisGenerator ephemerisGenerator = propagator.getEphemerisGenerator();
        propagator.propagate(epoch.shiftedBy(horizon));
        final BoundedPropagator ephemeris = ephemerisGenerator.getGeneratedEphemeris();

        final List<StateRow> states = new ArrayList<>();
        for (final double offset : numberList(config, "state_output_epochs_s")) {
            if (offset < 0.0 || offset > horizon) {
                throw new IllegalArgumentException("state epoch outside declared horizon: " + offset);
            }
            final SpacecraftState state = ephemeris.propagate(epoch.shiftedBy(offset));
            states.add(new StateRow(offset, state.getPosition(), state.getVelocity()));
        }

        final List<EventRow> accessEvents = eventRows(accessRecorder, epoch, "aos", "los");
        final List<EventRow> eclipseEvents = eventRows(eclipseRecorder, epoch, "egress", "ingress");
        writeOutput(Path.of(args[1]), config, sourceIdentity, states, accessEvents, eclipseEvents);
    }

    private static Frame constantRateBodyFrame(final Frame inertial, final AbsoluteDate epoch,
                                                final double rate, final double angleAtEpoch) {
        final Rotation initialRotation = new Rotation(
            Vector3D.PLUS_K, angleAtEpoch, RotationConvention.VECTOR_OPERATOR);
        final Transform initial = new Transform(
            epoch, initialRotation, new Vector3D(0.0, 0.0, rate));
        return new Frame(inertial, new ShiftedTransformProvider(epoch, initial),
            "constant-rate-spherical-earth", false);
    }

    private static List<EventRow> eventRows(final RecordAndContinue recorder,
                                             final AbsoluteDate epoch,
                                             final String increasingType,
                                             final String decreasingType) {
        final List<EventRow> rows = new ArrayList<>();
        for (final RecordAndContinue.Event event : recorder.getEvents()) {
            rows.add(new EventRow(
                event.isIncreasing() ? increasingType : decreasingType,
                event.getState().getDate().durationFrom(epoch)));
        }
        return rows;
    }

    private static void writeOutput(final Path output, final Map<String, String> config,
                                    final String sourceIdentity, final List<StateRow> states,
                                    final List<EventRow> accessEvents,
                                    final List<EventRow> eclipseEvents) throws IOException {
        try (PrintWriter writer = new PrintWriter(
                Files.newBufferedWriter(output, StandardCharsets.UTF_8))) {
            writer.println("{");
            field(writer, 1, "schema", "orekit_external_truth_raw.v1", true);
            field(writer, 1, "case_id", config.get("case_id"), true);
            field(writer, 1, "source_identity_sha256", sourceIdentity, true);
            field(writer, 1, "generated_at_utc", config.get("generated_at_utc"), true);
            writer.println("  \"tool\": {");
            field(writer, 2, "name", "Apache Orekit", true);
            field(writer, 2, "version", config.get("orekit_version"), true);
            field(writer, 2, "java_runtime", System.getProperty("java.runtime.version"), false);
            writer.println("  },");
            writer.println("  \"model\": {");
            field(writer, 2, "propagator", "NumericalPropagator", true);
            field(writer, 2, "orbit_type", "CARTESIAN", true);
            field(writer, 2, "integrator", config.get("integrator"), true);
            numberField(writer, 2, "integrator_step_s", number(config, "integrator_step_s"), true);
            field(writer, 2, "gravity", "NewtonianAttraction_plus_J2OnlyPerturbation", true);
            field(writer, 2, "drag", "DragForce_plus_SimpleExponentialAtmosphere_plus_IsotropicDrag", true);
            field(writer, 2, "access_detector", "ElevationDetector", true);
            field(writer, 2, "eclipse_detector", "CylindricalShadowEclipseDetector", false);
            writer.println("  },");
            writer.println("  \"identity\": {");
            field(writer, 2, "frame", config.get("frame"), true);
            field(writer, 2, "epoch", config.get("epoch"), true);
            field(writer, 2, "time_scale", config.get("time_scale"), true);
            field(writer, 2, "orekit_data_revision", config.get("orekit_data_revision"), true);
            field(writer, 2, "eop_source", config.get("eop_source"), true);
            field(writer, 2, "ephemeris_source", config.get("ephemeris_source"), false);
            writer.println("  },");
            numberField(writer, 1, "horizon_s", number(config, "horizon_s"), true);
            writer.println("  \"states\": [");
            for (int index = 0; index < states.size(); index++) {
                final StateRow state = states.get(index);
                writer.println("    {");
                numberField(writer, 3, "epoch_s", state.epochSeconds(), true);
                vectorField(writer, 3, "position_m", state.position(), true);
                vectorField(writer, 3, "velocity_m_s", state.velocity(), false);
                writer.print("    }");
                writer.println(index + 1 == states.size() ? "" : ",");
            }
            writer.println("  ],");
            writer.println("  \"events\": {");
            eventArray(writer, "access", accessEvents, true);
            eventArray(writer, "eclipse", eclipseEvents, false);
            writer.println("  }");
            writer.println("}");
        }
    }

    private static void eventArray(final PrintWriter writer, final String name,
                                   final List<EventRow> events, final boolean comma) {
        writer.println("    \"" + name + "\": [");
        for (int index = 0; index < events.size(); index++) {
            final EventRow event = events.get(index);
            writer.println("      {");
            field(writer, 4, "type", event.type(), true);
            numberField(writer, 4, "epoch_s", event.epochSeconds(), false);
            writer.print("      }");
            writer.println(index + 1 == events.size() ? "" : ",");
        }
        writer.print("    ]");
        writer.println(comma ? "," : "");
    }

    private static void field(final PrintWriter writer, final int indent, final String key,
                              final String value, final boolean comma) {
        writer.print("  ".repeat(indent));
        writer.print("\"");
        writer.print(jsonEscape(key));
        writer.print("\": \"");
        writer.print(jsonEscape(value));
        writer.print("\"");
        writer.println(comma ? "," : "");
    }

    private static void numberField(final PrintWriter writer, final int indent, final String key,
                                    final double value, final boolean comma) {
        writer.print("  ".repeat(indent));
        writer.print("\"");
        writer.print(key);
        writer.print("\": ");
        writer.print(String.format(Locale.ROOT, "%.17e", value));
        writer.println(comma ? "," : "");
    }

    private static void vectorField(final PrintWriter writer, final int indent, final String key,
                                    final Vector3D value, final boolean comma) {
        writer.print("  ".repeat(indent));
        writer.printf(Locale.ROOT, "\"%s\": [%.17e, %.17e, %.17e]%s%n",
            key, value.getX(), value.getY(), value.getZ(), comma ? "," : "");
    }

    private static String jsonEscape(final String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static void validatePinnedConfiguration(final Map<String, String> config) {
        if (!config.keySet().equals(REQUIRED_KEYS)) {
            final Set<String> missing = new java.util.HashSet<>(REQUIRED_KEYS);
            missing.removeAll(config.keySet());
            final Set<String> unknown = new java.util.HashSet<>(config.keySet());
            unknown.removeAll(REQUIRED_KEYS);
            throw new IllegalArgumentException("configuration keys mismatch; missing=" + missing
                + ", unknown=" + unknown);
        }
        exact(config, "orekit_version", "13.1.7");
        exact(config, "frame", "EME2000");
        exact(config, "epoch", "2000-01-01T12:00:00_TDB");
        exact(config, "time_scale", "TDB_J2000_RELATIVE_SECONDS");
        exact(config, "integrator", "ClassicalRungeKuttaIntegrator");
        exact(config, "atmosphere_model", "SimpleExponentialAtmosphere");
        exact(config, "atmospheric_refraction", "none");
        exact(config, "terrain_mask", "none");
        exact(config, "eclipse_model", "cylindrical_spherical_body");
        exact(config, "output_float_format", "%.17e");
        exact(config, "orekit_data_revision", "none");
        exact(config, "eop_source", "none");
        exact(config, "ephemeris_source", "fixed_sun_direction_input");
    }

    private static void exact(final Map<String, String> config, final String key,
                              final String expected) {
        if (!expected.equals(config.get(key))) {
            throw new IllegalArgumentException(key + " must equal " + expected);
        }
    }

    private static Map<String, String> readStrictProperties(final Path path) throws IOException {
        final Map<String, String> values = new LinkedHashMap<>();
        int lineNumber = 0;
        for (final String line : Files.readAllLines(path, StandardCharsets.UTF_8)) {
            lineNumber++;
            if (line.isBlank()) {
                continue;
            }
            final int separator = line.indexOf('=');
            if (separator <= 0 || separator == line.length() - 1) {
                throw new IllegalArgumentException("malformed configuration line " + lineNumber);
            }
            final String key = line.substring(0, separator);
            final String value = line.substring(separator + 1);
            if (!key.equals(key.trim()) || !value.equals(value.trim())) {
                throw new IllegalArgumentException("configuration whitespace at line " + lineNumber);
            }
            if (values.putIfAbsent(key, value) != null) {
                throw new IllegalArgumentException("duplicate configuration key: " + key);
            }
        }
        return values;
    }

    private static double number(final Map<String, String> config, final String key) {
        final double value = Double.parseDouble(config.get(key));
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException(key + " must be finite");
        }
        return value;
    }

    private static int integer(final Map<String, String> config, final String key) {
        return Integer.parseInt(config.get(key));
    }

    private static Vector3D vector(final Map<String, String> config, final String key) {
        final double[] values = numberList(config, key);
        if (values.length != 3) {
            throw new IllegalArgumentException(key + " must contain three numbers");
        }
        return new Vector3D(values[0], values[1], values[2]);
    }

    private static double[] numberList(final Map<String, String> config, final String key) {
        return Arrays.stream(config.get(key).split(",", -1))
            .mapToDouble(Double::parseDouble)
            .peek(value -> {
                if (!Double.isFinite(value)) {
                    throw new IllegalArgumentException(key + " must contain finite numbers");
                }
            })
            .toArray();
    }

    private static String requireSha256(final String value) {
        if (!value.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("source identity must be lowercase SHA-256");
        }
        return value;
    }

    private record StateRow(double epochSeconds, Vector3D position, Vector3D velocity) {
    }

    private record EventRow(String type, double epochSeconds) {
    }

    private static final class ShiftedTransformProvider implements TransformProvider {
        private final AbsoluteDate epoch;
        private final Transform transformAtEpoch;

        private ShiftedTransformProvider(final AbsoluteDate epoch,
                                         final Transform transformAtEpoch) {
            this.epoch = epoch;
            this.transformAtEpoch = transformAtEpoch;
        }

        @Override
        public Transform getTransform(final AbsoluteDate date) {
            return transformAtEpoch.shiftedBy(date.durationFrom(epoch));
        }

        @Override
        public <T extends CalculusFieldElement<T>> FieldTransform<T> getTransform(
                final FieldAbsoluteDate<T> date) {
            return new FieldTransform<>(date.getField(), getTransform(date.toAbsoluteDate()));
        }
    }
}
