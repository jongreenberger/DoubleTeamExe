


//--------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------


cbuffer blend : register(b5)
{
	float4 blendColor;
	float blendTime;
	float3 padding;

};

// triangle that spans NDC
static const float3 FULLSCREEN_TRI[] = {
   float3( -1.0f, -1.0f, 0.0f ),
   float3(  3.0f, -1.0f, 0.0f ), 
   float3( -1.0f,  3.0f, 0.0f )
}; 

static const float2 FULLSCREEN_UV[] = {
   float2(  0.0f,  1.0f ),
   float2(  2.0f,  1.0f ), 
   float2(  0.0f, -1.0f )
}; 

//--------------------------------------------------------------------------------------
// Textures and Samplers
//--------------------------------------------------------------------------------------
Texture2D <float4> tDiffuse : register(t0);
SamplerState sLinear : register(s0);

//--------------------------------------------------------------------------------------
// Input/Output Structures
//--------------------------------------------------------------------------------------

struct vs_input_t
{
   uint vertex_id        : SV_VertexID;
};

struct v2f_t
{
   float4 position         : SV_Position;
   float2 uv               : UV; 
};


//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
v2f_t VertexFunction(vs_input_t input)
{
   v2f_t v2f = (v2f_t)0;

   v2f.position   = float4( FULLSCREEN_TRI[input.vertex_id], 1.0f ); 
   v2f.uv         = FULLSCREEN_UV[input.vertex_id];    

   return v2f;
}

//--------------------------------------------------------------------------------------
// Fragment Shader
//--------------------------------------------------------------------------------------
float4 FragmentFunction( v2f_t input ) : SV_Target0
{
   float4 color = tDiffuse.Sample( sLinear, input.uv ); 
   

   float trueBlend = blendTime*blendTime*(3.f - 2.f*blendTime);


   return lerp(color, blendColor, trueBlend);

   return color;
}