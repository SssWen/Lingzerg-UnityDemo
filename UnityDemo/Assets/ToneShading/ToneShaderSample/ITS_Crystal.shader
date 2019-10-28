Shader "IllustractionToonShader/ITS_Crystal"
{
	Properties
	{
		_MainColor("Main Color", Color) = (1,1,1,1)
		[MaterialToggle] _LightColor("Light Color", Float) = 1

		_RefractTex("RefractCube", Cube) = "white"{}

		[Toggle(_ITS_NORMAL_TEX)] _ITS_NORMAL_TEX("Use Normal Texture", Float) = 0
		_NormalTex("Normal Texture", 2D) = "white" {}

		[Toggle(_ITS_REFLECT_TEX)] _ITS_REFLECT_TEX("Use Reflect Texture", Float) = 0
		_ReflectTex("Reflect Texture", Cube) = "white" {}
		_ReflectStrength("Reflect Strength", Float) = 0.17

		[Toggle(_ITS_FRESNEL_TEX)] _ITS_FRESNEL_TEX("Use Fresnel Texture", Float) = 0
		_FresnelTex("Fresnel Texture", 2D) = "white" {}

		_RGBRefractIndex("RGB Refract Index", Vector) = (2.40, 2.41, 2.417,0) // RGB light refract index in diamond

		// Specular
		[Toggle(_ITS_SPECULAR)] _ITS_SPECULAR("Enable Specular", Float) = 0
		_SpecularColor("Specular Color", Color) = (1,1,1,1)
		_SpecularPower("Specular Power", Float) = 8
		_SpecularStrength("Specular Strength", Float) = 1
		[MaterialToggle]_SpecularToon("Specular Toon", Float) = 0

		// Emissive
		[Toggle(_ITS_EMISSIVE)] _ITS_EMISSIVE("Enable Emissive", Float) = 0
		_EmissiveTex("Emissive Texture", 2D) = "white" {}
		[HDR]_EmissiveColor("Emissive Color", Color) = (0,0,0,1)

		// GI
		[Toggle(_ITS_GI)] _ITS_GI("Enable GI", Float) = 0
		_GIThreshold("GI Threshold", Range(0, 1)) = 0

		// Outline
		[KeywordEnum(NORMAL, POSITION)] _ITS_OUTLINE("Outline Mode", Float) = 0
		_OutlineWidth("Outline Width", Float) = 1
		_OutlineColor("Outline Color", Color) = (0.5,0.5,0.5,1)
		[KeywordEnum(NONE, NOLIGHT, LIGHT)] _ITS_OUTLINE_BLEND_MAIN("Outline Blend Main Texture Mode", Float) = 0
		[Toggle(_ITS_OUTLINE_MASK_TEX)] _ITS_OUTLINE_MASK_TEX("Outline Use Mask Texture", Float) = 0
		_OutlineMaskTex("Outline Mask Texture", 2D) = "white" {}
		[Toggle(_ITS_OUTLINE_COLOR_TEX)] _ITS_OUTLINE_COLOR_TEX("Outline Use Color Texture", Float) = 0
		_OutlineColorTex("Outline Color Texture", 2D) = "white" {}
		_FarthestDistance("Outline Farthest Distance", Float) = 10
		_NearestDistance("Outline Nearest Distance", Float) = 0.5
		_OffsetZ("Outline Offset Camera Z", Float) = 0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
		Pass
		{
			Name "Outline"
			Tags { }
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal xboxone ps4 switch
			#pragma target 3.0
			#pragma multi_compile _ITS_CLIPPING_NONE
			#pragma shader_feature _ITS_OUTLINE_BLEND_MAIN_NONE _ITS_OUTLINE_BLEND_MAIN_NOLIGHT _ITS_OUTLINE_BLEND_MAIN_LIGHT 
			#pragma shader_feature _ITS_OUTLINE_MASK_TEX
			#pragma shader_feature _ITS_OUTLINE_COLOR_TEX
			#pragma shader_feature _ITS_OUTLINE_NORMAL _ITS_OUTLINE_POSITION
			#include "ITS_Outline.cginc"
			ENDCG
		}

		Pass
		{
			Name "BackFace"
			Cull Front
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
			#pragma multi_compile_fwdbase
			#pragma multi_compile _ITS_CLIPPING_NONE
			#pragma multi_compile _ITS_CRYSTAL_INNER
			#pragma shader_feature _ITS_REFLECT_TEX
			#pragma shader_feature _ITS_FRESNEL_TEX
			#pragma shader_feature _ITS_SPECULAR
			#pragma shader_feature _ITS_EMISSIVE
			#pragma shader_feature _ITS_GI
			#include "ITS_Crystal.cginc"
			ENDCG
		}

		Pass
		{
			Name "FrontFace"
			ZWrite on
			Blend srccolor dstcolor
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
			#pragma multi_compile_fwdbase
			#pragma multi_compile _ITS_CLIPPING_NONE
			#pragma multi_compile _ITS_CRYSTAL_OUTTER
			#pragma shader_feature _ITS_REFLECT_TEX
			#pragma shader_feature _ITS_FRESNEL_TEX
			#pragma shader_feature _ITS_SPECULAR
			#pragma shader_feature _ITS_EMISSIVE
			#pragma shader_feature _ITS_GI
			#include "ITS_Crystal.cginc"
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
			#pragma multi_compile _ITS_CLIPPING_NONE
			#include "ITS_ShadowCaster.cginc"
			ENDCG
		}
	}

	FallBack "VertexLit"
}