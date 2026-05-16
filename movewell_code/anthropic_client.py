"""
PhysioAI — Anthropic API Client
wrapper بسيط لاستدعاء Claude API
"""

import os
import json


async def get_ai_response(system: str, messages: list, max_tokens: int = 1000) -> str:
    """
    يستدعي Claude API ويرجع الرد كـ string
    في البيئة الحقيقية: استبدل بـ anthropic.AsyncAnthropic
    """
    try:
        import anthropic
        client = anthropic.AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
        response = await client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=max_tokens,
            system=system,
            messages=messages,
        )
        return response.content[0].text
    except ImportError:
        return "[anthropic library not installed — pip install anthropic]"
    except Exception as e:
        return f"[AI Error: {str(e)}]"


async def get_ai_explanation(prompt: str) -> str:
    """استدعاء بسيط بدون system prompt"""
    return await get_ai_response(
        system="أنت طبيب علاج طبيعي خبير ومتعاطف. ردودك بالعربية الفصحى البسيطة.",
        messages=[{"role": "user", "content": prompt}],
    )


async def get_ai_response_stream(system: str, messages: list):
    """Streaming version للردود الطويلة"""
    try:
        import anthropic
        client = anthropic.AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
        async with client.messages.stream(
            model="claude-sonnet-4-20250514",
            max_tokens=1500,
            system=system,
            messages=messages,
        ) as stream:
            async for text in stream.text_stream:
                yield text
    except Exception as e:
        yield f"[Error: {e}]"
