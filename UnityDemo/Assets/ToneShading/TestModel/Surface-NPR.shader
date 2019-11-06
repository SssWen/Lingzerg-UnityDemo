Shader "Custom/Surface/Surface-NPR"
{
    Properties
    {
		//*** 完成 *** 1 高光颜色 和 暗部颜色 固有色 + 滑块
		//*** 完成 *** 2 环境映射 支持反射球和天空盒反射
		//*** 完成 *** 3 顶点色做mask 控制法线映射球
		
		//*** 完成 *** 1张 diffuse
		//*** 完成 *** 1张 4通道控制图  R=金属 G=高光 B=AO（阴影）alpha=内描边

		//1张 单通道菲涅尔

		// 1 C# 加一个质心调整脚本
		// 2 尝试修正描边的不连续以及脱离模型表面
		//
		// *** 低优先级任务 ***
		// * C# 支持复杂渐变颜色过渡
		// * 先做一个临时版本的, 每个颜色增加一个滑动条,用来表示当前颜色的强度
		//

		//*** 完成 *** 光照+法线 计算新法线 = N=_scale*L+N
		//高光流动

		[Header(Color)]
        _MainTex ("Main Texture", 2D) = "while" {}
		_Mask("Mask Texture", 2D) = "while" {}
		_Mask2("Mask2 Texture", 2D) = "while" {}

		//[Space(50)]
		//[Header(MappingNormalSwitch)]
		//[Toggle]
		//_MappingNormalSwitch ("Mapping Normal Switch Type",Float) = 0

		[Space(50)]
		[Header(LightDirNormal)]
		[Toggle]
		_LightDirNormalSwitch ("Mapping Normal Switch Type",Float) = 0
		_LightIntansity ("Light Intansity",Float) = 1
		
		//highlight
		//shadow
		[Space(50)]
		[Header(RampSwitch)]
		[Toggle]
		_RampSwitch("Color Ramp Type",Float) = 0

		[Space(50)]
		[Header(ColorRamp)]
		_Color("Base Color", Color) = (1, 1, 1, 1)
		_ColorIntensity("Color Intensity", Range(0,1)) = 0.2

		[Space(10)]
		_BrightColor("Bright", Color) = (1, 1, 1, 1)
		_BrightIntensity("Bright Intensity", Range(0,2)) = 0.2
		[Space(10)]
		_GrayColor("Gray", Color) = (1, 1, 1, 1)
		_GrayIntensity("Gray Intensity", Range(0,1)) = 0.2
		[Space(10)]
		_DarkColor("Dark", Color) = (1, 1, 1, 1)
		_DarkIntensity("Dark Intensity", Range(0,1)) = 0.2
		
		[Space(50)]
		[Header(TexRamp)]
		_Ramp ("Ramp Texture", 2D) = "white" {}
		_RampIn("Ramp In", Range(0,1)) = 0.2

		[Space(50)]
		[Header(Indirect Light)]
		[Toggle]
		_IndirectType("Indirect Type",Float) = 0
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
		_Smoothness("Smoothness", Range(0, 1)) = 0.5

		[Space(50)]
		[Header(SpecularAndShadow)]
		_SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
		_SpecularScale ("Specular Scale", Range(0, 0.99)) = 1
		[Space]
		_ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
		_ShadowScale ("Shadow Scale", Range(0, 0.99)) = 1

		[Space(50)]
		[Header(Innerline)]
		_InnerIntansity ("Shadow Scale", Range(0, 1)) = 0.5

		[Space(50)]
		[Header(Outline)]
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Width", Float) = 0.01
		_OutlineColorIntensity("Outline Color Intensity", Float) = 1

		/** Special - 特殊功能 - 顶点色控制顶点法线朝向质心 **/
		[Space(50)]
		[Header(VertexColorControllPosPoint)]
		_R ("R 的质心坐标", Vector) = (0, 0, 0, 1)
		_G ("G 的质心坐标", Vector) = (0, 0, 0, 1)
		_B ("B 的质心坐标", Vector) = (0, 0, 0, 1)
		
		/** Special - 特殊功能 - Finil **/
		[Space(50)]
		[Header(FresnelMetallic)]
		_FresnelCol("Fresnel Color", Color) = (1,1,1,1)
		_FresnelBase("Fresnel Base", Range(0.0, 1.0)) = 0
		_FresnelScale("Fresnel Scale", Range(0.0, 1.0)) = 0.0
		_FresnelPow("Fresnel Pow", Range(0, 5)) = 0 //幂数

		[Space(50)]
		[Header(Mask)]
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
			#pragma target 3.0
			
			uniform float _OutlineWidth,_OutlineColorIntensity;
			uniform float _FarthestDistance;
			uniform float _NearestDistance;
			uniform float4 _OutlineColor;
			uniform float _OffsetZ;

			struct VertexInput 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
			
			};

			struct VertexOutput 
			{
				float4 pos : SV_POSITION;
			
			};

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o = (VertexOutput)0;
			
				float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
			
				float outlineWidth = (_OutlineWidth*0.001*smoothstep(_FarthestDistance, _NearestDistance, distance(objPos.rgb, _WorldSpaceCameraPos)));

				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - o.pos.xyz);
				float4 viewDirectionVP = mul(UNITY_MATRIX_VP, float4(viewDirection.xyz, 1));

			#if defined(UNITY_REVERSED_Z)
				_OffsetZ = _OffsetZ * -0.01;
			#else
				_OffsetZ = _OffsetZ * 0.01;
			#endif

				float4 vPos = float4(UnityObjectToViewPos(v.vertex),1.0f);
				float cameraDis = length(vPos.xyz);

				o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal*outlineWidth*cameraDis, 1));
				o.pos.z = o.pos.z*v.color.a*_OutlineColorIntensity + _OffsetZ* viewDirectionVP.z;
				return o;
			}

			float4 frag(VertexOutput i) : SV_Target 
			{
				float3 color = _OutlineColor.rgb;
				return fixed4(color, 1);
			}
			// ITP_Outline.cginc

			ENDCG
		}

        Pass
        {
			Name "NPR Shading"
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
				//fixed4 tangent : TANGENT;
				fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
				fixed4 pos : SV_POSITION; //齐次坐标
				fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
				fixed3 normal : TEXCOORD1;
			//#if defined(BINORMAL_PER_FRAGMENT) //是否计算次法线
			//	fixed4 tangent : TEXCOORD2;
			//#else 
			//	fixed3 tangent : TEXCOORD2;
			//	fixed3 binormal : TEXCOORD3;
			//#endif
				fixed3 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


			sampler2D _Mask,_Mask2;
			sampler2D _LUT;

			fixed _RampSwitch,_MappingNormalSwitch,_LightDirNormalSwitch;

			fixed4 _Color,_BrightColor,_GrayColor,_DarkColor;
			fixed _ColorIntensity,_BrightIntensity,_GrayIntensity,_DarkIntensity;

			sampler2D _Ramp;
			fixed _RampIn;

			fixed _InnerIntansity,_LightIntansity;

			fixed4 _SpecularColor,_ShadowColor;
			fixed _SpecularScale,_ShadowScale;

			fixed _Metallic, _Smoothness,_IndirectType;

			
			//菲涅尔表面相关逻辑
			fixed _FresnelBase;
			fixed _FresnelScale;
			fixed _FresnelPow;
			fixed4 _FresnelCol;

			fixed4 _R,_G,_B;

			//#include "InitNormal.cginc"

			fixed3 getNormal(fixed3 pos, fixed3 normal,fixed3 color) {
				normal = normalize(lerp(normal,(pos.xyz-_R.rgb)*-1, color.r));
				normal = normalize(lerp(normal,(pos.xyz-_G.rgb)*-1, color.g));
				normal = normalize(lerp(normal,(pos.xyz-_B.rgb)*-1, color.b));

				return normal;
			}

            Interpolators MyVertexProgram (VertexData v)
            {
                Interpolators i = (Interpolators)0;
                i.pos = UnityObjectToClipPos(v.vertex);

				i.worldPos.xyz = normalize(mul(unity_ObjectToWorld, v.vertex));
                i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.color = v.color;
				
				//i.normal = UnityObjectToWorldNormal(v.normal);
				//i.worldNormal  = UnityObjectToWorldNormal(v.normal);
				i.normal = normalize(UnityObjectToWorldNormal(v.normal));
				//i.normal = lerp(i.normal,getNormal(v.vertex.xyz, i.normal,i.color),_MappingNormalSwitch);

				i.normal = lerp(i.normal,_WorldSpaceLightPos0.xyz*_LightIntansity + i.normal,_LightDirNormalSwitch);
			//#if defined(BINORMAL_PER_FRAGMENT)
			//	i.tangent = fixed4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
			//#else
			//	i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
			//	i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
			//#endif
                return i;
            }

			//_BrightColor,_DarkColor;
			//_ColorIntensity,_BrightIntensity,_DarkIntensity;
			fixed3 getColorRamp(fixed3 albedo,fixed diff) {
				//_ColorIntensity+_BrightIntensity+_DarkIntensity
				
				fixed Intensity = _DarkIntensity+_GrayIntensity+_BrightIntensity;
				fixed darkIntensity = _DarkIntensity/Intensity;
				fixed grayIntensity = _GrayIntensity/Intensity;
				fixed brightIntensity = _BrightIntensity/Intensity;

				fixed gbIntensity = _GrayIntensity+_DarkIntensity;
				fixed gbDarkIntensity = _DarkIntensity/gbIntensity;
				fixed gbGrayIntensity = _GrayIntensity/gbIntensity;
				
				fixed3 dark = lerp(_DarkColor.rgb,_GrayColor,saturate(round(diff-brightIntensity-darkIntensity)+1));
				return _LightColor0.rgb * albedo * lerp(dark.rgb, _BrightColor.rgb,  saturate(round(diff-darkIntensity)));
			}
			
			fixed3 getTexRamp(fixed3 albedo,fixed diff)
			{
				return (_LightColor0.rgb * albedo * tex2D(_Ramp, float2(clamp(diff*_RampIn,0.01,1), clamp(diff*_RampIn,0.01,1))).rgb).rgb;
			}

			float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
			{
				return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
			}
			
			fixed3 getIndirectLight(Interpolators i, float3 albedo,float3 ambient,float perceptualRoughness,float roughness,float nv,float3 F0 ) {
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
				float3 reflectVec = reflect(-normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz), i.normal);

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
				return iblDiffuseResult + iblSpecularResult;
				
			}
			//_IndirectType

            fixed4 MyFragmentProgram (Interpolators i) : SV_Target
            {
				//return fixed4(i.normal,1);
				//return i.color;
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
				//法线和半角向量的关系,如果结果=0, 则法线垂直于半角向量,什么鬼的几何意义
				//假如半角向量和法线点乘等于1 则代表半角向量等于法向量

				fixed4 c = tex2D(_MainTex, i.uv);
				
				float4 mask = tex2D(_Mask, i.uv);
				float4 mask2 = tex2D(_Mask2, i.uv);

				fixed3 albedo = c.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				ambient *= mask.b*(1-nl);

				//return mask.b;

				//菲涅尔F
				//unity_ColorSpaceDielectricSpec.rgb这玩意大概是float3(0.04, 0.04, 0.04)，就是个经验值
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
				//float3 F = lerp(pow((1 - max(vh, 0)),5), 1, F0);//是hv不是nv
				float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);

				//漫反射
				fixed diff =  dot(i.normal, lightDir);
				diff = (diff * 0.5 + 0.5);

				//fixed3 diffuse = lerp(diffuse,_ShadowColor, mask.b);
				fixed3 diffuse = lerp(getTexRamp(albedo,diff), getColorRamp(albedo,diff), _RampSwitch);
				//diffuse = lerp(diffuse, _ShadowColor,(1-mask.b)*_ShadowScale*(1-nl));
				
				diffuse *= lerp(1,(1 - F)*(1-_Metallic), mask.r);
				
				//计算阴影叠加
				//return float4(diffuse,1);

				//粗糙度
				float perceptualRoughness = 1 - _Smoothness;
				float roughness = perceptualRoughness * perceptualRoughness;
				//float squareRoughness = roughness * roughness;

				////镜面反射部分
				//D是法线分布函数或者叫正态分部函数，从统计学上估算微平面的取向 - 这里才是高光
				float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);//Unity把roughness lerp到了0.002
				float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);

				////几何遮蔽G 说白了就是粗糙度
				//float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
				//float kInIBL = pow(squareRoughness, 2) / 8;
				//float GLeft = nl / lerp(nl, 1, kInDirectLight);
				//float GRight = nv / lerp(nv, 1, kInDirectLight);
				//float G = GLeft * GRight;

				//高光部分
				fixed spec = dot(i.normal, halfVector);
				fixed w = fwidth(spec) * 2.0;// (D * G * F * 0.25) / (nv * nl);//
				//* lerp(0, 1, mask.g) * _SpecularScale;
				fixed3 specular = _SpecularColor.rgb * lerp(0, 1, smoothstep(-D, D, D + _SpecularScale - 1)) * _SpecularScale* lerp(0, 1, mask.g)*nl;
				//return fixed4(specular,1);

				fixed4 finalColor = fixed4(ambient + diffuse + specular,1);

				//叠加阴影贴图和高光贴图
				//finalColor.rgb += shadowCol*0.5f*step(_SpecStep,ilmTexB*pow(nh,_Shininess*ilmTexR*128)) *shadowContrast ;
				finalColor.rgb *= lerp(0+1-_InnerIntansity, 1, mask.a);
				
				fixed fresnel = _FresnelBase + _FresnelScale * pow(1 - dot(i.normal, viewDir), _FresnelPow);
				float3 IndirectResult = lerp(float3(0,0,0), lerp(float3(0,0,0),getIndirectLight(i, albedo,ambient,perceptualRoughness,roughness, nv, F0), mask.r), _IndirectType);

				fresnel = lerp(0,fresnel,mask2.r);

				finalColor *= _LightColor0;
			 	finalColor *= 1 + UNITY_LIGHTMODEL_AMBIENT;
				
				finalColor.a = c.a;
				
				return fixed4(lerp(finalColor, _FresnelCol.rgb, fresnel)*_FresnelCol.a+IndirectResult, 1);
            }
            ENDCG
        }
    }
}
