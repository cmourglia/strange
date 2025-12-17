use bevy::prelude::*;
use bevy_ecs::query::{QueryData, QueryFilter};

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

#[derive(Component, Debug, Clone, Copy)]
pub enum Shape {
    Sphere(SphereShape),
}

impl Shape {
    pub fn sphere(radius: f32) -> Self {
        Self::Sphere(SphereShape { radius })
    }
}

#[derive(Debug, Clone, Copy)]
struct SphereShape {
    pub radius: f32,
}

fn sphere_sphere_collision(
    s1: &SphereShape,
    t1: &Transform,
    b1: &mut Body,
    s2: &SphereShape,
    t2: &Transform,
    b2: &mut Body,
) {
    let ab = t2.translation - t1.translation;
    let radius_ab = s1.radius + s2.radius;
    let d = ab.length_squared();
    let intersects = d <= (radius_ab * radius_ab);

    println!("{} {} {}", d, radius_ab, radius_ab * radius_ab);

    if !intersects {
        return;
    }

    b1.velocity = Vec3::ZERO;
    b2.velocity = Vec3::ZERO;
}

pub fn collide(mut q: Query<(&mut Body, &Shape, &Transform)>) {
    let mut pairs = q.iter_combinations_mut();

    while let Some([(mut b1, s1, t1), (mut b2, s2, t2)]) = pairs.fetch_next() {
        match (s1, s2) {
            (Shape::Sphere(s1), Shape::Sphere(s2)) => {
                sphere_sphere_collision(s1, t1, &mut b1, s2, t2, &mut b2)
            }
        }
    }
}

pub fn apply_gravity(mut q: Query<&mut Body>, time: Res<Time>) {
    const GRAVITY: Vec3 = vec3(0.0, -10.0, 0.0);
    let dt = time.delta_secs();

    for mut b in q {
        let gravity = GRAVITY * b.mass * dt;
        b.apply_impulse_linear(gravity);
    }
}

pub fn integrate(mut q: Query<(&mut Transform, &mut Body)>, time: Res<Time>) {
    let dt = time.delta_secs();

    for (mut t, mut b) in q {
        t.translation += b.inv_mass * dt * b.velocity;
    }
}
