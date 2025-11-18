shader_type canvas_item;

uniform float rotate_degree : hint_range(0.0, 360.0, 0.1) = 0;
uniform float move_degree :  hint_range(0.0, 360.0, 0.1) = 0;
uniform float speed : hint_range(0.0, 100.0) = 1;
uniform float scale : hint_range(0.01, 100.0, 0.01) = 0.2;
uniform vec2 gap = vec2(0.5, 0.5);
uniform vec2 node_scale = vec2(1.0);

uniform vec4 tint : source_color = vec4(1.0);

vec2 rotate(vec2 uv, float local_angle) {
    mat2 rotation = mat2(
        vec2(sin(local_angle), -cos(local_angle)),
        vec2(cos(local_angle),  sin(local_angle))
    );
    return uv * rotation;
}

void fragment() {
    vec2 scaled_uv = UV * node_scale / scale;

    float rot = radians(rotate_degree + 90.0);
    float move = radians(move_degree + 180.0) - rot;

    vec2 dir = vec2(cos(move), sin(move));
    vec2 rotated_uv = rotate(scaled_uv, rot);
    vec2 scrolled_uv = rotated_uv + dir * speed * TIME;

    // periodo del tile
    vec2 period = vec2(1.0) + gap;

    // uso fract() para evitar negativos y asegurar tiling perfecto
    vec2 pos = fract(scrolled_uv / period) * period;

    // si gap = 0 => period = 1 y pos es exacto de 0..1 sin seams
    float alpha = step(pos.x, 1.0) * step(pos.y, 1.0);

    vec4 tex = texture(TEXTURE, pos);

    COLOR = vec4(tex.rgb * tint.rgb, alpha * tint.a);
}
