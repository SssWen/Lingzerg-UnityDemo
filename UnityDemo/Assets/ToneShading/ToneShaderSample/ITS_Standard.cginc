// UCTS_Main.cginc
// 2019/05/16 Create by Grissom Lee mail:xdonlee@163.com
//

uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
uniform float4 _MainColor;
#ifdef _ITS_NORMAL_TEX
uniform sampler2D _NormalTex; uniform float4 _NormalTex_ST;
#endif
#ifdef _ITS_MASK_TEX
uniform sampler2D _MaskTex; uniform float4 _MaskTex_ST;
#endif

// Diffuse
#ifdef _ITS_RAMP_TEX
uniform sampler2D _DiffuseRampTex;
#else
uniform float _DiffuseLowThreshold;
uniform float _DiffuseLowSmoothness;
uniform float _DiffuseMiddleThreshold;
uniform float _DiffuseMiddleSmoothness;
uniform float _DiffuseHighThreshold;
uniform float _DiffuseHighSmoothness;
#endif
uniform fixed _DiffuseLightColor;
#ifdef _ITS_DIFFUSE_TEX
uniform sampler2D _DiffuseLowTex; uniform float4 _DiffuseLowTex_ST;
uniform sampler2D _DiffuseMiddleTex; uniform float4 _DiffuseMiddleTex_ST;
uniform sampler2D _DiffuseHighTex; uniform float4 _DiffuseHighTex_ST;
#endif
uniform float4 _DiffuseLowColor;
uniform float4 _DiffuseMiddleColor;
uniform float4 _DiffuseHighColor;
uniform sampler2D _DiffuseBrushTex; uniform float4 _DiffuseBrushTex_ST;
uniform float _DiffuseBrushStrength;
uniform fixed _ShadowToMain;
uniform float _ShadowThreshold;

// Specular
uniform fixed _SpecularLightColor;
#ifndef _ITS_SPECULAR_NONE
#	ifdef _ITS_SPECULAR_RAMP
uniform sampler2D _SpecularRampTex;
#	endif
#	ifdef _ITS_SPECULAR_TEX
uniform sampler2D _SpecularPrimaryTex; uniform float4 _SpecularPrimaryTex_ST;
#		ifdef _ITS_SPECULAR_DOUBLE
uniform sampler2D _SpecularSecondaryTex; uniform float4 _SpecularSecondaryTex_ST;
#		endif
#	endif
uniform float4 _SpecularPrimaryColor;
uniform float _SpecularPrimaryPower;
uniform float _SpecularPrimaryStrength;
uniform float _SpecularPrimaryShift;
uniform fixed _SpecularPrimaryOnShadow;
uniform float _SpecularPrimaryShadowThreshold;
uniform fixed _SpecularPrimaryToon;
uniform sampler2D _SpecularBrushTex; uniform float4 _SpecularBrushTex_ST;
uniform float _SpecularBrushStrength;
uniform float _SpecularShift;
uniform float _SpecularJitter;
#	ifdef _ITS_SPECULAR_DOUBLE
uniform float4 _SpecularSecondaryColor;
uniform float _SpecularSecondaryPower;
uniform float _SpecularSecondaryStrength;
uniform float _SpecularSecondaryShift;
uniform fixed _SpecularSecondaryOnShadow;
uniform float _SpecularSecondaryShadowThreshold;
uniform fixed _SpecularSecondaryToon;
#	endif
#	ifdef _ITS_SPECULAR_ANISOTROPIC
#		ifdef _ITS_SHIFT_TEX
uniform sampler2D _ShiftTex; uniform float4 _ShiftTex_ST;
#		endif
#	endif
#	ifdef _ITS_GLITTER_TEX
uniform sampler2D _GlitterTex; uniform float4 _GlitterTex_ST;
uniform float _SpecularPrimaryGlitter;
#		ifdef _ITS_SPECULAR_DOUBLE
uniform float _SpecularSecondaryGlitter;
#		endif
#	endif
#endif

// Rim Light
#ifdef _ITS_RIM_LIGHT
uniform sampler2D _RimBrushTex; uniform float4 _RimBrushTex_ST;
uniform float _RimBrushThreshold;
uniform float4 _RimColor;
uniform fixed _RimLightColor;
uniform float _RimPower;
uniform float _RimInsideMask;
uniform fixed _RimToon;
uniform fixed _RimLightMask;
uniform float _RimLightMaskThreshold;
uniform fixed _RimAntipodean;
uniform float4 _RimAntipodeanColor;
uniform fixed _RimAntipodeanLightColor;
uniform float _RimAntipodeanPower;
uniform fixed _RimAntipodeanToon;
#endif

// MatCap
#ifdef _ITS_MATCAP
uniform sampler2D _MatCapTex;
uniform float4 _MatCapColor;
uniform fixed _MatCapLightColor;
uniform fixed _MatCapBlendAdd;
uniform float _MatCapUVThreshold;
uniform float _MatCapUVRotate;
#	ifdef _ITS_MATCAP_NORMAL_TEX
uniform sampler2D _MatCapNormalTex;
#	endif
uniform float _MatCapNormalUVRotate;
uniform fixed _MatCapOnShadow;
uniform float _MatCapShadowThreshold;
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

// Transparency
#ifdef _ITS_TRANSPARENCY
uniform float _Transparency;
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

inline float AnisotropicSpecular(float3 T, float3 V, float3 L, float power, float strength) 
{
	float3 H = normalize(L + V);
	float dotTH = dot(T, H);
	float sinTH = sqrt(1.0 - dotTH * dotTH);
	float dirAtten = smoothstep(-1.0, 0.0, dotTH);
	return dirAtten * pow(sinTH, power) * strength;
}

float4 frag(VertexOutput i) : SV_TARGET
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
	clip(alpha - 0.05);
#endif

	// Calulate tangent space
	float3x3 tangentTransform = float3x3(i.tangent, i.bitangent, i.normal);
#ifdef _ITS_NORMAL_TEX
	i.normal = normalize(mul(UnpackNormal(tex2D(_NormalTex, TRANSFORM_TEX(i.uv0, _NormalTex))).rgb, tangentTransform));
#endif

	// Calulate view direction
	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);	// need optimization

	// Calulate light direction and color
#ifdef _ITS_PASS_FORWARD_BASE
	float3 defaultLightDirection = float3(0.0, 0.1, 0.1);
	float3 defaultLightColor = float3(0.5, 0.5, 0.5);
	float3 lightDirection = normalize(lerp(defaultLightDirection, _WorldSpaceLightPos0.xyz, any(_WorldSpaceLightPos0.xyz)));
	float3 lightColor = lerp(defaultLightColor, _LightColor0.rgb, any(_LightColor0.rgb));
#elif _ITS_PASS_FORWARD_ADD
	float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w));	// need optimization
	float3 lightColor = _LightColor0.rgb*0.5;
	alpha = 0;
#endif

	// Attenuation calulate
	float attenuation = LIGHT_ATTENUATION(i)*0.5 + 0.5;
	float dotNL = dot(i.normal, lightDirection);
	float dotNV = dot(i.normal, viewDirection);

	float halfLambert = 0.5 * dotNL + 0.5;
	halfLambert = lerp(halfLambert, (halfLambert*saturate(((attenuation*0.5) + 0.5 + _ShadowThreshold))), _ShadowToMain);
	float rimAttenuation = 1 - saturate(dotNV);

#ifdef _ITS_MASK_TEX
	float4 maskTexColor = tex2D(_MaskTex, TRANSFORM_TEX(i.uv0, _MaskTex));
	halfLambert = saturate(pow(halfLambert, 1 - 0.95 * (1 - maskTexColor.r)));
#endif

#ifndef _ITS_SPECULAR_NONE
	float3 halfDirection = normalize(viewDirection + lightDirection);
	float dotHN = dot(i.normal, halfDirection);
	float specularAttenuation = 0.5 * dotHN + 0.5;
#endif

	// Diffuse
	// Texture sampling main texture
#if !defined(_ITS_CLIPPING_ALPHA)
	float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
#endif

	float3 diffuseBaseColor = mainTexColor.rgb * _MainColor.rgb;
	float3 diffuseLowColor = _DiffuseLowColor.rgb;
	float3 diffuseMiddleColor = _DiffuseMiddleColor.rgb;
	float3 diffuseHighColor = _DiffuseHighColor.rgb;
#ifdef _ITS_DIFFUSE_TEX
	diffuseLowColor *= tex2D(_DiffuseLowTex, TRANSFORM_TEX(i.uv0, _DiffuseLowTex)).rgb;
	diffuseMiddleColor *= tex2D(_DiffuseMiddleTex, TRANSFORM_TEX(i.uv0, _DiffuseMiddleTex)).rgb;
	diffuseHighColor *= tex2D(_DiffuseHighTex, TRANSFORM_TEX(i.uv0, _DiffuseHighTex)).rgb;
#endif
	diffuseBaseColor = lerp(diffuseBaseColor, diffuseBaseColor * lightColor.rgb, _DiffuseLightColor) * mainTexColor;
	diffuseLowColor = lerp(diffuseLowColor, diffuseLowColor * lightColor.rgb, _DiffuseLightColor) * mainTexColor;
	diffuseMiddleColor = lerp(diffuseMiddleColor, diffuseMiddleColor * lightColor.rgb, _DiffuseLightColor) * mainTexColor;
	diffuseHighColor = lerp(diffuseHighColor, diffuseHighColor * lightColor.rgb, _DiffuseLightColor) * mainTexColor;
	float4 diffuseBrushTexColor = tex2D(_DiffuseBrushTex, TRANSFORM_TEX(i.uv0, _DiffuseBrushTex)) * _DiffuseBrushStrength;

#ifdef _ITS_RAMP_TEX
	float3 diffuseRamp = tex2D(_DiffuseRampTex, float2(halfLambert, rimAttenuation)).rgb;
	float shadowAttenuation = diffuseRamp.r * diffuseBrushTexColor.r;
	float3 color = lerp(diffuseBaseColor, lerp(lerp(diffuseLowColor, diffuseMiddleColor, diffuseRamp.g * diffuseBrushTexColor.g), diffuseHighColor, diffuseRamp.b * diffuseBrushTexColor.b), shadowAttenuation);
#else
	float shadowAttenuation = saturate(1.0 - (halfLambert - _DiffuseLowThreshold + _DiffuseLowSmoothness) / _DiffuseLowSmoothness) * diffuseBrushTexColor.r;
	float3 color = lerp(diffuseBaseColor, lerp(lerp(diffuseLowColor, diffuseMiddleColor, 
		saturate(1.0 - (halfLambert - _DiffuseMiddleThreshold + _DiffuseMiddleSmoothness) / _DiffuseMiddleSmoothness) * diffuseBrushTexColor.g), diffuseHighColor,
		saturate(1.0 - (halfLambert - _DiffuseHighThreshold + _DiffuseHighSmoothness) / _DiffuseHighSmoothness) * diffuseBrushTexColor.b),
		shadowAttenuation);
#endif
	
	// Specular
#ifndef _ITS_SPECULAR_NONE
	float3 specularPrimaryColor = _SpecularPrimaryColor.rgb;
#	ifdef _ITS_SPECULAR_DOUBLE
	float3 specularSecondaryColor = _SpecularSecondaryColor.rgb;
#	endif
#	ifdef _ITS_SPECULAR_TEX
	specularPrimaryColor *= tex2D(_SpecularPrimaryTex, TRANSFORM_TEX(i.uv0, _SpecularPrimaryTex)).rgb;
#		ifdef _ITS_SPECULAR_DOUBLE
	specularSecondaryColor *= tex2D(_SpecularSecondaryTex, TRANSFORM_TEX(i.uv0, _SpecularSecondaryTex)).rgb;
#		endif
#	endif
	specularPrimaryColor = lerp(specularPrimaryColor, specularPrimaryColor * lightColor.rgb, _SpecularLightColor);
#	ifdef _ITS_SPECULAR_DOUBLE
	specularSecondaryColor = lerp(specularSecondaryColor, specularSecondaryColor * lightColor.rgb, _SpecularLightColor);
#	endif
	float4 specularBrushTexColor = tex2D(_SpecularBrushTex, TRANSFORM_TEX(i.uv0, _SpecularBrushTex)) * _SpecularBrushStrength;

	float specularPrimaryMask = specularBrushTexColor.r;
#	ifdef _ITS_SPECULAR_DOUBLE
	float specularSecondaryMask = specularBrushTexColor.g;
#	endif
#	ifdef _ITS_SPECULAR_STANDARD	// Standard specular
#		ifdef _ITS_ANTI_ALIASING
	float specularWidth = fwidth(specularAttenuation);
	specularPrimaryColor *= lerp(pow(specularAttenuation, _SpecularPrimaryPower) * _SpecularPrimaryStrength, lerp(0, 1, smoothstep(-specularWidth, specularWidth, specularAttenuation - _SpecularPrimaryStrength)), _SpecularPrimaryToon) * specularPrimaryMask;
#			ifdef _ITS_SPECULAR_DOUBLE
	specularSecondaryColor *= lerp(pow(specularAttenuation, _SpecularSecondaryPower) * _SpecularSecondaryStrength, lerp(0, 1, smoothstep(-specularWidth, specularWidth, specularAttenuation - _SpecularSecondaryStrength)), _SpecularSecondaryToon) * specularSecondaryMask;
#			endif
#		else
	specularPrimaryColor *= lerp(pow(specularAttenuation, _SpecularPrimaryPower) * _SpecularPrimaryStrength, (1.0 - step(specularAttenuation, (1.0 - _SpecularPrimaryStrength))), _SpecularPrimaryToon) * specularPrimaryMask;
#			ifdef _ITS_SPECULAR_DOUBLE
	specularSecondaryColor *= lerp(pow(specularAttenuation, _SpecularSecondaryPower) * _SpecularSecondaryStrength, (1.0 - step(specularAttenuation, (1.0 - _SpecularSecondaryStrength))), _SpecularSecondaryToon) * specularSecondaryMask;
#			endif
#		endif
#	elif _ITS_SPECULAR_ANISOTROPIC	// Anisotropic specular
	float3 anisotropicLightDirection = normalize(mul(lightDirection/**-1*/, tangentTransform));
#		ifdef _ITS_SHIFT_TEX
	float4 shiftTexValue = tex2D(_ShiftTex, TRANSFORM_TEX(i.uv0, _ShiftTex));
#		else
	float4 shiftTexValue = float4(1, 1, 1, 1);
#endif
	float jitter = _SpecularJitter * 0.5;
	float shiftValue = lerp((0.5 - jitter), (0.5 + jitter), shiftTexValue) - _SpecularShift;
	specularPrimaryColor *= AnisotropicSpecular(normalize(i.bitangent + (shiftValue + _SpecularPrimaryShift) * i.normal), viewDirection, anisotropicLightDirection, _SpecularPrimaryPower, _SpecularPrimaryStrength) * specularPrimaryMask;
#			ifdef _ITS_SPECULAR_DOUBLE
	specularSecondaryColor *= AnisotropicSpecular(normalize(i.bitangent + (shiftValue + _SpecularSecondaryShift) * i.normal), viewDirection, anisotropicLightDirection, _SpecularSecondaryPower, _SpecularSecondaryStrength) * specularSecondaryMask;
#			endif
#		ifdef _ITS_GLITTER_TEX
	float4 glitterTexValue = tex2D(_GlitterTex, TRANSFORM_TEX(i.uv0, _GlitterTex));
	specularPrimaryColor *= glitterTexValue.r * _SpecularPrimaryGlitter;
#			ifdef _ITS_SPECULAR_DOUBLE
	specularSecondaryColor *= glitterTexValue.r * _SpecularSecondaryGlitter;
#			endif
#		endif
#	elif _ITS_SPECULAR_RAMP			// Ramp sepcular
	float4 specularRamp = tex2D(_SpecularRampTex, float2(dotHN, rimAttenuation));
	specularPrimaryColor *= specularRamp.r * _SpecularPrimaryStrength * specularPrimaryMask;
#		ifdef _ITS_SPECULAR_DOUBLE
	specularSecondaryColor *= specularRamp.g * _SpecularSecondaryStrength * specularSecondaryMask;
#		endif
#	endif

	color += saturate(lerp(specularPrimaryColor, specularPrimaryColor*((1.0 - shadowAttenuation) + (shadowAttenuation*_SpecularPrimaryShadowThreshold)), _SpecularPrimaryOnShadow));
#	ifdef _ITS_SPECULAR_DOUBLE
	color += saturate(lerp(specularSecondaryColor, specularSecondaryColor*((1.0 - shadowAttenuation) + (shadowAttenuation*_SpecularSecondaryShadowThreshold)), _SpecularSecondaryOnShadow));
#	endif
#endif

	// Rim light
#ifdef _ITS_RIM_LIGHT
	float3 rimColor = _RimColor.rgb;
	rimColor = lerp(rimColor, rimColor * lightColor.rgb, _RimLightColor);
	float3 rimAntipodeanColor = lerp(_RimAntipodeanColor, _RimAntipodeanColor * lightColor.rgb, _RimAntipodeanLightColor);

#ifdef _ITS_RIM_ENVIRONMENT
	half3 reflectionDir = reflect(-viewDirection, i.normal);
	float3 envSample = DecodeHDR(UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectionDir), unity_SpecCube0_HDR);
	rimColor *= envSample;
	rimAntipodeanColor *= envSample;
#endif

	float4 rimBrushTexColor = tex2D(_RimBrushTex, TRANSFORM_TEX(i.uv0, _RimBrushTex)) + _RimBrushThreshold;
	float rimPower = pow(rimAttenuation, exp2(lerp(3, 0, _RimPower)));							 // need optimization
	float rimAntipodeanPower = pow(rimAttenuation, exp2(lerp(3, 0, _RimAntipodeanPower)));		 // need optimization
#ifdef _ITS_ANTI_ALIASING
	float powerWidth = fwidth(rimPower);
	float rimMask = saturate(lerp(((rimPower - _RimInsideMask) / (1.0 - _RimInsideMask)), lerp(0, 1, smoothstep(-powerWidth, powerWidth, rimPower - _RimInsideMask)), _RimToon));
	float antipodeanPowerWidth = fwidth(rimPower);
	float rimAntipodeanMask = saturate(lerp(((rimAntipodeanPower - _RimInsideMask) / (1.0 - _RimInsideMask)), lerp(0, 1, smoothstep(-antipodeanPowerWidth, antipodeanPowerWidth, rimAntipodeanPower - _RimInsideMask)), _RimAntipodeanToon) - (saturate(halfLambert) + _RimLightMaskThreshold));
#else
	float rimMask = saturate(lerp(((rimPower - _RimInsideMask) / (1.0 - _RimInsideMask)), step(_RimInsideMask, rimPower), _RimToon));
	float rimAntipodeanMask = saturate(lerp(((rimAntipodeanPower - _RimInsideMask) / (1.0 - _RimInsideMask)), step(_RimInsideMask, rimAntipodeanPower), _RimAntipodeanToon) - (saturate(halfLambert) + _RimLightMaskThreshold));
#endif
	rimColor = lerp(rimColor * rimMask, rimColor * saturate((rimMask - ((1.0 - halfLambert) + _RimLightMaskThreshold))), _RimLightMask);
	rimColor = lerp(rimColor, rimColor + rimAntipodeanColor * rimAntipodeanMask, _RimAntipodean);
	rimColor *= rimBrushTexColor.r;

	color += rimColor;
#endif

	// MatCap
#ifdef _ITS_MATCAP
	float matcapUVRotateAngle = (_MatCapUVRotate*3.141592654);
	float matcapUVRotateSpeed = 1.0;
	float matcapUVRotateCOS = cos(matcapUVRotateSpeed*matcapUVRotateAngle);
	float matcapUVRotateSIN = sin(matcapUVRotateSpeed*matcapUVRotateAngle);
	float2 matcapUVRotatePIV = float2(0.5, 0.5);
	float3 matcapNormal = i.normal;
#	ifdef _ITS_MATCAP_NORMAL_TEX
	float matcapNormalUVRotateAngle = (_MatCapNormalUVRotate*3.141592654);
	float matcapNormalUVRotateSpeed = 1.0;
	float matcapNormalUVRotateCOS = cos(matcapNormalUVRotateSpeed*matcapNormalUVRotateAngle);
	float matcapNormalUVRotateSIN = sin(matcapNormalUVRotateSpeed*matcapNormalUVRotateAngle);
	float2 matcapNormalUVRotatePIV = float2(0.5, 0.5);
	float2 matcapNormalUVRotate = (mul(i.uv0 - matcapNormalUVRotatePIV, float2x2(matcapNormalUVRotateCOS, -matcapNormalUVRotateSIN, matcapNormalUVRotateSIN, matcapNormalUVRotateCOS)) + matcapNormalUVRotatePIV);
	float3 matcaoNormalValue = UnpackNormal(tex2D(_MatCapNormalTex, matcapNormalUVRotate));
	matcapNormal = mul(matcaoNormalValue.rgb, tangentTransform).xyz.rgb;
#	endif
	float2 matcapUVRotate = (mul(((mul(UNITY_MATRIX_V, float4(matcapNormal, 0)).xyz.rgb.rg*0.5 + 0.5) - _MatCapUVThreshold) / (1.0 - 2 * _MatCapUVThreshold) - matcapUVRotatePIV, float2x2(matcapUVRotateCOS, -matcapUVRotateSIN, matcapUVRotateSIN, matcapUVRotateCOS)) + matcapUVRotatePIV);
	float3 matcapColor = tex2D(_MatCapTex, matcapUVRotate).rgb * _MatCapColor.rgb;
	matcapColor = lerp(matcapColor, matcapColor*lightColor.rgb, _MatCapLightColor);
	matcapColor = saturate(lerp(matcapColor, matcapColor*((1.0 - shadowAttenuation) + (shadowAttenuation*_MatCapShadowThreshold)), _MatCapOnShadow));
	color = lerp(color * matcapColor, color + matcapColor, _MatCapBlendAdd);
#endif

	// Emissive
#ifdef _ITS_EMISSIVE
	color += tex2D(_EmissiveTex, TRANSFORM_TEX(i.uv0, _EmissiveTex)).rgb * _EmissiveColor.rgb;
#endif

	// GI
#ifdef _ITS_GI
	color += saturate(ShadeSH9(float4(i.normal, 1))*_GIThreshold);
#endif

#ifdef _ITS_TRANSPARENCY
	alpha = saturate((alpha + _Transparency));
#else
	alpha = 1.0;
#endif
	fixed4 finalRGBA = fixed4(color, alpha);

	UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
	return finalRGBA;
}