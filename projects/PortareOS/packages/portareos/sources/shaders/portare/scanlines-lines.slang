#version 450

// Scanlines at the console's own line count, whatever resolution the core
// renders at.
//
// A scanline shader that counts the lines of the image it is given draws one
// per line of that image. With SwanStation upscaling 4x, the image is already
// 960 lines tall - the panel's own rows - and every row would be a
// "scanline". This one takes the line count as a parameter instead: 240 for
// a PlayStation, which on a 960-row panel is exactly 4 rows per line, the
// top two at full brightness and the bottom two dimmed.

layout(push_constant) uniform Push
{
	vec4 OutputSize;
	float LINES;
	float DARKNESS;
} params;

#pragma parameter LINES "Console lines per frame" 240.0 120.0 1080.0 1.0
#pragma parameter DARKNESS "Scanline darkness" 0.45 0.0 1.0 0.05

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
	vec3 colour = texture(Source, vTexCoord).rgb;

	// Which output row this is, and where in its console line: in whole
	// rows, so at an integer scale every line gets the same pattern.
	float rows_per_line = params.OutputSize.y / params.LINES;
	float row = floor(vTexCoord.y * params.OutputSize.y);
	float within = mod(row, rows_per_line);

	float keep = within < rows_per_line * 0.5 ? 1.0 : 1.0 - params.DARKNESS;
	FragColor = vec4(colour * keep, 1.0);
}
