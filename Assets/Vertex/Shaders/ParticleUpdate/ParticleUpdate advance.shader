﻿Shader "Custom/ParticleUpdate/add" {
	Properties{
		_FirstPos("firstPos",2D) = "black"{}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		ZTest Always
		ZWrite On
		Cull Back

		CGINCLUDE

		uniform sampler2D
			_MrTex0,
			_MrTex1;
		uniform float3 _Pos;
		sampler2D _FirstPos;
			
		struct appdata
		{
			float4 vertex : POSITION;
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		struct pOut{
			float4 position : COLOR0;
			float4 velocity : COLOR1;
		};


		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = v.vertex;
			o.uv = (v.vertex.xy/v.vertex.w+1.0)*0.5;
			return o;
		}
		
		float3 firstPos(float2 uv){
			float3 pos = tex2D(_FirstPos, uv)-0.5;
			return pos * 20;
		}
		pOut frag_initialize(v2f i){
			float4
				position = float4(firstPos(i.uv),0),
				velocity = 0;
			
			pOut o;
			o.position = position;
			o.velocity = velocity;
			return o;
		}

		pOut frag_update_base (v2f i)
		{
			float4
				position = tex2D(_MrTex0, i.uv),
				velocity = tex2D(_MrTex1, i.uv);
			
			float3 rnd = tex2D(_FirstPos, i.uv+_Time.x)-0.5;
			velocity.xyz += rnd * length(velocity.xyz)*0.02;
			
			velocity = velocity * 0.99;
			position += velocity * unity_DeltaTime.x;
			
			velocity.w = 1.0;
			position.w = 1.0;
			if(length(position.xyz) > sqrt(2)*50){
				position.xyz = firstPos(i.uv) * 0.25;
				position.y += 50.0;
				velocity.xyz = 0;
			}
			
			pOut o;
			o.position = position;
			o.velocity = velocity;
			return o;
		}
		
		pOut frag_update_to_pos (v2f i) //マウスに寄ってくる
		{
			float4
				position = tex2D(_MrTex0, i.uv),
				velocity = tex2D(_MrTex1, i.uv);
			
			float3 to = _Pos.xyz - position.xyz;
			velocity.xyz = velocity.xyz + to * 0.5 * (i.uv.y+i.uv.x/64.0+0.1);
			
			pOut o;
			o.position = position;
			o.velocity = velocity;
			return o;
		}
		
		pOut frag_update_to_rnd (v2f i) //ランダムに動く
		{
			float4
				position = tex2D(_MrTex0, i.uv),
				velocity = tex2D(_MrTex1, i.uv);
			
			float3 rnd = tex2D(_FirstPos, i.uv+_Time.x)-0.5;
			velocity.xyz += rnd * length(velocity.xyz)*0.05;
			
			pOut o;
			o.position = position;
			o.velocity = velocity;
			return o;
		}
		
		pOut frag_update_toFirst (v2f i) //最初の位置に戻る
		{
			float4
				position = tex2D(_MrTex0, i.uv),
				velocity = tex2D(_MrTex1, i.uv);
			
			float3 to = firstPos(i.uv);
			velocity.xyz += (to - position.xyz);
			velocity.xyz *= 0.5;
			
			pOut o;
			o.position = position;
			o.velocity = velocity;
			return o;
		}
		
		pOut frag_update_gravity (v2f i) //重力
		{
			float4
				position = tex2D(_MrTex0, i.uv),
				velocity = tex2D(_MrTex1, i.uv);
			
			velocity.y -= unity_DeltaTime.x * 9.8;
			
			pOut o;
			o.position = position;
			o.velocity = velocity;
			return o;
		}
		
		pOut frag_update_coll (v2f i) //衝突
		{
			float4
				position = tex2D(_MrTex0, i.uv),
				velocity = tex2D(_MrTex1, i.uv);
			
			if(length(position.xyz-_Pos.xyz) < 8.0){
				float3 to = _Pos.xyz + 8.0*normalize(position.xyz-_Pos.xyz);
				velocity.xyz += (to - position.xyz) * 30;
				position.xyz = to;
			}
			
			pOut o;
			o.position = position;
			o.velocity = velocity;
			return o;
		}
		
		ENDCG

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_initialize
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_update_base
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_update_to_pos
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_update_to_rnd
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_update_toFirst
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_update_gravity
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_update_coll
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
	}
}