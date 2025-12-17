use bevy::{
    camera::Exposure,
    core_pipeline::tonemapping::Tonemapping,
    light::light_consts::lux,
    pbr::{Atmosphere, AtmosphereSettings},
    post_process::bloom::Bloom,
    prelude::*,
    render::view::Hdr,
};

mod debug_material;
mod sim;
mod stepping;

use debug_material::DebugMaterialPlugin;
use stepping::SteppingPlugin;

use crate::{debug_material::*, sim::*};

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(DebugMaterialPlugin)
        .add_plugins(
            SteppingPlugin::default()
                .add_schedule(Update)
                .add_schedule(FixedUpdate)
                .at(percent(35), percent(50)),
        )
        .add_systems(Startup, setup)
        .add_systems(FixedUpdate, (apply_gravity, collide, integrate).chain())
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<DebugMaterial>>,
) {
    let blockout_material = materials.add(debug_material());

    commands.spawn((
        Mesh3d(meshes.add(Sphere::new(0.5))),
        MeshMaterial3d(blockout_material.clone()),
        Transform::from_xyz(0.0, 1.5, 0.0),
        Shape::sphere(0.5),
        Body::new(1.0),
    ));

    commands.spawn((
        Mesh3d(meshes.add(Sphere::new(100.0))),
        MeshMaterial3d(blockout_material.clone()),
        Transform::from_xyz(0.0, -100.0, 0.0),
        Shape::sphere(100.0),
        Body::FIXED,
    ));

    commands.spawn((
        DirectionalLight {
            shadows_enabled: true,
            illuminance: lux::RAW_SUNLIGHT,
            ..Default::default()
        },
        Transform::from_xyz(1.0, 1.0, 1.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    commands.spawn((
        Camera3d::default(),
        Camera::default(),
        Hdr,
        Atmosphere::EARTH,
        AtmosphereSettings::default(),
        Exposure::SUNLIGHT,
        Tonemapping::AcesFitted,
        Bloom::NATURAL,
        Transform::from_xyz(-5.0, 5.0, 7.5).looking_at(vec3(0.0, 0.5, 0.0), Vec3::Y),
    ));
}
