#!/usr/bin/env python3
"""
Train the tiny Hello Computer FAQ reranker.

This is intentionally offline-only. The app should ship frozen weights, while
curated data and preference examples live here for repeatable evaluation.

Training stages:
1. Supervised BCE: learns from labeled correct/incorrect FAQ candidates.
2. Preference optimization: an RL-style contextual bandit stage that rewards
   chosen candidates over rejected candidates using pairwise policy gradients.
"""

from __future__ import annotations

import argparse
import copy
import json
import math
import random
from pathlib import Path
from typing import Iterable


INPUT_SIZE = 8
HIDDEN_SIZE = 6


INITIAL_HIDDEN_WEIGHTS = [
    [1.20, 0.85, 0.70, 1.10, 0.35, 0.30, 0.10, -0.15],
    [0.30, 1.25, 0.55, 0.90, 0.25, 0.45, 0.05, -0.10],
    [0.15, 0.25, 1.35, 0.45, 0.80, 0.60, 0.05, -0.20],
    [0.60, 0.55, 0.35, 1.45, 0.15, 0.10, -0.05, 0.05],
    [0.75, 0.40, 0.25, 0.70, 0.10, 0.20, 0.35, -0.30],
    [0.20, 0.30, 0.20, 0.80, 0.15, 0.35, 0.55, 0.10],
]
INITIAL_HIDDEN_BIASES = [-0.65, -0.60, -0.55, -0.75, -0.45, -0.30]
INITIAL_OUTPUT_WEIGHTS = [[1.25, 1.05, 0.95, 1.40, 0.80, 0.70]]
INITIAL_OUTPUT_BIASES = [-1.55]


class TinyReranker:
    def __init__(self) -> None:
        self.hidden_weights = copy.deepcopy(INITIAL_HIDDEN_WEIGHTS)
        self.hidden_biases = copy.deepcopy(INITIAL_HIDDEN_BIASES)
        self.output_weights = copy.deepcopy(INITIAL_OUTPUT_WEIGHTS)
        self.output_biases = copy.deepcopy(INITIAL_OUTPUT_BIASES)

    def forward(self, features: list[float]) -> tuple[list[float], float, float]:
        hidden_pre = []
        hidden = []
        for row, bias in zip(self.hidden_weights, self.hidden_biases):
            z = sum(w * x for w, x in zip(row, features)) + bias
            hidden_pre.append(z)
            hidden.append(math.tanh(z))

        logit = sum(w * h for w, h in zip(self.output_weights[0], hidden)) + self.output_biases[0]
        confidence = sigmoid(logit)
        return hidden, logit, confidence

    def supervised_step(self, features: list[float], label: float, learning_rate: float) -> float:
        hidden, _logit, confidence = self.forward(features)
        error = confidence - label

        old_output_weights = self.output_weights[0][:]
        for j in range(HIDDEN_SIZE):
            self.output_weights[0][j] -= learning_rate * error * hidden[j]
        self.output_biases[0] -= learning_rate * error

        for j in range(HIDDEN_SIZE):
            hidden_grad = error * old_output_weights[j] * (1.0 - hidden[j] * hidden[j])
            for i in range(INPUT_SIZE):
                self.hidden_weights[j][i] -= learning_rate * hidden_grad * features[i]
            self.hidden_biases[j] -= learning_rate * hidden_grad

        return binary_cross_entropy(label, confidence)

    def preference_step(
        self,
        chosen_features: list[float],
        rejected_features: list[float],
        reward: float,
        learning_rate: float,
        kl_anchor: "TinyReranker",
        kl_weight: float,
    ) -> float:
        chosen_hidden, chosen_logit, _ = self.forward(chosen_features)
        rejected_hidden, rejected_logit, _ = self.forward(rejected_features)
        margin = chosen_logit - rejected_logit
        preference_probability = sigmoid(margin)
        margin_error = (preference_probability - 1.0) * reward

        old_output_weights = self.output_weights[0][:]
        for j in range(HIDDEN_SIZE):
            grad = margin_error * (chosen_hidden[j] - rejected_hidden[j])
            grad += kl_weight * (self.output_weights[0][j] - kl_anchor.output_weights[0][j])
            self.output_weights[0][j] -= learning_rate * grad
        self.output_biases[0] -= learning_rate * kl_weight * (self.output_biases[0] - kl_anchor.output_biases[0])

        for features, hidden, direction in (
            (chosen_features, chosen_hidden, 1.0),
            (rejected_features, rejected_hidden, -1.0),
        ):
            for j in range(HIDDEN_SIZE):
                hidden_grad = margin_error * direction * old_output_weights[j] * (1.0 - hidden[j] * hidden[j])
                for i in range(INPUT_SIZE):
                    anchor_delta = self.hidden_weights[j][i] - kl_anchor.hidden_weights[j][i]
                    grad = hidden_grad * features[i] + kl_weight * anchor_delta
                    self.hidden_weights[j][i] -= learning_rate * grad
                bias_delta = self.hidden_biases[j] - kl_anchor.hidden_biases[j]
                self.hidden_biases[j] -= learning_rate * (hidden_grad + kl_weight * bias_delta)

        return -math.log(max(preference_probability, 1e-9)) * reward


def sigmoid(value: float) -> float:
    if value >= 0:
        z = math.exp(-value)
        return 1.0 / (1.0 + z)
    z = math.exp(value)
    return z / (1.0 + z)


def binary_cross_entropy(label: float, prediction: float) -> float:
    clipped = min(max(prediction, 1e-9), 1.0 - 1e-9)
    return -(label * math.log(clipped) + (1.0 - label) * math.log(1.0 - clipped))


def load_training_data(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    expected_features = data.get("feature_names", [])
    if len(expected_features) != INPUT_SIZE:
        raise ValueError(f"Expected {INPUT_SIZE} feature names, found {len(expected_features)}")

    for example in data.get("supervised_examples", []):
        validate_features(example["features"], example.get("candidate_id", "supervised"))
    for example in data.get("supervised_eval_examples", []):
        validate_features(example["features"], example.get("candidate_id", "supervised_eval"))
    for example in data.get("preference_examples", []):
        validate_features(example["chosen_features"], example.get("chosen_candidate_id", "chosen"))
        validate_features(example["rejected_features"], example.get("rejected_candidate_id", "rejected"))
    for example in data.get("preference_eval_examples", []):
        validate_features(example["chosen_features"], example.get("chosen_candidate_id", "chosen_eval"))
        validate_features(example["rejected_features"], example.get("rejected_candidate_id", "rejected_eval"))
    return data


def validate_features(features: Iterable[float], label: str) -> None:
    values = list(features)
    if len(values) != INPUT_SIZE:
        raise ValueError(f"{label} has {len(values)} features, expected {INPUT_SIZE}")
    if any(not isinstance(value, (int, float)) for value in values):
        raise ValueError(f"{label} contains non-numeric features")


def evaluate_supervised(model: TinyReranker, examples: list[dict], threshold: float = 0.5) -> dict:
    if not examples:
        return {"loss": 0.0, "accuracy": 0.0}

    loss = 0.0
    correct = 0
    for example in examples:
        label = float(example["label"])
        _hidden, _logit, confidence = model.forward(example["features"])
        loss += binary_cross_entropy(label, confidence)
        correct += int((confidence >= threshold) == bool(label))

    return {
        "loss": loss / len(examples),
        "accuracy": correct / len(examples),
    }


def evaluate_preferences(model: TinyReranker, examples: list[dict]) -> dict:
    if not examples:
        return {"loss": 0.0, "accuracy": 0.0}

    loss = 0.0
    correct = 0
    for example in examples:
        _hidden, chosen_logit, _confidence = model.forward(example["chosen_features"])
        _hidden, rejected_logit, _confidence = model.forward(example["rejected_features"])
        preference_probability = sigmoid(chosen_logit - rejected_logit)
        loss += -math.log(max(preference_probability, 1e-9)) * float(example.get("reward", 1.0))
        correct += int(chosen_logit > rejected_logit)

    return {
        "loss": loss / len(examples),
        "accuracy": correct / len(examples),
    }


def train(args: argparse.Namespace) -> TinyReranker:
    data = load_training_data(Path(args.data))
    supervised_examples = data.get("supervised_examples", [])
    supervised_eval_examples = data.get("supervised_eval_examples", [])
    preference_examples = data.get("preference_examples", [])
    preference_eval_examples = data.get("preference_eval_examples", [])

    random.seed(args.seed)
    model = TinyReranker()

    print("Initial train supervised:", format_metrics(evaluate_supervised(model, supervised_examples)))
    print("Initial eval supervised:", format_metrics(evaluate_supervised(model, supervised_eval_examples)))
    print("Initial train preferences:", format_metrics(evaluate_preferences(model, preference_examples)))
    print("Initial eval preferences:", format_metrics(evaluate_preferences(model, preference_eval_examples)))

    for epoch in range(args.supervised_epochs):
        random.shuffle(supervised_examples)
        for example in supervised_examples:
            model.supervised_step(
                features=example["features"],
                label=float(example["label"]),
                learning_rate=args.supervised_learning_rate,
            )

    rl_anchor = copy.deepcopy(model)
    for epoch in range(args.preference_epochs):
        random.shuffle(preference_examples)
        for example in preference_examples:
            model.preference_step(
                chosen_features=example["chosen_features"],
                rejected_features=example["rejected_features"],
                reward=float(example.get("reward", 1.0)),
                learning_rate=args.preference_learning_rate,
                kl_anchor=rl_anchor,
                kl_weight=args.kl_weight,
            )

    final_train_supervised = evaluate_supervised(model, supervised_examples)
    final_eval_supervised = evaluate_supervised(model, supervised_eval_examples)
    final_train_preferences = evaluate_preferences(model, preference_examples)
    final_eval_preferences = evaluate_preferences(model, preference_eval_examples)

    print("Final train supervised:", format_metrics(final_train_supervised))
    print("Final eval supervised:", format_metrics(final_eval_supervised))
    print("Final train preferences:", format_metrics(final_train_preferences))
    print("Final eval preferences:", format_metrics(final_eval_preferences))
    print_overfit_warnings(
        train_supervised=final_train_supervised,
        eval_supervised=final_eval_supervised,
        train_preferences=final_train_preferences,
        eval_preferences=final_eval_preferences,
    )
    print()
    print(swift_constants(model))
    return model


def print_overfit_warnings(
    train_supervised: dict,
    eval_supervised: dict,
    train_preferences: dict,
    eval_preferences: dict,
) -> None:
    warnings = []
    if train_supervised["accuracy"] - eval_supervised["accuracy"] > 0.10:
        warnings.append(
            "Supervised accuracy gap is large. Add harder negative examples before shipping new weights."
        )
    if train_preferences["accuracy"] - eval_preferences["accuracy"] > 0.10:
        warnings.append(
            "Preference accuracy gap is large. Add more held-out preference pairs before trusting the RL stage."
        )

    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"- {warning}")


def format_metrics(metrics: dict) -> str:
    return ", ".join(f"{key}={value:.4f}" for key, value in metrics.items())


def swift_constants(model: TinyReranker) -> str:
    hidden_weights = format_matrix(model.hidden_weights)
    hidden_biases = format_vector(model.hidden_biases)
    output_weights = format_matrix(model.output_weights)
    output_biases = format_vector(model.output_biases)
    return f"""Swift weights:
hidden weights:
{hidden_weights}

hidden biases:
{hidden_biases}

output weights:
{output_weights}

output biases:
{output_biases}"""


def format_matrix(matrix: list[list[float]]) -> str:
    rows = [f"    [{', '.join(format_float(value) for value in row)}]" for row in matrix]
    return "[\n" + ",\n".join(rows) + "\n]"


def format_vector(vector: list[float]) -> str:
    return "[" + ", ".join(format_float(value) for value in vector) + "]"


def format_float(value: float) -> str:
    return f"{value:.4f}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train Hello Computer FAQ reranker weights.")
    parser.add_argument(
        "--data",
        default="Training/HelloComputer/hello_computer_training_data.json",
        help="Path to labeled training and preference data.",
    )
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--supervised-epochs", type=int, default=600)
    parser.add_argument("--preference-epochs", type=int, default=250)
    parser.add_argument("--supervised-learning-rate", type=float, default=0.035)
    parser.add_argument("--preference-learning-rate", type=float, default=0.012)
    parser.add_argument(
        "--kl-weight",
        type=float,
        default=0.001,
        help="Keeps preference optimization close to the supervised policy.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    train(parse_args())
