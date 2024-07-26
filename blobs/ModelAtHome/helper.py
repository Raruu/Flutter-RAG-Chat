import re

def split_list(input_list: list[str], slice_size: int = 7) -> list[list[str]]:
    return [
        input_list[i : i + slice_size] for i in range(0, len(input_list), slice_size)
    ]

def clamp(n, min_value, max_value):
    return max(min_value, min(n, max_value))

def join_sentences_chunk_to_paragraph(sentences_chunk: str):
        return re.sub(
            r"\.([A-Z])", r". \1", "".join(sentences_chunk).replace("  ", " ").strip()
        )