"""Independent body-frame gyrostat RK4 reference. Python standard library only.

No imports or exported paths from production. Quaternion and rotor momentum
are integrated together. Production instead updates total inertial momentum.
Physical inputs are hand-declared in inputs.json; compare two RK4 resolutions.
"""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def cross(a, b):
    return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]

def rotate(q, v, inverse=False):
    # Explicit rotation matrix, independently of production vector cross formula.
    w, x, y, z = q
    n = math.sqrt(sum(a*a for a in q))
    w, x, y, z = [a/n for a in (w,x,y,z)]
    m = [[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
         [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
         [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]]
    if inverse:
        m = list(zip(*m))
    return [sum(a*b for a,b in zip(row,v)) for row in m]

def rates(c, t):
    return [[math.radians(w+a*t) for w,a in zip(c['rate_deg_s'],c['accel_deg_s2'])],
            [math.radians(a) for a in c['accel_deg_s2']]]

def terms(c, t, y):
    wi, ai = rates(c,t)
    wb, ab = rotate(y[:4],wi,True), rotate(y[:4],ai,True)
    body_h = [c['inertia'][i]*wb[i]+sum(c['axes'][j][i]*y[4+j] for j in range(3)) for i in range(3)]
    gyroscopic = cross(wb,body_h)
    torque = [c['disturbance'][i]+c['unload'][i] for i in range(3)]
    body_motor = [torque[i]-c['inertia'][i]*ab[i]-gyroscopic[i] for i in range(3)]
    motor = [sum(a*b for a,b in zip(axis,body_motor)) for axis in c['axes']]
    return motor, rotate(y[:4],body_h)

def derivative(c,t,y):
    wi, _ = rates(c,t)
    w,x,yq,z = y[:4]
    a,b,d = wi
    dq = [-0.5*(a*x+b*yq+d*z), 0.5*(a*w+b*z-d*yq),
          0.5*(-a*z+b*w+d*x), 0.5*(a*yq-b*x+d*w)]
    motor,_ = terms(c,t,y)
    return dq+motor

def rk4(c,t,y,h):
    k1 = derivative(c,t,y)
    k2 = derivative(c,t+h/2,[v+h*k/2 for v,k in zip(y,k1)])
    k3 = derivative(c,t+h/2,[v+h*k/2 for v,k in zip(y,k2)])
    k4 = derivative(c,t+h,[v+h*k for v,k in zip(y,k3)])
    return [v+h*(a+2*b+2*d+e)/6 for v,a,b,d,e in zip(y,k1,k2,k3,k4)]

def integrate(c, substeps):
    y = c['initial_quaternion']+c['initial_momentum']
    output = []
    spacing = 0.125
    h = spacing/substeps
    for index in range(round(c['duration_s']/spacing)+1):
        t = index*spacing
        q = y[:4]
        n = math.sqrt(sum(v*v for v in q))
        motor,total = terms(c,t,y)
        wi,ai = rates(c,t)
        output.append({'t':t,'pose':{'quaternion_wxyz':[v/n for v in q],
            'angular_velocity_inertial_deg_s':[math.degrees(v) for v in wi],
            'angular_acceleration_inertial_deg_s2':[math.degrees(v) for v in ai]},
            'momentum_nms':y[4:],'motor_torque_nm':motor,'total_inertial_momentum_nms':total})
        if index < round(c['duration_s']/spacing):
            for sub in range(substeps):
                y = rk4(c,t+sub*h,y,h)
    return output

def main():
    cases = json.loads((ROOT/'inputs.json').read_text())['cases']
    rows = []
    for c in cases:
        coarse, fine = integrate(c,32), integrate(c,64)
        delta = max(abs(x-y) for a,b in zip(coarse,fine)
                    for key in ['momentum_nms','motor_torque_nm','total_inertial_momentum_nms']
                    for x,y in zip(a[key],b[key]))
        if delta > 1e-8:
            raise ValueError(f"RK4 convergence failed: {c['id']} {delta}")
        max_h = [max(abs(s['momentum_nms'][i]) for s in fine) for i in range(3)]
        max_t = [max(abs(s['motor_torque_nm'][i]) for s in fine) for i in range(3)]
        feasible = all(v<=cap for v,cap in zip(max_h,c['momentum_capacity'])) and all(v<=cap for v,cap in zip(max_t,c['motor_capacity']))
        status = 'supported' if feasible else 'violated'
        if status != c['expected_status']:
            raise ValueError(f"independent status mismatch: {c['id']}")
        rows.append({'id':c['id'],'rk4_resolution_delta':delta,'expected_status':status,
            'max_abs_momentum_nms':max_h,'max_abs_motor_torque_nm':max_t,'samples':fine})
    out = {'format':'independent_wheel_reference.v1','generator':'Python 3 standard library RK4',
        'sample_step_s':0.125,'fine_rk4_step_s':0.125/64,'coarse_rk4_step_s':0.125/32,
        'convergence_tolerance':1e-8,'cases':rows}
    (ROOT/'reference.json').write_text(json.dumps(out,sort_keys=True,indent=2)+'\n')
    names = ['generate.py','inputs.json','reference.json']
    (ROOT/'SHA256SUMS').write_text(''.join(hashlib.sha256((ROOT/n).read_bytes()).hexdigest()+'  '+n+'\n' for n in names))
    print('Generated',len(rows),'independent wheel cases')
if __name__ == '__main__':
    main()
