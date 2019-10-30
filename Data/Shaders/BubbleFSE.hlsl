//--------------------------------------------------------------------------------------
// Stream Input
// ------
// Stream Input is input that is walked by the vertex shader.  
// If you say "Draw(3,0)", you are telling to the GPU to expect '3' sets, or 
// elements, of input data.  IE, 3 vertices.  Each call of the VertxShader
// we be processing a different element. 
//--------------------------------------------------------------------------------------

// inputs are made up of internal names (ie: uv) and semantic names
// (ie: TEXCOORD).  "uv" would be used in the shader file, where
// "TEXCOORD" is used from the client-side (cpp code) to attach ot. 
// The semantic and internal names can be whatever you want, 
// but know that semantics starting with SV_* usually denote special 
// inputs/outputs, so probably best to avoid that naming.
struct vs_input_t 
{
   float3 position      : POSITION; 
   float4 color         : COLOR; 
   float2 uv            : TEXCOORD; 
}; 

struct BubbleData
{
	float2 pos;
	float radiusSquared;
	float timeScale;
};

//--------------------------------------------------------------------------------------
// Uniform Input
// ------
// Uniform Data is also externally provided data, but instead of changing
// per vertex call, it is constant for all vertices, hence the name "Constant Buffer"
// or "Uniform Buffer".  This is read-only memory; 
//
// I tend to use all cap naming here, as it is effectively a 
// constant from the shader's perspective. 
//
// register(b2) determines the buffer unit to use.  In this case
// we'll say this data is coming from buffer slot 2. 
//--------------------------------------------------------------------------------------
cbuffer cameraConstants : register(b2)
{
   float4x4 modelView;
};

cbuffer modelConstants : register(b3)
{
	float4x4 modelViewProj;
};

cbuffer bubbleConstants : register(b6)
{
	int nBubbles;
	float pad0;
	float pad1;
	float pad2;
	BubbleData bubbles[100];
};

//--------------------------------------------------------------------------------------
float RangeMap(float inVal, float inMin, float inMax, float outMin, float outMax)
{
	return (inVal - inMin)*((outMax - outMin)/(inMax - inMin)) + outMin;
}

float IsPointInDisc( float2 pos, float2 center, float radiusSquared)
{
	float2 disp = center - pos;
	return disp.x*disp.x + disp.y*disp.y < radiusSquared;
}

float4 GetTimeBubbleColor( float2 worldPos)
{
	float4 ans;
	float timeScale = 1.f;
	for( int i = 0; i < nBubbles; ++i)
	{
		float wasInside = IsPointInDisc( worldPos, bubbles[i].pos, bubbles[i].radiusSquared ); 
		timeScale = wasInside ? timeScale * bubbles[i].timeScale : timeScale; 
	}

	if( timeScale < 1.f )
	{
		ans.xyz = float3( 0.f, 0.f, 1.f);
		ans.w = RangeMap( timeScale, 0.1f, 1.f, 0.7f, 0.f); 
	}
	else
	{
		ans.xyz = float3( 1.f, 0.f, 0.f);
		ans.w = RangeMap( timeScale, 1.f, 3.f, 0.f, 0.7f);
	}
	ans.w = clamp( ans.w, 0.f, 0.7f); 
	return ans;

}

//--------------------------------------------------------------------------------------
// Texures & Samplers
// ------
// Another option for external data is a Texture.  This is usually a large
// set of data (like an image) that we want to "sample" from.  
//
// A sampler are the rules for how to collect texel data for a given UV. 
//
// Like constant buffers, these hav ea slot they're expecting to be bound
// t0 means use texture unit 0,
// s0 means use sampler unit 0,
//
// In D3D11, constant buffers, textures, and samplers all have their own set 
// of slots.  Some data types may share a slot space (for example, unordered access 
// views (uav) use the texture space). 
//--------------------------------------------------------------------------------------
Texture2D<float4> tAlbedo : register(t0); // texutre I'm using for albedo (color) information
SamplerState sAlbedo : register(s0);      // sampler I'm using for the Albedo texture

//--------------------------------------------------------------------------------------
// Programmable Shader Stages
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// for passing data from vertex to fragment (v-2-f)
struct v2f_t 
{
   float4 position : SV_POSITION; 
   float4 color : COLOR; 
   float2 uv : UV;
   float2 worldPos : WPOS;
}; 



//--------------------------------------------------------------------------------------
// Vertex Shader
v2f_t VertexFunction(vs_input_t input)
{
   v2f_t v2f = (v2f_t)0;
	float4 inputPos;
	inputPos.xyz = input.position;
	inputPos.w = 1.f;
	v2f.position = mul(modelViewProj,inputPos);


   v2f.color = input.color; 
   v2f.uv = input.uv; 
   v2f.worldPos = input.position.xy; 
   return v2f;
}

//--------------------------------------------------------------------------------------
// Fragment Shader
// 
// SV_Target0 at the end means the float4 being returned
// is being drawn to the first bound color target.
float4 FragmentFunction( v2f_t input ) : SV_Target0
{
   // First, we sample from our texture


   // component wise multiply to "tint" the output
   float4 finalColor = input.color * GetTimeBubbleColor( input.worldPos ); 

   // output it; 
   return finalColor; 
}