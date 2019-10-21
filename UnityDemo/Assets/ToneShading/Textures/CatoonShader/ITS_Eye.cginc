// UCTS_Eye.cginc
// 2019/05/21 Create by Grissom Lee mail:xdonlee@163.com
//

uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
uniform float4 _MainColor;
uniform fixed _MainLightColor;
#ifdef _ITS_MASK_TEX
uniform sampler2D _MaskTex; uniform float4 _MaskTex_ST;
#endif
#ifdef _ITS_NORMAL_TEX
uniform sampler2D _NormalTex; uniform float4 _NormalTex_ST;
#endif

// Caustic
#ifdef _ITS_CAUSTIC
uniform fixed _CausticLightColor;
uniform sampler2D _CausticTex; uniform float4 _CausticTex_ST;
uniform float4 _CausticColor;
uniform float _CausticPower;
#endif
uniform float _Refraction;
fixed4 _EyeForward;

// Specular
#ifdef _ITS_SPECULAR
uniform fixed _SpecularLightColor;
uniform sampler2D _SpecularTex; uniform float4 _SpecularTex_ST;
uniform float4 _SpecularColor;
uniform float _SpecularRotate;
#endif

// Emissive
#ifdef _ITS_EMISSIVE
uniform sampler2D _EmissiveTex; uniform float4 _EmissiveTex_ST;
uniform float4 _EmissiveColor;
#endif

// GI
#ifdef _ITS_GI
uniform float _GIThreshold;
#endif

// Clipping
#ifndef _ITS_CLIPPING_NONE
uniform float _ClippingLevel;
uniform fixed _ClippingInverse;
#	ifdef _ITS_CLIPPING_MASK
uniform sampler2D _ClippingMask; uniform float4 _ClippingMask_ST;
#	endif
#endif

struct VertexInput
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 texcoord0 : TEXCOORD0;
};

struct VertexOutput
{
	float4 pos : SV_POSITION;
	float2 uv0 : TEXCOORD0;
	float4 posWorld : TEXCOORD1;
	float3 normal : TEXCOORD2;
	float3 tangent : TEXCOORD3;
	float3 bitangent : TEXCOORD4;
	LIGHTING_COORDS(5, 6)
	UNITY_FOG_COORDS(7)
};

VertexOutput vert(VertexInput v)
{
	VertexOutput o = (VertexOutput)0;
	o.uv0 = v.texcoord0;
	o.normal = normalize(UnityObjectToWorldNormal(v.normal));
	o.tangent = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
	o.bitangent = normalize(cross(o.normal, o.tangent) * v.tangent.w);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.pos = UnityObjectToClipPos(v.vertex);
	UNITY_TRANSFER_FOG(o, o.pos);
	TRANSFER_VERTEX_TO_FRAGMENT(o)
	return o;
}

float4 frag(VertexOutput i) : SV_TARGET
{
	float alpha = 1.0;
#ifdef _ITS_CLIPPING_MASK
	alpha = tex2D(_ClippingMask, TRANSFORM_TEX(i.uv0, _ClippingMask)).r;
	alpha = saturate((lerp(alpha, (1.0 - alpha), _ClippingInverse) + _ClippingLevel));
	clip(alpha - 0.5);
#endif

	// Calulate tangent space
	float3x3 tangentTransform = float3x3(i.tangent, i.bitangent, i.normal);
#ifdef _ITS_NORMAL_TEX
	i.normal = normalize(mul(UnpackNormal(tex2D(_NormalTex, TRANSFORM_TEX(i.uv0, _NormalTex))).rgb, tangentTransform));
#endif

#ifdef _ITS_MASK_TEX
	float maskValue = tex2D(_MaskTex, TRANSFORM_TEX(i.uv0, _MaskTex)).r;
#else
	float maskValue = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex)).a;
#endif

	// Calulate light direction and color
#ifdef _ITS_PASS_FORWARD_BASE
	float3 defaultLightDirection = float3(0.0, 0.1, 0.1);
	float3 defaultLightColor = float3(0.5, 0.5, 0.5);
	float3 lightDirection = normalize(lerp(defaultLightDirection, _WorldSpaceLightPos0.xyz, any(_WorldSpaceLightPos0.xyz)));
	float3 lightColor = lerp(defaultLightColor, _LightColor0.rgb, any(_LightColor0.rgb));
#elif _ITS_PASS_FORWARD_ADD
	float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w));
	float3 lightColor = _LightColor0.rgb*0.5;
	alpha = 0;
#endif

	// Calulate view direction
	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
	float3 offsetUV = float3(dot(viewDirection, i.tangent), dot(viewDirection, i.bitangent), dot(viewDirection, _EyeForward));
	offsetUV.x *= (1 - offsetUV.z) * _Refraction;
	offsetUV.y *= (1 - offsetUV.z) * _Refraction;

	float3 color = tex2D(_MainTex, i.uv0 + float2(-maskValue, -maskValue) * offsetUV);
	color *= lerp(_MainColor.rgb, _MainColor.rgb * lightColor.rgb, _MainLightColor);

#ifdef _ITS_CAUSTIC
	float3 causticTexColor = tex2D(_CausticTex, TRANSFORM_TEX(i.uv0, _CausticTex));
	half3 inverseLightDirection = normalize(reflect(-lightDirection, i.normal));
	half causticAttenuation = pow(DotClamped(inverseLightDirection, i.normal), _CausticPower);
	float3 causticColor = _CausticColor.rgb * causticTexColor.rgb * causticAttenuation;
	causticColor = lerp(causticColor.rgb, causticColor.rgb * lightColor.rgb, _CausticLightColor);
	color += causticColor;
#endif

#ifdef _ITS_SPECULAR
	//float3 halfDirection = normalize(viewDirection + lightDirection);
	float dotHN = dot(float3(1.0,1.0,1.0), _WorldSpaceCameraPos.xyz);
	float specularAttenuation = 0.5 * dotHN + 0.5;

	float specularUVRotateAngle = (specularAttenuation * _SpecularRotate*3.141592654);
	float specularUVRotateSpeed = 1.0;
	float specularUVRotateCOS = cos(specularUVRotateSpeed*specularUVRotateAngle);
	float specularUVRotateSIN = sin(specularUVRotateSpeed*specularUVRotateAngle);
	float2 specularUVRotatePIV = float2(0.5, 0.5);
	float2 specularUVRotate = (mul(i.uv0 - specularUVRotatePIV, float2x2(specularUVRotateCOS, -specularUVRotateSIN, specularUVRotateSIN, specularUVRotateCOS)) + specularUVRotatePIV);
	float3 specularColor = tex2D(_SpecularTex, TRANSFORM_TEX(specularUVRotate, _SpecularTex)).rgb * _SpecularColor.rgb;
	specularColor = lerp(specularColor.rgb, specularColor.rgb * lightColor.rgb, _SpecularLightColor);
	color += specularColor;
#endif

	// Emissive
#ifdef _ITS_EMISSIVE
	float3 emissiveColor = tex2D(_EmissiveTex, TRANSFORM_TEX(i.uv0, _EmissiveTex)).rgb * _EmissiveColor.rgb;
	color += emissiveColor;
#endif

	// GI
#ifdef _ITS_GI
	color += saturate(ShadeSH9(float4(i.normal, 1))*_GIThreshold);
#endif

	fixed4 finalRGBA = fixed4(color, alpha);

	UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
	return finalRGBA;
}