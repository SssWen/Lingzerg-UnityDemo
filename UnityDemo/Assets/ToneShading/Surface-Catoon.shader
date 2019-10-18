Shader "Custom/Surface/Surface-Catoon"
{
    Properties
    {
	
		[Header(Color)]
        _MainTex ("Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1, 1, 1, 1)

		[Space(50)]
		[Header(Ramp)]
		_Ramp ("Ramp Texture", 2D) = "white" {}
		_RampIn("Ramp In", Range(0.01,1)) = 0.2

		[Space(50)]
		[Header(MetallicAndSmoothness)]
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
		//_Smoothness("Smoothness", Range(0, 1)) = 0.5

		[Space(50)]
		[Header(Specular)]
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01

		[Space(50)]
		[Header(Outline)]
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Width", Range(.0,0.1)) = 0.01
		_Scale("_Scale", Float) = 1

		/** Special - 特殊功能 - Finil **/
		[Space(50)]
		[Header(FresnelMetallic)]
		_FresnelCol("Fresnel Color", Color) = (1,1,1,1)
		_FresnelBase("Fresnel Base", Range(0.0, 1.0)) = 0
		_FresnelScale("Fresnel Scale", Range(0.0, 1.0)) = 0.0
		_FresnelPow("Fresnel Pow", Range(0, 5)) = 0 //幂数

		[Space(50)]
		[Header(Mask)]
		_Mask ("Mask R-金属通道 G-无 B-无", 2D) = "black" {}
    }

	CGINCLUDE

	#define BINORMAL_PER_FRAGMENT

	ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

		Pass
		{
			Name "OUTLINE"

			Tags {"LightMode" = "Always"}

			Cull Front
			ZWrite On
			ColorMask RGB

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"
			
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed4 color : COLOR;
			};

			fixed _OutlineWidth,_Scale;

			fixed4 _OutlineColor;

			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				
				//float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
				//float cameraDis = length(pos.xyz);

				//float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				//normal.z = -0.5;

				//pos = pos + float4(normalize(normal), 0) * _OutlineWidth* v.color.a;
				//o.pos = mul(UNITY_MATRIX_P, pos);

				float4 vsPos = float4(UnityObjectToViewPos(v.vertex),1);
				float3 vsNormal = UnityObjectToViewPos(v.normal);
				vsNormal.z = 0.01;
				vsNormal.xy = vsNormal.xy/ length(vsNormal);

				//
				float4 viewDir = normalize(vsPos);
				viewDir = viewDir * _OutlineWidth * _Scale;
				float4 newVsPos = (v.color.z - 0.5) * viewDir + vsPos;

				float extrude = sqrt(-vsPos.z / unity_CameraProjection[1].y / _Scale);
				extrude = _OutlineWidth * _Scale * v.color.w * extrude;

				vsPos.xy = vsNormal * extrude + newVsPos;
				vsPos.z = newVsPos.z;

				o.pos = mul(UNITY_MATRIX_P, vsPos);
				//o.ditherParam = 0;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = _OutlineColor;
				return col;
			}
			ENDCG
		}

        Pass
        {
			Tags { "LightMode"="ForwardBase" }
			
			Cull Back
		
            CGPROGRAM

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
			
			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"

            struct VertexData
            {
                float4 vertex : POSITION;
				fixed3 normal : NORMAL;
				fixed4 tangent : TANGENT;
				fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
				fixed4 pos : SV_POSITION; //齐次坐标
				fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
				fixed3 normal : TEXCOORD1;
			#if defined(BINORMAL_PER_FRAGMENT) //是否计算次法线
				fixed4 tangent : TEXCOORD2;
			#else 
				fixed3 tangent : TEXCOORD2;
				fixed3 binormal : TEXCOORD3;
			#endif
				fixed3 worldPos : TEXCOORD4;
				float3 worldNormal : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _Mask;
			fixed4 _Color;

			sampler2D _Ramp;
			fixed _RampIn;

			fixed4 _Specular;
			fixed _SpecularScale;

			fixed _Metallic, _Smoothness;

			
			//菲涅尔表面相关逻辑
			fixed _FresnelBase;
			fixed _FresnelScale;
			fixed _FresnelPow;
			fixed4 _FresnelCol;

			#include "InitNormal.cginc"

            Interpolators MyVertexProgram (VertexData v)
            {
                Interpolators i = (Interpolators)0;
                i.pos = UnityObjectToClipPos(v.vertex);
				i.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex);
                i.uv = TRANSFORM_TEX(v.uv, _MainTex);

				i.normal = UnityObjectToWorldNormal(v.normal);
				i.worldNormal  = UnityObjectToWorldNormal(v.normal);
			#if defined(BINORMAL_PER_FRAGMENT)
				i.tangent = fixed4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
			#else
				i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
				i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
			#endif
				
                return i;
            }

            fixed4 MyFragmentProgram (Interpolators i) : SV_Target
            {
				//fixed4 albedo = tex2D(_MainTex, i.uv);
				//InitializeFragmentNormal(i);
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				//fixed3 diff = albedo * _LightColor0.rgb * saturate(dot(normalize(i.normal), normalize(_WorldSpaceLightPos0)));
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 lightColor = _LightColor0.rgb;
				float3 halfVector = normalize(lightDir + viewDir);  //半角向量, 光照方向,视角求和后,平分两者夹角的一个向量

				//防止除0
				float nl = max(saturate(dot(i.normal, lightDir)), 0.000001);   //法线点乘光照方向,拿到反射强度
				float nv = max(saturate(dot(i.normal, viewDir)), 0.000001);    //法线点乘视线方向,拿到实现与平面的倾斜关系
				float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);  //视角点乘 - 半角向量,这个点乘值的结果越接近0,视角和光线的夹角越大(最大为0,180度)
				float lh = max(saturate(dot(lightDir, halfVector)), 0.000001); //同上,只不过是从光照方向来求
				float nh = max(saturate(dot(i.normal, halfVector)), 0.000001); 
				//法线和半角向量的关系,如果结果=0,则法线垂直于半角向量,什么鬼的几何意义
				//假如半角向量和法线点乘等于1 则代表半角向量等于法向量

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
				
				fixed4 c = tex2D (_MainTex, i.uv);
				fixed3 albedo = c.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				//菲涅尔F
				//unity_ColorSpaceDielectricSpec.rgb这玩意大概是float3(0.04, 0.04, 0.04)，就是个经验值
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
				//float3 F = lerp(pow((1 - max(vh, 0)),5), 1, F0);//是hv不是nv
				float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);

				fixed diff =  dot(worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5);
				float4 mask = tex2D(_Mask, i.uv);
				fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(clamp(diff*_RampIn,0.01,1), clamp(diff*_RampIn,0.01,1))).rgb;
				diffuse *= lerp(1,(1 - F)*(1-_Metallic),mask.r);
				
				//高光
				float perceptualRoughness = 1 - _Smoothness;
				float roughness = perceptualRoughness * perceptualRoughness;
				float squareRoughness = roughness * roughness;

				//镜面反射部分
				//D是法线分布函数或者叫正态分部函数，从统计学上估算微平面的取向 - 这里才是高光
				float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);//Unity把roughness lerp到了0.002
				float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);

				//几何遮蔽G 说白了就是高光 - PS 作者写错了, 这里实际上有点像粗糙度,估计就是粗糙度
				float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
				float kInIBL = pow(squareRoughness, 2) / 8;
				float GLeft = nl / lerp(nl, 1, kInDirectLight);
				float GRight = nv / lerp(nv, 1, kInDirectLight);
				float G = GLeft * GRight;

				fixed spec = dot(worldNormal, worldHalfDir);
				fixed w = fwidth(spec) * 2.0;// (D * G * F * 0.25) / (nv * nl);//
				float3 specular =_Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
				
				fixed fresnel = _FresnelBase + _FresnelScale * pow(1 - dot(i.normal, viewDir), _FresnelPow);

				fixed3 finalColor = (ambient + diffuse + specular);
				fresnel = lerp(0,fresnel,mask.r);

				return fixed4(lerp(finalColor, _FresnelCol.rgb, fresnel)*_FresnelCol.a, 1);
            }
            ENDCG
        }
    }
}
