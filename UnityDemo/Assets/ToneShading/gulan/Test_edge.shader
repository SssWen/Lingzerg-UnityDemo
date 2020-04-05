Shader "Custom/Test_edge"
{
    Properties
    {
	_OutlineWidth ("Outline Width", Range(0.01, 1)) = 0.24
        _OutLineColor ("OutLine Color", Color) = (0.5,0.5,0.5,1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        pass
        {
           Tags {"LightMode"="ForwardBase"}
			 
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 vert(appdata_base v): SV_POSITION
	    {
                return UnityObjectToClipPos(v.vertex);
            }

            half4 frag() : SV_TARGET 
	   {
                return half4(1,1,1,1);
            }

            ENDCG
        }

        
    }
}
