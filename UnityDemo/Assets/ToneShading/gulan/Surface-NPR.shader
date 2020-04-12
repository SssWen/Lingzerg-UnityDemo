// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

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

        //*** 新一期任务 ***
        //4阴影差值，
        //ramp只对阴影部分有效
        //ao始终都在

		// * 1：bug - 整体变暗
		// 2：bloom
		// 3：ao跟随漫反射衰减
		// * 4：阴影贴图强度控制
		// 5：角色接受阴影


		[Header(Color)]
        _MainTex ("Main Texture", 2D) = "while" {}
		_Mask("Mask Texture,r:金属度,b:阴影", 2D) = "while" {}
		_Mask2("Mask2 Texture,r:菲涅尔", 2D) = "while" {}
        _LerpShadow("4 Shadow Texture", 2D) = "while" {}
		_LerpShadowIntansity("4 Shadow Intansity", Float) = 1

		_FaceFront ("定义一个正面朝向,用于插值,只读取XZ", Vector) = (0, 0, 1, 1)

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
		//_ColorIntensity("Color Intensity", Range(0,1)) = 0.2

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
		_SpecularScale ("Specular Scale", Range(8, 256)) = 1
		//_Specular2DScale ("Specular Scale", Range(0, 0.1)) = 0.01


		[Space]
		_AOColor ("AO Color", Color) = (0, 0, 0, 1)
		_AOScale ("AO Scale", Range(0.0, 1.0)) = 1

		[Space(50)]
		[Header(Innerline)]
		_InnerIntansity ("Inner Edge Scale", Range(0, 1)) = 0.5

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
		_FresnelBase("Fresnel Base", Range(0.0, 1.0)) = 1.0
		_FresnelScale("Fresnel Scale", Range(0.0, 1.0)) = 1.0
		_FresnelPow("Fresnel Pow", Range(0, 5)) = 5.0 //幂数

		_FresnelMin("Fresnel Smoothstep Min", Range(0, 2)) = 1.0 //菲涅尔最小值
		_FresnelMax("Fresnel Smoothstep Max", Range(0, 2)) = 1.0 //菲涅尔最大值
		_FresnelSmooth("Fresnel Smooth", Range(0, 2)) = 1.0 //菲涅尔最大值

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
		
/***
        //描边的Pass
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
***/

		Pass
		{
			Tags {"LightMode"="ForwardBase"}
			Name "Outline"
			Cull Front
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			half _OutlineWidth;
			half4 _OutLineColor;

			struct a2v 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 vertColor : COLOR;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 vertColor : COLOR;
			};


			v2f vert (a2v v) 
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = UnityObjectToClipPos(v.vertex);
				float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz);
				float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//将法线变换到NDC空间
				float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角的位置的顶点变换到观察空间
				float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
				ndcNormal.x *= aspect;
				pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy * v.vertColor.a;//顶点色a通道控制粗细
				o.pos = pos;
				o.vertColor = v.vertColor.rgb;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET 
			{
				return fixed4(_OutLineColor * i.vertColor, 0);//顶点色rgb通道控制描边颜色
			}
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
				fixed3 worldNormal : TEXCOORD2;
				
				fixed3 V : TEXCOORD3;
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


			sampler2D _Mask,_Mask2,_LerpShadow;
			sampler2D _LUT;
			fixed4 _FaceFront;

			fixed _RampSwitch,_MappingNormalSwitch,_LightDirNormalSwitch;

			fixed4 _Color,_BrightColor,_GrayColor,_DarkColor;
			fixed _BrightIntensity,_GrayIntensity,_DarkIntensity;

			sampler2D _Ramp;
			fixed _RampIn;

			fixed _InnerIntansity,_LightIntansity,_LerpShadowIntansity;

			fixed4 _SpecularColor,_AOColor;
			fixed _SpecularScale,_AOScale;//_Specular2DScale

			fixed _Metallic, _Smoothness,_IndirectType;

		
			//菲涅尔表面相关逻辑
			fixed _FresnelBase;
			fixed _FresnelScale;
			fixed _FresnelPow;
			fixed4 _FresnelCol;
			fixed _FresnelMin;
			fixed _FresnelMax;
			fixed _FresnelSmooth;

			fixed4 _R,_G,_B;

			// fixed3 getNormal(fixed3 pos, fixed3 normal,fixed3 color) {
			// 	normal = normalize(lerp(normal,(pos.xyz-_R.rgb)*-1, color.r));
			// 	normal = normalize(lerp(normal,(pos.xyz-_G.rgb)*-1, color.g));
			// 	normal = normalize(lerp(normal,(pos.xyz-_B.rgb)*-1, color.b));

			// 	return normal;
			// }

			Interpolators MyVertexProgram (VertexData v)
			{
				Interpolators i = (Interpolators)0;
				i.pos = UnityObjectToClipPos(v.vertex);

				// Transform the normal from object space to world space
				i.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				
				// Transform the vertex from object spacet to world space
				i.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				//i.worldPos.xyz = normalize(mul(unity_ObjectToWorld, v.vertex));
				//i.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));

				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.color = v.color;
				
				i.normal = mul(v.normal, (float3x3)unity_WorldToObject);
				//i.normal = lerp(i.normal,getNormal(v.vertex.xyz, i.normal,i.color),_MappingNormalSwitch);

				i.V = normalize(WorldSpaceViewDir(v.vertex));
				

				i.normal = normalize(lerp(i.normal,_WorldSpaceLightPos0.xyz*_LightIntansity + i.normal,_LightDirNormalSwitch));
			
				return i;
			}

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

			//根据阴影纹理标记的信息,选择使用哪个通道的阴影
			fixed getLerpShadow(float4 lerpShadow,fixed3 lightDir) {

				fixed3 lightDirProject = fixed3(lightDir.x,0,lightDir.z);
				fixed dotValue =  dot(lightDirProject,normalize(_FaceFront.xyz));

				fixed crossValue = normalize(cross(lightDirProject,normalize(_FaceFront.xyz)).y);

				if (crossValue < 0) {
					if(dotValue >= 0) {
						return lerp(lerpShadow.r,lerpShadow.g,abs(dotValue));
					} else {
						return lerp(lerpShadow.r, lerpShadow.a,abs(dotValue));
					}
				} else {
					if(dotValue > 0) {
						return lerp(lerpShadow.b,lerpShadow.g,abs(dotValue));
					} else {
						return lerp(lerpShadow.b, lerpShadow.a,abs(dotValue));
					}
				}


				//return lerp(,lerp(1-lerpShadow.b, lerpShadow.a,crossValue*dotValue),dotValue);

				//return 1-lerpShadow.b;
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

			fixed4 MyFragmentProgram (Interpolators i) : SV_Target
			{
				//*** 准备数据 ***//
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				fixed3 worldNormal = normalize(i.worldNormal);
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(lightDir + viewDir);
				
				fixed4 c = tex2D(_MainTex, i.uv);
				
				float4 mask = tex2D(_Mask, i.uv);
				float4 mask2 = tex2D(_Mask2, i.uv);
				float4 lerpShadow = tex2D(_LerpShadow,i.uv);

				//*** 准备数据结束 ***//

				// fixed spec = dot(worldNormal, halfDir);
				// fixed w = fwidth(spec) * 2.0;
				// fixed3 specular = _SpecularColor.rgb * lerp(0, 1, smoothstep(-w, w, spec + _Specular2DScale - 1)) * step(0.0001, _Specular2DScale);
				
				//blinn 高光模型
				fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(worldNormal, halfDir)), _SpecularScale);
				//return fixed4(specular,1);
				specular *= mask.g;

				fixed3 albedo = c.rgb * _Color.rgb;
				fixed3 ambient = albedo;
				ambient = lerp(ambient * mask.b * (1-_AOScale) * _AOColor * normalize(dot(worldNormal , lightDir)), ambient, mask.b);// * _AOScale * _AOColor;
				//return fixed4(ambient,1);
				ambient *= getLerpShadow(lerpShadow,lightDir)*_LerpShadowIntansity;
				//return mask.b;
				//return getLerpShadow(lerpShadow,lightDir);
				//return fixed4(ambient,1);
				
				//防止除0
				float vh = max(saturate(dot(viewDir, halfDir)), 0.000001);
				float nv = max(saturate(dot(i.normal, viewDir)), 0.000001);    //法线点乘视线方向,拿到实现与平面的倾斜关系

				//菲涅尔F
				//unity_ColorSpaceDielectricSpec.rgb这玩意大概是float3(0.04, 0.04, 0.04)，就是个经验值
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
				//float3 F = lerp(pow((1 - max(vh, 0)),5), 1, F0);//是hv不是nv
				float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);

				
				//漫反射系数

				
				fixed diff =  dot(lerp(i.normal,worldNormal,mask.r), lightDir);
				diff = (diff * 0.5 + 0.5);
				
				//选择使用哪种diffuse ramp方式
				fixed3 rampColor = lerp(getTexRamp(albedo,diff), getColorRamp(albedo,diff), _RampSwitch);
				fixed3 diffuse = rampColor;//lerp(rampColor,albedo,mask.b).rgb;
				//叠加金属度,金属情况下,漫反射为0
				diffuse *= lerp(1,(1 - F)*(1-_Metallic), mask.r);
				//return fixed4(diffuse,1);
 				

				//合并 基础色 漫反射 高光色 alpha
				fixed4 finalColor = fixed4(ambient * diffuse + specular, _Color.a);
				//叠加阴影贴图和高光贴图
				
				//return finalColor;

				//粗糙度
				float perceptualRoughness = 1 - _Smoothness;
				float roughness = perceptualRoughness * perceptualRoughness;
				float3 IndirectResult = lerp(float3(0,0,0), lerp(float3(0,0,0),getIndirectLight(i, albedo,ambient,perceptualRoughness,roughness, nv, F0), mask.r), _IndirectType);
				
				//菲涅尔
				fixed fresnel = _FresnelBase + _FresnelScale * pow(1 - dot(i.worldNormal, i.V), _FresnelPow);
				
				

				fresnel = lerp(0,fresnel,mask.r);
				fresnel = smoothstep(_FresnelMin, _FresnelMax, fresnel);
				fresnel = smoothstep(0, _FresnelSmooth, fresnel);
				
				//内描边
				finalColor.rgb += IndirectResult;
				finalColor.rgb *= lerp(1-_InnerIntansity, 1, mask.a);

				//return 1;
				return fixed4(lerp(finalColor, _FresnelCol.rgb, fresnel)*_FresnelCol.a, finalColor.a);//+IndirectResult
			}
			ENDCG
		}

		Pass {
			Name "Shadow"
			
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SEMITRANSPARENT_SHADOWS
			#pragma shader_feature _SMOOTHNESS_ALBEDO

			#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma instancing_options lodfade

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "UnityCG.cginc"

			#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
				#if defined(_SEMITRANSPARENT_SHADOWS)
					#define SHADOWS_SEMITRANSPARENT 1
				#else
					#define _RENDERING_CUTOUT
				#endif
			#endif

			#if SHADOWS_SEMITRANSPARENT || defined(_RENDERING_CUTOUT)
				#if !defined(_SMOOTHNESS_ALBEDO)
					#define SHADOWS_NEED_UV 1
				#endif
			#endif

			UNITY_INSTANCING_BUFFER_START(InstanceProperties)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
			#define _Color_arr InstanceProperties
			UNITY_INSTANCING_BUFFER_END(InstanceProperties)

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Cutoff;

			sampler3D _DitherMaskLOD;

			struct VertexData {
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct InterpolatorsVertex {
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 position : SV_POSITION;
				#if SHADOWS_NEED_UV
					float2 uv : TEXCOORD0;
				#endif
				#if defined(SHADOWS_CUBE)
					float3 lightVec : TEXCOORD1;
				#endif
			};

			struct Interpolators {
				UNITY_VERTEX_INPUT_INSTANCE_ID
				#if SHADOWS_SEMITRANSPARENT || defined(LOD_FADE_CROSSFADE)
					UNITY_VPOS_TYPE vpos : VPOS;
				#else
					float4 positions : SV_POSITION;
				#endif

				#if SHADOWS_NEED_UV
					float2 uv : TEXCOORD0;
				#endif
				#if defined(SHADOWS_CUBE)
					float3 lightVec : TEXCOORD1;
				#endif
			};

			float GetAlpha (Interpolators i) {
				float alpha = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color).a;
				#if SHADOWS_NEED_UV
					alpha *= tex2D(_MainTex, i.uv.xy).a;
				#endif
				return alpha;
			}

			InterpolatorsVertex MyShadowVertexProgram (VertexData v) {
				InterpolatorsVertex i;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, i);
				#if defined(SHADOWS_CUBE)
					i.position = UnityObjectToClipPos(v.position);
					i.lightVec =
						mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
				#else
					i.position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
					i.position = UnityApplyLinearShadowBias(i.position);
				#endif

				#if SHADOWS_NEED_UV
					i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				#endif
				return i;
			}

			float4 MyShadowFragmentProgram (Interpolators i) : SV_TARGET {
				UNITY_SETUP_INSTANCE_ID(i);
				#if defined(LOD_FADE_CROSSFADE)
					UnityApplyDitherCrossFade(i.vpos);
				#endif

				float alpha = GetAlpha(i);
				#if defined(_RENDERING_CUTOUT)
					clip(alpha - _Cutoff);
				#endif

				#if SHADOWS_SEMITRANSPARENT
					float dither =
						tex3D(_DitherMaskLOD, float3(i.vpos.xy * 0.25, alpha * 0.9375)).a;
					clip(dither - 0.01);
				#endif
				
				#if defined(SHADOWS_CUBE)
					float depth = length(i.lightVec) + unity_LightShadowBias.x;
					depth *= _LightPositionRange.w;
					return UnityEncodeCubeShadowDepth(depth);
				#else
					return 0;
				#endif
			}

			ENDCG
		}
/****/
    }
}
