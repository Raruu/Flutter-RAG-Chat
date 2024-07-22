def split_list(input_list: list[str], slice_size: int = 7) -> list[list[str]]:
    return [
        input_list[i : i + slice_size] for i in range(0, len(input_list), slice_size)
    ]


def clamp(n, min_value, max_value):
    return max(min_value, min(n, max_value))
