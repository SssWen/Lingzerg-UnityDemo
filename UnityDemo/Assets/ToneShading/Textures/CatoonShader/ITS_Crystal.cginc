// UCTS_Crystal.cginc
// 2019/05/23 Create by Grissom Lee mail:xdonlee@163.com
//

uniform float4 _MainColor;
uniform fixed _LightColor;
uniform samplerCUBE _RefractTex;
#ifdef _ITS_NORMAL_TEX
uniform sampler2D _NormalTex; uniform float4 _NormalTex_ST;
#endif
#ifdef _ITS_REFLECT_TEX
uniform samplerCUBE _ReflectTex;
#endif
uniform float _ReflectStrength;
#ifdef _ITS_FRESNEL_TEX
uniform sampler2D _FresnelTex;
#endif
uniform float _DispersionStrength;
uniform float3 _RGBRefractIndex;

// Specular
#ifdef _ITS_SPECULAR
uniform float4 _SpecularColor;
uniform float _SpecularPower;
uniform float _SpecularStrength;
uniform fixed _SpecularToon;
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

inline float3 InnerRefract(float3 I, float3 N, float ETA)
{
	float c1 = -dot(I, N);
	float cs2 = 1.0f - ETA * ETA*(1.0f - c1 * c1);
	cs2 = abs(cs2);
	return (ETA*I + (ETA*c1 - sqrt(cs2))*N);
}

float4 frag(VertexOutput i) : SV_TARGET
{
	// Calulate tangent space
	float3x3 tangentTransform = float3x3(i.tangent, i.bitangent, i.normal);
#ifdef _ITS_NORMAL_TEX
	i.normal = normalize(mul(UnpackNormal(tex2D(_NormalTex, TRANSFORM_TEX(i.uv0, _NormalTex))).rgb, tangentTransform));
#endif

	// Calulate light direction and color
	float3 defaultLightDirection = float3(0.0, 0.1, 0.1);
	float3 defaultLightColor = float3(0.5, 0.5, 0.5);
	float3 lightDirection = normalize(lerp(defaultLightDirection, _WorldSpaceLightPos0.xyz, any(_WorldSpaceLightPos0.xyz)));
	float3 lightColor = lerp(defaultLightColor, _LightColor0.rgb, any(_LightColor0.rgb));

	// Calulate view direction
	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

	// Back face
#ifdef _ITS_CRYSTAL_INNER
	float3 refractDirection = normalize(InnerRefract(-viewDirection, i.normal, _RGBRefractIndex.r));
	float3 reflectDirection = normalize(reflect(-viewDirection, i.normal));
	float3 refractColor = texCUBE(_RefractTex, refractDirection).rgb;
	float3 reflectColor = texCUBE(_RefractTex, reflectDirection).rgb;
	float3 color = (refractColor + reflectColor) * 0.6 * _MainColor.rgb;
	color = lerp(color, color * lightColor.rgb, _LightColor);
#elif _ITS_CRYSTAL_OUTTER	// Front face
	float dotNV = saturate(dot(i.normal, viewDirection));
	float rimAttenuation = 1 - dotNV;
	// Fefract and reflect direction
	float3 refractDirection = normalize(refract(-viewDirection, i.normal, 1 / _RGBRefractIndex.r));
	float3 refractDirectionG = refract(-viewDirection, i.normal, 1 / _RGBRefractIndex.g);
	float3 refractDirectionB = refract(-viewDirection, i.normal, 1 / _RGBRefractIndex.b);
	float3 reflectDirection = normalize(reflect(-viewDirection, i.normal));
#	ifdef _ITS_FRESNEL_TEX
	float fresnel = tex2D(_FresnelTex, half2(dotNV, 0.5f)).r;
#	else
	float fresnel = pow(rimAttenuation, 2.0f);
#	endif
#	ifdef _ITS_REFLECT_TEX
	float3 reflectColor = texCUBE(_ReflectTex, reflectDirection).rgb;
#	else
	float3 reflectColor = DecodeHDR(UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDirection), unity_SpecCube0_HDR);
#	endif
	float3 refractColor = float3(texCUBE(_RefractTex, refractDirection).r,
		texCUBE(_RefractTex, refractDirectionG).g,
		texCUBE(_RefractTex, refractDirectionB).b) * _MainColor.rgb;
	float3 color = lerp(refractColor, refractColor*lightColor, _LightColor) + reflectColor * fresnel * _ReflectStrength;
#endif
	
	// Specular
#if defined(_ITS_CRYSTAL_OUTTER) && defined(_ITS_SPECULAR)
	float specularAttenuation = saturate(dot(reflectDirection, lightDirection));
#	ifdef _ITS_ANTI_ALIASING
	float specularWidth = fwidth(specularAttenuation);
	float3 specularColor = lerp(_SpecularStrength*pow(specularAttenuation, _SpecularPower), lerp(0, 1, smoothstep(-specularWidth, specularWidth, specularAttenuation - _SpecularStrength)), _SpecularToon) * _SpecularColor;
#	else
	float3 specularColor = lerp(_SpecularStrength*pow(specularAttenuation, _SpecularPower), (1.0 - step(specularAttenuation, (1.0 - _SpecularStrength))), _SpecularToon) * _SpecularColor;
#	endif
	specularColor = lerp(specularColor, specularColor * lightColor, _LightColor);
	color += specularColor;
#endif

	// Emissive
#ifdef _ITS_EMISSIVE
	color += tex2D(_EmissiveTex, TRANSFORM_TEX(i.uv0, _EmissiveTex)).rgb * _EmissiveColor.rgb;
#endif

	// GI
#if defined(_ITS_CRYSTAL_OUTTER) && defined(_ITS_GI)
	color += saturate(ShadeSH9(float4(i.normal, 1))*_GIThreshold);
#endif

	fixed4 finalRGBA = fixed4(color, 1);

	UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
	return finalRGBA;
}