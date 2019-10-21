Shader "IllustractionToonShader/ITS_FullScreen"
{
	Properties
	{
		_MainTex("Texture", 2D) = "black" {}
		_ChromaTex("Chroma", 2D) = "gray" {}
		_Color("Main Color", Color) = (1,1,1,1)
		_Scale("Scale", Range(1,100)) = 2

		_Hue("Hue", Range(0,359)) = 0
		_Saturation("Saturation", Range(0,3.0)) = 1.0
		_Value("Value", Range(0,3.0)) = 1.0
		_InBlack("Input Black", Range(0, 255)) = 0
		_InGamma("Input Gamma", Range(0, 2)) = 1
		_InWhite("Input White", Range(0, 255)) = 255
		_OutWhite("Output White", Range(0, 255)) = 255
		_OutBlack("Output Black", Range(0, 255)) = 0

		[Toggle(APPLY_GAMMA)] _ApplyGamma("Apply Gamma", Float) = 0
		[Toggle(USE_YPCBCR)] _UseYpCbCr("Use YpCbCr", Float) = 0
		[Toggle(UV_FLIP)] _UVFlip("UV Flip", Float) = 0
		[Toggle(COLOR_GRADING)] _ColorGrading("Color Grading", Float) = 0
		//[Toggle(USE_DEPTH)] _UseDepth("Use Depth", Float) = 0
	}
		
	SubShader
	{
		Tags{ "Queue" = "Background" "RenderType" = "Opaque" }
		LOD 100
		Cull Off
		ZWrite Off
		ZTest Always
		Lighting Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature APPLY_GAMMA
			#pragma shader_feature USE_YPCBCR
			#pragma shader_feature UV_FLIP
			#pragma shader_feature COLOR_GRADING
			//#pragma shader_feature USE_DEPTH
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct fragOut
			{
				half4 color : COLOR;
#if USE_DEPTH
				float depth : DEPTH;
#endif
			};

			uniform sampler2D _MainTex;
#if USE_YPCBCR
			uniform sampler2D _ChromaTex;
#endif
			uniform float4 _MainTex_ST;
			uniform float4 _MainTex_TexelSize;
			uniform fixed4 _Color;
			uniform float _Scale;
			uniform float _Depth;

#if USE_DEPTH
			uniform float _TexResX;
			uniform float _TexResY;
			StructuredBuffer<float> _DepthBuffer;
#endif

			uniform half _Hue;
			uniform half _Saturation;
			uniform half _Value;
			uniform float _InBlack;
			uniform float _InGamma;
			uniform float _InWhite;
			uniform float _OutWhite;
			uniform float _OutBlack;

			//RGB to HSV
			float3 RGB2HSV(float3 rgb)
			{
				float3 hsv;
				float _max = max(rgb.x, max(rgb.y, rgb.z));
				float _min = min(rgb.x, min(rgb.y, rgb.z));

				if (rgb.x == _max)
				{
					hsv.x = (rgb.y - rgb.z) / (_max - _min);
				}
				if (rgb.y == _max)
				{
					hsv.x = 2 + (rgb.z - rgb.x) / (_max - _min);
				}
				if (rgb.z == _max)
				{
					hsv.x = 4 + (rgb.x - rgb.y) / (_max - _min);
				}
				hsv.x = hsv.x * 60.0;
				if (hsv.x < 0)
					hsv.x = hsv.x + 360;
				hsv.z = _max;
				hsv.y = (_max - _min) / _max;
				return hsv;
			}

			//HSV to RGB
			float3 HSV2RGB(float3 hsv)
			{
				float R, G, B;
				if (hsv.y == 0)
				{
					R = G = B = hsv.z;
				}
				else
				{
					hsv.x = hsv.x / 60.0;
					int i = (int)hsv.x;
					float f = hsv.x - (float)i;
					float a = hsv.z * (1 - hsv.y);
					float b = hsv.z * (1 - hsv.y * f);
					float c = hsv.z * (1 - hsv.y * (1 - f));
					switch (i)
					{
					case 0: R = hsv.z; G = c; B = a;
						break;
					case 1: R = b; G = hsv.z; B = a;
						break;
					case 2: R = a; G = hsv.z; B = c;
						break;
					case 3: R = a; G = b; B = hsv.z;
						break;
					case 4: R = c; G = a; B = hsv.z;
						break;
					case 5: R = hsv.z; G = a; B = b;
						break;
					}
				}
				return float3(R, G, B);
			}

			float GetPixelLevel(float inPixel)
			{
				return (pow(((inPixel * 255.0) - _InBlack) / (_InWhite - _InBlack), _InGamma) * (_OutWhite - _OutBlack) + _OutBlack) / 255.0;
			}

			float2 ScaleZoomToFit(float targetWidth, float targetHeight, float sourceWidth, float sourceHeight)
			{
#if defined(ALPHAPACK_TOP_BOTTOM)
				sourceHeight *= 0.5;
#elif defined(ALPHAPACK_LEFT_RIGHT)
				sourceWidth *= 0.5;
#endif
				float targetAspect = targetHeight / targetWidth;
				float sourceAspect = sourceHeight / sourceWidth;
				float2 scale = float2(1.0, sourceAspect / targetAspect);
				if (targetAspect < sourceAspect)
				{
					scale = float2(targetAspect / sourceAspect, 1.0);
				}
				return scale;
			}

			v2f vert(appdata_img v)
			{
				v2f o;

				float2 scale = ScaleZoomToFit(_ScreenParams.x, _ScreenParams.y, _MainTex_TexelSize.z, _MainTex_TexelSize.w);
				float2 pos = ((v.vertex.xy) * scale * _Scale);

				if (_ProjectionParams.x < 0.0)
				{
					pos.y = (1.0 - pos.y) - 1.0;
				}

				o.vertex = float4(pos.xy, UNITY_NEAR_CLIP_VALUE, 1.0);

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
#if UV_FLIP
				o.uv.y = 1 - o.uv.y;
#endif
				return o;
			}

			fragOut frag(v2f i)
			{
#if USE_YPCBCR
#	if SHADER_API_METAL || SHADER_API_GLES || SHADER_API_GLES3
					float3 ypcbcr = float3(tex2D(_MainTex, i.uv).r, tex2D(_ChromaTex, i.uv).rg);
#	else
					float3 ypcbcr = float3(tex2D(_MainTex, i.uv).r, tex2D(_ChromaTex, i.uv).ra);
#	endif
					float3 col = Convert420YpCbCr8ToRGB(ypcbcr);
#else
					fixed4 col = tex2D(_MainTex, i.uv);
#endif
#if APPLY_GAMMA
				col.rgb = GammaToLinear(col.rgb);
#endif

#if COLOR_GRADING
				float3 colorHSV;
				colorHSV.xyz = RGB2HSV(col.xyz);
				colorHSV.x += _Hue;
				colorHSV.x = colorHSV.x % 360;
				colorHSV.y *= _Saturation;
				colorHSV.z *= _Value;
				col.xyz = HSV2RGB(colorHSV.xyz);

				col.rgb = fixed3(GetPixelLevel(col.r), GetPixelLevel(col.g), GetPixelLevel(col.b));
				col *= _Color;
#endif

				fragOut o;
				o.color = fixed4(col.rgb, 1.0);
#if USE_DEPTH
				int dx = (int)(i.uv.x * _TexResX);
				int dy = (int)(i.uv.y * _TexResY);
				int di = (int)(dx + dy * _TexResX);
				float depth = _DepthBuffer[di];
				if (depth == 0) depth = 5000;
				o.depth = depth / 5000;
#endif
				return o;
			}
			ENDCG
		}
	}

	FallBack "VertexLit"
}
