Shader "Ogxd/Wireframe"
{
	Properties
	{
      _EdgeColor("Edge Color", Color) = (0 ,0 ,0 ,1)
      _WireframeThickness("Thickness", Range(0.0, 3.0)) = 0.5
      [Toggle()] _FixedWidth("Relative to Screen", Float) = 0.0
      _WireframeSmoothing("Smoothing", Range(0.0, 3.0)) = 1.0
      [Toggle(_QUADIFY)] _Quadify("Quadify", Float) = 0.0
	}

   SubShader
   {
      Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }

      Pass
      {
         Name "Wireframe"

         Cull Back
         ZWrite On
         Blend SrcAlpha OneMinusSrcAlpha
         
         CGPROGRAM

         #pragma glsl
         #pragma vertex vert
         #pragma geometry geom
         #pragma fragment frag
         #pragma multi_compile __ _QUADIFY
         #include "UnityCG.cginc"

         struct appdata
         {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
         };

         struct v2g
         {
            float4 vertex : SV_POSITION;
         };

         struct g2f
         {
            float4 vertex : SV_POSITION;
            float3 bary : TEXCOORD1;
         };

         v2g vert(appdata v)
         {
            v2g o;
            o.vertex = mul(unity_ObjectToWorld, v.vertex);
            return o;
         }

         [maxvertexcount(3)]
         void geom(triangle v2g i[3], inout TriangleStream<g2f> triStream) {
            float3 param = float3(0.0, 0.0, 0.0);

#ifdef _QUADIFY
            float A = length(i[0].vertex - i[1].vertex);
            float B = length(i[1].vertex - i[2].vertex);
            float C = length(i[2].vertex - i[0].vertex);

            if (A > B && A > C)
               param.y = 1.0;
            else if (B > C && B > A)
               param.x = 1.0;
            else
               param.z = 1.0;
#endif

            g2f o;
            o.vertex = mul(UNITY_MATRIX_VP, i[0].vertex);
            o.bary = float3(1.0, 0.0, 0.0) + param;
            triStream.Append(o);

            o.vertex = mul(UNITY_MATRIX_VP, i[1].vertex);
            o.bary = float3(0.0, 0.0, 1.0) + param;
            triStream.Append(o);

            o.vertex = mul(UNITY_MATRIX_VP, i[2].vertex);
            o.bary = float3(0.0, 1.0, 0.0) + param;
            triStream.Append(o);
         }

         float _WireframeThickness;
         float _WireframeSmoothing;
         float _FixedWidth;
         float4 _EdgeColor;

         half4 frag(g2f i) : SV_Target
         {
            float3 bary = i.bary;
            float3 deltas = fwidth(bary);
            float3 smoothing = deltas * _WireframeSmoothing;
            float3 thickness = deltas * _WireframeThickness / max((1 - _FixedWidth) * i.vertex.w, _FixedWidth);
            bary = smoothstep(thickness, thickness + smoothing, bary);
            float t = min(bary.x, min(bary.y, bary.z));

            return half4(_EdgeColor.rgb, 1 - t);
         }
         ENDCG
      }
   }
}