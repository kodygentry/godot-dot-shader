shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : source_color, hint_normal_roughness_texture, filter_nearest;

uniform float depth_threshold : hint_range(0, 1) = 0.05;
uniform float reverse_depth_threshold : hint_range(0, 1) = 0.25;
uniform float normal_threshold : hint_range(0, 1) = 0.6;
uniform float darken_amount : hint_range(0, 1, 0.01) = 0.3;
uniform float lighten_amount : hint_range(0, 10, 0.01) = 1.5;
uniform vec3 normal_edge_bias = vec3(1, 1, 1);
uniform vec3 light_direction = vec3(-0.96, -0.18, 0.2);

// Additional uniforms for dithering adjustments
uniform float dither_repeat = 1.0; // Adjust repeat scale of dither pattern.
uniform float dither_strength = 1.0; // Blend factor between original and dither effect.
uniform float min_dither_brightness = 0.1; // Below this, force dark output.

// Custom colors for the dithering effect:
// Here, we use color_a for low brightness areas and color_b for higher brightness areas.
uniform vec4 color_a = vec4(0.2, 0.0, 0.0, 1.0); 
uniform vec4 color_b = vec4(0.8, 0.4, 0.2, 1.0);

// Toggle the Bayer matrix size: set to 4, 8, or 16.
uniform int bayer_mode = 4;

void vertex() {
    POSITION = vec4(VERTEX, 1.0);
}

void fragment(){
	vec3 color_in = texture(screen_texture, SCREEN_UV).rgb;
	float brightness = dot(color_in, vec3(0.299, 0.587, 0.114));
	
	if (brightness < min_dither_brightness) {
		ALBEDO = color_a.rgb;
	} else {
		vec2 pixel_coord = SCREEN_UV * VIEWPORT_SIZE / dither_repeat;
		float threshold = 0.0;
		
		if(bayer_mode == 4){
			int x = int(floor(mod(pixel_coord.x, 4.0)));
			int y = int(floor(mod(pixel_coord.y, 4.0)));
			
			int index = y * 4 + x;
            float bayer4[16] = float[](
                0.0/16.0,   8.0/16.0,   2.0/16.0,  10.0/16.0,
                12.0/16.0,  4.0/16.0,   14.0/16.0, 6.0/16.0,
                3.0/16.0,   11.0/16.0,  1.0/16.0,  9.0/16.0,
                15.0/16.0,  7.0/16.0,   13.0/16.0, 5.0/16.0
            );
            threshold = bayer4[index];
		} else if(bayer_mode == 8) {
            // 8x8 Bayer matrix (64 values).
            int x = int(floor(mod(pixel_coord.x, 8.0)));
            int y = int(floor(mod(pixel_coord.y, 8.0)));
            int index = y * 8 + x;
            float bayer8[64] = float[](
                0.0/64.0,   32.0/64.0,   8.0/64.0,   40.0/64.0,   2.0/64.0,   34.0/64.0,   10.0/64.0,  42.0/64.0,
                48.0/64.0,  16.0/64.0,   56.0/64.0,  24.0/64.0,   50.0/64.0,  18.0/64.0,   58.0/64.0,  26.0/64.0,
                12.0/64.0,  44.0/64.0,   4.0/64.0,   36.0/64.0,   14.0/64.0,  46.0/64.0,    6.0/64.0,  38.0/64.0,
                60.0/64.0,  28.0/64.0,   52.0/64.0,  20.0/64.0,   62.0/64.0,  30.0/64.0,   54.0/64.0,  22.0/64.0,
                3.0/64.0,   35.0/64.0,  11.0/64.0,  43.0/64.0,    1.0/64.0,  33.0/64.0,    9.0/64.0,  41.0/64.0,
                51.0/64.0,  19.0/64.0,  59.0/64.0,  27.0/64.0,   49.0/64.0,  17.0/64.0,   57.0/64.0,  25.0/64.0,
                15.0/64.0,  47.0/64.0,   7.0/64.0,  39.0/64.0,   13.0/64.0,  45.0/64.0,    5.0/64.0,  37.0/64.0,
                63.0/64.0,  31.0/64.0,  55.0/64.0,  23.0/64.0,   61.0/64.0,  29.0/64.0,   53.0/64.0,  21.0/64.0
            );
            threshold = bayer8[index];
        }
		
		// Use the threshold from the chosen matrix to select between the two colors.
        vec3 dithered_color = (brightness < threshold) ? color_a.rgb : color_b.rgb;
        ALBEDO = mix(color_in, dithered_color, dither_strength);
	}
}