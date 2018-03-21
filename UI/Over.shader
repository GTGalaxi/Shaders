Shader "Custom/UI/OverCutout" {
Properties {
    _Color ("Tint", Color) = (1,1,1,1)
    _Cutoff ("Cutoff", Range(0,1)) = 0.1
    [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}

	_StencilComp ("Stencil Comparison", Float) = 8
	_Stencil ("Stencil ID", Float) = 0
	_StencilOp ("Stencil Operation", Float) = 0
	_StencilWriteMask ("Stencil Write Mask", Float) = 255
	_StencilReadMask ("Stencil Read Mask", Float) = 255
	_ColorMask ("Color Mask", Float) = 15
}
SubShader {
	Tags { 
		"RenderType"="Transparent" 
		"Queue" = "AlphaTest" 
        "PreviewType"="Plane"
        "CanUseSpriteAtlas"="True"
	}
	Stencil {
		Ref [_Stencil]
		Comp [_StencilComp]
		Pass [_StencilOp] 
		ReadMask [_StencilReadMask]
		WriteMask [_StencilWriteMask]
	}
	ColorMask [_ColorMask]
	
    Pass {
        Name "OHigh"
        
        Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
        ZTest Always
        
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"
        
        struct v2f {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };
        
        sampler2D _MainTex;
        float4 _Color;
        float _Cutoff;
        float4 _MainTex_ST;
        
        v2f vert (appdata_tan v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
            return o;
        }
        
        fixed4 frag (v2f i) : COLOR
        {
            fixed4 colour = tex2D(_MainTex, i.uv);   
            clip( colour.a * _Color.a  - _Cutoff );
            return colour * _Color;
        }
        ENDCG
    }
}
Fallback "Transparent/Cutout/Diffuse"
}