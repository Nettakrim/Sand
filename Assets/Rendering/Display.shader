Shader "Custom/Display" {
Properties {
    _TexA ("TexA", 2D) = "black" {}
    _TexB ("TexB", 2D) = "black" {}
    _Step ("Step", float) = 0
    _SandColors ("SandColors", 2D) = "white" {}
    _TexelSize("TexelSize", Vector) = (1, 1, 1, 1)
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
            sampler2D _SandColors;
            float4 _TexelSize;

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


            float3 renderEmpty(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderWall(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderConveyor(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderSplitter(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderCrossroad(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderMiner(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderPainter(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderBin(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderShippingPoint(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderWeightFilter(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderColorFilter(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderSmartFilter(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }

            float3 renderGate(uint4 data, float3 sandColor, float2 pixelPos) {
                return sandColor;
            }



            float3 getSandColor(uint sand) {
                return tex2D(_SandColors, float2(float((sand >> 5) + ((sand & 31) > 15 ? 8 : 0))/16.0, float(sand & 15)/16.0)).rgb;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 pixelPos = float2(frac(i.texcoord.x*_TexelSize.z)-0.5, frac(i.texcoord.y*_TexelSize.w)-0.5);

                uint4 data = uint4(lerp(tex2D(_TexA, i.texcoord), tex2D(_TexB, i.texcoord), _Step)*255.0);
                float3 col = float3(0,0,0);

                float3 sandColor = getSandColor(data.g);

                if (data.b == 0) {
                    col = renderEmpty(data, sandColor, pixelPos);
                } else if (data.b == 1) {
                    col = renderWall(data, sandColor, pixelPos);
                } else if (data.b == 2) {
                    col = renderConveyor(data, sandColor, pixelPos);
                } else if (data.b == 3) {
                    col = renderSplitter(data, sandColor, pixelPos);
                } else if (data.b >= 4 && data.b <= 7) {
                    col = renderCrossroad(data, sandColor, pixelPos);
                } else if (data.b == 8) {
                    col = renderMiner(data, sandColor, pixelPos);
                } else if (data.b == 9) {
                    col = renderPainter(data, sandColor, pixelPos);
                } else if (data.b == 10) {
                    col = renderBin(data, sandColor, pixelPos);
                } else if (data.b == 11) {
                    col = renderShippingPoint(data, sandColor, pixelPos);
                } else if (data.b == 12) {
                    col = renderWeightFilter(data, sandColor, pixelPos);
                } else if (data.b == 13) {
                    col = renderColorFilter(data, sandColor, pixelPos);
                } else if (data.b == 14) {
                    col = renderSmartFilter(data, sandColor, pixelPos);
                } else if (data.b == 15) {
                    col = renderGate(data, sandColor, pixelPos);
                }

                return fixed4(col.r, col.g, col.b, 1);
            }
        ENDCG
    }
}

}
