use bevy::prelude::*;

#[derive(Component)]
pub struct Body {
    pub mass: f32,
    pub inv_mass: f32,
    pub velocity: Vec3,
}

impl Body {
    pub const FIXED: Self = Body::new(0.0);

    pub const fn new(mass: f32) -> Self {
        Self {
            mass,
            inv_mass: if mass == 0.0 { 0.0 } else { 1.0 / mass },
            velocity: Vec3::ZERO,
        }
    }

    pub fn apply_impulse_linear(&mut self, impulse: Vec3) {
        if self.inv_mass == 0.0 {
            return;
        }

        self.velocity += impulse * self.inv_mass;
    }
}

#[derive(Component)]
pub enum Shape {
    Sphere(SphereShape),
}

impl Shape {
    pub fn sphere(radius: f32) -> Self {
        Self::Sphere(SphereShape { radius })
    }
}

#[derive(Component)]
struct SphereShape {
    pub radius: f32,
}

pub fn integrate(mut q: Query<(&mut Transform, &mut Body)>, time: Res<Time>) {
    let dt = time.delta_secs();

    const GRAVITY: Vec3 = vec3(0.0, -10.0, 0.0);

    for (mut t, mut b) in q {
        let gravity = GRAVITY * b.mass * dt;
        b.apply_impulse_linear(gravity);
        t.translation += b.inv_mass * dt * b.velocity;
    }
}
