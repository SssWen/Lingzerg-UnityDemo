Shader "IllustractionToonShader/ITS_Eye"
{
	Properties
	{
		[Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2  //OFF/FRONT/BACK

		_MainTex("Main Texture", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,1,1,1)
		[MaterialToggle] _MainLightColor("Light Color", Float) = 1

		[Toggle(_ITS_MASK_TEX)] _ITS_MASK_TEX("Use Mask Texture", Float) = 0
		_MaskTex("Texture", 2D) = "white" {}

		[Toggle(_ITS_NORMAL_TEX)] _ITS_NORMAL_TEX("Use Normal Texture", Float) = 0
		_NormalTex("Normal Texture", 2D) = "white" {}

		// Caustic
		[Toggle(_ITS_CAUSTIC)] _ITS_CAUSTIC("Enable Caustic", Float) = 0
		[MaterialToggle] _CausticLightColor("Caustic Light Color", Float) = 1
		_CausticTex("Texture", 2D) = "white" {}
		_CausticColor("Caustic Color", Color) = (1,1,1,1)
		_CausticPower("Caustic Power",Float) = 3

		_Refraction("Index Of Refraction", Range(0.0,2.0)) = 0.568
		_EyeForward("Eye Forward",Vector) = (0,0,1)

		// Specular
		[Toggle(_ITS_SPECULAR)] _ITS_SPECULAR("Enable Specular", Float) = 0
		[MaterialToggle] _SpecularLightColor("Specular Light Color", Float) = 1
		_SpecularTex("Specular Texture", 2D) = "white" {}
		_SpecularColor("Specular Color", Color) = (1,1,1,1)
		_SpecularRotate("Specular Rotate",Float) = 3

		// Emissive
		[Toggle(_ITS_EMISSIVE)] _ITS_EMISSIVE("Enable Emissive", Float) = 0
		_EmissiveTex("Emissive Texture", 2D) = "white" {}
		[HDR]_EmissiveColor("Emissive Color", Color) = (0,0,0,1)

		// GI
		[Toggle(_ITS_GI)] _ITS_GI("Enable GI", Float) = 0
		_GIThreshold("GI Threshold", Range(0, 1)) = 0

		// Clipping
		[KeywordEnum(NONE, ALPHA, MASK)] _ITS_CLIPPING("Clipping Mode", Float) = 0
		_ClippingMask("Clipping Mask", 2D) = "white" {}
		[MaterialToggle] _ClippingInverse("Clipping Inverse", Float) = 0
		_ClippingLevel("Clipping Level", Range(0, 1)) = 0
	}

	SubShader
	{
		Pass
		{
			Name "ForwardBase"
			Tags{ "LightMode" = "ForwardBase" }
			Cull[_CullMode]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile_fog
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal xboxone ps4 switch
			#pragma target 3.0
			#pragma multi_compile _ITS_PASS_FORWARD_BASE
			#pragma shader_feature _ITS_MASK_TEX
			#pragma shader_feature _ITS_NORMAL_TEX
			#pragma shader_feature _ITS_CAUSTIC
			#pragma shader_feature _ITS_SPECULAR
			#pragma shader_feature _ITS_EMISSIVE
			#pragma shader_feature _ITS_GI
			#pragma shader_feature _ITS_CLIPPING_NONE _ITS_CLIPPING_MASK
			#include "ITS_Eye.cginc"
			ENDCG
		}

		Pass
		{
			Name "ForwardAdd"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend One One
			Cull[_CullMode]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fog
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal xboxone ps4 switch
			#pragma target 3.0
			#pragma multi_compile _ITS_PASS_FORWARD_ADD
			#pragma shader_feature _ITS_MASK_TEX
			#pragma shader_feature _ITS_NORMAL_TEX
			#pragma shader_feature _ITS_CAUSTIC
			#pragma shader_feature _ITS_SPECULAR
			#pragma shader_feature _ITS_EMISSIVE
			#pragma shader_feature _ITS_GI
			#pragma shader_feature _ITS_CLIPPING_NONE _ITS_CLIPPING_MASK
			#include "ITS_Eye.cginc"
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			Offset 1, 1
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_fog
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal xboxone ps4 switch
			#pragma target 3.0
			#pragma shader_feature _ITS_CLIPPING_NONE _ITS_CLIPPING_MASK
			#include "ITS_ShadowCaster.cginc"
			ENDCG
		}
	}

	FallBack "VertexLit"
}