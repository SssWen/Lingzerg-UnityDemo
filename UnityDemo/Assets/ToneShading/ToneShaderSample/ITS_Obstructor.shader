Shader "IllustractionToonShader/ITS_Obstructor" 
{
	Properties
	{
		_ShadowColor("Shadow Color", Color) = (0.1, 0.1, 0.1, 0.53)
	}

	SubShader 
	{
		Tags { "Queue" = "Geometry-10" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
		Lighting Off
		Pass 
		{ 
			ZTest LEqual
			ZWrite On
			ColorMask 0
		}

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				SHADOW_COORDS(2)
			};

			fixed4 _ShadowColor;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed atten = SHADOW_ATTENUATION(i);
				float alpha = saturate(1 - atten)*_ShadowColor.a;
				clip(alpha - 0.0000000001);
				return fixed4(_ShadowColor.rgb, alpha);
			}
			ENDCG
		}
	}

	FallBack "VertexLit"
}