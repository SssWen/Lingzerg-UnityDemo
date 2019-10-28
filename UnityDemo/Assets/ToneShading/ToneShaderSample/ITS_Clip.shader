Shader "IllustractionToonShader/ITS_Clip" 
{
	Properties
	{
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#pragma multi_compile_fwdbase
			#pragma only_renderers d3d9 d3d11 glcore gles
			#pragma target 3.0

			struct VertexInput 
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
			};

			struct VertexOutput 
			{
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
			};

			VertexOutput vert(VertexInput v) 
			{
				VertexOutput o = (VertexOutput)0;
				o.uv0 = v.texcoord0;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
			float4 frag(VertexOutput i) : COLOR
			{
				clip(0.0f);
				return fixed4(0.0f,0.0f,0.0f,0.0f);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
