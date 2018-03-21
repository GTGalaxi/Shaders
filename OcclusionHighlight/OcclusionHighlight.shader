Shader "Custom/OcclusionHighlight" {
Properties {
    _Color ("Main Colour", Color) = (.5,.5,.5,1)
    _HighlightCol ("Highlight Colour" , Color) = (0,1,1,0.7)
    [Toggle(INDEPENDENT_ALPHA)]
    _IndependentAlpha ("Independent Highlight Alpha", Float) = 0
    [Toggle(TRANSPARENT_TRUE)] 
    _TransHigh ("Highlight Transparency", Float) = 1
    [Toggle(ZWRITE_ON)] 
    _ZWrite ("ZWrite", Float) = 0
    _Cutoff ("Cutoff", Range(0,1)) = 0.1
    _MainTex ("Base (RGB)", 2D) = "white" {}
}
SubShader {
        // occlusion highlight rendering pass
    Pass {
        Name "OHigh"
        Tags { "RenderType"="Transparent" "Queue" = "AlphaTest" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZTest Greater
        Cull Off
        ZWrite [_ZWrite] // comment out for showing texture and outline through wall               
        
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
        float4 _Color;
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
            clip( colour.a * _Color.a  - _Cutoff );
            #ifdef INDEPENDENT_ALPHA
                colour.a = colour.a * _HighlightCol.a;
            #else
                colour.a = colour.a * _HighlightCol.a * _Color.a;
            #endif
            fixed4 HighlightOut = _HighlightCol * pow(Highlight, 0);
            #ifdef TRANSPARENT_TRUE
                HighlightOut.a = colour.a;
            #endif
            return HighlightOut;
        }
        ENDCG
    }
        // base texture rendering pass
    Pass {
        Name "Base"
        Tags { "RenderType"="Transparent" "Queue" = "AlphaTest" "LightMode"="ForwardBase" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
        #include "AutoLight.cginc"
    
        struct v2f {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            SHADOW_COORDS(1)
            fixed3 diff : COLOR0;
            fixed3 ambient : COLOR1;
        };
    
        sampler2D _MainTex;
        float4 _Color;
        float _Cutoff;

        v2f vert (appdata_base v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;

            half3 worldNormal = UnityObjectToWorldNormal(v.normal);

            half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
            
            o.diff = nl * _LightColor0;
            o.ambient = ShadeSH9(half4(worldNormal,1));
            TRANSFER_SHADOW(o)
            return o;
        }
    
        fixed4 frag (v2f i) : SV_Target
        {    
            fixed4 colour = tex2D(_MainTex, i.uv);
            fixed shadow = SHADOW_ATTENUATION(i);
            fixed3 lighting = i.diff * shadow + i.ambient;
            
            clip( colour.a * _Color.a  - _Cutoff );
            colour.rgb *= lighting;
            return colour * _Color;
        }
        ENDCG
    }
        // shadow caster rendering pass, implemented manually
    Pass {
        Name "Shadows"
        Tags {"LightMode"="ShadowCaster"}
        
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_shadowcaster
        #include "UnityCG.cginc"
        #include "ShadowCastCG.cginc"

        #pragma target 2.0

        v2f vert(appdata_base v)
        {
            v2f o;
            o.uv = v.texcoord;
            TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
            return o;
        }

        float4 frag(v2f i) : SV_Target
        {
            fixed4 texcol = tex2D( _MainTex, i.uv );
            clip( texcol.a * _Color.a  - _Cutoff );
            SHADOW_CASTER_FRAGMENT(i)
        }
        ENDCG
    }     
}
Fallback "Transparent/Cutout/Diffuse"
}