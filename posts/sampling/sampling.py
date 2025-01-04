import math
import random
from datetime import datetime
import tqdm
import scipy


def search_for_lg2(sample, probs):
    left = 0
    right = len(probs) - 1

    while left < right:
        mid = left + (right - left) // 2
        if probs[mid] <= sample:
            left = mid + 1
        else:
            right = mid
    return left


def search_for_linear(sample, probs):
    for i, t in enumerate(probs):
        if t > sample:
            return i
    return len(probs) - 1


def sample(logits):
    # O(n)
    exps = [math.exp(x) for x in logits]

    # O(n)
    denom = sum(exps)

    # O(n)
    # this step inlines probability calculation
    # with cumulative sum calculation
    probs = [exps[0] / denom]
    for i in range(1, len(exps)):
        probs.append(probs[i - 1] + exps[i] / denom)

    # O(1), probably
    sample = random.random()

    # O(lg(n)), hopefully
    index = search_for_lg2(sample, probs)
    return index


def eval_gumbel_log(x):
    return -math.log(-math.log(x))


def eval_gumbel_direct(x):
    delta = 1 / math.e
    q4 = -7 * math.e**4 / 180
    q3 = math.e**3 / 24
    q2 = -(math.e**2) / 6

    # 1. move the x to 0
    x -= delta
    # 2. apply the polynomial
    numerator = math.e * x
    # Horner's method!
    denominator = ((((q4 * x) + q3) * x + q2) * x) * x + 1
    return numerator / denominator


def sample_gumbel(logits):
    max = -float("inf")
    max_i = 0
    for i, x in enumerate(logits):
        # G = eval_gumbel_log(random.random())
        G = eval_gumbel_direct(random.random())
        v = x + G
        if v > max:
            max = v
            max_i = i
    return max_i


def categorical(logits):
    exps = [math.exp(x) for x in logits]
    denom = sum(exps)
    probs = [t / denom for t in exps]
    return probs


if __name__ == "__main__":
    import json

    result_dict = {"method": "gumbel_direct", "x": [], "y": []}
    sizes = (
        list(range(2, 10))
        + list(range(10, 100, 10))
        + list(range(100, 1000, 100))
        + list(range(1000, 10_000, 1000))
        + [10_000]
    )
    for n in tqdm.tqdm(sizes, position=0, miniters=1):
        vals = []
        for _ in range(10_000):
            logits = [random.random() for _ in range(n)]
            start = datetime.now()
            sample_gumbel(logits)
            time_delta = datetime.now() - start
            vals.append(time_delta.microseconds)
        result_dict["x"].append(n)
        result_dict["y"].append(sum(vals) / len(vals))

    with open("gumbel_direct.json", "w") as file:
        json.dump(result_dict, file)
    # for n in (5, 10, 50, 100):
    #     total_count = 5000 * n
    #     logits = [random.random() for _ in range(n)]
    #     expected_freq = [t * total_count for t in categorical(logits)]
    #     samples = [0] * n
    #     for _ in range(total_count):
    #         i = sample_gumbel(logits)
    #         samples[i] += 1
    #     result = scipy.stats.chisquare(samples, expected_freq, ddof=n - 2)
    #     print(f"cumulative, gumbel, k={n}, p_value={result.pvalue}")

    # 334.236/745.302
# approx. 0.4484571354
