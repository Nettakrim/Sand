Shader "Custom/Display" {
Properties {
    _TexA ("TexA", 2D) = "black" {}
    _TexB ("TexB", 2D) = "black" {}
    _Step ("Step", float) = 0
}

SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Pass {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _TexA;
            sampler2D _TexB;
            float4 _TexA_ST;
            float _Step;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _TexA);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                uint4 data = uint4(lerp(tex2D(_TexA, i.texcoord), tex2D(_TexB, i.texcoord), _Step)*255.0);
                float4 col = float4(0,0,0,0);

                col = data;

                return col;
            }
        ENDCG
    }
}

}
