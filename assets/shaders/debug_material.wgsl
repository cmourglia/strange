#import bevy_pbr::{
    pbr_fragment::pbr_input_from_standard_material,
    pbr_functions::alpha_discard,
    mesh_functions,
}

#ifdef PREPASS_PIPELINE 
#import bevy_pbr::{
    prepass_io::{VertexOutput, FragmentOutput},
    pbr_deferred_functions::deferred_output,
}
#else
#import bevy_pbr::{
    forward_io::{VertexOutput, FragmentOutput},
    pbr_functions::{apply_pbr_lighting, main_pass_post_lighting_processing},
}
#endif

#import bevy::bevy_render::color_operations::hsv_to_rgb
#import bevy::bevy_render::color_operations::rgb_to_hsv

struct BlockoutMaterial {
    line_color: vec4f,
    line_size: vec2f,
}

@group(#{MATERIAL_BIND_GROUP}) @binding(100)
var<uniform> extension: BlockoutMaterial;


@fragment
fn fragment(
    in: VertexOutput,
    @builtin(front_facing) is_front: bool,
) -> FragmentOutput {
    var pbr_input = pbr_input_from_standard_material(in, is_front);

    let instance_index = in.instance_index;

    var M = mesh_functions::get_local_from_world(in.instance_index);
    var mesh_in = in;

    mesh_in.world_position = M * in.world_position;
    mesh_in.world_normal = (M * vec4f(in.world_normal, 0.0)).xyz;

    var computed_checkers = (checkerboard(mesh_in, 0.1) + checkerboard(mesh_in, 1.0)) * 0.5;

    let nx = abs(mesh_in.world_normal.x);
    let ny = abs(mesh_in.world_normal.y);
    let nz = abs(mesh_in.world_normal.z);

    var color = vec3f(0.5, 0.5, 1.0);
    if nx > ny && nx > nz {
        color = vec3f(1.0, 0.5, 0.5);
    } else if ny > nz && ny > nz {
        color = vec3f(0.5, 1.0, 0.5);
    }

    var floor_wall_split = oklab_from_linear(color);
    floor_wall_split.x = (floor_wall_split.x + computed_checkers.x * 0.2) - 0.2;

    pbr_input.material.base_color = mix(
        vec4(blockout(mesh_in)),
        extension.line_color,
        vec4(linear_from_oklab(floor_wall_split), 1.0)
    );

    //let dx = 0.25;
    //let dy = 0.25;

    //var final_color = vec3f(0);

    //for (var y = 0.0; y < 1.0; y += dy) {
    //    for (var x = 0.0; x < 1.0; x += dx) {
    //        let sample_pos = pos + dpdx(pos) * x + dpdy(pos) * y;
    //        final_color += get_color(sample_pos, normal);
    //    }
    //}
    //pbr_input.material.base_color = vec4(final_color, 1.0);

    //pbr_input.material.base_color = vec4(computed_checkers, 1.0);
    pbr_input.material.base_color = alpha_discard(pbr_input.material, pbr_input.material.base_color);

#ifdef PREPASS_PIPELINE
    let out = deferred_output(in, pbr_input);
#else
    var out: FragmentOutput;
    out.color = apply_pbr_lighting(pbr_input);

    out.color = main_pass_post_lighting_processing(pbr_input, out.color);
#endif

    return out;
}

fn get_color(pos: vec3f, normal: vec3f) -> vec3f {
    let pi = 3.141519;

    let scaled_pos = pos * pi * 2.0;
    let scaled_pos2 = scaled_pos / 10.0 + vec3f(pi / 4.0);

    var s = cos(scaled_pos2.x) * cos(scaled_pos2.y) * cos(scaled_pos2.z);
    var t = cos(scaled_pos.x) * cos(scaled_pos.y) * cos(scaled_pos.z);

    let nx = abs(normal.x);
    let ny = abs(normal.y);
    let nz = abs(normal.z);

    var base_color = vec3f(0.5, 0.5, 1.0);
    if nx > ny && nx > nz {
        base_color = vec3f(1.0, 0.5, 0.5);
    } else if ny > nz && ny > nz {
        base_color = vec3f(0.5, 1.0, 0.5);
    }

    t = ceil(t * 0.9);
    s = (ceil(s * 0.9) + 3.0) * 0.25;

    let colorB = vec3f(0.7);
    let colorA = vec3f(1.0);
    let final_color = mix(colorA, colorB, t) * s;

    return base_color * final_color;
}

fn checker(axis: vec2f, size: f32) -> f32 {
    let pos = floor(axis.xy / size);
    let tile = (pos.x + (pos.y % 2.0)) % 2.0;
    return abs(tile);
}

fn checkerboard(mesh: VertexOutput, size: f32) -> vec3f {
    let x = max(0.1, checker(mesh.world_position.zy, size));
    let y = max(0.1, checker(mesh.world_position.xz, size));
    let z = max(0.1, checker(mesh.world_position.xy, size));

    let normal = abs(mesh.world_normal);
    let weights = normal / (normal.x + normal.y + normal.z);
    let checkers = (x * weights.x + y * weights.y + z * weights.z);

    return vec3(checkers);
}

fn blockout(mesh: VertexOutput) -> f32 {
    let x = pristine_grid(mesh.world_position.zy, extension.line_size);
    let y = pristine_grid(mesh.world_position.xz, extension.line_size);
    let z = pristine_grid(mesh.world_position.xy, extension.line_size);

    let normal = abs(mesh.world_normal);
    let weights = normal / (normal.x + normal.y + normal.z);

    return 0.0;

    return (x * weights.x + y * weights.y + z * weights.z);
}

fn pristine_grid(uv: vec2f, line_width: vec2f) -> f32 {
    let ddx = dpdx(uv);
    let ddy = dpdy(uv);
    let uv_deriv = vec2(length(vec2(ddx.x, ddy.x)), length(vec2(ddx.y, ddy.y)));

    let invert_line = vec2<bool>(line_width.x > 0.5, line_width.y > 0.5);
    var target_width: vec2f;

    if invert_line.x {
        target_width.x = 1.0 - line_width.x;
    } else {
        target_width.x = line_width.x;
    }

    if invert_line.x {
        target_width.y = 1.0 - line_width.y;
    } else {
        target_width.y = line_width.y;
    }

    let draw_width = clamp(target_width, uv_deriv, vec2(0.5));
    let line_aa = uv_deriv * 1.5;

    var grid_uv = abs(fract(uv) * 2.0 - 1.0);
    if invert_line.x { grid_uv.x = grid_uv.x; } else { grid_uv.x = 1.0 - grid_uv.x; }
    if invert_line.y { grid_uv.y = grid_uv.y; } else { grid_uv.y = 1.0 - grid_uv.y; }

    var grid2 = smoothstep(draw_width + line_aa, draw_width - line_aa, grid_uv);
    grid2 *= clamp(target_width / draw_width, vec2(0.0), vec2(1.0));
    grid2 = mix(grid2, target_width, clamp(uv_deriv * 2.0 - 1.0, vec2(0.0), vec2(1.0)));

    if invert_line.x {
        grid2.x = 1.0 - grid2.x;
    }

    if invert_line.y {
        grid2.y = 1.0 - grid2.y;
    }

    return mix(grid2.x, 1.0, grid2.y);
}

//By Björn Ottosson
//https://bottosson.github.io/posts/oklab
//Shader functions adapted by "mattz"
//https://www.shadertoy.com/view/WtccD7
fn oklab_from_linear(linear: vec3f) -> vec3f {
    let im1: mat3x3<f32> = mat3x3<f32>(0.4121656120, 0.2118591070, 0.0883097947,
        0.5362752080, 0.6807189584, 0.2818474174,
        0.0514575653, 0.1074065790, 0.6302613616);

    let im2: mat3x3<f32> = mat3x3<f32>(0.2104542553, 1.9779984951, 0.0259040371,
        0.7936177850, -2.4285922050, 0.7827717662,
        -0.0040720468, 0.4505937099, -0.8086757660);

    let lms: vec3f = im1 * linear;

    return im2 * (sign(lms) * pow(abs(lms), vec3(1.0 / 3.0)));
}

fn linear_from_oklab(oklab: vec3f) -> vec3f {
    let m1: mat3x3<f32> = mat3x3<f32>(1.000000000, 1.000000000, 1.000000000,
        0.396337777, -0.105561346, -0.089484178,
        0.215803757, -0.063854173, -1.291485548);

    let m2: mat3x3<f32> = mat3x3<f32>(4.076724529, -1.268143773, -0.004111989,
        -3.307216883, 2.609332323, -0.703476310,
        0.230759054, -0.341134429, 1.706862569);
    let lms: vec3f = m1 * oklab;

    return m2 * (lms * lms * lms);
}
//By Inigo Quilez, under MIT license
//https://www.shadertoy.com/view/ttcyRS
fn oklab_mix(lin1: vec3f, lin2: vec3f, a: f32) -> vec3f {
    // https://bottosson.github.io/posts/oklab
    let kCONEtoLMS: mat3x3<f32> = mat3x3<f32>(
        0.4121656120, 0.2118591070, 0.0883097947,
        0.5362752080, 0.6807189584, 0.2818474174,
        0.0514575653, 0.1074065790, 0.6302613616
    );
    let kLMStoCONE: mat3x3<f32> = mat3x3<f32>(
        4.0767245293, -1.2681437731, -0.0041119885,
        -3.3072168827, 2.6093323231, -0.7034763098,
        0.2307590544, -0.3411344290, 1.7068625689
    );
                    
    // rgb to cone (arg of pow can't be negative)
    let lms1: vec3f = pow(kCONEtoLMS * lin1, vec3(1.0 / 3.0));
    let lms2: vec3f = pow(kCONEtoLMS * lin2, vec3(1.0 / 3.0));
    // lerp
    var lms: vec3f = mix(lms1, lms2, a);
    // gain in the middle (no oklab anymore, but looks better?)
    lms *= 1.0 + 0.2 * a * (1.0 - a);
    // cone to rgb
    return kLMStoCONE * (lms * lms * lms);
}
