Shader "Unlit/NPR-gulan-eye"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _EyeTex ("Texture", 2D) = "white" {}
        _Color("Bright", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {
				"IgnoreProjector" = "True"
				"Queue" = "Transparent"
				"RenderType" = "Transparent"
			}

        LOD 100

        Pass
        {

            Tags {
				"LightMode" = "ForwardBase"
			}

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct VertexData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                //float2 uv2 : TEXCOORD1;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                //float2 uv2 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _EyeTex;//_MainTex,
            float4  _EyeTex_ST;//_MainTex_ST,
            fixed4 _Color;
            Interpolators vert (VertexData v)
            {
                Interpolators i;

                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                fixed dis = distance(fixed3(0,0,0),worldLightDir);
                fixed edge = sqrt(worldLightDir.x*worldLightDir.x+worldLightDir.z*worldLightDir.z);
                fixed lightcos = edge/dis;
                v.vertex.xz = v.vertex.xz+lightcos*worldLightDir.xz*0.003;

//v.vertex.x = v.vertex.x*sin(_Time.y);
//v.vertex.z = v.vertex.z*sin(_Time.y);
                i.vertex = UnityObjectToClipPos(v.vertex);
                //XZ

                i.uv = TRANSFORM_TEX(v.uv, _EyeTex);
                //i.uv2 = TRANSFORM_TEX(v.uv2, _EyeTex);
                return i;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                //col += tex2D(_EyeTex, i.uv2*2);//fixed4(1,0,0,1);//
                //return fixed4(1,0,0,1);
                return tex2D(_EyeTex, i.uv) * _Color;
            }
            ENDCG
        }
    }
}
