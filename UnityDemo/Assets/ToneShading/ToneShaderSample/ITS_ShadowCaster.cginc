// UCTS_ShadowCaster.cginc
// 2019/05/16 Create by Grissom Lee mail:xdonlee@163.com
//
#ifndef _ITS_CLIPPING_NONE
uniform float _ClippingLevel;
uniform fixed _ClippingInverse;
#endif

#ifdef _ITS_CLIPPING_ALPHA
uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
#elif _ITS_CLIPPING_MASK
uniform sampler2D _ClippingMask; uniform float4 _ClippingMask_ST;
#endif

struct VertexInput 
{
	float4 vertex : POSITION;
#ifndef _ITS_CLIPPING_NONE
	float2 texcoord0 : TEXCOORD0;
#endif
};

struct VertexOutput 
{
	V2F_SHADOW_CASTER;
#ifndef _ITS_CLIPPING_NONE
	float2 uv0 : TEXCOORD1;
#endif
};

VertexOutput vert(VertexInput v) 
{
	VertexOutput o = (VertexOutput)0;
#ifndef _ITS_CLIPPING_NONE
	o.uv0 = v.texcoord0;
#endif
	o.pos = UnityObjectToClipPos(v.vertex);
	TRANSFER_SHADOW_CASTER(o)
	return o;
}

float4 frag(VertexOutput i) : SV_TARGET
{
#ifndef _ITS_CLIPPING_NONE
#ifdef _ITS_CLIPPING_ALPHA
	float alpha = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex)).a;
#elif _ITS_CLIPPING_MASK
	float alpha = tex2D(_ClippingMask, TRANSFORM_TEX(i.uv0, _ClippingMask)).r;
#endif
	alpha = saturate((lerp(alpha, (1.0 - alpha), _ClippingInverse) + _ClippingLevel));
	clip(alpha - 0.5);
#endif
	SHADOW_CASTER_FRAGMENT(i)
}
