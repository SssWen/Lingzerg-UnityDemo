Shader "IllustractionToonShader/ITS_Standard (Transpancy No Outline)"
{
	Properties
	{
		_Transparency("Transparency", Range(-1, 1)) = 0

		_MainTex("Main Texture", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,1,1,1)

		[Toggle(_ITS_NORMAL_TEX)] _ITS_NORMAL_TEX("Use Normal Texture", Float) = 0
		_NormalTex("Normal Texture", 2D) = "white" {}

		// Diffuse
		[MaterialToggle] _DiffuseLightColor("Diffuse Light Color", Float) = 1
		[Toggle(_ITS_RAMP_TEX)] _ITS_RAMP_TEX("Use Ramp Texture", Float) = 0
		_DiffuseRampTex("Diffuse Ramp Texture", 2D) = "white" {} // Three Channel (Low, Middle, High)

		_DiffuseBrushTex("Diffuse Brush Texture", 2D) = "white" {} // Three Channel (Low, Middle, High)
		_DiffuseBrushStrength("Diffuse Brush Strength", Range(0, 5)) = 1

		[Toggle(_ITS_DIFFUSE_TEX)] _ITS_DIFFUSE_TEX("Use Diffuse Texture", Float) = 0
		_DiffuseLowTex("Diffuse Low Texture", 2D) = "white" {}
		_DiffuseLowColor("Diffuse Low Color", Color) = (1,1,1,1)
		_DiffuseMiddleTex("Diffuse Middle Texture", 2D) = "white" {}
		_DiffuseMiddleColor("Diffuse Middle Color", Color) = (1,1,1,1)
		_DiffuseHighTex("Diffuse High Texture", 2D) = "white" {}
		_DiffuseHighColor("Diffuse High Color", Color) = (1,1,1,1)

		_DiffuseLowThreshold("Diffuse Low Threshold", Range(0, 1)) = 0.6
		_DiffuseLowSmoothness("Diffuse Low Smoothness", Range(0.0001, 1)) = 0.0001
		_DiffuseMiddleThreshold("Diffuse Middle Threshold", Range(0, 1)) = 0.4
		_DiffuseMiddleSmoothness("Diffuse Middle Smoothness", Range(0.0001, 1)) = 0.0001
		_DiffuseHighThreshold("Diffuse High Threshold", Range(0, 1)) = 0.2
		_DiffuseHighSmoothness("Diffuse High Smoothness", Range(0.0001, 1)) = 0.0001

		[MaterialToggle] _ShadowToMain("Shadow To Main", Float) = 1
		_ShadowThreshold("Shadow Threshold", Range(-0.5, 0.5)) = 0

		// Specular
		[KeywordEnum(NONE, STANDARD, RAMP, ANISOTROPIC)] _ITS_SPECULAR("Specular Mode", Float) = 0
		[Toggle(_ITS_SPECULAR_DOUBLE)] _ITS_SPECULAR_DOUBLE("Specular Double", Float) = 0
		[MaterialToggle] _SpecularLightColor("Specular Light Color", Float) = 1
		_SpecularRampTex("Specular Ramp Texture", 2D) = "white" {} // Two Channel (Low, High)

		_SpecularBrushTex("Specular Brush Texture", 2D) = "white" {}
		_SpecularBrushStrength("Specular Brush Strength", Float) = 1

		_SpecularShift("Specular Shift", Float) = 0.8
		_SpecularJitter("Specular Jitter", Float) = 1

		// Shift Texture
		[Toggle(_ITS_SHIFT_TEX)] _ITS_SHIFT_TEX("Use Shift Texture", Float) = 0
		_ShiftTex("Shift Texture", 2D) = "white" {}

		// Glitter Texture
		[Toggle(_ITS_GLITTER_TEX)] _ITS_GLITTER_TEX("Use Glitter Texture", Float) = 0
		_GlitterTex("Glitter Texture", 2D) = "white" {}

		[Toggle(_ITS_SPECULAR_TEX)] _ITS_SPECULAR_TEX("Use Specular Texture", Float) = 0
		_SpecularPrimaryTex("Specular Primary Texture", 2D) = "white" {}
		_SpecularPrimaryColor("Specular Primary Color", Color) = (1,1,1,1)
		_SpecularPrimaryPower("Specular Primary Power", Float) = 0
		_SpecularPrimaryStrength("Specular Primary Strength", Float) = 0
		_SpecularPrimaryShift("Specular Primary Shift", Float) = 0
		_SpecularPrimaryGlitter("Specular Primary Glitter", Float) = 0
		[MaterialToggle]_SpecularPrimaryOnShadow("Specular Primary On Shadow", Float) = 0
		_SpecularPrimaryShadowThreshold("Specular Shadow Primary Threshold", Range(0, 1)) = 0
		[MaterialToggle]_SpecularPrimaryToon("Specular Primary Toon", Float) = 0
		_SpecularSecondaryTex("Specular Secondary Texture", 2D) = "white" {}
		_SpecularSecondaryColor("Specular Secondary Color", Color) = (1,1,1,1)
		_SpecularSecondaryPower("Specular Secondary Power", Float) = 0
		_SpecularSecondaryStrength("Specular Secondary Strength", Float) = 0
		_SpecularSecondaryShift("Specular Secondary Shift", Float) = 0
		_SpecularSecondaryGlitter("Specular Secondary Glitter", Float) = 0
		[MaterialToggle]_SpecularSecondaryOnShadow("Specular Secondary On Shadow", Float) = 0
		_SpecularSecondaryShadowThreshold("Specular Secondary Shadow Threshold", Range(0, 1)) = 0
		[MaterialToggle]_SpecularSecondaryToon("Specular Secondary Toon", Float) = 0

		// Rim Light
		[Toggle(_ITS_RIM_LIGHT)] _ITS_RIM_LIGHT("Enable Rim Light", Float) = 0
		[Toggle(_ITS_RIM_ENVIRONMENT)] _ITS_RIM_ENVIRONMENT("Enable Rim Environment", Float) = 0
		_RimBrushTex("Rim Brush Texture", 2D) = "white" {}
		_RimBrushThreshold("Rim Brush Threshold", Range(-1, 1)) = 1

		_RimColor("Rim Color", Color) = (1,1,1,1)
		[MaterialToggle] _RimLightColor("Rim Light Color", Float) = 1
		_RimPower("Rim Power", Range(0, 1)) = 0.1
		_RimInsideMask("Rim Inside Mask", Range(0.0001, 1)) = 0.0001
		[MaterialToggle] _RimToon("Rim Toon", Float) = 0

		[MaterialToggle] _RimLightMask("Rim Direction Mask", Float) = 0
		_RimLightMaskThreshold("Rim Direction Mask Threshold", Range(0, 0.5)) = 0

		[MaterialToggle] _RimAntipodean("Rim Antipodean", Float) = 0
		_RimAntipodeanColor("Rim Antipodean Color", Color) = (1,1,1,1)
		[MaterialToggle] _RimAntipodeanLightColor("Rim Antipodean Light Color", Float) = 1
		_RimAntipodeanPower("Rim Antipodean Power", Range(0, 1)) = 0.1
		[MaterialToggle] _RimAntipodeanToon("Rim Antipodean Toon", Float) = 0

		// MatCap
		[Toggle(_ITS_MATCAP)] _ITS_MATCAP("Enable MatCap", Float) = 0
		_MatCapTex("MatCap Texture", 2D) = "black" {}
		_MatCapColor("MatCap Color", Color) = (1,1,1,1)
		[MaterialToggle] _MatCapLightColor("MatCap Light Color", Float) = 1
		[MaterialToggle] _MatCapBlendAdd("MatCap Blend Add", Float) = 1
		_MatCapUVThreshold("MatCap UV Threshold", Range(-0.5, 0.5)) = 0
		_MatCapUVRotate("MatCap UV Rotate", Range(-1, 1)) = 0
		[Toggle(_ITS_MATCAP_NORMAL_TEX)] _ITS_MATCAP_NORMAL_TEX("MatCap Use Normal Texture", Float) = 0
		_MatCapNormalTex("MatCap Normal Texture", 2D) = "bump" {}
		_MatCapNormalUVRotate("Rotate_NormalMapForMatCapUV", Range(-1, 1)) = 0
		[MaterialToggle] _MatCapOnShadow("MatCap On Shadow", Float) = 0
		_MatCapShadowThreshold("MatCap Shadow Threshold", Range(0, 1)) = 0

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
		Tags{ "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" }

		Pass
		{
			Name "ForwardBase"
			Tags{ "LightMode" = "ForwardBase" }
			Cull Off
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

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
			#pragma multi_compile _ITS_TRANSPARENCY
			#pragma multi_compile _ITS_PASS_FORWARD_BASE
			#pragma multi_compile _ITS_ANTI_ALIASING
			#pragma shader_feature _ITS_NORMAL_TEX
			#pragma shader_feature _ITS_RAMP_TEX
			#pragma shader_feature _ITS_DIFFUSE_TEX
			#pragma shader_feature _ITS_SPECULAR_TEX
			#pragma shader_feature _ITS_SHIFT_TEX
			#pragma shader_feature _ITS_GLITTER_TEX
			#pragma shader_feature _ITS_RIM_LIGHT
			#pragma shader_feature _ITS_RIM_ENVIRONMENT
			#pragma shader_feature _ITS_MATCAP
			#pragma shader_feature _ITS_MATCAP_NORMAL_TEX
			#pragma shader_feature _ITS_EMISSIVE
			#pragma shader_feature _ITS_GI
			#pragma shader_feature _ITS_CLIPPING_NONE _ITS_CLIPPING_ALPHA _ITS_CLIPPING_MASK
			#pragma shader_feature _ITS_SPECULAR_NONE _ITS_SPECULAR_STANDARD _ITS_SPECULAR_RAMP _ITS_SPECULAR_ANISOTROPIC
			#pragma shader_feature _ITS_SPECULAR_DOUBLE
			#include "ITS_Standard.cginc"
			ENDCG
		}

		Pass
		{
			Name "ForwardAdd"
			Tags{ "LightMode" = "ForwardAdd" }
			Cull Off
			ZWrite Off
			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fog
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal xboxone ps4 switch
			#pragma target 3.0
			#pragma multi_compile _ITS_TRANSPARENCY
			#pragma multi_compile _ITS_PASS_FORWARD_ADD
			#pragma multi_compile _ITS_ANTI_ALIASING
			#pragma shader_feature _ITS_NORMAL_TEX
			#pragma shader_feature _ITS_RAMP_TEX
			#pragma shader_feature _ITS_DIFFUSE_TEX
			#pragma shader_feature _ITS_SPECULAR_TEX
			#pragma shader_feature _ITS_SHIFT_TEX
			#pragma shader_feature _ITS_GLITTER_TEX
			#pragma shader_feature _ITS_RIM_LIGHT
			#pragma shader_feature _ITS_RIM_ENVIRONMENT
			#pragma shader_feature _ITS_MATCAP
			#pragma shader_feature _ITS_MATCAP_NORMAL_TEX
			#pragma shader_feature _ITS_EMISSIVE
			#pragma shader_feature _ITS_GI
			#pragma shader_feature _ITS_CLIPPING_NONE _ITS_CLIPPING_ALPHA _ITS_CLIPPING_MASK
			#pragma shader_feature _ITS_SPECULAR_NONE _ITS_SPECULAR_STANDARD _ITS_SPECULAR_RAMP _ITS_SPECULAR_ANISOTROPIC
			#pragma shader_feature _ITS_SPECULAR_DOUBLE
			#include "ITS_Standard.cginc"
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
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
			#pragma shader_feature _ITS_CLIPPING_NONE _ITS_CLIPPING_ALPHA _ITS_CLIPPING_MASK
			#include "ITS_ShadowCaster.cginc"
			ENDCG
		}
	}

	FallBack "VertexLit"
}