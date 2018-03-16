Shader "Custom/OcclusionHighlight" {
Properties {
    _Colour ("Main Colour", Color) = (.5,.5,.5,1)
    _HighlightCol ("Highlight Colour" , Color) = (1,0,0,1)
    [Toggle(INDEPENDENT_ALPHA)]
    _IndependentAlpha ("Independent Highlight Alpha", Float) = 0
    [Toggle(TRANSPARENT_TRUE)] 
    _TransHigh ("Highlight Transparency", Float) = 0
    _Cutoff ("Cutoff", Range(0,1)) = 0.1
    _MainTex ("Base (RGB)", 2D) = "white" {}
}
SubShader {
    Pass {
            Name "Behind"
            Tags { "RenderType"="Transparent" "Queue" = "AlphaTest" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Greater
            Cull Off
            ZWrite Off                
            
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature TRANSPARENT_TRUE
            #pragma shader_feature INDEPENDENT_ALPHA
            #include "UnityCG.cginc"
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };
            
            sampler2D _MainTex;
            float4 _Colour;
            float4 _HighlightCol;
            float _Cutoff;
            float4 _MainTex_ST;
            
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = normalize(v.normal);
                o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
				return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
                fixed Highlight = 1 - saturate(dot(normalize(i.viewDir), i.normal));      
				fixed4 colour = tex2D(_MainTex, float2(i.uv.xy));   
             	if(colour.a < _Cutoff) discard;
                #ifdef INDEPENDENT_ALPHA
                    colour.a = colour.a * _HighlightCol.a;
                #else
                    colour.a = colour.a * _HighlightCol.a * _Colour.a;
                #endif
                fixed4 HighlightOut = _HighlightCol * pow(Highlight, 0);
                #ifdef TRANSPARENT_TRUE
                    HighlightOut.a = colour.a;
                #endif
                return HighlightOut;
            }
            ENDCG
        }
    Pass {
            Name "Base"
            Tags { "RenderType"="Transparent" "Queue"="AlphaTest" }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite On
            ZTest LEqual

        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
        
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };
        
            sampler2D _MainTex;
            float4 _Colour;
            float _Cutoff;
            float4 _MainTex_ST;

            v2f vert (appdata_tan v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = normalize(v.normal);
                o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
                return o;
            }
        
            fixed4 frag (v2f i) : COLOR
            {    
                float4 colour = tex2D(_MainTex, float2(i.uv.xy));
                if(colour.a < _Cutoff) discard;
                return colour * _Colour;
            }
            ENDCG
            
            SetTexture [_MainTex] {
                ConstantColor [_Color]
                Combine texture * constant
            }
            SetTexture [_MainTex] {
                Combine previous * primary DOUBLE
            }
			 
	 	}      
    }
    Fallback "Transparent/Cutout/Diffuse"
}
