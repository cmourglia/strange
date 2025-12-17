use bevy::{
    app::Plugin,
    asset::Asset,
    color::{Color, LinearRgba, palettes::css::WHITE},
    math::Vec2,
    pbr::{ExtendedMaterial, MaterialExtension, MaterialPlugin, StandardMaterial},
    reflect::Reflect,
    render::render_resource::AsBindGroup,
    shader::ShaderRef,
};

const SHADER_ASSET_PATH: &str = "shaders/debug_material.wgsl";

pub struct DebugMaterialPlugin;

pub type DebugMaterial = ExtendedMaterial<StandardMaterial, DebugMaterialExt>;

impl Plugin for DebugMaterialPlugin {
    fn build(&self, app: &mut bevy::prelude::App) {
        app.add_plugins(MaterialPlugin::<DebugMaterial>::default());
    }
}

pub fn debug_material() -> DebugMaterial {
    DebugMaterial {
        base: StandardMaterial {
            base_color: WHITE.into(),
            opaque_render_method: bevy::pbr::OpaqueRendererMethod::Auto,
            ..Default::default()
        },
        extension: DebugMaterialExt::default(),
    }
}

#[derive(Asset, AsBindGroup, Reflect, Debug, Clone)]
pub struct DebugMaterialExt {
    #[uniform(100)]
    pub line_color: LinearRgba,

    #[uniform(100)]
    pub line_size: Vec2,
}

impl Default for DebugMaterialExt {
    fn default() -> Self {
        Self {
            line_color: Color::WHITE.into(),
            line_size: Vec2::splat(0.01),
        }
    }
}

impl MaterialExtension for DebugMaterialExt {
    fn fragment_shader() -> ShaderRef {
        SHADER_ASSET_PATH.into()
    }

    fn deferred_fragment_shader() -> ShaderRef {
        SHADER_ASSET_PATH.into()
    }
}
