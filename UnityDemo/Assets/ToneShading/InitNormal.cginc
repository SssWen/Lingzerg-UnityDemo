#if !defined(NORMAL_INCLUDED)
#define NORMAL_INCLUDED


float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

float3 GetTangentSpaceNormal(Interpolators i) {
	float3 normal = float3(0, 0, 1);
#if defined(_NORMAL_MAP)
	normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
#endif
#if defined(_DETAIL_NORMAL_MAP)
	float3 detailNormal =
		UnpackScaleNormal(
			tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale
		);
	detailNormal = lerp(float3(0, 0, 1), detailNormal, GetDetailMask(i));
	normal = BlendNormals(normal, detailNormal);
#endif
	return normal;
}

void InitializeFragmentNormal(inout Interpolators i) {
	float3 tangentSpaceNormal = GetTangentSpaceNormal(i);
#if defined(BINORMAL_PER_FRAGMENT)
	float3 binormal =
		CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
#else
	float3 binormal = i.binormal;
#endif

	i.normal = normalize(
		tangentSpaceNormal.x * i.tangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * i.normal
	);
}

#endif