Shader "Custom/blinnPhong"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Normal("Normal", 2D) = "blue" {}
        _Specular("Specular", 2D) = "black" {}
        _Environment("Environment", Cube) = "white" {}
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass
        {
            Tags { "LightMode" = "Forwardbase"}
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase

            struct vertIN {
                float4 vert : POSITION;
                float3 norm : NORMAL;
                float3 tan : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct vertOUT {
                float4 pos : SV_POSITION;
                float3x3 tbn : TEXCOORD0;
                float2 uv : TEXCOORD3;
                float worldPos : TEXCOORD4;
            };

            vertOUT vert(vertIN v)
            {
                vertOUT o;
                o.pos = UnityObjectToClipPos(v.vert);
                o.uv = v.uv;

                float3 worldNorm = UnityObjectToWorldNormal(v.norm);
                float3 worldTan = UnityObjectToWorldDir(v.tan.xyz);
                float3 worldBitan = cross(worldNorm, worldTan);

                o.worldPos = mul(unity_ObjectToWorld, v.vert).xyz;
                o.tbn = float3x3(worldTan, worldBitan, worldNorm);

                return o;
            }

            sampler2D _Normal;
            sampler2D _Diffuse;
            sampler2D _Specular;
            samplerCUBE _Environment;
            float4 _LightColour0;

            float4 frag(vertOUT i) : SV_TARGET
            {
                // common variables
                float3 unpackNormal = UnpackNormal(tex2D(_Normal, i.uv));
                float3 normal = normalize(mul(transpose(i.tbn), unpackNormal));
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfVec = normalize(viewDir + _WorldSpaceLightPos0.xyz);
                float3 env = texCUBE(_Environment, reflect(-viewDir, normal)).rgb;
                float3 sceneLight = lerp(_LightColour0, env + _LightColour0 * 0.5, 0.5);

                // Blinn phong calulations
                float diffuseBlinnPhong = max(dot(normal, _WorldSpaceLightPos0.xyz), 0.0);

                float specularblinnPhong = max(0.0, dot(halfVec, normal));
                specularblinnPhong = pow(specularblinnPhong, 4.0);

                float4 tex = tex2D(_Diffuse, i.uv);
                float4 specMask = tex2D(_Specular, i.uv);

                float3 specularColour = specMask.rgb * specularblinnPhong;

                //final calculations
                float3 resDiffuse = sceneLight * diffuseBlinnPhong * tex.rgb;
                float3 resSpecular = specularColour * sceneLight;
                float3 resAmbiant = UNITY_LIGHTMODEL_AMBIENT.rgb * tex.rgb;

                return float4(resDiffuse + resSpecular + resAmbiant, 1.0);
            }
            ENDCG
        }
    }
}
