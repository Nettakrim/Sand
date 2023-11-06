Shader "Custom/Display" {
Properties {
    _TexA ("TexA", 2D) = "black" {}
    _TexB ("TexB", 2D) = "black" {}
    _Step ("Step", float) = 0
    _SandColors ("SandColors", 2D) = "white" {}
    _GroundColors ("GroundColors", 2D) = "white" {}
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
            sampler2D _GroundColors;
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



            float2 rotatePosition(float2 pixelPos, uint data) {
                if ((data&2) == 0) {
                    pixelPos = pixelPos.yx;
                }
                if ((data&1) == 0) {
                    pixelPos = float2(pixelPos.x, -pixelPos.y);
                }
                return pixelPos;
            }

            float2 getColorPosition(uint value) {
                return float2(float((value >> 5) + ((value & 31) > 15 ? 8 : 0))/16.0, float(value & 15)/16.0);
            }

            float3 getBaseColor(uint ground, uint sand) {
                return sand == 0 ? tex2D(_GroundColors, getColorPosition(ground)).rgb : tex2D(_SandColors, getColorPosition(sand)).rgb;
            }







            float3 renderEmpty(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderWall(uint4 data, float3 baseColor, float2 pixelPos) {
                return float3(0.1, 0.1, 0.1);
            }

            float3 renderConveyor(uint4 data, float3 baseColor, float2 pixelPos) {
                float2 pos = rotatePosition(pixelPos, data.a);

                pos.y = frac(pos.y+_Time.y*5)-0.5;
                bool state = abs(pos.x)>pos.y && (pos.y > 0 || (abs(pos.x)+abs(pos.y) < 0.5));

                float3 color = state ? float3(0.25,0.25,0.3) : float3(0.2, 0.2, 0.25);

                if (data.g > 0) {
                    color = baseColor;
                }

                return color;
            }

            float3 renderSplitter(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderCrossroad(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderMiner(uint4 data, float3 baseColor, float2 pixelPos) {
                uint timer = data.a >> 2;

                float2 pos = rotatePosition(pixelPos, data.a);

                float angle = ((atan2(pos.x*2, pos.y*2)/3.14159265)+0.75)/1.5;

                float3 color = (angle + float(timer)/7.0) > 1 ? float3(1, 1, 1) : float3(0.1, 0.1, 0.1);

                if (max(abs(pos.x),abs(pos.y)) < 0.3 || angle < 0 || angle > 1) {
                    color = baseColor;
                }

                return color;
            }

            float3 renderPainter(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderBin(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderShippingPoint(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderWeightFilter(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderColorFilter(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderSmartFilter(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            float3 renderGate(uint4 data, float3 baseColor, float2 pixelPos) {
                return baseColor;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 pixelPos = float2(frac(i.texcoord.x*_TexelSize.z)-0.5, frac(i.texcoord.y*_TexelSize.w)-0.5);

                uint4 data = uint4(lerp(tex2D(_TexA, i.texcoord), tex2D(_TexB, i.texcoord), _Step)*255.0);
                float3 col = float3(0,0,0);

                float3 baseColor = getBaseColor(data.r, data.g);

                if (data.b == 0) {
                    col = renderEmpty(data, baseColor, pixelPos);
                } else if (data.b == 1) {
                    col = renderWall(data, baseColor, pixelPos);
                } else if (data.b == 2) {
                    col = renderConveyor(data, baseColor, pixelPos);
                } else if (data.b == 3) {
                    col = renderSplitter(data, baseColor, pixelPos);
                } else if (data.b >= 4 && data.b <= 7) {
                    col = renderCrossroad(data, baseColor, pixelPos);
                } else if (data.b == 8) {
                    col = renderMiner(data, baseColor, pixelPos);
                } else if (data.b == 9) {
                    col = renderPainter(data, baseColor, pixelPos);
                } else if (data.b == 10) {
                    col = renderBin(data, baseColor, pixelPos);
                } else if (data.b == 11) {
                    col = renderShippingPoint(data, baseColor, pixelPos);
                } else if (data.b == 12) {
                    col = renderWeightFilter(data, baseColor, pixelPos);
                } else if (data.b == 13) {
                    col = renderColorFilter(data, baseColor, pixelPos);
                } else if (data.b == 14) {
                    col = renderSmartFilter(data, baseColor, pixelPos);
                } else if (data.b == 15) {
                    col = renderGate(data, baseColor, pixelPos);
                }

                return fixed4(col.r, col.g, col.b, 1);
            }
        ENDCG
    }
}

}
