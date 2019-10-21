// ITP_Outline.cginc
// 2019/05/16 Create by Grissom Lee mail:xdonlee@163.com
//
#if defined(_ITS_OUTLINE_BLEND_MAIN_NOLIGHT) || defined(_ITS_OUTLINE_BLEND_MAIN_LIGHT) || defined(_ITS_CLIPPING_ALPHA)
uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
#endif

#ifndef _ITS_OUTLINE_BLEND_MAIN_NONE
uniform float4 _MainColor;
#endif

#ifdef _ITS_OUTLINE_BLEND_MAIN_LIGHT
uniform float4 _LightColor0;
#endif

uniform float _OutlineWidth;
uniform float _FarthestDistance;
uniform float _NearestDistance;
uniform float4 _OutlineColor;
uniform float _OffsetZ;

#ifdef _ITS_OUTLINE_MASK_TEX
uniform sampler2D _OutlineMaskTex; uniform float4 _OutlineMaskTex_ST;
#endif

#ifdef _ITS_OUTLINE_COLOR_TEX
uniform sampler2D _OutlineColorTex; uniform float4 _OutlineColorTex_ST;
#endif

#ifndef _ITS_CLIPPING_NONE
uniform float _ClippingLevel;
uniform fixed _ClippingInverse;
#endif 

#ifdef _ITS_TRANSPARENCY
uniform float _Transparency;
#endif 

#ifdef _ITS_CLIPPING_MASK
uniform sampler2D _ClippingMask; uniform float4 _ClippingMask_ST;
#endif

struct VertexInput 
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
#if defined(_ITS_OUTLINE_MASK_TEX) || !defined(_ITS_CLIPPING_NONE) || defined(_ITS_OUTLINE_COLOR_TEX) || !defined(_ITS_OUTLINE_BLEND_MAIN_NONE)
	float2 texcoord0 : TEXCOORD0;
#endif
};

struct VertexOutput 
{
	float4 pos : SV_POSITION;
#if defined(_ITS_OUTLINE_MASK_TEX) || !defined(_ITS_CLIPPING_NONE) || defined(_ITS_OUTLINE_COLOR_TEX) || !defined(_ITS_OUTLINE_BLEND_MAIN_NONE)
	float2 uv0 : TEXCOORD0;
#endif
};

VertexOutput vert(VertexInput v)
{
	VertexOutput o = (VertexOutput)0;
#if defined(_ITS_OUTLINE_MASK_TEX) || !defined(_ITS_CLIPPING_NONE) || defined(_ITS_OUTLINE_COLOR_TEX) || !defined(_ITS_OUTLINE_BLEND_MAIN_NONE)
	o.uv0 = v.texcoord0;
#endif

#ifdef _ITS_OUTLINE_MASK
	o.pos = UnityObjectToClipPos(v.vertex);
	return o;
#endif

	float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
#ifdef _ITS_OUTLINE_MASK_TEX
	float outlineMask = tex2Dlod(_OutlineMaskTex, float4(TRANSFORM_TEX(o.uv0, _OutlineMaskTex), 0.0, 0)).r;
	float outlineWidth = (_OutlineWidth*0.001*smoothstep(_FarthestDistance, _NearestDistance, distance(objPos.rgb, _WorldSpaceCameraPos))*outlineMask);
#else
	float outlineWidth = (_OutlineWidth*0.001*smoothstep(_FarthestDistance, _NearestDistance, distance(objPos.rgb, _WorldSpaceCameraPos)));
#endif
	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.pos.xyz);
	float4 viewDirectionVP = mul(UNITY_MATRIX_VP, float4(viewDirection.xyz, 1));

#if defined(UNITY_REVERSED_Z)
	_OffsetZ = _OffsetZ * -0.01;
#else
	_OffsetZ = _OffsetZ * 0.01;
#endif

#ifdef _ITS_OUTLINE_NORMAL
	o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal*outlineWidth, 1));
#elif _ITS_OUTLINE_POSITION
	outlineWidth = outlineWidth * 2;
	o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + normalize(v.vertex)*outlineWidth, 1));
#endif
	o.pos.z = o.pos.z + _OffsetZ * viewDirectionVP.z;
	return o;
}

float4 frag(VertexOutput i) : SV_Target 
{
	float alpha = 1.0;

#ifdef _ITS_CLIPPING_ALPHA
	float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
	alpha = mainTexColor.a;
#elif _ITS_CLIPPING_MASK
	alpha = tex2D(_ClippingMask, TRANSFORM_TEX(i.uv0, _ClippingMask)).r;
#endif

#ifndef _ITS_CLIPPING_NONE
	alpha = saturate((lerp(alpha, (1.0 - alpha), _ClippingInverse) + _ClippingLevel));
	clip(alpha - 0.5);
#endif

	float3 color = _OutlineColor.rgb;

#if !defined(_ITS_OUTLINE_BLEND_MAIN_NONE) && !defined(_ITS_CLIPPING_ALPHA)
	float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
#endif

#ifdef _ITS_OUTLINE_BLEND_MAIN_NOLIGHT
	float3 mainColor = mainTexColor.rgb * _MainColor.rgb;
	color *= (mainColor * mainColor);
#elif _ITS_OUTLINE_BLEND_MAIN_LIGHT
	float3 mainColor = mainTexColor.rgb * _MainColor.rgb * _LightColor0.rgb;
	color *= (mainColor * mainColor);
#endif

#ifdef _ITS_TRANSPARENCY
	alpha = saturate((alpha + _Transparency));
#endif

#ifdef _ITS_OUTLINE_MASK
	return fixed4(0, 0, 0, 1);
#endif

#ifdef _ITS_OUTLINE_COLOR_TEX
	float3 outlineTexColor = tex2D(_OutlineColorTex, TRANSFORM_TEX(i.uv0, _OutlineColorTex)).rgb;
	return fixed4(color * outlineTexColor, alpha);
#else
	return fixed4(color, alpha);
#endif
}
// ITP_Outline.cginc
