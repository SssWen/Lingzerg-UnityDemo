Shader "Custom/Surface/Surface-Catoon"
{
    Properties
    {
		//*** 完成 1 高光颜色 和 暗部颜色 固有色 + 滑块
		//*** 完成 2 环境映射 支持反射球和天空盒反射
		//3 顶点色做mask 控制法线映射球
		[Header(Color)]
        _MainTex ("Texture", 2D) = "white" {}

		[Space(50)]
		[Header(RampSwitch)]
		[Toggle]
		_RampSwitch("Color Ramp Type",Float) = 1

		[Space(50)]
		[Header(ColorRamp)]
		_Color("Base Color", Color) = (1, 1, 1, 1)
		_ColorIntensity("Color Intensity", Range(0.01,1)) = 0.2
		[Space(10)]
		_BrightColor("Bright", Color) = (1, 1, 1, 1)
		_BrightIntensity("Color Intensity", Range(0.01,1)) = 0.2
		[Space(10)]
		_DarkColor("Dark", Color) = (1, 1, 1, 1)
		_DarkIntensity("Color Intensity", Range(0.01,1)) = 0.2
		
		[Space(50)]
		[Header(TexRamp)]
		_Ramp ("Ramp Texture", 2D) = "white" {}
		_RampIn("Ramp In", Range(0.01,1)) = 0.2

		[Space(50)]
		[Header(Metallic)]
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
		_Smoothness("Smoothness", Range(0, 1)) = 0.5

		[Space(50)]
		[Header(Specular)]
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01

		[Space(50)]
		[Header(Outline)]
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Width", Float) = 0.01
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
		_Mask ("Mask R-金属通道 G-菲涅尔 B-无 A-无", 2D) = "black" {}
		_LUT("LUT", 2D) = "white" {}
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
			Name "Outline"
			Tags { }
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal xboxone ps4 switch
			#pragma target 3.0
			#pragma shader_feature _ITS_CLIPPING_NONE _ITS_CLIPPING_ALPHA _ITS_CLIPPING_MASK
			#pragma shader_feature _ITS_OUTLINE_BLEND_MAIN_NONE _ITS_OUTLINE_BLEND_MAIN_NOLIGHT _ITS_OUTLINE_BLEND_MAIN_LIGHT 
			#pragma shader_feature _ITS_OUTLINE_MASK_TEX
			#pragma shader_feature _ITS_OUTLINE_COLOR_TEX
			#pragma shader_feature _ITS_OUTLINE_NORMAL _ITS_OUTLINE_POSITION
			
			#if defined(_ITS_OUTLINE_BLEND_MAIN_NOLIGHT) || defined(_ITS_OUTLINE_BLEND_MAIN_LIGHT) || defined(_ITS_CLIPPING_ALPHA)
			uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
			#endif

			#ifndef _ITS_OUTLINE_BLEND_MAIN_NONE
			uniform float4 _MainColor;
			#endif

			#ifdef _ITS_OUTLINE_BLEND_MAIN_LIGHT
			uniform float4 _LightColor0;
			#endif

			uniform float _OutlineWidth;
			uniform float _FarthestDistance;
			uniform float _NearestDistance;
			uniform float4 _OutlineColor;
			uniform float _OffsetZ;

			#ifdef _ITS_OUTLINE_MASK_TEX
			uniform sampler2D _OutlineMaskTex; uniform float4 _OutlineMaskTex_ST;
			#endif

			#ifdef _ITS_OUTLINE_COLOR_TEX
			uniform sampler2D _OutlineColorTex; uniform float4 _OutlineColorTex_ST;
			#endif

			#ifndef _ITS_CLIPPING_NONE
			uniform float _ClippingLevel;
			uniform fixed _ClippingInverse;
			#endif 

			#ifdef _ITS_TRANSPARENCY
			uniform float _Transparency;
			#endif 

			#ifdef _ITS_CLIPPING_MASK
			uniform sampler2D _ClippingMask; uniform float4 _ClippingMask_ST;
			#endif

			struct VertexInput 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			#if defined(_ITS_OUTLINE_MASK_TEX) || !defined(_ITS_CLIPPING_NONE) || defined(_ITS_OUTLINE_COLOR_TEX) || !defined(_ITS_OUTLINE_BLEND_MAIN_NONE)
				float2 texcoord0 : TEXCOORD0;
			#endif
			};

			struct VertexOutput 
			{
				float4 pos : SV_POSITION;
			#if defined(_ITS_OUTLINE_MASK_TEX) || !defined(_ITS_CLIPPING_NONE) || defined(_ITS_OUTLINE_COLOR_TEX) || !defined(_ITS_OUTLINE_BLEND_MAIN_NONE)
				float2 uv0 : TEXCOORD0;
			#endif
			};

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o = (VertexOutput)0;
			#if defined(_ITS_OUTLINE_MASK_TEX) || !defined(_ITS_CLIPPING_NONE) || defined(_ITS_OUTLINE_COLOR_TEX) || !defined(_ITS_OUTLINE_BLEND_MAIN_NONE)
				o.uv0 = v.texcoord0;
			#endif

			#ifdef _ITS_OUTLINE_MASK
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			#endif

				float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
			#ifdef _ITS_OUTLINE_MASK_TEX
				float outlineMask = tex2Dlod(_OutlineMaskTex, float4(TRANSFORM_TEX(o.uv0, _OutlineMaskTex), 0.0, 0)).r;
				float outlineWidth = (_OutlineWidth*0.001*smoothstep(_FarthestDistance, _NearestDistance, distance(objPos.rgb, _WorldSpaceCameraPos))*outlineMask);
			#else
				float outlineWidth = (_OutlineWidth*0.001*smoothstep(_FarthestDistance, _NearestDistance, distance(objPos.rgb, _WorldSpaceCameraPos)));
			#endif
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.pos.xyz);
				float4 viewDirectionVP = mul(UNITY_MATRIX_VP, float4(viewDirection.xyz, 1));

			#if defined(UNITY_REVERSED_Z)
				_OffsetZ = _OffsetZ * -0.01;
			#else
				_OffsetZ = _OffsetZ * 0.01;
			#endif

			#ifdef _ITS_OUTLINE_NORMAL
				o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal*outlineWidth, 1));
			#elif _ITS_OUTLINE_POSITION
				outlineWidth = outlineWidth * 2;
				o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + normalize(v.vertex)*outlineWidth, 1));
			#endif
				o.pos.z = o.pos.z + _OffsetZ * viewDirectionVP.z;
				return o;
			}

			float4 frag(VertexOutput i) : SV_Target 
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
				clip(alpha - 0.5);
			#endif

				float3 color = _OutlineColor.rgb;

			#if !defined(_ITS_OUTLINE_BLEND_MAIN_NONE) && !defined(_ITS_CLIPPING_ALPHA)
				float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
			#endif

			#ifdef _ITS_OUTLINE_BLEND_MAIN_NOLIGHT
				float3 mainColor = mainTexColor.rgb * _MainColor.rgb;
				color *= (mainColor * mainColor);
			#elif _ITS_OUTLINE_BLEND_MAIN_LIGHT
				float3 mainColor = mainTexColor.rgb * _MainColor.rgb * _LightColor0.rgb;
				color *= (mainColor * mainColor);
			#endif

			#ifdef _ITS_TRANSPARENCY
				alpha = saturate((alpha + _Transparency));
			#endif

			#ifdef _ITS_OUTLINE_MASK
				return fixed4(0, 0, 0, 1);
			#endif

			#ifdef _ITS_OUTLINE_COLOR_TEX
				float3 outlineTexColor = tex2D(_OutlineColorTex, TRANSFORM_TEX(i.uv0, _OutlineColorTex)).rgb;
				return fixed4(color * outlineTexColor, alpha);
			#else
				return fixed4(color, alpha);
			#endif
			}
			// ITP_Outline.cginc

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
			sampler2D _LUT;

			fixed _RampSwitch;

			fixed4 _Color,_BrightColor,_DarkColor;
			fixed _ColorIntensity,_BrightIntensity,_DarkIntensity;

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
				i.color = v.color;
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

			//_BrightColor,_DarkColor;
			//_ColorIntensity,_BrightIntensity,_DarkIntensity;
			fixed3 getColorRamp(fixed3 albedo,fixed diff) {
				//_ColorIntensity+_BrightIntensity+_DarkIntensity
				return _LightColor0.rgb * albedo * lerp(_BrightColor.rgb, _DarkColor.rgb,  round(diff-_BrightIntensity+_DarkIntensity));
			}

			fixed3 getTexRamp(fixed3 albedo,fixed diff) {
				return (_LightColor0.rgb * albedo * tex2D(_Ramp, float2(clamp(diff*_RampIn,0.01,1), clamp(diff*_RampIn,0.01,1))).rgb).rgb;
			}

			float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
			{
				return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
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
				
				fixed3 diffuse = lerp(getTexRamp(albedo,diff), getColorRamp(albedo,diff), _RampSwitch);

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


				/*间接光计算*/

				/*
				***SH9部分***
				* 球谐实际上代表了漫反射近似,在环境光照下的漫反射
				*/
				half3 ambient_contrib = ShadeSH9(float4(i.normal, 1));
				/*
				half3 ambient_contrib = 0.0;
				ambient_contrib.r = dot(unity_SHAr, half4(i.normal, 1.0));
				ambient_contrib.g = dot(unity_SHAg, half4(i.normal, 1.0));
				ambient_contrib.b = dot(unity_SHAb, half4(i.normal, 1.0));
				*/

				float3 iblDiffuse = max(half3(0, 0, 0), ambient + ambient_contrib);

				/*
				***IBL部分***
				* ibl本质就是为了镜面反射
				*/
				
				float mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
				float3 reflectVec = reflect(-viewDir, i.normal);

				half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;
				half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip); //根据粗糙度生成lod级别对贴图进行采样

				float3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);

				//利用LUT 获取积分的预计算
				//nv和 roughness 不能等于1 , 因为LUT在两者等于1的时候,会产生突变,导致物体出现亮斑
				float2 envBDRF = tex2D(_LUT, float2(lerp(0, 0.99 ,nv), lerp(0, 0.99, roughness))).rg; // LUT采样
				
				//添加的部分从这里开始
				float3 Flast = fresnelSchlickRoughness(max(nv, 0.0), F0, roughness);
				float kdLast = (1 - Flast) * (1 - _Metallic);
				//添加的部分到这里结束

				float3 iblDiffuseResult = iblDiffuse * kdLast * albedo;
				float3 iblSpecularResult = iblSpecular * (Flast * envBDRF.r + envBDRF.g);
				float3 IndirectResult = iblDiffuseResult + iblSpecularResult;

				fresnel = lerp(0,fresnel,mask.g);

				return fixed4(lerp(finalColor, _FresnelCol.rgb, fresnel)*_FresnelCol.a+IndirectResult, 1);
            }
            ENDCG
        }
    }
}
