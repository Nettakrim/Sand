Shader "Custom/Display" {
Properties {
    _WorldTex ("WorldTex", 2D) = "black" {}
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

            sampler2D _WorldTex;
            float4 _WorldTex_ST;
            sampler2D _SandColors;
            sampler2D _GroundColors;
            float4 _TexelSize;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _WorldTex);
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







            float3 renderEmpty(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                return baseColor;
            }

            float3 renderWall(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                return float3(0.1, 0.1, 0.1);
            }

            float3 renderConveyor(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                float2 pos = rotatePosition(pixelPos, data.a)/2;

                pos.y = frac(pos.y+_Time.y*5)-0.5;
                bool state = abs(pos.x)>pos.y && (pos.y > 0 || (abs(pos.x)+abs(pos.y) < 0.5));
                state = state^((worldPos.x^worldPos.y)&1);

                float3 color = state ? float3(0.25,0.25,0.3) : float3(0.2, 0.2, 0.25);

                if (data.g > 0) {
                    color = baseColor;
                }

                return color;
            }

            float3 renderSplitter(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                float3 color;

                bool isRight = ((data.a >> 2)&1) == 0;
                color = float3(0.6, 0.6, 0.6);

                float2 enterPos = rotatePosition(pixelPos, data.a);
                float2 exitPos = rotatePosition(pixelPos, (data.a&3) ^ (2 | ((data.a >> 1) ^ (data.a >> 2))));

                bool inner = max(abs(pixelPos.x),abs(pixelPos.y)) < 0.3;

                if (data.g > 0) {
                    if (inner) {
                        color = baseColor;
                    }
                    else if (enterPos.y > -exitPos.y) {
                        color = abs(enterPos.x) > abs(exitPos.x) ? float3(1, 1, 1) : float3(0.8, 0.8, 0.8);
                    }
                } else if (inner) {
                    color = isRight ? float3(0.1, 0.1, 0.1) : float3(0.3, 0.3, 0.3);
                }

                return color;
            }

            float3 renderCrossroad(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                float3 color;
                bool state = abs(pixelPos.x) > abs(pixelPos.y);

                color = state ? (data.g == 0 ? float3(0.1, 0.1, 0.1) : baseColor) : (data.a == 0 ? float3(0.2, 0.2, 0.2) : getBaseColor(data.a, data.a));
                
                return color;
            }

            float3 renderMiner(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                uint timer = data.a >> 2;

                float2 pos = rotatePosition(pixelPos, data.a);

                float angle = ((atan2(pos.x*2, pos.y*2)/3.14159265)+0.75)/1.5;

                float3 color = (angle + float(timer)/6.0) > 1 ? float3(1, 1, 1) : float3(0.1, 0.1, 0.1);

                if (max(abs(pos.x),abs(pos.y)) < 0.3 || angle < 0 || angle > 1) {
                    color = baseColor;
                }

                return color;
            }

            float3 renderPainter(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                uint timer = data.a >> 2;

                float3 color;
                float3 brightGround = getBaseColor(0, (data.r & 31) | (data.g == 0 ? data.r : (data.g & 224)));

                bool inner = max(abs(pixelPos.x),abs(pixelPos.y)) < 0.3;

                if (data.g > 0) {
                    if (inner) {
                        color = lerp(baseColor, brightGround, float(timer)/7);
                    } else {
                        color = brightGround;
                    }
                } else {
                    color = inner ? baseColor : brightGround;
                }

                return color;
            }

            float3 renderBin(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                float size = 0.2;
                bool state = ((pixelPos.x < pixelPos.y-size) || (pixelPos.x > pixelPos.y+size)) && ((-pixelPos.x < pixelPos.y-size) || (-pixelPos.x > pixelPos.y+size));
                return state ? float3(1,0.2,0.2) : float3(1,1,1);
            }

            float3 renderShippingPoint(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                return baseColor;
            }

            float3 renderWeightFilter(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                bool state = (abs(pixelPos.x)+abs(pixelPos.y)) < 0.5;
                return state ? baseColor : 1-((float((data.a-4) & 12)/12.0));
            }

            float3 renderColorFilter(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                bool state = (abs(pixelPos.x)+abs(pixelPos.y)) < 0.5;
                return state ? baseColor : getBaseColor(0, (data.a & 28) | 1);
            }

            float3 renderSmartFilter(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                bool state = (abs(pixelPos.x)+abs(pixelPos.y)) < 0.5;
                return state ? baseColor : float3(1,0,1);
            }

            float3 renderGate(uint4 data, float3 baseColor, float2 pixelPos, uint2 worldPos) {
                float3 color;

                float2 pos = rotatePosition(pixelPos, data.a);

                bool inner = (abs(pos.x) < 0.3) && data.g > 0;

                float id = float(data.a >> 2)/64;
                color = float3(id,id,id);

                return inner ? baseColor : color;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 pixelPos = float2(frac(i.texcoord.x*_TexelSize.z)-0.5, frac(i.texcoord.y*_TexelSize.w)-0.5);
                uint2 worldPos = uint2(uint(i.texcoord.x*_TexelSize.z), uint(i.texcoord.y*_TexelSize.w));

                uint4 data = uint4(tex2D(_WorldTex, i.texcoord)*255.0);
                float3 col = float3(0,0,0);

                float3 baseColor = getBaseColor(data.r, data.g);

                if (data.b == 0) {
                    col = renderEmpty(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 1) {
                    col = renderWall(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 2) {
                    col = renderConveyor(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 3) {
                    col = renderSplitter(data, baseColor, pixelPos, worldPos);
                } else if (data.b >= 4 && data.b <= 7) {
                    col = renderCrossroad(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 8) {
                    col = renderMiner(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 9) {
                    col = renderPainter(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 10) {
                    col = renderBin(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 11) {
                    col = renderShippingPoint(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 12) {
                    col = renderWeightFilter(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 13) {
                    col = renderColorFilter(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 14) {
                    col = renderSmartFilter(data, baseColor, pixelPos, worldPos);
                } else if (data.b == 15) {
                    col = renderGate(data, baseColor, pixelPos, worldPos);
                }

                return fixed4(col.r, col.g, col.b, 1);
            }
        ENDCG
    }
}

}
