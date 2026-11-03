import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.function.DoubleUnaryOperator;
import org.hipparchus.CalculusFieldElement;
import org.hipparchus.geometry.euclidean.threed.FieldVector3D;
import org.hipparchus.analysis.integration.IterativeLegendreGaussIntegrator;
import org.hipparchus.analysis.solvers.BracketingNthOrderBrentSolver;
import org.hipparchus.geometry.euclidean.threed.Vector3D;
import org.orekit.bodies.OneAxisEllipsoid;
import org.orekit.frames.*;
import org.orekit.propagation.SpacecraftState;
import org.orekit.propagation.events.EclipseDetector;
import org.orekit.time.*;
import org.orekit.utils.*;

/** Independent matched-model geometry. No production outputs or Elixir imports. */
public final class EventReference {
  static final Frame FRAME = FramesFactory.getEME2000();
  static final AbsoluteDate EPOCH = new AbsoluteDate(2000, 1, 1, 12, 0, 0, TimeScalesFactory.getTAI());
  static SpacecraftState state(double[] p, double t) {
    Vector3D position = new Vector3D(p[3]*1000, (p[4]+p[5]*t)*1000, p[6]*1000);
    Vector3D velocity = new Vector3D(0, p[5]*1000, 0);
    return new SpacecraftState(new AbsolutePVCoordinates(FRAME, EPOCH.shiftedBy(t), new PVCoordinates(position, velocity)));
  }
  // Numerically integrate vertical strips of intersecting angular disks. This
  // deliberately does not use the analytic lens-area expression in production.
  static double visible(double a, double b, double d) {
    if (d >= a+b) return 1;
    if (d <= Math.abs(a-b)) return b >= a ? 0 : 1-b*b/(a*a);
    double lo = Math.max(-a, d-b), hi = Math.min(a, d+b);
    double chord = (d*d+a*a-b*b)/(2*d);
    DoubleUnaryOperator strip = x -> 2*Math.min(Math.sqrt(Math.max(0,a*a-x*x)),
                                              Math.sqrt(Math.max(0,b*b-(x-d)*(x-d))));
    IterativeLegendreGaussIntegrator integrator = new IterativeLegendreGaussIntegrator(16,1e-11,1e-16,3,64);
    double area = 0;
    double[] cuts = {lo, Math.max(lo,Math.min(hi,chord)), hi};
    for (int i=1;i<cuts.length;i++) if (cuts[i]>cuts[i-1]) {
      double start=cuts[i-1], span=cuts[i]-start;
      // x=start+span*sin(u)^2 removes square-root endpoint singularities.
      area += integrator.integrate(200000, u->{double sn=Math.sin(u),cs=Math.cos(u);
        return strip.applyAsDouble(start+span*sn*sn)*2*span*sn*cs;},0,Math.PI/2);
    }
    return Math.max(0,Math.min(1,1-area/(Math.PI*a*a)));
  }
  record Contact(String kind, double t) {}
  static List<Contact> roots(String kind, DoubleUnaryOperator g, double stop) {
    List<Contact> roots = new ArrayList<>();
    BracketingNthOrderBrentSolver solver = new BracketingNthOrderBrentSolver(1e-14,1e-10,5);
    double a=0, ga=g.applyAsDouble(a);
    for (int i=1;i<=Math.round(stop/0.05);i++) {
      double b=Math.min(stop,i*0.05), gb=g.applyAsDouble(b);
      if (ga*gb<0) roots.add(new Contact(kind,solver.solve(100,g::applyAsDouble,a,b)));
      a=b; ga=gb;
    }
    return roots;
  }
  public static void main(String[] args) throws Exception {
    Locale.setDefault(Locale.ROOT);
    List<String> lines=Files.readAllLines(Path.of(args[0]));
    String[] keys=lines.get(0).split(",");
    try(PrintWriter out=new PrintWriter(Files.newBufferedWriter(Path.of(args[1])))) {
      out.printf("{\"format\":\"orekit_finite_sun_reference.v1\",\"tool\":\"Orekit 13.1.7 / Hipparchus 4.0.3\",\"java_runtime\":\"%s\",\"cases\":[",System.getProperty("java.runtime.version"));
      boolean firstCase=true;
      for(String line:lines.subList(1,lines.size())) {
        String[] cells=line.split(","); double[] p=Arrays.stream(cells).skip(1).mapToDouble(Double::parseDouble).toArray();
        Vector3D sunPosition=new Vector3D(p[2]*1000,0,0);
        ExtendedPositionProvider sun=new ExtendedPositionProvider() {
          public Vector3D getPosition(AbsoluteDate date, Frame frame) {
            if(frame!=FRAME)throw new IllegalArgumentException("unmatched frame");return sunPosition;
          }
          public <T extends CalculusFieldElement<T>> FieldVector3D<T> getPosition(FieldAbsoluteDate<T> date, Frame frame) {
            if(frame!=FRAME)throw new IllegalArgumentException("unmatched frame");return new FieldVector3D<>(date.getField(),sunPosition);
          }
        };
        OneAxisEllipsoid body=new OneAxisEllipsoid(p[0]*1000,0,FRAME);
        OccultationEngine engine=new OccultationEngine(sun,p[1]*1000,body);
        EclipseDetector outer=new EclipseDetector(engine).withPenumbra();
        EclipseDetector umbra=new EclipseDetector(engine).withUmbra();
        List<Contact> contacts=new ArrayList<>();
        contacts.addAll(roots("outer",t->outer.g(state(p,t)),p[7]));
        contacts.addAll(roots("umbra",t->umbra.g(state(p,t)),p[7]));
        contacts.addAll(roots("antumbra",t->{var a=engine.angles(state(p,t));return a.getSeparation()+a.getLimbRadius()-a.getOccultedApparentRadius();},p[7]));
        contacts.sort(Comparator.comparing(Contact::kind).thenComparingDouble(Contact::t));
        TreeSet<Double> times=new TreeSet<>();
        for(int i=0;i<=Math.round(p[7]/p[8]);i++) times.add(i*p[8]);
        for(Contact c:contacts) for(double offset:new double[]{-0.001,0,0.001}) times.add(c.t()+offset);
        // Add an interior sample in every partial-light transition.
        List<Double> ordered=contacts.stream().map(Contact::t).sorted().toList();
        for(int i=1;i<ordered.size();i++) times.add((ordered.get(i-1)+ordered.get(i))/2);
        if(!firstCase)out.print(",");firstCase=false;
        out.printf("{\"id\":\"%s\",\"inputs\":{",cells[0]);
        for(int i=1;i<keys.length;i++){if(i>1)out.print(",");out.printf("\"%s\":%.17g",keys[i],p[i-1]);}
        out.print("},\"contacts\":[");boolean first=true;
        for(Contact c:contacts){if(!first)out.print(",");first=false;out.printf("{\"kind\":\"%s\",\"epoch_s\":%.17g}",c.kind(),c.t());}
        out.print("],\"samples\":[");first=true;
        for(double t:times){
          var a=engine.angles(state(p,t));double alpha=a.getOccultedApparentRadius(),beta=a.getLimbRadius(),d=a.getSeparation();
          String regime=d>=alpha+beta?"none":beta>=alpha&&d<=beta-alpha?"umbra":alpha>beta&&d<=alpha-beta?"antumbra":"penumbra";
          if(!first)out.print(",");first=false;
          double fraction=visible(alpha,beta,d);
          double cosine=sunPosition.subtract(state(p,t).getPosition()).normalize().getX();
          out.printf("{\"epoch_s\":%.17g,\"source_radius_rad\":%.17g,\"body_radius_rad\":%.17g,\"separation_rad\":%.17g,\"visible_fraction\":%.17g,\"panel_cosine\":%.17g,\"bus_power_w\":%.17g,\"regime\":\"%s\"}",t,alpha,beta,d,fraction,cosine,1000*fraction*Math.max(0,cosine),regime);
        }
        out.print("]}");
      }
      out.println("]}");
    }
  }
}
